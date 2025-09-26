{
  pkgs,
  lib,
  config,
  ...
}:

{
  # Import comprehensive LibVirt host configuration
  imports = [
    ./libvirt-host.nix
  ];

  # This module now focuses on importing the comprehensive libvirt host configuration
  # All libvirt, QEMU, GPU passthrough, and VM networking configuration is managed
  # declaratively through Nix in the libvirt-host.nix module.
}

  # Boot configuration for partial GPU passthrough
  boot = {
    # Enable IOMMU but allow host GPU usage
    kernelParams =
      [
        "iommu=pt"

        # Enable NVIDIA features for sharing
        "nvidia-drm.modeset=1"
        "nvidia.NVreg_EnableGpuFirmware=0"

        # Enable SR-IOV and virtualization features
        "pci=realloc"
        "pcie_aspm=off"

        # KVM optimizations
        "kvm.ignore_msrs=1"
        "kvm.report_ignored_msrs=0"

        # Hugepages for better VM performance
        "default_hugepagesz=1G"
        "hugepagesz=1G"
        "hugepages=4" # 4GB of hugepages
      ]
      ++ lib.optionals (pkgs.stdenv.hostPlatform.system == "x86_64-linux") [
        # Intel-specific IOMMU (x86_64 only)
        "intel_iommu=on"
      ]
      ++ lib.optionals (pkgs.stdenv.hostPlatform.system == "aarch64-linux") [
        # ARM64-specific virtualization parameters
        "arm64.nopauth"
      ];

    # Load required modules for partial passthrough
    initrd = {
      kernelModules = [
        "vfio"
        "vfio_iommu_type1"
        "vfio_pci"
      ];
    };

    # Enable KVM and GPU modules
    kernelModules =
      [
        "vhost-net" # Network virtualization
        "nvidia" # NVIDIA driver for host
        "nvidia_drm" # NVIDIA DRM for display
        "nvidia_modeset"
        "nvidia_uvm" # Unified Memory for CUDA
      ]
      ++ lib.optionals (pkgs.stdenv.hostPlatform.system == "x86_64-linux") [
        "kvm-intel" # Intel CPU virtualization (x86_64 only)
      ]
      ++ lib.optionals (pkgs.stdenv.hostPlatform.system == "aarch64-linux") [
        "kvm" # Generic KVM for ARM64
      ];

    # Extra module options for partial sharing
    extraModprobeConfig = ''
      # NVIDIA options for virtualization
      options nvidia NVreg_OpenRmEnableUnsupportedGpus=1
      options nvidia NVreg_EnableGpuFirmware=0
      options nvidia-drm modeset=1

      # KVM options
      ${lib.optionalString (
        pkgs.stdenv.hostPlatform.system == "x86_64-linux"
      ) "options kvm_intel nested=1"}
      options kvm ignore_msrs=1
    '';
  };

  # Hardware configuration for partial GPU sharing
  hardware = {
    # Enable OpenGL for guest (updated options)
    graphics = {
      enable = true;
      enable32Bit = lib.mkIf (pkgs.stdenv.hostPlatform.system == "x86_64-linux") true;
      extraPackages = with pkgs; [
        vaapiVdpau
        libvdpau-va-gl
      ];
    };

    # NVIDIA configuration for host usage and VM sharing
    nvidia = {
      modesetting.enable = true;
      powerManagement.enable = false;
      powerManagement.finegrained = false;
      open = false; # Use proprietary driver for better VM support
      nvidiaSettings = true;

      # Enable NVIDIA persistence daemon for VM sharing
      nvidiaPersistenced = true;

      # Package selection (latest stable for best VM support)
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };
  };

  # Install virtualization packages
  environment.systemPackages = with pkgs; [
    # Core virtualization tools
    qemu_kvm # Main QEMU/KVM binary
    qemu_full # Full QEMU with all features
    libvirt # Virtualization management daemon
    virt-manager # GUI for managing VMs
    virt-viewer # Viewer for VMs

    # QEMU utilities
    qemu # QEMU user tools
    qemu-utils # QEMU disk/image utilities
    
    # VirtIO filesystem daemon for folder sharing
    virtiofsd # VirtIO filesystem daemon for virtiofs

    # Spice (remote desktop) support
    spice-gtk # Spice GTK client
    spice-protocol # Spice protocol definitions
    spice-vdagent # Spice guest agent

    # Windows guest drivers
    win-virtio # VirtIO drivers for Windows
    win-spice # Spice guest tools for Windows

    # GPU passthrough and sharing tools
    looking-glass-client # Client for Looking Glass
    scream # Network audio for Windows VMs
    barrier # Share mouse/keyboard between host and guest

    # NVIDIA tools for monitoring and management
    nvidia-system-monitor-qt # GUI for NVIDIA monitoring
    nvtopPackages.nvidia # Terminal-based GPU monitoring

    # Container tools for GPU sharing
    nvidia-docker # NVIDIA container runtime

    # VFIO tools
    pciutils # For lspci to identify devices
    usbutils # For lsusb
    
    # Network tools for VM networking
    bridge-utils # Bridge utilities for VM networking
    dnsmasq # DHCP and DNS for VM networks
  ];

  # Systemd services for GPU sharing and virtualization
  systemd.services = {
    # NVIDIA persistence daemon (helps with VM GPU access)
    nvidia-persistenced = {
      description = "NVIDIA Persistence Daemon";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "forking";
        Restart = "always";
        PIDFile = "/var/run/nvidia-persistenced/nvidia-persistenced.pid";
        ExecStart = "${pkgs.linuxPackages.nvidia_x11.persistenced}/bin/nvidia-persistenced --verbose";
        ExecStopPost = "${pkgs.coreutils}/bin/rm -rf /var/run/nvidia-persistenced";
        User = "nvidia-persistenced";
        Group = "nvidia-persistenced";
      };
    };

    # Ensure libvirtd starts after network and GPU services
    libvirtd = {
      after = [
        "network.target"
        "systemd-udev-settle.service"
        "nvidia-persistenced.service"
      ];
      wants = [ 
        "systemd-udev-settle.service" 
        "libvirt-guests.service"
      ];
      
      # Ensure default network is available
      postStart = ''
        # Wait for libvirtd to be ready
        sleep 2
        
        # Create default network if it doesn't exist
        if ! ${pkgs.libvirt}/bin/virsh net-list --all | grep -q "default"; then
          ${pkgs.libvirt}/bin/virsh net-define ${pkgs.writeText "default-network.xml" ''
            <network>
              <name>default</name>
              <uuid>9a05da11-e96b-47f3-8253-a3a482e445f5</uuid>
              <forward mode='nat'/>
              <bridge name='virbr0' stp='on' delay='0'/>
              <mac address='52:54:00:0a:cd:21'/>
              <ip address='192.168.122.1' netmask='255.255.255.0'>
                <dhcp>
                  <range start='192.168.122.2' end='192.168.122.254'/>
                </dhcp>
              </ip>
            </network>
          ''}
        fi
        
        # Start default network
        ${pkgs.libvirt}/bin/virsh net-autostart default || true
        ${pkgs.libvirt}/bin/virsh net-start default || true
      '';
    };
    
    # Service to create shared directories for VMs
    vm-setup = {
      description = "Setup VM shared directories and permissions";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        # Create shared memory directory for virtiofs
        mkdir -p /dev/shm
        chmod 1777 /dev/shm
        
        # Create VM images directory
        mkdir -p /var/lib/libvirt/images
        chown qemu-libvirtd:libvirtd /var/lib/libvirt/images
        chmod 755 /var/lib/libvirt/images
        
        # Create projects directory if it doesn't exist
        if [ ! -d /home/hrpr/projects ]; then
          mkdir -p /home/hrpr/projects
          chown hrpr:users /home/hrpr/projects
          chmod 755 /home/hrpr/projects
        fi
      '';
    };
  };

  # User and group configuration for virtualization
  users = {
    users.hrpr = {
      extraGroups = [
        "libvirtd"     # LibVirt daemon access
        "kvm"          # KVM device access
        "input"        # Input devices passthrough
        "disk"         # Disk management
        "docker"       # Container GPU access
        "qemu-libvirtd" # QEMU processes
      ];
    };
    
    # Ensure required system users exist
    users.qemu-libvirtd = {
      isSystemUser = true;
      group = "libvirtd";
      home = "/var/lib/libvirt";
      createHome = false;
      shell = pkgs.bash;
    };
    
    # System groups
    groups = {
      libvirtd = {};
      qemu-libvirtd = {};
    };
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

  # Environment variables for GPU sharing
  environment.variables = {
    # NVIDIA variables for VM support
    NVIDIA_VISIBLE_DEVICES = "all";
    NVIDIA_DRIVER_CAPABILITIES = "all";

    # VFIO runtime directory
    VFIO_USER_BIND_DIR = "/dev/vfio";

    # Looking Glass shared memory
    LOOKING_GLASS_SHARED_MEM = "/dev/shm/looking-glass";

    # LibVirt default URI
    LIBVIRT_DEFAULT_URI = "qemu:///system";
  };
}
