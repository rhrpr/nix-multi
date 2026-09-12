{
  pkgs,
  lib,
  desktopManager ? "end4",
  ...
}:

let
  isPlasma = desktopManager == "plasma";
  isEnd4 = desktopManager == "end4" || desktopManager == "hyprland";
  isOmarchy = desktopManager == "omarchy";
in
{
  imports = [
    ./vscode.nix
  ]
  ++ lib.optionals (!isOmarchy) [
    ./browser.nix
  ]
  ++ lib.optionals isPlasma [
    ./plasma.nix
  ]
  ++ lib.optionals isEnd4 [
    ./hyprland.nix
  ]
  # Note: omarchy dotfiles are seeded by omarchy-nix.homeManagerModules.default
  # (included in mksystem.nix sharedModules for isOmarchy).  That module
  # copies files as mutable seeds — not symlinks — so the theme engine and
  # user edits survive.  The source package is built from the `omarchy` flake
  # input (see modules/nixos/omarchy.nix), so `nix flake update omarchy`
  # always reflects the latest upstream.
  ;

  # Linux-specific packages
  home.packages =
    with pkgs;
    lib.optionals stdenv.hostPlatform.isLinux [
      # Linux desktop utilities
      xclip
      wl-clipboard

      # System monitoring
      htop
      btop

      # File managers and utilities
      ranger
      fd
      bat
    ];

  # Enable XDG
  xdg.enable = true;
}
