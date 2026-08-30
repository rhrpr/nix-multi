{
  pkgs,
  lib,
  desktopManager ? "plasma",
  ...
}:

let
  isPlasma = desktopManager == "plasma";
  isHyprland = desktopManager == "hyprland";
in
{
  imports =
    [
      ./vscode.nix
      ./browser.nix  # Always import browser config for Linux
    ]
    ++ lib.optionals isPlasma [
      ./plasma.nix
    ]
    ++ lib.optionals isHyprland [
      ./hyprland.nix
    ];

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
