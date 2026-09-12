{
  lib,
  pkgs,
  username,
  useremail,
  isVM,
  currentSystem,
  omarchy, # upstream omacom/omarchy flake input (flake = false, pinned in flake.lock)
  omarchy-nix, # NixOS port flake — provides packages.${system}.omarchy
  ...
}:

# ---------------------------------------------------------------------------
# Omarchy NixOS system module
#
# HOW UPSTREAM TRACKING WORKS
# ============================
# omarchy-nix builds its omarchy package from its own pinned copy of the
# upstream (github:omacom/omarchy/quattro, stored in omarchy-nix's flake.lock).
# That means updating omarchy-nix in our flake.lock does not necessarily
# pull the latest upstream commit — omarchy-nix controls that pointer.
#
# To decouple the two: we build the omarchy package from the `omarchy` flake
# input (github:omacom/omarchy, pinned in OUR flake.lock) by overriding the
# package's `src`.  All of omarchy-nix's NixOS patches still apply; only the
# source tree changes.  This way:
#
#   nix flake update omarchy    →  pulls latest omacom/omarchy commit
#   nixos-rebuild switch        →  omarchy-nix rebuilds the package from it,
#                                  activation scripts seed the new configs
#
# The home-manager module (omarchy-nix.homeManagerModules.default) seeds
# dotfiles as MUTABLE copies — not symlinks — so the theme engine and user
# edits survive. That module handles all file management; no additional home
# module is needed in this repo.
# ---------------------------------------------------------------------------

let
  # Build the omarchy package from the directly pinned upstream snapshot.
  # overrideAttrs replaces `src`; omarchy-nix's NixOS-specific patches
  # (env-bootstrap path fixup, systemd unit rewriting, etc.) still apply.
  omarchyPkg = (omarchy-nix.packages.${currentSystem}.omarchy).overrideAttrs (_old: {
    src = omarchy;
  });
in
{
  # The omarchy-nix module provides the actual upstream Omarchy Quattro
  # desktop, adapted for declarative NixOS package management.
  omarchy = {
    enable = true;
    package = omarchyPkg;
    full_name = username;
    email_address = useremail;
    timezone = "Europe/London";
    terminal = "foot";
    scale = 1;

    managedPackagesFile =
      if builtins.pathExists ../../omarchy-packages.json then ../../omarchy-packages.json else null;

    # The VM already authenticates through its host/disk boundary and has
    # historically auto-logged in. Physical hosts retain the SDDM prompt.
    autologin.user = if isVM then username else null;
  };

  # Omarchy uses these groups for input automation, display brightness, and
  # the Quickshell desktop services. Existing groups remain additive.
  users.users.${username}.extraGroups = [
    "input"
    "ydotool"
    "i2c"
  ];

  # Omarchy's Nix-native Install/Remove and Update actions need to know which
  # consumer flake to edit and rebuild.
  environment.sessionVariables.OMARCHY_NIX_FLAKE = "/home/${username}/.config/nix-multi";

  # Bluetooth is deliberately disabled by the VM module. Document that as an
  # expected override of Omarchy's physical-desktop default.
  warnings = lib.optional isVM "Omarchy VM profile: Bluetooth remains disabled; GPU passthrough is recommended for Quickshell.";
}
