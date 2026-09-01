# Durable multi-agent development workflow

**Primary control plane:** Agent Deck  
**Execution plane:** native Claude Code, Codex CLI, Gemini CLI, GitHub Copilot CLI, and Hermes Agent  
**Local inference:** LM Studio on the M4 MacBook Pro (24 GB unified memory)  
**Last verified:** 2026-09-01

## Decision

Use **Agent Deck** as the session multiplexer and worktree manager. Keep each vendor's
native CLI and authentication path. Use **Hermes** as an additional agent and model
router, not as a compulsory proxy in front of every subscription.

This separation is deliberate:

- Agent Deck supports Claude, Codex, Gemini, Copilot, Hermes, persistent metadata,
  isolated tmux sessions, git worktrees, status, session forking, and fleet recovery.
- Native CLIs are the reliable way to consume ChatGPT, Claude, Gemini, and Copilot
  subscriptions.
- Hermes can use ChatGPT/Codex OAuth, Copilot OAuth/ACP, LM Studio, APIs, and paid
  fallbacks. It cannot turn every consumer subscription into a general-purpose API.
- Git worktrees prevent simultaneous agents from editing the same checkout.
- A tracked handoff file transfers explicit state between model families; native hidden
  conversation state is not portable.

## Architecture

| Layer | Tool | Responsibility | Persistent data |
|---|---|---|---|
| Portfolio queue | GitHub Issues/Projects | Cross-project priority, ownership, acceptance criteria | GitHub |
| Session control | Agent Deck | Groups, status, tmux sessions, worktrees, recovery | `~/.local/share/agent-deck` |
| Execution | Native CLIs | Coding, review, tests, research | Vendor-specific home directories |
| Flexible agent | Hermes | Provider switching, local delegation, specialist/fallback models | `~/.hermes` |
| Local worker | LM Studio | Cheap auxiliary work and one delegated child at a time | LM Studio application data |
| Durable handoff | `.ai/HANDOFF.md` | Model-neutral state, decisions, commands, blockers | Git branch |
| Isolation | Git worktrees | One writable checkout per task | Repository and `.worktrees/` |

Agent Deck is the command centre. VS Code remains a useful diff/editor surface: open the
specific worktree, not the primary checkout, while an agent is changing it.

## Subscription and routing policy

| Source | Preferred path | Use for | Do not assume |
|---|---|---|---|
| ChatGPT | Codex CLI sign-in; Hermes Codex OAuth where supported | Implementation, tests, review, orchestration | An OpenAI API key is included |
| Claude | Claude Code sign-in to Pro/Max | Architecture, difficult refactors, interactive iteration | Claude Pro is a general Anthropic API entitlement |
| Gemini | Gemini CLI Google-account sign-in | Large-context mapping, documentation, second opinions | A Gemini consumer plan can be consumed by Hermes as an API |
| GitHub Copilot | Copilot CLI; Hermes Copilot OAuth/ACP | Quick implementation, shell help, alternative model access | Usage is unlimited across all models |
| LM Studio | OpenAI-compatible localhost endpoint through Hermes | Compression, triage, extraction, bounded delegated work | A 9B local model should own high-risk changes |
| OpenRouter/API keys | Hermes fallback only | Outage escape hatch or a named specialist model | This is covered by existing subscriptions |

The default cost order is:

1. LM Studio for bounded auxiliary/delegated work.
2. A native subscription CLI selected for the task.
3. Hermes with an eligible OAuth-backed source.
4. Paid API/OpenRouter fallback only when explicitly useful.

Hermes `fallback_providers` handles availability failure. It is not a semantic router
that reliably decides task complexity.

## First installation

Apply the Darwin configuration:

```bash
darwin-rebuild switch --flake ~/.config/nix-multi#Ryans-MacBook-Pro
```

Authenticate each native CLI interactively. OAuth tokens and refresh credentials are
mutable and must remain outside Git and the Nix store:

```bash
codex
claude
gemini
copilot
hermes model
```

Then validate:

```bash
ai-agent-doctor
hermes-local-health
```

## Day-to-day workflow

### One project, several independent tasks

Create one worktree-backed session per task:

```bash
cd ~/projects/example

agent-deck add . -t api-auth -g example -c claude \
  --worktree agent/api-auth --new-branch

agent-deck add . -t auth-tests -g example -c codex \
  --worktree agent/auth-tests --new-branch

agent-deck add . -t repo-map -g example -c gemini \
  --worktree agent/repo-map --new-branch
```

Rules:

- One concurrently writing agent per worktree.
- One branch per independently mergeable outcome.
- Parallel agents may inspect the same repository, but they must not write to the same
  checkout.
- Give every task acceptance criteria and a required test command.
- Merge or rebase deliberately after reviewing each branch; do not let agents
  automatically merge one another's work.

### Different projects

Create an Agent Deck group for each project and set its default path:

```bash
agent-deck group create terrashift
agent-deck group create meridian
agent-deck group create nix-multi

agent-deck group update terrashift --default-path ~/projects/terrashift
agent-deck group update meridian --default-path ~/projects/meridian
agent-deck group update nix-multi --default-path ~/.config/nix-multi
```

Launch the TUI with `agent-deck` (or the `ai` alias). The actionable sort keeps
waiting and failed sessions above idle work.

### Use Hermes

Hermes appears as a first-class Agent Deck tool:

```bash
agent-deck launch . -t local-triage -g nix-multi -c hermes \
  -m "Inspect the flake and produce a bounded change plan."
```

Use Hermes when provider switching or local delegation is valuable. Use a native CLI
when the subscription path or tool-specific session features matter more.

## Model handoff protocol

Hidden conversation history does not transfer between Claude, Codex, Gemini, Copilot,
and Hermes. Before changing tool or reaching a quota boundary, require the current agent
to:

1. Stop starting new work.
2. Run the relevant tests or record why they cannot run.
3. Update a tracked `.ai/HANDOFF.md` from
   `docs/templates/AI-HANDOFF.md`.
4. Commit coherent changes, or explicitly list uncommitted files and diffs.
5. Record the exact next command and the next smallest action.

Stop the old session before starting a different agent in the same worktree:

```bash
WORKTREE=$(agent-deck session show api-auth --json | jq -r '.path')
agent-deck session stop api-auth
agent-deck launch "$WORKTREE" -t api-auth-codex -g example -c codex \
  -m "Read .ai/HANDOFF.md, verify repository state, then continue the recorded next action."
```

The receiving agent must verify `git status`, the branch name, and the last test result
before editing.

## Reboot, crash, and quota recovery

Agent Deck persists metadata and native session identifiers, but tmux processes do not
survive a reboot. Recover sequentially:

```bash
agent-deck fleet status
agent-deck fleet recover
agent-deck fleet recover --yes
```

The first recovery command is read-only and the second is a dry run. The confirmed
recovery staggers restarts to avoid simultaneous OAuth refresh-token races.

For one dead session:

```bash
agent-deck session restart <session>
```

If panes are alive but Agent Deck lost its control connection:

```bash
agent-deck session revive --all
```

When a provider quota is exhausted, do not repeatedly restart that CLI. Complete the
handoff protocol, stop it, and start an eligible native CLI or Hermes in the same
worktree.

## Persistence and backup boundary

Declarative Nix configuration owns packages, PATH, Agent Deck defaults, Hermes routing,
and helper commands. It must not own OAuth or API credentials.

Back up at least:

```text
~/.local/share/agent-deck
~/.claude
~/.codex
~/.gemini
~/.hermes
```

Use Time Machine or another encrypted user-level backup. Do not add these directories,
their auth files, `.env` files, or copied credentials to the repository.

## Review gates

Every agent task is complete only when:

- acceptance criteria are met;
- the diff is reviewed from outside the writing agent's session;
- tests and formatting pass, or failures are recorded;
- secrets and mutable auth state remain untracked;
- `.ai/HANDOFF.md` is current if work will continue;
- a human approves merge for security, infrastructure, destructive, or billing changes.

A useful pairing is writer/reviewer diversity: Claude writes and Codex reviews, Codex
writes and Gemini maps risk, or Hermes/local workers gather evidence while a frontier
native CLI makes the final change.

## Why not make Hermes the only entry point?

Hermes is the best provider-flexible agent in this stack, but it is not the best durable
multi-project operating system by itself. Consumer subscription support differs by
provider, and native CLIs retain their own session/resume behavior. Agent Deck can launch
all of them, preserve the fleet view, isolate their branches, and recover them after a
reboot. Hermes remains valuable inside that control plane.

## References

- [Agent Deck](https://github.com/asheshgoplani/agent-deck)
- [Agent Deck configuration](https://github.com/asheshgoplani/agent-deck/blob/main/skills/agent-deck/references/config-reference.md)
- [Agent Deck CLI and fleet recovery](https://github.com/asheshgoplani/agent-deck/blob/main/skills/agent-deck/references/cli-reference.md)
- [Hermes providers](https://hermes-agent.nousresearch.com/docs/integrations/providers)
- [Gemini CLI quotas](https://github.com/google-gemini/gemini-cli/blob/main/docs/resources/quota-and-pricing.md)
- [Claude Code setup](https://docs.anthropic.com/en/docs/claude-code/getting-started)
- [Codex with a ChatGPT plan](https://help.openai.com/en/articles/11369540-using-codex-with-your-chatgpt-plan)
