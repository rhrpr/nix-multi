{ config, pkgs, ... }:

{
  # Hyprland system configuration
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };
  
  # Essential packages for Hyprland
  environment.systemPackages = with pkgs; [
    # Hyprland ecosystem
    waybar              # Status bar
    rofi-wayland        # Application launcher
    dunst               # Notification daemon
    swww                # Wallpaper daemon
    grim                # Screenshot tool
    slurp               # Screen area selection
    wl-clipboard        # Clipboard utilities
    
    # Terminal and shell
    kitty               # Terminal emulator
    alacritty           # Alternative terminal
    
    # File managers
    nautilus            # GUI file manager
    ranger              # Terminal file manager
    
    # Media and graphics
    mpv                 # Video player
    imv                 # Image viewer
    
    # System monitoring
    btop                # System monitor
    
    # Network
    networkmanagerapplet
    
    # Authentication
    polkit-kde-agent
    
    # Screen locking
    swaylock-effects
    
    # Screen recording
    wf-recorder
    
    # PDF viewer
    zathura
    
    # Archives
    file-roller
    
    # Fonts and theming
    gtk3
    gtk4
    qt5.qtwayland
    qt6.qtwayland
  ];
  
  # Enable some additional services
  services.gnome.gnome-keyring.enable = true;
  programs.dconf.enable = true;
  
  # Security
  security.pam.services.swaylock = {};
}