{
  config,
  pkgs,
  lib,
  ...
}:

{
  programs.plasma = {
    enable = true;

    # Import existing plasma configuration
    shortcuts = (import ../plasma/plasma.conf).programs.plasma.shortcuts;
    configFile = (import ../plasma/plasma.conf).programs.plasma.configFile;
    dataFile = (import ../plasma/plasma.conf).programs.plasma.dataFile;
  };

  # Plasma-specific packages
  home.packages = with pkgs; [
    kdePackages.kdeconnect-kde
    kdePackages.filelight
    kdePackages.kcharselect
    kdePackages.kcolorchooser
    kdePackages.kruler
    kdePackages.kmag
    kdePackages.bluedevil # KDE Bluetooth support
  ];
}
