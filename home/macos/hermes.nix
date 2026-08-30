##############################################################################
#
#  Hermes Agent — Home Manager configuration (macOS)
#
#  Architecture (cost-ordered):
#    TIER 0  local M4 / LM Studio     — auxiliary + subagent work
#    TIER 1  ChatGPT/Codex OAuth      — main planner/reasoner
#    TIER 2  OpenRouter (PAYG)        — fallback / specialist models
#
#  After a `darwin-rebuild switch`:
#
#  1. Discover your local model ID:
#       lms server start
#       curl -s http://localhost:1234/v1/models | jq -r '.data[].id'
#     Then set `localModelId` below and rebuild.
#
#  2. Authenticate Codex as the main model:
#       hermes model
#     Follow the OAuth / device-code flow. This writes ~/.hermes/config.yaml
#     keys that Nix will not overwrite on future rebuilds.
#
#  3. Set model to JIT loading so it doesn't hold RAM while idle:
#       hermes config set model.lmstudio_load_mode jit
#
#  4. Add your OpenRouter API key:
#       echo 'OPENROUTER_API_KEY=sk-or-...' >> ~/.hermes/.env
#     (file is created with 600 permissions by the activation script)
#
#  5. Validate:
#       hermes-local-health
#       hermes doctor
#
##############################################################################
{
  config,
  lib,
  pkgs,
  username,
  hermes-agent,
  ...
}:

let
  # ─────────────────────────────────────────────────────────────────────────
  # LOCAL MODEL ID
  #
  # Set this to the exact model ID from:
  #   curl -s http://localhost:1234/v1/models | jq -r '.data[].id'
  #
  # Recommended: a Qwen3.5-class ~9B MLX 4-bit model.
  # Leave as "" until discovered; hermes falls back to the main model.
  # ─────────────────────────────────────────────────────────────────────────
  localModelId = "";

  # OpenRouter fallback model (PAYG — activated only when main + local fail).
  # Check openrouter.ai/models for the best current value.
  openrouterFallbackModel = "google/gemini-2.5-flash";

  # Build a shared auxiliary-task config block for a given timeout (seconds).
  # Each auxiliary task targets LM Studio with a fallback to the main model.
  lmAux =
    timeout:
    lib.optionalAttrs (localModelId != "") {
      base_url = "http://localhost:1234/v1";
      api_key = "local-key";
      model = localModelId;
      inherit timeout;
      fallback_chain = [ { provider = "main"; } ];
    }
    // lib.optionalAttrs (localModelId == "") {
      fallback_chain = [ { provider = "main"; } ];
    };

in
{
  imports = [ hermes-agent.homeManagerModules.default ];

  services.hermes-agent = {
    # Enables settings management (config.yaml generation with deep-merge).
    # Does NOT start a background gateway daemon — run `hermes` directly.
    enable = true;

    settings = {
      # ── OpenRouter routing policy ────────────────────────────────────────
      # Only applies when traffic goes through OpenRouter (PAYG path).
      provider_routing = {
        sort = "price";
        data_collection = "deny";
      };

      # ── Local auxiliary tasks → LM Studio ───────────────────────────────
      # Background/cheap work goes to the local M4 worker to preserve the
      # Codex subscription quota. Each task falls back to the main model if
      # LM Studio is unavailable.
      #
      # Start conservatively at max_concurrency = 1 on a 24 GB machine.
      # After measuring memory pressure and throughput, raise to 2.
      auxiliary = {
        max_concurrency = 1;

        compression = lmAux 180;

        title_generation = (lmAux 60) // {
          enabled = true;
        };

        approval = lmAux 60;
        triage_specifier = lmAux 120;
        skills_hub = lmAux 60;
        mcp = lmAux 60;

        # Enable only after confirming the chosen local model's vision support.
        vision = lmAux 180;
      };

      # ── Local subagent delegation ────────────────────────────────────────
      # Codex plans and synthesises; local Qwen workers perform the delegated
      # research, code-inspection, and extraction tasks.
      #
      # Conservative defaults for a 24 GB unified-memory laptop.
      # Raise max_concurrent_children to 2 only after Phase 1 benchmarks pass.
      delegation = lib.mkMerge [
        {
          base_url = "http://localhost:1234/v1";
          api_key = "local-key";
          api_mode = "chat_completions";
          max_concurrent_children = 1;
          max_spawn_depth = 1;
          orchestrator_enabled = false;
          max_iterations = 30;
        }
        (lib.optionalAttrs (localModelId != "") {
          model = localModelId;
        })
      ];

      # ── Main-model failure fallback ──────────────────────────────────────
      # Availability failover only — NOT complexity-based routing.
      # Normal path: Codex main → local LM Studio auxiliary/delegation.
      # Fallback path: Codex fails → LM Studio → OpenRouter.
      fallback_providers =
        lib.optional (localModelId != "") {
          provider = "lmstudio";
          model = localModelId;
        }
        ++ [
          {
            provider = "openrouter";
            model = openrouterFallbackModel;
          }
        ];
    };
  };

  # ── LM Studio CLI on PATH ────────────────────────────────────────────────
  # lms is a ~62MB Bun-compiled native binary bundled with the LM Studio app.
  # It has no stable download URL so cannot be packaged as a Nix derivation.
  # LM Studio places it at ~/.lmstudio/bin/lms on first run of the GUI app.
  # This replaces what `npx lmstudio install-cli` does (PATH manipulation only).
  # Prerequisite: open LM Studio.app at least once after a fresh install.
  home.sessionPath = [ "${config.home.homeDirectory}/.lmstudio/bin" ];

  # ── Shell integration ────────────────────────────────────────────────────
  home.shellAliases = {
    "hermes-health" = "hermes-local-health";
    "hermes-dr" = "hermes doctor";
    "hermes-st" = "hermes status";
  };

  programs.zsh.initContent = lib.mkAfter ''
    # LM Studio helpers
    lms-models() {
      curl -s http://localhost:1234/v1/models | jq -r '.data[].id'
    }
    lms-start() { lms server start; }
    lms-stop()  { lms server stop; }

    # Estimate LM Studio memory for a model at 64K context before loading
    lms-estimate() {
      local model="$1"
      lms load "$model" --context-length 64000 --estimate-only
    }
  '';

  # ── ~/.hermes/.env bootstrap ─────────────────────────────────────────────
  # Creates the env file with 600 permissions on first activation.
  # Populate it manually — never commit secrets to the Nix store:
  #   echo 'OPENROUTER_API_KEY=sk-or-...' >> ~/.hermes/.env
  home.activation.hermesEnvSetup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    HERMES_HOME="$HOME/.hermes"
    HERMES_ENV="$HERMES_HOME/.env"

    if [ ! -d "$HERMES_HOME" ]; then
      $DRY_RUN_CMD mkdir -p "$HERMES_HOME"
    fi

    if [ ! -f "$HERMES_ENV" ]; then
      $DRY_RUN_CMD touch "$HERMES_ENV"
      $DRY_RUN_CMD chmod 600 "$HERMES_ENV"
      echo "hermes: created $HERMES_ENV — add OPENROUTER_API_KEY=sk-or-... to it"
    else
      # Always enforce correct permissions even if the file pre-exists.
      $DRY_RUN_CMD chmod 600 "$HERMES_ENV"
    fi
  '';
}
