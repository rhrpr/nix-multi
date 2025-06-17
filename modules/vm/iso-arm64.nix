# ARM64 NixOS ISO Configuration for UTM
# Optimized for Apple Silicon Macs running UTM
{ pkgs, lib, modulesPath, username, ... }:

{
  imports = [
    # Use the graphical installation CD base
    (modulesPath + "/installer/cd-dvd/installation-cd-graphical-calamares.nix")
  ];

  # ISO configuration
  isoImage = {
    # Optimize for ARM64
    isoName = "nixos-hyprland-aarch64.iso";
    
    # Set reasonable ISO size limits
    squashfsCompression = "zstd -Xcompression-level 6";
    
    # Make the ISO bootable on ARM64 systems
    makeEfiBootable = true;
    makeUsbBootable = true;
    
    # Append custom kernel parameters for VM optimization
    appendToMenuLabel = " (ARM64 for UTM)";
    grubTheme = null;  # Use default theme for compatibility
  };

  # System configuration for live environment
  system.stateVersion = "24.05";

  # Enable Hyprland for the live session
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # Display manager configuration
  services.displayManager = {
    gdm = {
      enable = true;
      wayland = true;
    };
    defaultSession = "hyprland";
  };

  # Essential packages for live environment
  environment.systemPackages = with pkgs; [
    # Terminal and shell
    kitty
    alacritty
    
    # System utilities
    git
    curl
    wget
    vim
    nano
    htop
    btop
    
    # Development tools
    gcc
    nodejs
    python3
    
    # GUI applications
    firefox
    
    # File management
    thunar
    ranger
    
    # System tools
    gparted
    gnome.gnome-disk-utility
    
    # Archive tools
    unzip
    zip
    p7zip
    
    # Network tools
    networkmanagerapplet
    
    # Hyprland utilities
    waybar
    wofi
    dunst
    swww
    grim
    slurp
    wl-clipboard
  ];

  # Enable networking
  networking = {
    networkmanager.enable = true;
    wireless.enable = false;  # Conflicts with NetworkManager
    
    # Enable SSH for remote management
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
    };
  };

  # Enable SSH
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = true;
  };

  # Audio configuration
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # User configuration for live environment
  users.users = {
    nixos = {
      isNormalUser = true;
      extraGroups = [ "wheel" "networkmanager" "audio" "video" ];
      # Set a default password for the live environment
      initialPassword = "nixos";
      shell = pkgs.bash;
    };
    
    # Add the configured user as well
    ${username} = {
      isNormalUser = true;
      extraGroups = [ "wheel" "networkmanager" "audio" "video" ];
      initialPassword = "nixos";
      shell = pkgs.bash;
    };
  };

  # Enable sudo without password for wheel group (live environment)
  security.sudo.wheelNeedsPassword = false;

  # Hardware support for ARM64
  hardware = {
    # Enable all firmware
    enableAllFirmware = true;
    enableRedistributableFirmware = true;
    
    # OpenGL support for ARM64
    opengl = {
      enable = true;
      driSupport = true;
    };
    
    # Bluetooth support
    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
  };

  # Services for live environment
  services = {
    # Enable the X11 windowing system
    xserver = {
      enable = true;
      
      # Keyboard configuration
      xkb = {
        layout = "us";
        variant = "";
      };
    };
    
    # Enable CUPS for printing
    printing.enable = true;
    
    # Enable sound
    pulseaudio.enable = false;  # Using PipeWire instead
    
    # Bluetooth service
    blueman.enable = true;
  };

  # Environment variables for Hyprland
  environment.sessionVariables = {
    # Enable Wayland for supported applications
    NIXOS_OZONE_WL = "1";
    
    # Set default terminal
    TERMINAL = "kitty";
    
    # Hyprland specific
    WLR_NO_HARDWARE_CURSORS = "1";  # Helps with VM cursor issues
  };

  # Fonts for better text rendering
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
  ];

  # Enable automatic login for live environment
  services.displayManager.autoLogin = {
    enable = true;
    user = "nixos";
  };

  # Workaround for GNOME autologin
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;
}