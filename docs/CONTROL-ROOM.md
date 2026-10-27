# AI Control Room

One screen holds every coding agent: Claude Code, Codex, Gemini, Hermes and
plain shells, tiled in panes and grouped by project. You drive it with the
keyboard or by voice, it arranges your desktop apps around it, and it comes
back after a reboot without you doing anything.

```
┌──────────────────────── AeroSpace workspace 1AI (main display) ────────────────────────┐
│ Ghostty "Control Room" window → Herdr                                                   │
│ ┌ sidebar ────────┐ ┌ nix ─────────────────────────┬──────────────────────────────────┐ │
│ │ hq              │ │ nix-claude   ● working       │ nix-codex    ○ idle              │ │
│ │ nix        ●    │ │                              │                                  │ │
│ │ terrashift ▲    │ ├──────────────────────────────┼──────────────────────────────────┤ │
│ │ meridian   ✔    │ │ nix-gemini   ✔ done          │ nix-shell                        │ │
│ │ agents…         │ │                              │                                  │ │
│ └─────────────────┘ └──────────────────────────────┴──────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────────────────┘
  alt-2 Code · alt-5 Chrome · alt-8 Mail …  apps go to their own workspaces automatically
  ⌃⌥Space (hold) voice command · ⌃⌥D (hold) dictate · ⌃⌥A control room · ⌃⌥S status
```

## Existing tools, and why this setup is built on Herdr

Multiplexers built for AI agents already exist. This setup does not replace
them: it uses the one this repo already standardised on and adds the parts
none of them cover (voice, desktop apps, login bring-up, Nix).

| Tool | Kind | Agents | Survives reboot | Voice | Notes |
|---|---|---|---|---|---|
| **Herdr** (in use) | TUI multiplexer, Rust | ~25 kinds incl. Claude, Codex, Gemini, Hermes, agy | Layout plus native agent resume | No | Agent state detection, CLI and socket API, worktrees, remote machines |
| Agent Deck (installed) | TUI fleet manager | Claude, Codex, Gemini… | Session DB | No | Cost dashboard, conductors; never give it the same session as Herdr |
| Claude Squad | tmux TUI | Claude, Codex, Gemini, Aider | tmux sessions | No | Worktree per task |
| dmux / workmux / ittybitty | tmux scripts | mostly Claude | tmux | No | Lightweight worktree + pane spawners |
| amux | tmux + web dashboard | Claude, Codex, Gemini, OpenCode | Watchdog restarts | No | Self-hosted web UI |
| NTM | tmux orchestrator | Claude, Codex, Gemini | tmux | No | Broadcast prompts to many panes |
| vupai | tmux + push-to-talk | Claude mainly | tmux | **Yes**, on-device Parakeet | The closest to "voice control room", but it runs its own tmux server |
| cmux, Superset/Paradev, Nimbalyst (ex-Crystal), Conductor, T3 Code, Vibe Kanban | Desktop GUI apps | various | app-dependent | Paseo only | Good for diff review; they own the terminals, so they don't sit inside Nix/Herdr |

The rule from `AI-AGENT-WORKFLOW.md` still applies: **each live session has
exactly one terminal owner, and that owner is Herdr.**

## What each layer does

| Layer | Tool | Responsibility | Defined in |
|---|---|---|---|
| Terminal runtime | Herdr | Panes, agent status, native resume after restart, notifications | `home/macos/herdr.nix` |
| Glue | `control-room` | Declarative projects → Herdr panes, revive, HQ dashboard, voice router, desks | `home/macos/control-room/` |
| Window manager | AeroSpace | Workspaces; app → workspace rules generated from the same app table | `home/macos/aerospace.nix`, `home/aerospace/aerospace.toml` |
| Hotkeys + voice | Hammerspoon + sox + whisper.cpp | Push-to-talk, on-device speech-to-text, dictation | `home/macos/control-room/hammerspoon.lua` |
| Login bring-up | launchd agent | Runs `control-room boot` | `home/macos/control-room/default.nix` |
| System | nix-darwin | Casks, "reopen windows" defaults | `modules/darwin/control-room.nix` |

## First run

```bash
darwin-rebuild switch --flake ~/.config/nix-multi#Ryans-MacBook-Pro

herdr-agent-setup          # native resume hooks for claude/codex/copilot/hermes/agy
control-room voice-setup   # downloads whisper small.en (~460 MB) once
control-room doctor        # every check should say [ok]
control-room up            # builds the hq + project workspaces
control-room attach-window # opens the Ghostty "Control Room" window (or alt-shift-a)
```

macOS will ask for these permissions once. Nix cannot grant them.

- **Accessibility:** AeroSpace and Hammerspoon.
- **Microphone:** Hammerspoon. It starts `sox`, so the microphone request is attributed to Hammerspoon.
- **Automation:** allow Hammerspoon or control-room to control "System Events" if asked (used for quitting apps).

Sign each agent CLI in once (`claude`, `codex`, `gemini`). The control room
never touches credentials.

## Projects and panes

Edit `home/macos/control-room/config.nix`:

```nix
programs.controlRoom.projects.myapp = {
  path = "~/projects/myapp";
  aliases = [ "my app" ];          # spoken names
  # panes default to: claude | codex / gemini | shell (an even grid)
  panes = [
    { name = "claude"; kind = "claude"; }
    { name = "codex";  kind = "codex"; args = [ "--model" "gpt-5-codex" ]; }
    { name = "server"; command = "npm run dev"; }
    { name = "shell"; }
  ];
};
```

Rebuild, then run `control-room up`. Up is idempotent: it only creates
workspaces that are missing. Each pane is labelled `<project>-<pane>` (for
example `nix-claude`). That label is how you address the pane by voice, and it
persists across restarts.

## Reboot behaviour

1. At login, launchd runs `control-room boot`.
2. Boot opens AeroSpace and Hammerspoon. It then opens the Ghostty "Control
   Room" window (`--window-save-state=never`, title-pinned to `1AI`). That
   window runs `herdr`.
3. Attaching starts the Herdr server. Herdr restores every workspace, tab,
   pane, directory and label. It resumes Claude, Codex, Copilot, Hermes and
   Antigravity from their recorded session ids.
4. Gemini has no official Herdr integration. The `cr-gemini` wrapper reports
   its own resume command (`cr-gemini --resume` → `gemini --resume latest`),
   so Herdr resumes Gemini too.
5. After `settleSeconds`, `control-room up --revive` checks for panes that
   came back as bare shells. For each one that still has its shell in the
   foreground, it relaunches the pane's agent with continue flags
   (`claude --continue`, `codex resume --last`, …). It also re-runs commands
   such as dev servers.
6. macOS reopens your other apps because "Reopen windows when logging back in"
   is turned on. AeroSpace rules put each app in its workspace, and a
   notification gives the fleet summary.

Running processes (builds, tests) cannot survive a reboot. Herdr detach
keeps them alive for everything short of that. Put tests and builds under an
agent, or write `.ai/HANDOFF.md`.

## Voice

Hold **⌃⌥Space**, speak, then release. Audio is recorded with `sox` and
transcribed on-device by whisper.cpp (Metal). The text is routed by a
deterministic grammar. If the grammar finds no match and
`voice.llm.enable = true`, the local LM Studio model rewrites the phrase into
the grammar. Nothing leaves the machine.

| Say | Effect |
|---|---|
| "nix claude, refactor the flake inputs" | Prompt `nix-claude` (`herdr agent prompt`) |
| "tell terra codex to run the tests" / "ask meridian hermes …" | Same, verb form |
| "nix: summarise open PRs" | Prompt the project's first agent |
| "everyone, write a handoff file" | Prompt every idle agent |
| "approve nix claude" / "stop web codex" | Enter or Esc on that agent (approve / interrupt) |
| "read nix gemini" / "what is nix claude doing" | Notification with its last lines, spoken |
| "status" / "who's blocked" | Spoken fleet summary |
| "go to nix" / "go to mail" / "go to vs code" | Herdr workspace / AeroSpace space / app |
| "open spotify" / "quit chrome" | Launch or quit apps |
| "review desk" / "desk research" / "desk reset" | Pull apps beside the control room, or send them home |
| "new codex in nix" | Split a pane in that project and start the agent |
| "control room" | Jump to workspace 1AI |

Hold **⌃⌥D** to dictate. The text is typed into whatever has focus (an agent
pane, Slack, a browser), so long prompts can be spoken straight into Claude.

To test routing without a microphone, run `control-room parse "approve nix claude"`.
Misheard names are fixed by adding `aliases`. Whisper is also primed with
your project names.

## Keys

| Keys | Action |
|---|---|
| ⌃⌥Space (hold) | Voice command |
| ⌃⌥D (hold) | Dictate into focused window |
| ⌃⌥A / alt-a / alt-1 | Control room workspace |
| ⌃⌥S | Spoken status |
| ⌃⌥R / ⌃⌥E / ⌃⌥0 | Review desk / research desk / reset desk |
| alt-shift-a | Reopen the control-room window if closed |
| alt-shift-u | `control-room up --revive` |
| Ctrl-b then w / v / - / z / q | Herdr: workspaces, split right, split down, zoom, detach |

The menu-bar ⌁ item offers the same actions.

## CLI

```text
control-room up [--revive]    status [--speak|--json]    dash
control-room focus <target>   desk <name|reset>          boot | attach-window
control-room voice "<text>"   parse "<text>"             transcribe <wav>
control-room voice-setup      doctor
```

Aliases: `cr`, `crs` (status), `cru` (up), `crv` (voice).
Logs are in `~/.local/state/control-room/`: `control-room.log`, `voice.log`
and the `boot.*.log` files.

## Troubleshooting

- **Nothing happens at login:** check `launchctl print gui/$(id -u)/org.nix-community.home.control-room`
  and `~/.local/state/control-room/boot.err.log`. To rerun boot by hand, use
  `control-room boot`.
- **An agent came back as a shell:** run `herdr integration status`. Reinstall
  outdated hooks (`herdr-agent-setup`), then press alt-shift-u.
- **Voice says "no speech model":** run `control-room voice-setup`. If
  nothing is recorded, check the Microphone permission for Hammerspoon.
- **Windows land in the wrong place:** run `aerospace list-apps` to get the
  bundle id, then add or fix the entry in `programs.controlRoom.apps`.
- **Rectangle and AeroSpace both installed:** use AeroSpace for tiling. Leave
  Rectangle's shortcuts unused or remove the cask.
- **A home-manager switch reruns boot:** this is expected. Boot is idempotent,
  so it only opens what is missing.
