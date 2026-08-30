##############################################################################
#
#  Hermes Agent — system-level nix-darwin helpers (macOS)
#
#  Installs diagnostic and setup scripts into the system environment.
#  Runtime authentication (hermes model, codex login) remains mutable and
#  is NOT managed here — see home/macos/hermes.nix for the declarative
#  config.yaml settings.
#
##############################################################################
{
  pkgs,
  username,
  ...
}:

let
  # ── hermes-local-health ──────────────────────────────────────────────────
  # Validates the full Hermes + LM Studio stack on macOS.
  hermesLocalHealth = pkgs.writeShellApplication {
    name = "hermes-local-health";
    runtimeInputs = with pkgs; [
      curl
      jq
      coreutils
    ];
    text = ''
      set -euo pipefail

      PASS="[ok]"
      WARN="[warn]"
      FAIL="[fail]"

      echo "=== Hermes Local Stack Health Check ==="
      echo ""

      # ── hermes CLI ──────────────────────────────────────────────────────
      if command -v hermes &>/dev/null; then
        echo "$PASS hermes CLI available"
      else
        echo "$FAIL hermes CLI: not found"
      fi

      # ── jq ──────────────────────────────────────────────────────────────
      if command -v jq &>/dev/null; then
        echo "$PASS jq available"
      else
        echo "$FAIL jq: not found (add pkgs.jq to your configuration)"
      fi

      # ── lms CLI ─────────────────────────────────────────────────────────
      if command -v lms &>/dev/null; then
        echo "$PASS lms CLI available ($(which lms))"
      elif [ -x "$HOME/.lmstudio/bin/lms" ]; then
        echo "$WARN lms found at ~/.lmstudio/bin/lms but not on PATH"
        echo "       Rebuild Home Manager to apply home.sessionPath, or re-login"
      else
        echo "$FAIL lms CLI not found"
        echo "       Open LM Studio.app at least once — it places lms at ~/.lmstudio/bin/lms"
        echo "       ~/.lmstudio/bin is added to PATH declaratively by Home Manager (no npx needed)"
      fi

      # ── LM Studio server ────────────────────────────────────────────────
      echo ""
      echo "--- LM Studio server (http://localhost:1234/v1) ---"
      if curl -sf --max-time 3 http://localhost:1234/v1/models &>/dev/null; then
        echo "$PASS server reachable"
        MODELS=$(curl -s http://localhost:1234/v1/models | jq -r '.data[].id' 2>/dev/null)
        if [ -n "$MODELS" ]; then
          echo "$PASS models available:"
          while IFS= read -r line; do echo "         $line"; done <<< "$MODELS"
        else
          echo "$WARN no models loaded (start one in LM Studio or via lms load)"
        fi
      else
        echo "$FAIL server not reachable"
        echo "       Run: lms server start"
      fi

      # ── hermes config ───────────────────────────────────────────────────
      echo ""
      echo "--- Hermes configuration ---"
      HERMES_HOME="$HOME/.hermes"
      HERMES_CFG="$HERMES_HOME/config.yaml"
      HERMES_ENV="$HERMES_HOME/.env"
      HERMES_AUTH="$HERMES_HOME/auth.json"

      if [ -f "$HERMES_CFG" ]; then
        echo "$PASS ~/.hermes/config.yaml exists"
        if grep -q "delegation" "$HERMES_CFG" 2>/dev/null; then
          echo "$PASS delegation block found in config"
        else
          echo "$WARN delegation block not found — rebuild and run: hermes doctor"
        fi
        if grep -q "auxiliary" "$HERMES_CFG" 2>/dev/null; then
          echo "$PASS auxiliary block found in config"
        else
          echo "$WARN auxiliary block not found"
        fi
        if grep -q "LOCAL_MODEL_ID\|<set-" "$HERMES_CFG" 2>/dev/null; then
          echo "$WARN localModelId is still a placeholder — set it in home/macos/hermes.nix and rebuild"
        fi
      else
        echo "$FAIL ~/.hermes/config.yaml missing — run: hermes doctor"
      fi

      if [ -f "$HERMES_ENV" ]; then
        PERMS=$(stat -f %Lp "$HERMES_ENV" 2>/dev/null || stat -c %a "$HERMES_ENV" 2>/dev/null || echo "?")
        if [ "$PERMS" = "600" ]; then
          echo "$PASS ~/.hermes/.env exists (permissions: 600)"
        else
          echo "$WARN ~/.hermes/.env permissions are $PERMS (should be 600 — run: chmod 600 ~/.hermes/.env)"
        fi
        if grep -q "OPENROUTER_API_KEY" "$HERMES_ENV" 2>/dev/null; then
          echo "$PASS OPENROUTER_API_KEY set in .env"
        else
          echo "$WARN OPENROUTER_API_KEY not found in .env"
          echo "       Run: echo 'OPENROUTER_API_KEY=sk-or-...' >> ~/.hermes/.env"
        fi
      else
        echo "$FAIL ~/.hermes/.env missing"
        echo "       Run: echo 'OPENROUTER_API_KEY=sk-or-...' >> ~/.hermes/.env && chmod 600 ~/.hermes/.env"
      fi

      if [ -f "$HERMES_AUTH" ]; then
        echo "$PASS ~/.hermes/auth.json exists (OAuth credentials present)"
      else
        echo "$WARN ~/.hermes/auth.json missing — run: hermes model  (to complete Codex OAuth)"
      fi

      echo ""
      echo "--- Next steps after first install ---"
      echo "  1. Open LM Studio.app once (places lms at ~/.lmstudio/bin/lms)"
      echo "     ~/.lmstudio/bin is on PATH via Home Manager — no npx install-cli needed"
      echo "  2. lms server start   (or: launchd agent starts it at login if enabled)"
      echo "  3. hermes-model-discover"
      echo "     -> set localModelId in home/macos/hermes.nix, then rebuild"
      echo "  4. hermes model   (complete Codex OAuth)"
      echo "  5. hermes config set model.lmstudio_load_mode jit"
      echo "  6. echo 'OPENROUTER_API_KEY=sk-or-...' >> ~/.hermes/.env"
      echo "  7. hermes doctor"
      echo "  8. hermes-local-health  (this script)"
      echo ""
      echo "=== End of health check ==="
    '';
  };

  # ── hermes-model-discover ────────────────────────────────────────────────
  # Queries the running LM Studio server and prints available model IDs.
  hermesModelDiscover = pkgs.writeShellApplication {
    name = "hermes-model-discover";
    runtimeInputs = with pkgs; [
      curl
      jq
    ];
    text = ''
      set -euo pipefail
      echo "Querying LM Studio at http://localhost:1234/v1/models ..."
      MODELS=$(curl -sf --max-time 5 http://localhost:1234/v1/models | jq -r '.data[].id')
      if [ -z "$MODELS" ]; then
        echo "No models found. Is LM Studio server running? (lms server start)"
        exit 1
      fi
      echo ""
      echo "Available model IDs:"
      echo "$MODELS"
      echo ""
      echo "Set the chosen ID as localModelId in:"
      echo "  ~/.config/nix-multi/home/macos/hermes.nix"
      echo "Then rebuild:  darwin-rebuild switch --flake ~/.config/nix-multi#Ryans-MacBook-Pro"
    '';
  };

in
{
  environment.systemPackages = [
    hermesLocalHealth
    hermesModelDiscover
    pkgs.jq # required by health script and model discovery
  ];
}
