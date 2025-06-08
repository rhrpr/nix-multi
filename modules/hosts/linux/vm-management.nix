# Linux VM Management Module
# Provides VM creation and management tools for Linux hosts
{ pkgs, lib, config, username, gpuConfig, ... }:

{
  # VM creation and management tools for Linux
  environment.systemPackages = with pkgs; [
    # Core virtualization tools
    qemu_kvm         # KVM acceleration
    qemu_full        # Full QEMU with all features
    libvirt          # Virtualization management daemon
    virt-manager     # GUI for managing VMs
    virt-viewer      # Viewer for VMs
    virt-install     # VM installation tool

    # QEMU utilities
    qemu             # QEMU user tools
    qemu-utils       # QEMU disk/image utilities

    # Spice (remote desktop) support
    spice-gtk        # Spice GTK client
    spice-protocol   # Spice protocol definitions
    spice-vdagent    # Spice guest agent

    # Windows guest drivers
    win-virtio       # VirtIO drivers for Windows
    win-spice        # Spice guest tools for Windows

    # GPU passthrough and sharing tools
    looking-glass-client # Client for Looking Glass
    scream           # Network audio for Windows VMs
    barrier          # Share mouse/keyboard between host and guest
    
    # NVIDIA tools for monitoring and management
    nvidia-system-monitor-qt # GUI for NVIDIA monitoring
    nvtop            # Terminal-based GPU monitoring
    
    # VFIO tools
    pciutils         # For lspci to identify devices
    usbutils         # For lsusb
  ];

  # Enable virtualization services
  virtualisation = {
    libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        runAsRoot = true;
        swtpm.enable = true;
        ovmf = {
          enable = true;
          packages = [ pkgs.OVMFFull.fd ];
        };
        verbatimConfig = ''
          # GPU passthrough device permissions
          cgroup_device_acl = [
            "/dev/null", "/dev/full", "/dev/zero",
            "/dev/random", "/dev/urandom",
            "/dev/ptmx", "/dev/kvm", "/dev/kqemu",
            "/dev/rtc","/dev/hpet", "/dev/vfio/vfio",
            "/dev/nvidia0", "/dev/nvidiactl", "/dev/nvidia-modeset",
            "/dev/nvidia-uvm", "/dev/nvidia-uvm-tools"
          ]
        '';
      };
    };
    spiceUSBRedirection.enable = true;
  };

  # Add users to required groups
  users.users.${username} = {
    extraGroups = [ 
      "libvirtd" 
      "kvm" 
      "input"     # For input devices passthrough
      "disk"      # For disk management
    ];
  };

  # Network configuration for VMs
  networking = {
    # Enable IP forwarding for VM networking
    firewall = {
      # Allow libvirt networks
      trustedInterfaces = [ "virbr0" ];
      # Allow specific ports if needed
      allowedTCPPorts = [ 
        # 5900  # VNC (uncomment if using VNC)
        # 5901  # Additional VNC displays
      ];
    };
  };

  # Security and permissions
  security = {
    # Allow users in libvirtd group to manage VMs without password
    polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (action.id == "org.libvirt.unix.manage" &&
            subject.isInGroup("libvirtd")) {
            return polkit.Result.YES;
        }
      });
    '';
  };

  # Environment variables for VM management
  environment.variables = {
    # LibVirt default URI
    LIBVIRT_DEFAULT_URI = "qemu:///system";
    
    # Looking Glass shared memory
    LOOKING_GLASS_SHARED_MEM = "/dev/shm/looking-glass";
  };

  # Tmpfiles for VM management
  systemd.tmpfiles.rules = [
    "f /dev/shm/looking-glass 0660 ${username} kvm -"
    "d /var/lib/libvirt/images 0755 root root -"
  ];

  # Systemd services configuration
  systemd.services = {
    # Ensure libvirtd starts after network
    libvirtd = {
      after = [ "network.target" "systemd-udev-settle.service" ];
      wants = [ "systemd-udev-settle.service" ];
    };
  };
}
