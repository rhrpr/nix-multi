##############################################################################
#
#  LM Studio — nix-darwin integration (macOS)
#
#  Provides an optional launchd user agent that starts the LM Studio API
#  server at login. The agent starts the server only — it does NOT load any
#  model. Model loading is handled by Hermes via JIT mode, so the model
#  only occupies unified memory when inference is actually needed.
#
#  Prerequisites (one-time, outside Nix):
#    npx lmstudio install-cli        # installs ~/.lmstudio/bin/lms
#    lms server start                # verify the server starts manually
#
#  Usage in your darwin configuration:
#    services.lm-studio.enable = true;
#
#  After enabling and rebuilding:
#    launchctl list | grep lmstudio  # confirm agent is registered
#    curl -s http://localhost:1234/v1/models | jq  # confirm server running
#
##############################################################################
{
  config,
  lib,
  pkgs,
  username,
  ...
}:

let
  cfg = config.services.lm-studio;

  # lms is a native Bun-compiled binary bundled with the LM Studio GUI app.
  # It is placed at ~/.lmstudio/bin/lms when LM Studio first runs.
  # There is no stable download URL, so it cannot be packaged as a derivation.
  # The GUI app is already managed as a Homebrew cask in modules/darwin/apps.nix.
  # home.sessionPath in home/macos/hermes.nix adds ~/.lmstudio/bin to PATH,
  # replacing the need to run `npx lmstudio install-cli` manually.
  lmsBin = "/Users/${username}/.lmstudio/bin/lms";

  # Startup script — just starts the server, never loads a model.
  # JIT loading is configured separately via:
  #   hermes config set model.lmstudio_load_mode jit
  startScript = pkgs.writeShellApplication {
    name = "lmstudio-server-start";
    runtimeInputs = [ ];
    text = ''
      set -euo pipefail

      LMS="${lmsBin}"

      if [ ! -x "$LMS" ]; then
        echo "lmstudio-server: lms CLI not found at $LMS"
        echo "Run: npx lmstudio install-cli"
        exit 1
      fi

      # Only start if not already running (avoid duplicate server instances).
      if curl -sf --max-time 2 http://localhost:${toString cfg.port}/v1/models &>/dev/null; then
        echo "lmstudio-server: API server already running on port ${toString cfg.port}"
        exit 0
      fi

      echo "lmstudio-server: starting API server on port ${toString cfg.port}"
      exec "$LMS" server start --port ${toString cfg.port}
    '';
  };

in
{
  options.services.lm-studio = {
    enable = lib.mkEnableOption "LM Studio API server launchd agent";

    port = lib.mkOption {
      type = lib.types.port;
      default = 1234;
      description = "Port for the LM Studio OpenAI-compatible API server.";
    };

    logFile = lib.mkOption {
      type = lib.types.str;
      default = "/tmp/lmstudio-server.log";
      description = "Path to the launchd stdout/stderr log for the LM Studio server.";
    };
  };

  config = lib.mkIf cfg.enable {
    # ── launchd user agent ─────────────────────────────────────────────────
    # Runs as the logged-in user (not root), which is required for LM Studio
    # to access its model library under ~/Library/Application Support/LM Studio.
    launchd.user.agents.lmstudio-server = {
      serviceConfig = {
        Label = "ai.lmstudio.server";
        ProgramArguments = [
          "${startScript}/bin/lmstudio-server-start"
        ];
        RunAtLoad = true;
        KeepAlive = false;    # Do not restart if server exits cleanly
        StandardOutPath = cfg.logFile;
        StandardErrorPath = cfg.logFile;

        # Give the server 10 seconds to shut down cleanly before SIGKILL.
        ExitTimeOut = 10;

        # Throttle restart attempts if the server crashes immediately.
        ThrottleInterval = 30;
      };
    };

    # ── diagnostic helper ──────────────────────────────────────────────────
    # Adds lmstudio-server-status to PATH for quick health checks.
    environment.systemPackages = [
      (pkgs.writeShellApplication {
        name = "lmstudio-server-status";
        runtimeInputs = with pkgs; [ curl jq ];
        text = ''
          set -euo pipefail
          PORT="${toString cfg.port}"
          ENDPOINT="http://localhost:$PORT/v1"

          echo "=== LM Studio server status (port $PORT) ==="
          echo ""

          if curl -sf --max-time 3 "$ENDPOINT/models" &>/dev/null; then
            echo "[ok]   server reachable at $ENDPOINT"
            MODELS=$(curl -s "$ENDPOINT/models" | jq -r '.data[].id' 2>/dev/null || true)
            if [ -n "$MODELS" ]; then
              echo "[ok]   loaded models:"
              while IFS= read -r m; do echo "         $m"; done <<< "$MODELS"
            else
              echo "[warn] no models loaded (JIT mode: model loads on first request)"
            fi
          else
            echo "[fail] server not reachable at $ENDPOINT"
            echo "       Check: launchctl list | grep lmstudio"
            echo "       Logs:  cat ${cfg.logFile}"
            echo "       Manual start: lms server start --port $PORT"
          fi

          echo ""
          echo "--- launchd agent ---"
          launchctl list ai.lmstudio.server 2>/dev/null \
            && echo "[ok]   agent registered" \
            || echo "[warn] agent not registered (rebuild needed?)"
        '';
      })
    ];
  };
}
