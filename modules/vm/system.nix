{ 
  config, 
  pkgs, 
  lib,
  hostname,
  username,
  ... 
}:

{
  # VM-optimized system configuration
  imports = [
    ../nixos/system.nix  # Inherit base system config
  ];

  # VM-specific overrides
  networking.hostName = lib.mkForce hostname;

  # Optimize for VM environment
  services = {
    # Enable SPICE agent for better integration
    spice-vdagentd.enable = true;
    
    # Enable QEMU guest agent
    qemuGuest.enable = true;
    
    # Disable unnecessary services for VM
    udisks2.enable = lib.mkForce false;
    power-profiles-daemon.enable = lib.mkForce false;
    thermald.enable = lib.mkForce false;
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
      enable32Bit = true;
    };
    
    # VM doesn't need bluetooth typically
    bluetooth.enable = lib.mkForce false;
  };

  # Optimize memory usage for VM
  zramSwap = {
    enable = true;
    memoryPercent = 25;
  };

  # VM-specific user configuration
  users.users.${username} = {
    extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
    # Set a default password for VM (change after first login)
    password = "nixos";
  };

  # Enable automatic login for convenience in VM
  services.displayManager.autoLogin = {
    enable = true;
    user = username;
  };

  # VM-specific networking
  networking = {
    networkmanager.enable = true;
    firewall = {
      enable = true;
      # Open ports for potential VM services
      allowedTCPPorts = [ 22 ];  # SSH
    };
  };

  # Enable SSH for remote access
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin = "no";
    };
  };

  # System state version for VM
  system.stateVersion = "24.11";
}
