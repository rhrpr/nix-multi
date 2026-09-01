##############################################################################
#
#  Herdr — agent-aware terminal multiplexer and persistent workspace runtime
#
#  Herdr owns terminal sessions, panes, workspaces, worktrees, and native agent
#  restoration. Provider authentication and transcripts remain mutable in each
#  agent's own home directory.
#
##############################################################################
{ pkgs, ... }:

let
  herdrAgentSetup = pkgs.writeShellApplication {
    name = "herdr-agent-setup";
    runtimeInputs = with pkgs; [ coreutils ];
    text = ''
      set -euo pipefail

      for agent in claude codex copilot hermes antigravity-cli; do
        echo "Installing Herdr integration: $agent"
        herdr integration install "$agent"
      done

      echo
      herdr integration status
      echo
      echo "Gemini CLI is detected as a terminal agent, but has no native"
      echo "Herdr restore integration. Use the tracked AI handoff protocol."
    '';
  };

  aiAgentDoctor = pkgs.writeShellApplication {
    name = "ai-agent-doctor";
    runtimeInputs = with pkgs; [
      coreutils
      curl
      git
      jq
    ];
    text = ''
      set -u

      failed=0
      for tool in herdr claude codex gemini copilot hermes agy; do
        if command -v "$tool" >/dev/null 2>&1; then
          echo "[ok]   $tool"
        else
          echo "[fail] $tool is not on PATH"
          failed=1
        fi
      done

      echo
      if curl -sf --max-time 2 http://localhost:1234/v1/models >/dev/null; then
        echo "[ok]   LM Studio API is reachable"
      else
        echo "[warn] LM Studio API is offline; local Hermes work will fall back"
      fi

      echo
      echo "Herdr sessions:"
      herdr session list 2>/dev/null || echo "[warn] no Herdr session state yet"

      echo
      echo "Herdr integrations:"
      herdr integration status 2>/dev/null || echo "[warn] run: herdr-agent-setup"

      echo
      echo "Mutable state (keep outside Git and the Nix store):"
      echo "  ~/.config/herdr  ~/.claude  ~/.codex  ~/.gemini  ~/.hermes"
      echo
      if command -v agent-deck >/dev/null 2>&1; then
        echo "[optional] Agent Deck is installed; Herdr remains the default."
      fi
      echo "Back these directories up with Time Machine."

      exit "$failed"
    '';
  };
in
{
  xdg.configFile."herdr/config.toml" = {
    force = true;
    text = ''
      # Managed by Home Manager. Session state and agent credentials stay mutable.

      [session]
      resume_agents_on_restore = true

      [worktrees]
      directory = "~/.herdr/worktrees"

      [remote]
      manage_ssh_config = true

      [advanced]
      scrollback_limit_bytes = 10000000

      # Pane output may contain prompts, command output, or credentials.
      # Native agent restore plus the tracked handoff file is the safer default.
      [experimental]
      pane_history = false
    '';
  };

  home.packages = [
    herdrAgentSetup
    aiAgentDoctor
  ];

  home.shellAliases = {
    ai = "herdr";
    ai-status = "herdr session list";
    ai-integrations = "herdr integration status";
    ai-setup = "herdr-agent-setup";
  };
}
