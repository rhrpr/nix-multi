> [!NOTE]
> Historical tool inventory preserved from the original configuration.
> Commands and integration claims may not match current releases. Use
> [AI-AGENT-WORKFLOW.md](AI-AGENT-WORKFLOW.md) for the supported workflow.

# AI Tools Workflow with herdr

A practical guide to using the AI coding stack installed via `modules/darwin/ai-tools.nix`, centred on **herdr** as the workspace coordinator.

---

## Tool Reference

| Tool | Role |
|---|---|
| `herdr` | Terminal workspace manager — creates named workspaces and tracks which agents are running where |
| `claude-code` | Primary agentic coding assistant — writes, edits, and tests code autonomously |
| `oh-my-claudecode` | Spawns and coordinates parallel `claude-code` workers |
| `claude-code-router` | Routes `claude-code` requests to alternative model backends |
| `claude-desktop` | Persistent chat with Projects, file uploads, and artifact rendering |
| `copilot-cli` | Inline terminal completions, command explanations |
| `gemini-cli` | Second-opinion agent; excels at large-context summarisation |
| `hermes-agent` | Autonomous long-running research and self-refinement tasks |
| `hermes-desktop` | GUI for managing Hermes sessions |
| `hermes-hud` | Live TUI monitor showing Hermes state, memory, and token budget |
| `openclaw` | Multi-backend AI gateway daemon (manages local and remote models) |
| `backlog-md` | Git-tracked markdown task backlog readable by agents |
| `beads` | Distributed issue tracker living inside the repo |
| `vibe-kanban` | Visual kanban board assigning tasks to specific agents |
| `gitbutler` | Multi-branch Git client — one branch per agent |
| `openspec` | OpenAPI spec generation, validation, and diffing |
| `trellis` | Project scaffolding with AI-native conventions |
| `paseo-desktop` | Voice-controlled daemon for routing voice commands to agents |
| `agentsview` | Session replay and analytics for past agent runs |
| `codegraph` | Semantic symbol/call-chain graph for impact analysis |
| `context-hub` | LLM-optimised doc and skills retrieval |

---

## Example 1 — Greenfield API project

### Goal
Build a REST API from an OpenAPI spec, with each endpoint implemented by a separate `claude-code` worker.

### Setup

```sh
# 1. Scaffold the project with AI-native conventions
trellis init my-api --template rest-api
cd my-api

# 2. Create the herdr workspace
herdr create my-api

# 3. Draft the OpenAPI spec (iterate in Claude Desktop, then write to disk)
openspec init --title "My API" --version 1.0.0 > openapi.yaml
# Edit openapi.yaml in claude-desktop or with claude-code

# 4. Validate the spec
openspec validate openapi.yaml
```

### Parallel implementation

```sh
# 5. Seed the backlog from the spec — each path becomes a task
backlog init
backlog add "Implement GET /users endpoint"
backlog add "Implement POST /users endpoint"
backlog add "Implement DELETE /users/{id} endpoint"

# 6. Launch oh-my-claudecode to spawn one worker per backlog task
oh-my-claudecode --backlog backlog/ --workers 3

# oh-my-claudecode assigns each task to a claude-code instance.
# gitbutler manages one virtual branch per worker automatically.
```

### Monitor progress

```sh
# In a separate pane — watch all agent sessions in real time
herdr status my-api

# Or open the visual kanban
vibe-kanban --workspace my-api
```

### Review

```sh
# When workers finish, browse session recordings
agentsview --workspace my-api

# Inspect what changed in the call graph before merging
codegraph diff main HEAD
```

---

## Example 2 — Bug triage and fix with multi-agent review

### Goal
Reproduce a bug, fix it with `claude-code`, and have `hermes-agent` independently verify the fix.

### Setup

```sh
# Create an isolated herdr workspace for this bug
herdr create bug-fix-123

# Log the issue in beads (stays in the repo, agents can read it)
beads add --title "Auth token not refreshed on 401" --priority high
```

### Fix

```sh
# Ask codegraph to find all files touching token refresh
codegraph query "token refresh" --output affected-files.txt

# Give claude-code the affected files as focused context
claude-code fix "$(cat affected-files.txt)" --issue "$(beads show 1)"

# claude-code works on a gitbutler virtual branch 'fix/token-refresh'
```

### Independent review

```sh
# Route the review to hermes-agent (runs on a different model backend
# via claude-code-router, avoiding confirmation bias)
claude-code-router --backend hermes hermes-agent \
  "Review the diff on branch fix/token-refresh and verify the token
   refresh logic is correct. Output: LGTM or a list of issues."

# Watch hermes-agent's reasoning live
hermes-hud
```

### Merge

```sh
# Mark the beads issue resolved
beads close 1

# Merge the virtual branch in gitbutler
gitbutler merge fix/token-refresh

# Archive the session in agentsview for future reference
agentsview export --workspace bug-fix-123
```

---

## Example 3 — Long-running research with Hermes

### Goal
Survey a library's internals and produce a migration guide.

```sh
# Start the openclaw gateway so hermes can route to local + remote models
# (openclaw's launchd service starts automatically on login)

# Create a herdr workspace
herdr create research-migration

# Seed context — pull library docs into context-hub's local index
context-hub index --source https://docs.example-lib.io

# Launch hermes-agent with the research brief
hermes-agent \
  --context "$(context-hub search 'migration v2 to v3' --limit 20)" \
  "Produce a step-by-step migration guide from example-lib v2 to v3.
   Focus on breaking changes. Output markdown."

# Monitor memory and token usage
hermes-hud

# When done, the guide is written to ./output/migration-guide.md
# Review the full session
agentsview --workspace research-migration
```

---

## Example 4 — Voice-driven coding with paseo

### Goal
Issue natural-language voice commands to claude-code without leaving your keyboard.

```sh
# Start the paseo daemon (routes voice to the active herdr workspace)
paseo-desktop --workspace my-api &

# Now speak commands like:
#   "Add input validation to the POST /users handler"
#   "Run the test suite and fix any failures"
#   "Open the agentsview for my last session"
#
# paseo transcribes and dispatches to claude-code in the active workspace.
```

---

## Recommended shell aliases

Add to `~/.zshrc` or your shell config:

```sh
# Quick workspace bootstrap
alias ai-start='herdr create $(basename $PWD) && vibe-kanban &'

# Parallel claude workers from current backlog
alias ai-work='oh-my-claudecode --backlog backlog/ --workers 4'

# Live agent dashboard
alias ai-dash='herdr status && hermes-hud'

# Post-session review
alias ai-review='agentsview --workspace $(herdr current) && codegraph diff main HEAD'
```

---

## Tool interaction diagram

```
Voice input
    |
paseo-desktop
    |
    v
herdr (workspace router)
    |
    +---> oh-my-claudecode ---> claude-code (worker 1) ---> gitbutler branch 1
    |             |          -> claude-code (worker 2) ---> gitbutler branch 2
    |             |          -> claude-code (worker 3) ---> gitbutler branch 3
    |             |
    |             +--- backlog-md (task source)
    |             +--- beads     (issue source)
    |             +--- vibe-kanban (visual tracker)
    |
    +---> hermes-agent (research / review)
    |         |
    |         +--- context-hub (doc retrieval)
    |         +--- hermes-hud  (live monitor)
    |
    +---> claude-code-router --> openclaw gateway --> local/remote models
    |
    +---> agentsview  (session replay)
    +---> codegraph   (impact analysis)
    +---> openspec    (API contract validation)
```

---

## Tips

- **Keep `herdr` as the entry point.** Always `herdr create <name>` before starting any multi-agent session so workspace state, logs, and gitbutler branches stay grouped.
- **Use `beads` for machine-readable tasks, `backlog-md` for human-readable context.** Agents read both; `beads` is better for claiming/closing; `backlog-md` is better for narrative context.
- **`codegraph` before big refactors.** Run `codegraph query <symbol>` to understand blast radius before sending claude-code into the codebase.
- **`claude-code-router` for cost control.** Point heavy batch jobs at a cheaper backend without changing any other tooling.
- **`agentsview` is your audit trail.** Every session is recorded locally — replay any run to understand exactly what an agent did and why.
