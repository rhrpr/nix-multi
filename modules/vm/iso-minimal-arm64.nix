# Minimal ARM64 NixOS ISO Configuration for UTM
# Lightweight configuration for Apple Silicon Macs
{ pkgs, lib, modulesPath, ... }:

{
  imports = [
    # Use the minimal installation CD base
    (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
  ];

  # ISO configuration
  isoImage = {
    # Optimize for ARM64
    isoName = "nixos-minimal-aarch64.iso";
    
    # Aggressive compression for smaller ISO
    squashfsCompression = "zstd -Xcompression-level 15";
    
    # Make the ISO bootable on ARM64 systems
    makeEfiBootable = true;
    makeUsbBootable = true;
    
    # Minimize ISO size
    includeSystemBuildDependencies = false;
    
    # Custom menu label
    appendToMenuLabel = " (Minimal ARM64 for UTM)";
    grubTheme = null;
  };

  # System configuration for minimal live environment
  system.stateVersion = "24.05";

  # Minimal package set
  environment.systemPackages = with pkgs; [
    # Essential system tools
    git
    curl
    wget
    vim
    nano
    htop
    
    # Basic development tools
    gcc
    
    # Network utilities
    openssh
    
    # File utilities
    unzip
    zip
    
    # Text processing
    gnused
    gawk
    
    # System utilities
    lshw
    pciutils
    usbutils
  ];

  # Enable minimal networking
  networking = {
    # Use systemd-networkd for minimal networking
    useNetworkd = true;
    useDHCP = lib.mkDefault true;
    
    # Enable SSH for remote management
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
    };
  };

  # Enable SSH for remote management
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin = "yes";  # For installation convenience
    };
  };

  # Minimal user configuration
  users.users.nixos = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    initialPassword = "nixos";
    shell = pkgs.bash;
  };

  # Enable sudo without password for convenience
  security.sudo.wheelNeedsPassword = false;

  # Minimal hardware support
  hardware = {
    enableRedistributableFirmware = true;
  };

  # Essential services only
  services = {
    # Minimal systemd configuration
    journald.extraConfig = ''
      SystemMaxUse=100M
      RuntimeMaxUse=50M
    '';
  };

  # Disable unnecessary services for minimal ISO
  services.xserver.enable = lib.mkForce false;
  services.pulseaudio.enable = lib.mkForce false;
  sound.enable = lib.mkForce false;
  hardware.bluetooth.enable = lib.mkForce false;
  
  # Disable desktop environment
  services.displayManager.gdm.enable = lib.mkForce false;
  
  # Minimal boot configuration
  boot = {
    # Minimal kernel modules
    kernelModules = [ ];
    
    # Faster boot
    plymouth.enable = false;
    
    # Minimal initrd
    initrd = {
      systemd.enable = true;
      verbose = false;
    };
  };

  # Environment optimizations
  environment.variables = {
    # Reduce memory usage
    EDITOR = "nano";
    PAGER = "less";
  };

  # Minimal console configuration
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  # Disable documentation to save space
  documentation = {
    nixos.enable = false;
    man.enable = lib.mkDefault false;
    info.enable = false;
    doc.enable = false;
  };

  # System optimization for minimal footprint
  system.extraDependencies = [ ];
  
  # Reduce closure size
  environment.defaultPackages = lib.mkForce [
    pkgs.nano
    pkgs.perl
    pkgs.rsync
    pkgs.strace
  ];
}