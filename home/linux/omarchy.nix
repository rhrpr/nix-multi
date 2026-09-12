{
  pkgs,
  lib,
  omarchy, # nix store path of upstream omacom/omarchy (flake = false)
  ...
}:

# ---------------------------------------------------------------------------
# Upstream omarchy dotfile integration
#
# HOW IT WORKS
# ============
# Home Manager's `home.file` attribute maps destination paths (relative to
# $HOME) to nix-store source paths.  At activation time home-manager creates
# symlinks:
#
#   ~/.config/hypr  →  /nix/store/<hash>-source/config/hypr
#
# Because the source is a nix store path it is read-only; apps that read (but
# don't write) their config work transparently.  Hyprland, foot, kitty, etc.
# all fall into that category.
#
# WHAT LIVES WHERE IN omacom/omarchy
# ===================================
#   config/   — user dotfiles that map 1-to-1 to ~/.config/
#   default/  — default/override layer (managed by omarchy-nix system module)
#   shell/    — Quickshell QML bar/notifications (needs omarchy-nix to build)
#   bin/      — scripts exposed as PATH commands (handled by omarchy-nix)
#   etc/      — system-level files (NixOS handles via modules/nixos/omarchy.nix)
#   themes/   — theme definitions (consumed by the theming engine in omarchy-nix)
#
# RESPONSIBILITY SPLIT
# ====================
# THIS MODULE  — symlinks config/* → ~/.config/* so the live config always
#                reflects the upstream commit pinned in flake.lock.
#                Run `nix flake update omarchy` then rebuild to upgrade.
#
# omarchy-nix  — builds the Quickshell shell, installs bin scripts, wires
#                systemd user services, applies themed templates, manages
#                the SDDM session entry, etc.
#
# We deliberately do NOT link:
#   config/git/   — managed by home/git.nix
#   default/      — owned by omarchy-nix (it applies the override layer)
#   shell/        — Quickshell source, must be compiled not symlinked
# ---------------------------------------------------------------------------

let
  # Symlink a directory from config/ into ~/.config/ only when the upstream
  # snapshot actually contains it.  Prevents evaluation errors if upstream
  # reorganises its layout between flake updates.
  cfg = dir: lib.optionalAttrs (builtins.pathExists "${omarchy}/config/${dir}") {
    ".config/${dir}" = {
      source = "${omarchy}/config/${dir}";
      recursive = true;
    };
  };

  # Same but for a single file.
  cfgFile = file: lib.optionalAttrs (builtins.pathExists "${omarchy}/config/${file}") {
    ".config/${file}".source = "${omarchy}/config/${file}";
  };
in
{
  home.file =
    { }
    # ---- Hyprland (Lua-based config, updated frequently upstream) ----
    // cfg "hypr"

    # ---- Terminals ----
    // cfg "foot"
    // cfg "alacritty"
    // cfg "ghostty"
    // cfg "kitty"

    # ---- Shell tooling ----
    // cfgFile "starship.toml"
    // cfg "tmux"

    # ---- TUI / productivity ----
    // cfg "btop"
    // cfg "lazygit"
    // cfg "imv"

    # ---- Omarchy-specific runtime config ----
    # (hooks, extensions, shell.json — not git since we manage that ourselves)
    // cfg "omarchy"

    # ---- Other apps ----
    // cfg "xournalpp"
    // cfg "opencode";

  xdg.enable = true;
}
