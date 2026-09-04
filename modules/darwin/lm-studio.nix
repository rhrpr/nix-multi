##############################################################################
#
#  LM Studio — nix-darwin integration (macOS)
#
#  Provides launchd user agents that start the LM Studio API server and
#  idempotently download the configured local model set. Models are not loaded
#  into memory at login: LM Studio's default JIT + auto-evict behavior loads
#  the model requested by OpenCode/Hermes and unloads idle models.
#
#  Prerequisite (one-time, outside Nix): open LM Studio.app once so its bundled
#  `lms` CLI is initialized. Home Manager already adds ~/.lmstudio/bin to PATH.
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

  # Startup script — starts the server, but never pre-loads a model. LM Studio
  # enables JIT loading, idle TTL, and auto-eviction by default.
  startScript = pkgs.writeShellApplication {
    name = "lmstudio-server-start";
    runtimeInputs = [ pkgs.curl ];
    text = ''
      set -euo pipefail

      LMS="${lmsBin}"

      if [ ! -x "$LMS" ]; then
        echo "lmstudio-server: lms CLI not found at $LMS"
        echo "Open LM Studio.app once so its bundled CLI is initialized."
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

  # Idempotent model bootstrap. `lms get` accepts LM Studio catalog IDs and
  # downloads the recommended compatible variant for an exact match. Keeping
  # this out of Home Manager activation prevents ~40 GB of network I/O from
  # blocking a rebuild. The launchd job retries periodically until `lms` is
  # available and each requested model has been installed.
  modelBootstrap = pkgs.writeShellApplication {
    name = "lmstudio-model-bootstrap";
    runtimeInputs = with pkgs; [ jq ];
    text = ''
      set -u

      LMS="${lmsBin}"
      MODELS=(
        ${lib.concatMapStringsSep "\n        " lib.escapeShellArg cfg.models}
      )

      if [ ! -x "$LMS" ]; then
        echo "lmstudio-model-bootstrap: lms CLI not found at $LMS"
        echo "Open LM Studio.app once; launchd will retry automatically."
        exit 0
      fi

      if ! INSTALLED_JSON=$("$LMS" ls --json); then
        echo "lmstudio-model-bootstrap: unable to query the local model library"
        exit 0
      fi

      failed=0
      for model in "''${MODELS[@]}"; do
        if jq -e --arg model "$model" 'any(.[]; .modelKey == $model)' \
          >/dev/null <<< "$INSTALLED_JSON"; then
          echo "[ok] $model"
          continue
        fi

        echo "[download] $model"
        if "$LMS" get "$model"; then
          INSTALLED_JSON=$("$LMS" ls --json)
        else
          echo "[warn] download failed for $model; launchd will retry later"
          failed=1
        fi
      done

      if [ "$failed" -eq 0 ]; then
        echo "lmstudio-model-bootstrap: all configured models are installed"
      fi

      # Download failures are deliberately non-fatal so launchd does not enter
      # a rapid crash/restart loop. StartInterval provides controlled retries.
      exit 0
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

    autoDownloadModels = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Automatically download missing models in the background.";
    };

    models = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "google/gemma-4-12b-qat"
        "google/gemma-4-e4b"
        "openai/gpt-oss-20b"
        "prism-ml/bonsai-27b"
        "qwen/qwen3.5-9b"
        "text-embedding-nomic-embed-text-v1.5"
      ];
      description = "LM Studio catalog model IDs that should exist locally.";
    };

    modelDownloadInterval = lib.mkOption {
      type = lib.types.ints.positive;
      default = 3600;
      description = "Seconds between idempotent checks for missing models.";
    };

    modelLogFile = lib.mkOption {
      type = lib.types.str;
      default = "/tmp/lmstudio-model-bootstrap.log";
      description = "Path to the model bootstrap launchd log.";
    };
  };

  config = lib.mkIf cfg.enable {
    # ── launchd user agent ─────────────────────────────────────────────────
    # Runs as the logged-in user (not root), which is required for LM Studio
    # to access its model library under ~/Library/Application Support/LM Studio.
    launchd.user.agents = {
      lmstudio-server = {
        serviceConfig = {
          Label = "ai.lmstudio.server";
          ProgramArguments = [
            "${startScript}/bin/lmstudio-server-start"
          ];
          RunAtLoad = true;
          KeepAlive = false; # Do not restart if server exits cleanly
          StandardOutPath = cfg.logFile;
          StandardErrorPath = cfg.logFile;

          # Give the server 10 seconds to shut down cleanly before SIGKILL.
          ExitTimeOut = 10;

          # Throttle restart attempts if the server crashes immediately.
          ThrottleInterval = 30;
        };
      };
    }
    // lib.optionalAttrs cfg.autoDownloadModels {
      lmstudio-model-bootstrap = {
        serviceConfig = {
          Label = "ai.lmstudio.model-bootstrap";
          ProgramArguments = [
            "${modelBootstrap}/bin/lmstudio-model-bootstrap"
          ];
          RunAtLoad = true;
          StartInterval = cfg.modelDownloadInterval;
          ProcessType = "Background";
          StandardOutPath = cfg.modelLogFile;
          StandardErrorPath = cfg.modelLogFile;
        };
      };
    };

    # ── diagnostic helper ──────────────────────────────────────────────────
    # Adds lmstudio-server-status to PATH for quick health checks.
    environment.systemPackages = [
      modelBootstrap
      (pkgs.writeShellApplication {
        name = "lmstudio-server-status";
        runtimeInputs = with pkgs; [
          curl
          jq
        ];
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
              echo "[ok]   models visible to the API:"
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
