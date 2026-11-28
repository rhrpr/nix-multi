# Linuxbrew bootstrap for NixOS.
#
# NixOS has no equivalent of nix-darwin's declarative `homebrew.*` options —
# Homebrew manages itself outside the Nix store on Linux too, under
# /home/linuxbrew/.linuxbrew (or ~/.linuxbrew for a non-root install). This
# module does three things:
#   1. Enables nix-ld so Homebrew's glibc-linked bottles can find a dynamic
#      loader and the common shared libraries they expect (NixOS's /lib
#      layout otherwise breaks them).
#   2. Generates /etc/Brewfile.linux from the single source of truth in
#      modules/shared/homebrew-nix-apps.nix, limited to brew formulae that are
#      both Linux-capable AND not already provided by nixpkgs in
#      modules/nixos/apps.nix (so nothing is ever installed twice).
#   3. Installs a `brew-linux-bundle` script that bootstraps Homebrew itself
#      (if missing) and runs `brew bundle` against the generated Brewfile.
#      This is intentionally NOT run automatically during `nixos-rebuild` —
#      it touches state outside the Nix store and needs network access, so
#      it's invoked explicitly via `make brew-linux-setup` (see Makefile).
{ pkgs, lib, ... }:
let
  homebrewApps = (import ../shared/homebrew-nix-apps.nix).entries;

  linuxBrews = builtins.filter (
    e: e.type == "brew" && builtins.elem "linux" e.platforms && e.linuxNixPkg == null
  ) homebrewApps;

  skippedAsNixManaged = builtins.filter (
    e: e.type == "brew" && builtins.elem "linux" e.platforms && e.linuxNixPkg != null
  ) homebrewApps;

  darwinOnly = builtins.filter (e: !(builtins.elem "linux" e.platforms)) homebrewApps;

  brewfile = pkgs.writeText "Brewfile.linux" ''
    # Generated from modules/shared/homebrew-nix-apps.nix — do not edit by hand.
    # Rebuild (nixos-rebuild switch) after changing the shared list, then
    # re-run `make brew-linux-setup` to apply it.
    #
    # Skipped — already provided by nixpkgs (see modules/nixos/apps.nix),
    # installing via brew too would double-manage them:
    ${lib.concatMapStringsSep "\n" (
      e: "#   ${e.name} -> pkgs.${e.linuxNixPkg} (${e.desc})"
    ) skippedAsNixManaged}
    #
    # Skipped — darwin-only (cask/mas has no Linux support, or the formula
    # is macOS-specific; see modules/shared/homebrew-nix-apps.nix `note` fields):
    ${lib.concatMapStringsSep "\n" (e: "#   ${e.name} (${e.desc})") darwinOnly}

    ${lib.concatMapStringsSep "\n" (e: ''brew "${e.name}" # ${e.desc}'') linuxBrews}
  '';
in
{
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    zlib
    openssl
    curl
    stdenv.cc.cc.lib
    glibc
  ];

  environment.etc."Brewfile.linux".source = brewfile;

  environment.systemPackages = [
    (pkgs.writeShellScriptBin "brew-linux-bundle" ''
      set -euo pipefail

      if ! command -v brew >/dev/null 2>&1; then
        echo "Homebrew not found on PATH — installing (requires network + sudo)..."
        NONINTERACTIVE=1 /bin/bash -c \
          "$(${pkgs.curl}/bin/curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        if [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
          eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
        elif [ -x "$HOME/.linuxbrew/bin/brew" ]; then
          eval "$("$HOME/.linuxbrew/bin/brew" shellenv)"
        fi
      fi

      echo "Running: brew bundle --file=/etc/Brewfile.linux"
      brew bundle --file=/etc/Brewfile.linux
    '')
  ];
}
