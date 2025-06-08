{
  config,
  lib,
  pkgs,
  desktopManager ? "plasma",
  hyprland,
  ...
}:

let
  isPlasma = desktopManager == "plasma";
  isHyprland = desktopManager == "hyprland";
in
{
  imports = [
    # Import Hyprland module if selected
  ] ++ lib.optionals isHyprland [
    hyprland.nixosModules.default
  ];

  # Common desktop configuration
  services.xserver = {
    enable = !isHyprland; # Disable X11 for Hyprland (uses Wayland)
    xkb = {
      layout = "us";
      variant = "";
    };
  };

  # Display manager configuration
  services.displayManager = lib.mkMerge [
    # Common display manager settings
    {
      autoLogin.enable = false;
    }
    
    # Plasma-specific configuration
    (lib.mkIf isPlasma {
      sddm = {
        enable = true;
        wayland.enable = true;
      };
    })
    
    # Hyprland-specific configuration
    (lib.mkIf isHyprland {
      # Use GDM or SDDM for Hyprland
      sddm = {
        enable = true;
        wayland.enable = true;
      };
    })
  ];

  # Desktop environment configuration
  services.desktopManager = lib.mkIf isPlasma {
    plasma6.enable = true;
  };

  # Hyprland configuration
  programs.hyprland = lib.mkIf isHyprland {
    enable = true;
    xwayland.enable = true;
    package = hyprland.packages.${pkgs.system}.hyprland;
  };

  # Wayland support
  environment.sessionVariables = lib.mkIf (isPlasma || isHyprland) {
    NIXOS_OZONE_WL = "1"; # Enable Wayland support in Chromium/Electron apps
    MOZ_ENABLE_WAYLAND = "1"; # Enable Wayland support in Firefox
  };

  # Security and authentication
  security = {
    polkit.enable = true;
    rtkit.enable = true;
    pam.services = {
      gdm.enableGnomeKeyring = lib.mkIf isHyprland true;
      login.enableGnomeKeyring = lib.mkIf isHyprland true;
    };
  };

  # Audio configuration
  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;
  };

  # Graphics and hardware acceleration
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Essential packages for desktop environments
  environment.systemPackages = with pkgs; [
    # Common desktop packages
    xdg-utils
    xdg-user-dirs
    
    # Wayland utilities
    wl-clipboard
    wayland-utils
    
    # Screen sharing and remote desktop
    kdePackages.xwaylandvideobridge
    
    # Font packages
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
  ] ++ lib.optionals isHyprland [
    # Hyprland-specific packages
    waybar
    rofi-wayland
    dunst
    swww # wallpaper daemon
    grim # screenshot
    slurp # screen selection
    wf-recorder # screen recording
    brightnessctl
    playerctl
    pamixer
    swaylock-effects
    swayidle
    networkmanagerapplet
    blueman
    pavucontrol
    file-roller
    nautilus
    gnome-calculator
    gnome-calendar
    gnome-clocks
    gnome-weather
  ] ++ lib.optionals isPlasma [
    # Additional Plasma packages
    kdePackages.kate
    kdePackages.kdeconnect-kde
    kdePackages.okular
    kdePackages.ark
    kdePackages.dolphin
    kdePackages.konsole
    kdePackages.spectacle
  ];

  # XDG portal configuration
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
    ] ++ lib.optionals isPlasma [
      kdePackages.xdg-desktop-portal-kde
    ] ++ lib.optionals isHyprland [
      xdg-desktop-portal-hyprland
    ] ++ [
      xdg-desktop-portal-gtk
    ];
    config = {
      common = {
        default = if isPlasma then ["kde"] else if isHyprland then ["hyprland"] else ["gtk"];
      };
    };
  };

  # Fonts configuration
  fonts = {
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-emoji
      liberation_ttf
      fira-code
      fira-code-symbols
      nerd-fonts.fira-code
      nerd-fonts.jetbrains-mono
      font-awesome
    ];
    
    fontconfig = {
      enable = true;
      defaultFonts = {
        serif = [ "Noto Serif" ];
        sansSerif = [ "Noto Sans" ];
        monospace = [ "Fira Code" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };

  # Network configuration
  networking.networkmanager.enable = true;
  
  # Bluetooth support
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  services.blueman.enable = lib.mkIf isHyprland true;

  # Printing support
  services.printing = {
    enable = true;
    drivers = with pkgs; [ cups-pdf-to-pdf ];
  };
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # Thunar file manager for Hyprland
  programs.thunar = lib.mkIf isHyprland {
    enable = true;
    plugins = with pkgs.xfce; [
      thunar-archive-plugin
      thunar-volman
    ];
  };
  
  services.gvfs.enable = lib.mkIf isHyprland true; # Trash and mount support
  services.tumbler.enable = lib.mkIf isHyprland true; # Thumbnail support

  # Gaming support (optional)
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };
  programs.gamemode.enable = true;
}