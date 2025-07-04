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
  # NixOS VM configuration with end-4 dots-hyprland
  # Machine: nixos-vm-end4
  # System: NixOS with Hyprland (end-4 dots-hyprland theme)

  imports = [
    # VM-specific configuration with end-4 dots-hyprland
    ../modules/vm/end4-dots-hyprland.nix
    
    # VM hardware configuration
    ../modules/vm/hardware-configuration.nix
    
    # VM guest optimizations
    ../modules/vm/vm-guest.nix
    
    # VM applications
    ../modules/vm/apps.nix
    
    # Shared VM tools
    ../modules/shared/vm-tools.nix
  ];

  # Override hostname for this specific VM
  networking.hostName = lib.mkForce "nixos-end4";

  # Enable VM image generation
  virtualisation.vmVariant = {
    # VM-specific settings
    virtualisation = {
      memorySize = 6144; # 6GB RAM
      cores = 4;
      
      # Graphics acceleration
      graphics = {
        enable = true;
        enable32Bit = true;
      };
      
      # Disk configuration
      diskSize = 32768; # 32GB disk
      
      # Network configuration
      forwardPorts = [
        {
          from = "host";
          host.port = 22001; # Different port from standard VM
          guest.port = 22;
        }
      ];
    };
    
    # VM-specific boot configuration
    boot.loader.timeout = 1; # Faster boot
    
    # VM-specific services
    services.getty.autologinUser = username;
  };

  # VM-specific optimizations for end-4 dots-hyprland
  environment.variables = {
    # Wayland-specific
    MOZ_ENABLE_WAYLAND = "1";
    QT_QPA_PLATFORM = "wayland";
    
    # Hyprland-specific
    WLR_NO_HARDWARE_CURSORS = "1";
    WLR_RENDERER_ALLOW_SOFTWARE = "1";
    
    # End-4 dots-hyprland theme variables
    HYPRCURSOR_THEME = "Bibata-Modern-Classic";
    HYPRCURSOR_SIZE = "24";
  };

  # Additional packages specific to end-4 dots-hyprland VM
  environment.systemPackages = with pkgs; [
    # Additional development tools for customization
    python3
    nodejs
    git
    
    # Additional media tools
    imagemagick
    
    # Additional system monitoring
    htop
    btop
    
    # Additional network tools
    wget
    curl
    
    # Text editors
    vim
    nano
    
    # Archive tools
    unzip
    zip
    
    # Process management
    killall
    
    # File utilities
    file
    tree
    
    # System information
    lshw
    usbutils
    pciutils
  ];

  # Enable additional services for end-4 dots-hyprland
  services = {
    # Enable location services (for adaptive themes)
    geoclue2.enable = true;
    
    # Enable GNOME keyring for credential management
    gnome.gnome-keyring.enable = true;
    
    # Enable printing (just in case)
    printing.enable = true;
    
    # Enable automatic timezone detection
    automatic-timezoned.enable = true;
  };

  # Enable additional hardware support
  hardware = {
    # Enable all firmware
    enableAllFirmware = true;
    
    # Enable additional OpenGL support
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        intel-media-driver
        vaapiIntel
        vaapiVdpau
        libvdpau-va-gl
      ];
    };
  };

  # System state version
  system.stateVersion = "24.11";
}