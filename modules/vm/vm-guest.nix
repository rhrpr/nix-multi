{ config, pkgs, lib, ... }:

{
  # QEMU Guest Agent for better VM integration
  services.qemuGuest.enable = true;

  # SPICE agent for display integration
  services.spice-vdagentd.enable = true;

  # VM-specific optimizations
  boot.kernelParams = [
    # Disable CPU mitigations for better VM performance
    "mitigations=off"
    
    # Optimize for virtualized environment
    "clocksource=kvm-clock"
    
    # Reduce boot time
    "quiet"
    "loglevel=3"
  ];

  # Enable virtio modules for better performance
  boot.initrd.kernelModules = [
    "virtio_balloon"
    "virtio_console" 
    "virtio_rng"
  ];

  # Filesystem optimizations for VM
  fileSystems."/" = {
    options = [ "noatime" "discard" ];  # SSD-like optimizations for VM disks
  };

  # Memory management for VM
  boot.kernel.sysctl = {
    # Optimize VM memory usage
    "vm.swappiness" = 10;
    "vm.vfs_cache_pressure" = 50;
    "vm.dirty_background_ratio" = 5;
    "vm.dirty_ratio" = 10;
  };

  # Networking optimizations
  networking = {
    # Use systemd-networkd for faster networking in VMs
    useNetworkd = true;
    useDHCP = false;
    
    # Optimize network interface
    interfaces.ens3 = {
      useDHCP = true;
      # Increase MTU for better performance if supported
      mtu = 1500;
    };
  };

  # Power management - disable for VM
  services.power-profiles-daemon.enable = lib.mkForce false;
  services.thermald.enable = lib.mkForce false;
  services.auto-cpufreq.enable = lib.mkForce false;

  # Display and graphics optimizations for VM
  services.xserver = {
    # Use SPICE/QXL driver for better VM graphics
    videoDrivers = [ "qxl" "virtio" ];
    
    # Enable shared clipboard
    displayManager.sessionCommands = ''
      ${pkgs.spice-vdagent}/bin/spice-vdagent
    '';
  };

  # Audio optimizations for VM
  hardware.pulseaudio.enable = lib.mkForce false;
  services.pipewire = {
    enable = true;
    audio.enable = true;
    pulse.enable = true;
    alsa.enable = true;
    
    # VM-specific audio config
    wireplumber.configPackages = [
      (pkgs.writeTextDir "share/wireplumber/bluetooth.lua.d/51-bluez-config.lua" ''
        bluez_monitor.enabled = false
      '')
    ];
  };

  # Time synchronization for VM
  services.chrony = {
    enable = true;
    servers = [ "pool.ntp.org" ];
  };

  # Disable unnecessary services for VM environment
  services = {
    # Disable hardware-specific services
    fwupd.enable = lib.mkForce false;
    udisks2.enable = lib.mkForce false;
    
    # Disable power management
    upower.enable = lib.mkForce false;
    
    # Disable bluetooth (usually not needed in VM)
    blueman.enable = lib.mkForce false;
  };

  # Security optimizations for VM
  security = {
    # Enable sudo without password for convenience (VM environment)
    sudo.wheelNeedsPassword = false;
    
    # Polkit for desktop environment
    polkit.enable = true;
  };

  # Environment variables for VM
  environment = {
    sessionVariables = {
      # Optimize for VM environment
      WLR_NO_HARDWARE_CURSORS = "1";
      WLR_RENDERER_ALLOW_SOFTWARE = "1";
      
      # Enable Wayland for applications
      NIXOS_OZONE_WL = "1";
      MOZ_ENABLE_WAYLAND = "1";
    };
    
    # Additional packages for VM management
    systemPackages = with pkgs; [
      spice-vdagent
      spice-gtk
      virtio-win  # Windows VM support if needed
    ];
  };

  # Systemd optimizations for VM
  systemd = {
    # Faster shutdown
    extraConfig = ''
      DefaultTimeoutStopSec=10s
      DefaultTimeoutStartSec=10s
    '';
    
    # Optimize journald for VM
    services.systemd-journald.serviceConfig = {
      SystemMaxUse = "100M";
      RuntimeMaxUse = "50M";
    };
  };
}
