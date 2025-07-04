{
  pkgs,
  lib,
  desktopManager ? "plasma",
  ...
}:

let
  isPlasma = desktopManager == "plasma";
  isHyprland = desktopManager == "hyprland";
  isEnd4Hyprland = desktopManager == "end4-hyprland";
in
{
  imports =
    [
      ./vscode.nix
    ]
    ++ lib.optionals isPlasma [
      ./plasma.nix
    ]
    ++ lib.optionals isHyprland [
      ./hyprland.nix
    ]
    ++ lib.optionals isEnd4Hyprland [
      ./end4-hyprland.nix
    ];

  # Linux-specific packages
  home.packages =
    with pkgs;
    lib.optionals stdenv.isLinux [
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
