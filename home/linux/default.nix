{
  pkgs,
  lib,
  desktopManager ? "plasma",
  zen-browser.homeModules.beta,
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

  # Enable Zen Browser
  programs.zen-browser.enable = true;
  programs.zen-browser.settings = {
    # Example settings, adjust as needed
    theme = "dark";
    extensions = [ "uBlockOrigin" "PrivacyBadger" ];
  };

  # Enable XDG
  xdg.enable = true;
}
