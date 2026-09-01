##############################################################################
#
#  Agent Deck — durable multi-project control plane for AI coding CLIs
#
#  Agent Deck owns session discovery, tmux lifecycle, worktree isolation, and
#  cold-boot recovery. Claude, Codex, Gemini, Copilot, and Hermes keep their
#  native authentication and transcript stores.
#
##############################################################################
{ pkgs, ... }:

let
  aiAgentDoctor = pkgs.writeShellApplication {
    name = "ai-agent-doctor";
    runtimeInputs = with pkgs; [
      coreutils
      curl
      git
      jq
      tmux
    ];
    text = ''
      set -u

      failed=0
      for tool in agent-deck claude codex gemini copilot hermes tmux; do
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
      echo "Agent Deck fleet state:"
      agent-deck fleet status 2>/dev/null || echo "[warn] no Agent Deck state yet"

      echo
      echo "Mutable state (keep outside Git and the Nix store):"
      echo "  ~/.local/share/agent-deck  ~/.claude  ~/.codex  ~/.gemini  ~/.hermes"
      echo "Back these directories up with Time Machine."

      exit "$failed"
    '';
  };
in
{
  xdg.configFile."agent-deck/config.toml" = {
    force = true;
    text = ''
      # Managed by Home Manager. Runtime state remains mutable under XDG_DATA_HOME.
      default_tool = "claude"
      group_sort = "actionable"
      sync_title = true

      [tmux]
      socket_name = "agent-deck"

      [worktree]
      default_location = "subdirectory"
      sparse_checkout = "inherit"

      [fork]
      inherit_from_parent = false
      worktree = true
      with_state = true
      with_ignored = false
      docker = "auto"
      branch_prefix = "agent/"

      [ui]
      footer = "curated"
      show_only_installed_tools = true
      attach_on_create = true

      [global_search]
      enabled = true
      tier = "balanced"
      memory_limit_mb = 128
      recent_days = 180
      index_rate_limit = 20

      [logs]
      max_size_mb = 5
      max_lines = 10000

      # Keep approval bypasses off globally. Opt in only for a disposable,
      # sandboxed worktree when the task justifies it.
      [claude]
      command = "claude"
      dangerous_mode = false

      [gemini]
      command = "gemini"
      yolo_mode = false

      [codex]
      command = "codex"
      yolo_mode = false

      [copilot]
      command = "copilot"

      [hermes]
      command = "hermes"
    '';
  };

  home.packages = [ aiAgentDoctor ];

  home.shellAliases = {
    ai = "agent-deck";
    ai-status = "agent-deck fleet status";
    ai-recover-plan = "agent-deck fleet recover";
    ai-recover = "agent-deck fleet recover --yes";
  };
}
