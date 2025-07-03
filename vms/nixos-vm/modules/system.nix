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

    # Keep X11 support for compatibility

    # VM-optimized settings
    videoDrivers = [ "virtio" ];
  };

  # Use new display manager configuration
  services.displayManager.gdm = {
    enable = true;
    wayland = true;
  };

  # Disable GNOME to use Hyprland
  services.desktopManager.gnome.enable = false;

  # Wayland specific services
  services.dbus.enable = true;
  security.polkit.enable = true;

  # Audio with PipeWire (better for Wayland)
  services.pulseaudio.enable = false;
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
    noto-fonts-cjk-sans
    noto-fonts-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    font-awesome
    nerd-fonts.fira-code
    nerd-fonts.droid-sans-mono
    nerd-fonts.jetbrains-mono
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

  # Hardware acceleration - use new hardware.graphics for newer NixOS
  hardware.graphics = {
    enable = true;
    # Only enable 32-bit support on x86_64 systems
    enable32Bit = pkgs.stdenv.isx86_64;
  };

  # Environment variables for Wayland
  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1"; # Fix for VM cursor issues
    NIXOS_OZONE_WL = "1"; # Enable Wayland for Electron apps
  };
}
