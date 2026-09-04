##############################################################################
#
#  AI Tools — installed via llm-agents.nix (github:numtide/llm-agents.nix)
#
#  All packages come from the llm-agents overlay applied below.
#  Access them as pkgs.llm-agents.<name>.
#
#  Categories:
#    - AI Coding Agents       CLI agents that write / edit code
#    - Claude Code Ecosystem  Orchestration and routing layers for Claude
#    - AI Assistants          Desktop / ambient AI companions
#    - Workflow & Planning    Issue trackers, kanban, and project managers
#    - Analytics & Context    Session viewers, code intelligence, doc search
#
#  Note: openclaw has no NixOS system service module (unlike darwin where
#  nix-openclaw.darwinModules.openclaw is loaded in lib/mksystem.nix).
#  The binary is installed here; run it manually or add a systemd user
#  service if a background daemon is needed.
#
##############################################################################
{
  pkgs,
  lib,
  llm-agents,
  hermes-agent,
  ...
}:
{
  # Enables OpenCode's hosted Exa web-search tool even though inference uses a
  # custom local provider. webfetch works without a feature flag.
  environment.variables.OPENCODE_ENABLE_EXA = "1";

  environment.systemPackages =
    let
      ai = llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
      # hermes-agent + hermes-desktop come from the NousResearch flake input
      # (already locked, and its Home-Manager module is imported in
      # home/macos/hermes.nix). llm-agents.nix pins a stale v2026.8.31 tag
      # tarball hash — upstream force-moved that tag — so its hermes-agent /
      # hermes-desktop packages fail to build. Sourcing them here keeps the
      # CLI and the HM module on the same version.
      hermesPkgs = hermes-agent.packages.${pkgs.stdenv.hostPlatform.system};
    in
    [

      ##########################################################################
      # AI Coding Agents
      ##########################################################################

      # claude-code — Anthropic's terminal-based agentic coding assistant.
      # Understands your codebase, writes and edits files, runs commands, and
      # iterates until tasks are complete. Primary driver for most AI work here.
      ai.claude-code

      # codex — OpenAI's CLI coding agent. Reads your codebase, writes and
      # edits files, and runs shell commands to complete tasks end-to-end.
      # Useful as a second-opinion agent alongside claude-code.
      ai.codex

      # copilot-cli — GitHub Copilot in the terminal. Autocompletes shell
      # commands, explains error output, and drafts code snippets inline.
      ai.copilot-cli

      # gemini-cli — Google Gemini brought to the terminal. Useful as a
      # second-opinion agent or for tasks that benefit from Gemini's long
      # context window (e.g. large repo summarisation).
      ai.gemini-cli

      # opencode — terminal coding agent configured declaratively in
      # home/macos/hermes.nix to use LM Studio and local models by default.
      # Its webfetch/websearch tools remain available to the local models.
      ai.opencode

      # antigravity-cli — terminal interface for Google's Antigravity agents.
      # The executable is `agy`; Herdr's integration records conversation IDs
      # so supported sessions can resume after a full server or machine restart.
      ai.antigravity-cli

      ##########################################################################
      # Claude Code Ecosystem
      ##########################################################################
      # hermes-agent — CLI TUI for the Hermes agent runtime. Provides the
      # `hermes` command used for model auth, config, status, and interactive
      # sessions. Must be on PATH before running `hermes model` OAuth flow.
      # From the NousResearch flake input (see hermesPkgs note above).
      hermesPkgs.default

      # claude-code-router — Proxy layer that routes Claude Code requests to
      # alternative model providers (OpenRouter, Bedrock, local models).
      # Lets you swap the backend without changing your claude-code workflow.
      # NOTE: commented out — npm dep fetch fails with HTTP/2 error on npmjs.org
      # ai.claude-code-router

      # oh-my-claudecode — Multi-agent orchestration harness for Claude Code.
      # Spawns and coordinates parallel claude-code workers, manages shared
      # context, and aggregates results into a single coherent output.
      # NOTE: commented out — npm dep fetch fails with HTTP/2 error on npmjs.org
      # ai.oh-my-claudecode

      ##########################################################################
      # AI Assistants
      ##########################################################################

      # hermes-desktop — Desktop companion GUI for Hermes. Provides a visual
      # interface for managing Hermes sessions and reviewing agent outputs.
      # From the NousResearch flake input (see hermesPkgs note above).
      hermesPkgs.desktop

      # hermes-hud — TUI heads-up display that shows live Hermes agent state:
      # current task, memory contents, tool calls in-flight, token budget.
      ai.hermes-hud

      # openclaw — Personal AI assistant that runs on any platform. Provides
      # a gateway daemon for routing requests to multiple AI backends.
      # Note: no NixOS system service module; run openclaw manually or add a
      # systemd user service if a persistent daemon is required.
      ai.openclaw

      ##########################################################################
      # Workflow & Project Management
      ##########################################################################

      # agent-deck — optional fleet-management alternative.
      # Installed for experiments requiring its session database, cost dashboard,
      # or conductor features. Herdr remains the default terminal/worktree owner;
      # never let both tools manage the same live agent session.
      ai.agent-deck

      # herdr — agent-aware terminal multiplexer and persistent runtime.
      # Owns real terminal panes, project workspaces, git worktrees, lifecycle
      # status, remote attachment, and supported native agent restoration.
      ai.herdr

      # backlog-md — Git-native project collaboration between humans and AI.
      # Stores tasks as markdown files committed to the repo; agents read and
      # update backlog items directly, keeping work in version control.
      ai.backlog-md

      # beads — Distributed issue tracker designed for AI-assisted workflows.
      # Issues live in the repo as structured data; multiple agents can claim,
      # update, and close issues concurrently without conflicts.
      ai.beads

      # vibe-kanban — Kanban board for orchestrating AI coding agents.
      # Provides a visual board where each card can be assigned to claude-code,
      # codex, gemini-cli, or a human; tracks agent progress in real-time.
      ai.vibe-kanban

      # gitbutler — Git client for managing multiple simultaneous feature
      # branches (virtual branches). Lets each AI agent work on its own branch
      # without traditional stashing or worktrees.
      ai.gitbutler

      # openspec — spec-driven development for AI coding assistants
      # (openspec.dev, @fission-ai/openspec). Manages change proposals and
      # capability specs as markdown in the repo; agents draft a spec, get it
      # approved, implement against it, then archive it. `openspec init` wires
      # up the AGENTS.md / tool instructions for the project.
      ai.openspec

      # trellis — Out-of-the-box engineering framework for AI coding.
      # Scaffolds projects with conventions that AI agents understand natively,
      # reducing prompt engineering overhead for standard patterns.
      ai.trellis

      ##########################################################################
      # Analytics & Context
      ##########################################################################

      # agentsview — Local-first viewer and analytics for AI coding agent
      # sessions. Browse past sessions, diff before/after states, and audit
      # what each agent changed during a run.
      ai.agentsview

      # codegraph — Semantic code intelligence for AI coding agents. Builds a
      # graph of symbols, call chains, and module relationships; agents query
      # it to understand impact before making changes.
      ai.codegraph

      # context-hub — CLI for searching and retrieving LLM-optimised docs and
      # skills. Agents call it to fetch relevant documentation snippets without
      # bloating the main prompt.
      ai.context-hub

    ];
}
