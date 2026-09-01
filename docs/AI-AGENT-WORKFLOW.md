# Durable multi-agent development workflow

**Terminal runtime:** Herdr  
**Execution plane:** native Claude Code, Codex CLI, Gemini CLI, GitHub Copilot CLI, Google Antigravity CLI, and Hermes Agent  
**Local inference:** LM Studio on the M4 MacBook Pro (24 GB unified memory)  
**Last verified:** 2026-09-01

## Decision

Use **Herdr** as the single agent-aware terminal multiplexer. Keep each vendor's native
CLI and authentication path. Use **Hermes** as an agent and model router inside Herdr,
not as a compulsory proxy in front of every subscription.

This separation is deliberate:

- Herdr owns persistent terminal sessions, workspaces, tabs, panes, agent status,
  remote attachment, git worktrees, and supported native agent restoration.
- Native CLIs are the reliable way to consume ChatGPT, Claude, Gemini, and Copilot
  subscriptions.
- Hermes can use ChatGPT/Codex OAuth, Copilot OAuth/ACP, LM Studio, APIs, and paid
  fallbacks. It cannot turn every consumer subscription into a general-purpose API.
- Git worktrees prevent simultaneous agents from editing the same checkout.
- A tracked handoff file transfers explicit state between model families and covers
  agents, including Gemini, without a current Herdr native-restore integration.

Do not nest another agent session manager inside Herdr. There should be one owner of
terminal processes and workspace state.

## Architecture

| Layer | Tool | Responsibility | Persistent data |
|---|---|---|---|
| Portfolio queue | GitHub Issues/Projects | Cross-project priority, ownership, acceptance criteria | GitHub |
| Terminal runtime | Herdr | Sessions, workspaces, panes, status, worktrees, restore, SSH | `~/.config/herdr` |
| Execution | Native CLIs | Coding, review, tests, research | Vendor-specific home directories |
| Flexible agent | Hermes | Provider switching, local delegation, specialist/fallback models | `~/.hermes` |
| Local worker | LM Studio | Cheap auxiliary work and one delegated child at a time | LM Studio application data |
| Durable handoff | `.ai/HANDOFF.md` | Model-neutral state, decisions, commands, blockers | Git branch |
| Isolation | Git worktrees | One writable checkout per task | `~/.herdr/worktrees` |

VS Code remains a useful diff/editor surface: open the specific Herdr worktree, not the
primary checkout, while an agent is changing it.

## Subscription and routing policy

| Source | Preferred path | Use for | Do not assume |
|---|---|---|---|
| ChatGPT | Codex CLI sign-in; Hermes Codex OAuth where supported | Implementation, tests, review, orchestration | An OpenAI API key is included |
| Claude | Claude Code sign-in to Pro/Max | Architecture, difficult refactors, interactive iteration | Claude Pro is a general Anthropic API entitlement |
| Gemini | Gemini CLI Google-account sign-in | Large-context mapping, documentation, second opinions | A Gemini consumer plan can be consumed by Hermes as an API |
| GitHub Copilot | Copilot CLI; Hermes Copilot OAuth/ACP | Quick implementation, shell help, alternative model access | Usage is unlimited across all models |
| Google Antigravity | Antigravity app and `agy` CLI | Parallel Google-agent workflows, autonomous coding, browser-in-loop work | Its state replaces Git or the tracked handoff |
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
agy
hermes model
```

Install Herdr's supported native restore integrations and validate:

```bash
herdr-agent-setup
ai-agent-doctor
hermes-local-health
```

The integration bootstrap installs current Herdr hooks for Claude, Codex, Copilot and
Hermes. Run `herdr integration status` after agent upgrades.

## Day-to-day workflow

### Start or reattach

Start Herdr where the work lives:

```bash
cd ~/projects
herdr
```

Herdr starts or attaches to its background server. Detach with `Ctrl+B`, then `Q`.
Running `herdr` again reattaches without stopping agents.

Use:

- `Ctrl+B`, then `Shift+N` to create a project workspace;
- `Ctrl+B`, then `Shift+G` to create a git worktree;
- `Ctrl+B`, then `V` or `-` to split panes;
- `Ctrl+B`, then `C` to create a tab;
- `Ctrl+B`, then `W` to navigate workspaces.

### Different projects

Create a workspace for each repository:

```bash
herdr workspace create --cwd ~/projects/terrashift --label terrashift
herdr workspace create --cwd ~/projects/meridian --label meridian
herdr workspace create --cwd ~/.config/nix-multi --label nix-multi
```

A workspace may contain the writing agent, test watcher, development server and logs in
separate panes. Herdr rolls agent status up so blocked work is visible without visiting
each pane.

### One project, several independent tasks

Create one worktree-backed workspace per independently mergeable task:

```bash
cd ~/projects/example

herdr worktree create --cwd . --branch agent/api-auth --base main --label api-auth
herdr worktree create --cwd . --branch agent/auth-tests --base main --label auth-tests
herdr worktree create --cwd . --branch agent/repo-map --base main --label repo-map
```

Enter each worktree workspace and run the appropriate native CLI in its root pane:

```bash
claude
codex
gemini
```

Rules:

- One concurrently writing agent per worktree.
- One branch per independently mergeable outcome.
- Parallel agents may inspect the same repository, but they must not write to the same
  checkout.
- Give every task acceptance criteria and a required test command.
- Review and merge deliberately; do not let agents automatically merge one another's
  work.

### Use Hermes

Run Hermes directly in a Herdr pane:

```bash
cd ~/.config/nix-multi
hermes
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

Then stop the old agent in that pane and start the replacement from the same worktree:

```bash
codex
# Prompt: Read .ai/HANDOFF.md, verify git status and the last test result,
# then continue only the recorded next action.
```

The receiving agent must verify `git status`, the branch name, and the last test result
before editing.

## Persistence, reboot, crash, and quota recovery

Normal detach is strongest: the Herdr server and all pane processes remain alive.

After a full machine or Herdr-server restart, the original processes are gone. Herdr
restores workspace/tab/pane layout and resumes supported agent conversations when current
integrations reported valid native session references:

- Claude Code
- Codex CLI
- GitHub Copilot CLI
- Hermes Agent

Gemini currently restores as a shell in the saved working directory. Continue it using
the tracked handoff file and Gemini's own session facilities where available.

Recovery sequence:

```bash
herdr
herdr integration status
```

Herdr resumes eligible panes after the client attaches and supplies terminal context. If
an integration is outdated or missing:

```bash
herdr integration install <agent>
```

When a provider quota is exhausted, do not repeatedly restart that CLI. Complete the
handoff protocol, stop it, and start an eligible native CLI or Hermes in the same pane
and worktree.

Keep pane-history persistence disabled by default: terminal output can contain prompts,
command output, tokens or secrets. Native restoration plus `.ai/HANDOFF.md` provides a
safer continuity layer.

## Persistence and backup boundary

Declarative Nix configuration owns packages, PATH, Herdr defaults, Hermes routing, and
helper commands. It must not own OAuth or API credentials.

Back up at least:

```text
~/.config/herdr
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
- the diff is reviewed from outside the writing agent's pane;
- tests and formatting pass, or failures are recorded;
- secrets and mutable auth state remain untracked;
- `.ai/HANDOFF.md` is current if work will continue;
- a human approves merge for security, infrastructure, destructive, or billing changes.

A useful pairing is writer/reviewer diversity: Claude writes and Codex reviews, Codex
writes and Gemini maps risk, or Hermes/local workers gather evidence while a frontier
native CLI makes the final change.

## Why not make Hermes the only entry point?

Hermes is the provider-flexible agent and local-delegation layer, but it is not the
terminal runtime. Consumer subscription support differs by provider, and native CLIs
retain their own authentication and session behavior. Herdr keeps them together without
replacing them.

## References

- [Herdr](https://herdr.dev/)\n- [Google Antigravity](https://antigravity.google/)\n- [Antigravity CLI installation](https://antigravity.google/docs/cli/install/)
- [Herdr session state and restore](https://herdr.dev/docs/session-state/)
- [Herdr integrations](https://herdr.dev/docs/integrations/)
- [Herdr worktrees](https://herdr.dev/docs/configuration/#worktrees)
- [Hermes providers](https://hermes-agent.nousresearch.com/docs/integrations/providers)
- [Gemini CLI quotas](https://github.com/google-gemini/gemini-cli/blob/main/docs/resources/quota-and-pricing.md)
- [Claude Code setup](https://docs.anthropic.com/en/docs/claude-code/getting-started)
- [Codex with a ChatGPT plan](https://help.openai.com/en/articles/11369540-using-codex-with-your-chatgpt-plan)
