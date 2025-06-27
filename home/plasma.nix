{ config, pkgs, lib, ... }:

{
  # Apply only if the system is Linux
  config = lib.mkIf pkgs.stdenv.isLinux {
    # System-level configuration for Plasma
    services.desktopManager.plasma6 = {
      enable = true;
    };

    # KDE/Plasma specific configurations
    environment.plasma6.excludePackages = with pkgs.kdePackages; [
      # Optional: exclude packages you don't want
      # oxygen
    ];

    # Set default theme configurations
    # Set default theme configurations
    qt = {
      enable = true;
      platformTheme = "kde";
      style = "breeze-dark";
    };

    # Additional Plasma-specific settings
    environment.variables = {
      QT_QPA_PLATFORM = "xcb"; # Ensure compatibility with X11
    };

    # Enable Wayland support if needed
    services.xserver.displayManager.defaultSession = "plasma"; # or "plasmawayland"
  };
}