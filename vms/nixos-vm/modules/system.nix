{ config, pkgs, ... }:

{
  # Time zone and locale
  time.timeZone = "America/New_York"; # Adjust to your timezone
  i18n.defaultLocale = "en_US.UTF-8";
  
  # Console and fonts
  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true;
  };
  
  # Enable Wayland and Hyprland
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };
  
  # Display manager with Hyprland support
  services.xserver = {
    enable = true;
    displayManager.gdm = {
      enable = true;
      wayland = true;
    };
    
    # Keep X11 support for compatibility
    desktopManager.gnome.enable = false; # Disable GNOME to use Hyprland
    
    # VM-optimized settings
    videoDrivers = [ "virtio" ];
  };
  
  # Wayland specific services
  services.dbus.enable = true;
  security.polkit.enable = true;
  
  # Audio with PipeWire (better for Wayland)
  sound.enable = false; # Disable ALSA
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };
  
  # Fonts for Hyprland
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    font-awesome
    (nerdfonts.override { fonts = [ "FiraCode" "DroidSansMono" "JetBrainsMono" ]; })
  ];
  
  # Portal for screen sharing and file dialogs
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-hyprland
      xdg-desktop-portal-gtk
    ];
  };
  
  # VM optimizations
  services.spice-vdagentd.enable = true;
  services.qemuGuest.enable = true;
  
  # Hardware acceleration
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };
  
  # Environment variables for Wayland
  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";  # Fix for VM cursor issues
    NIXOS_OZONE_WL = "1";           # Enable Wayland for Electron apps
  };
}