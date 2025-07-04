{
  config,
  pkgs,
  lib,
  hostname,
  username,
  hyprland,
  ...
}:

{
  # End-4 dots-hyprland VM configuration
  # Based on https://github.com/end-4/dots-hyprland
  # Adapted for NixOS from Arch Linux

  # Basic system configuration for VM
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Networking
  networking = {
    hostName = hostname;
    networkmanager.enable = true;
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ]; # SSH
    };
  };

  # Localization
  time.timeZone = "Europe/London";
  i18n.defaultLocale = "en_GB.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_GB.UTF-8";
    LC_IDENTIFICATION = "en_GB.UTF-8";
    LC_MEASUREMENT = "en_GB.UTF-8";
    LC_MONETARY = "en_GB.UTF-8";
    LC_NAME = "en_GB.UTF-8";
    LC_NUMERIC = "en_GB.UTF-8";
    LC_PAPER = "en_GB.UTF-8";
    LC_TELEPHONE = "en_GB.UTF-8";
    LC_TIME = "en_GB.UTF-8";
  };

  # Enable Hyprland
  programs.hyprland = {
    enable = true;
    package = hyprland.packages.${pkgs.system}.hyprland;
    portalPackage = hyprland.packages.${pkgs.system}.xdg-desktop-portal-hyprland;
  };

  # Enable essential programs
  programs = {
    firefox.enable = true;
    zsh.enable = true;
    dconf.enable = true;
    git.enable = true;
    neovim = {
      enable = true;
      defaultEditor = true;
    };
  };

  # XDG Portal configuration for Hyprland
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-wlr
    ];
  };

  # Enable sound with pipewire
  sound.enable = true;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # End-4 dots-hyprland specific packages
  environment.systemPackages = with pkgs; [
    # Core Hyprland ecosystem
    hyprland
    hyprpaper
    hyprpicker
    hypridle
    hyprlock
    
    # Widget system (Quickshell dependencies)
    qt6.qtbase
    qt6.qtdeclarative
    qt6.qtsvg
    qt6.qtwayland
    
    # Terminal and shell
    kitty
    zsh
    starship
    
    # File managers
    yazi
    nautilus
    
    # Browsers
    firefox
    
    # Media
    mpv
    imv
    
    # Development tools
    git
    neovim
    
    # System tools
    htop
    btop
    fastfetch
    
    # Network tools
    networkmanager
    
    # Wayland utilities
    wl-clipboard
    wtype
    wofi
    
    # Notification daemon
    dunst
    
    # Screen capture
    grim
    slurp
    
    # Color picker
    hyprpicker
    
    # Audio control
    pamixer
    pavucontrol
    
    # Brightness control
    brightnessctl
    
    # Image viewers
    imv
    
    # Archive utilities
    unzip
    
    # Fonts for end-4 theme
    (nerdfonts.override { fonts = [ "JetBrainsMono" "FiraCode" "Meslo" ]; })
    
    # Python for potential scripting
    python3
    
    # Node.js for potential web components
    nodejs
    
    # Curl for API calls (AI integration)
    curl
    
    # JSON utilities
    jq
    
    # Material Design color generation (placeholder - would need custom package)
    # materialyou-colors # This would need to be packaged separately
  ];

  # Enable fonts
  fonts = {
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk
      noto-fonts-emoji
      font-awesome
      (nerdfonts.override { fonts = [ "JetBrainsMono" "FiraCode" "Meslo" ]; })
    ];
    
    fontconfig = {
      enable = true;
      defaultFonts = {
        monospace = [ "JetBrainsMono Nerd Font" ];
        sansSerif = [ "Noto Sans" ];
        serif = [ "Noto Serif" ];
      };
    };
  };

  # VM-specific user configuration
  users.users.${username} = {
    # Set a default password for VM
    password = "nixos";
    
    # Add user to required groups for end-4 dots-hyprland
    extraGroups = [ 
      "wheel" 
      "networkmanager" 
      "audio" 
      "video" 
      "input" 
      "render" 
    ];
    
    # Set default shell
    shell = pkgs.zsh;
  };

  # Enable automatic login for convenience in VM
  services.displayManager.autoLogin = {
    enable = true;
    user = username;
  };

  # Use SDDM as display manager for better Hyprland integration
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  # VM optimization services
  services = {
    # Enable SPICE agent for better integration
    spice-vdagentd.enable = true;
    
    # Enable QEMU guest agent
    qemuGuest.enable = true;
    
    # Enable SSH for remote access
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = true;
        PermitRootLogin = "no";
      };
    };
    
    # Disable unnecessary services for VM
    udisks2.enable = lib.mkForce false;
    power-profiles-daemon.enable = lib.mkForce false;
    thermald.enable = lib.mkForce false;
    
    # Enable dbus for desktop integration
    dbus.enable = true;
  };

  # Security settings for Hyprland
  security = {
    polkit.enable = true;
    pam.services.hyprlock = {};
  };

  # VM-specific boot optimizations
  boot = {
    # Faster boot times
    kernelParams = [
      "quiet"
      "loglevel=3"
      "systemd.show_status=auto"
      "rd.udev.log_level=3"
    ];
    
    # Optimize initrd
    initrd = {
      verbose = false;
      systemd.enable = true;
    };
    
    # Plymouth for better boot experience
    plymouth = {
      enable = true;
      theme = "breeze";
    };
  };

  # VM-specific hardware optimizations
  hardware = {
    # Enable hardware acceleration for VMs
    graphics = {
      enable = true;
      enable32Bit = lib.mkIf (pkgs.stdenv.hostPlatform.system == "x86_64-linux") true;
    };
    
    # VM doesn't need bluetooth - force disable
    bluetooth = {
      enable = lib.mkForce false;
      powerOnBoot = lib.mkForce false;
    };
  };

  # Disable bluetooth services explicitly
  services.blueman.enable = lib.mkForce false;
  
  # Optimize memory usage for VM
  zramSwap = {
    enable = true;
    memoryPercent = 25;
  };

  # System state version for VM
  system.stateVersion = "24.11";
}