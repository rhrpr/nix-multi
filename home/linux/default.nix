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
  imports =
    [
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
    ++ lib.optionals isOmarchy [
      # Links dotfiles directly from upstream omacom/omarchy (flake input).
      # Run `nix flake update omarchy` to pull the latest upstream configs.
      ./omarchy.nix
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
