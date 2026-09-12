{
  pkgs,
  lib,
  desktopManager,
  ...
}:
{

  ##########################################################################
  #
  #  VM-specific apps and packages - optimized for Hyprland VM environment
  #
  ##########################################################################

  environment.systemPackages = with pkgs; [
    # Essential system tools
    git
    curl
    wget
    vim
    nano
    htop
    fastfetch

    # Hyprland-specific applications (lightweight for VM)
    kitty # Terminal
    firefox # Web browser
    xfce.thunar # File manager
    pavucontrol # Audio control
    networkmanagerapplet # Network management

    # Development tools (essential subset)
    vscode
    gnumake

    # Media and utilities
    mpv # Video player
    imv # Image viewer
    grim # Screenshots
    slurp # Area selection
    wl-clipboard # Clipboard utilities

    # System monitoring
    btop

    # Archive tools
    unzip
    zip

    # Text processing
    jq
    ripgrep
  ];

  # Enable essential programs
  programs = {
    # Git configuration
    git.enable = true;

    # Hyprland (configured in desktop.nix)
    hyprland.enable = lib.mkIf (desktopManager != "omarchy") true;

    # SSH for remote access
    ssh.startAgent = true;

    # Thunar file manager
    thunar = lib.mkIf (desktopManager != "omarchy") {
      enable = true;
      plugins = with pkgs.xfce; [
        thunar-archive-plugin
      ];
    };
  };

  # VM-specific services
  services = {
    # Enable printing (might be useful for VM)
    printing.enable = true;

    # Enable audio
    pipewire = {
      enable = true;
      audio.enable = true;
      pulse.enable = true;
      alsa.enable = true;
    };

    # Enable Thunar services
    gvfs.enable = lib.mkIf (desktopManager != "omarchy") true; # Trash and mount support
    tumbler.enable = lib.mkIf (desktopManager != "omarchy") true; # Thumbnail support
  };

  # Fonts for better VM experience
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-color-emoji
    fira-code
    font-awesome
  ];
}
