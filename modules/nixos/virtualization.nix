{ pkgs, lib, config, ... }:

{
  # Enable virtualization with partial GPU passthrough support
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
          # Partial GPU passthrough configuration
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
    
    # Enable Docker for container-based GPU sharing (optional)
    docker = {
      enable = true;
      enableNvidia = true;  # NVIDIA container runtime
    };
  };

  # Boot configuration for partial GPU passthrough
  boot = {
    # Enable IOMMU but allow host GPU usage
    kernelParams = [
      # Intel IOMMU
      "intel_iommu=on"
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
      "hugepages=4"  # 4GB of hugepages
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
    kernelModules = [
      "kvm-intel"  # Intel CPU virtualization
      "vhost-net"  # Network virtualization
      "nvidia"     # NVIDIA driver for host
      "nvidia_drm" # NVIDIA DRM for display
      "nvidia_modeset"
      "nvidia_uvm" # Unified Memory for CUDA
    ];

    # Extra module options for partial sharing
    extraModprobeConfig = ''
      # NVIDIA options for virtualization
      options nvidia NVreg_OpenRmEnableUnsupportedGpus=1
      options nvidia NVreg_EnableGpuFirmware=0
      options nvidia-drm modeset=1
      
      # KVM options
      options kvm_intel nested=1
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
  };

  # Install virtualization packages
  environment.systemPackages = with pkgs; [
    # Core virtualization tools
    qemu_kvm         # Main QEMU/KVM binary
    qemu_full        # Full QEMU with all features
    libvirt          # Virtualization management daemon
    virt-manager     # GUI for managing VMs
    virt-viewer      # Viewer for VMs

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
    nvtopPackages.nvidia     # Terminal-based GPU monitoring
    
    # Container tools for GPU sharing
    nvidia-docker    # NVIDIA container runtime
    
    # VFIO tools
    pciutils         # For lspci to identify devices
    usbutils         # For lsusb
  ];

  # Systemd services for GPU sharing
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
  };

  # Add users to required groups
  users.users.hrpr = {
    extraGroups = [ 
      "libvirtd" 
      "kvm" 
      "input"     # For input devices passthrough
      "disk"      # For disk management
      "docker"    # For container GPU access
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

  # Systemd services configuration
  systemd.services = {
    # Ensure libvirtd starts after network and GPU services
    libvirtd = {
      after = [ "network.target" "systemd-udev-settle.service" "nvidia-persistenced.service" ];
      wants = [ "systemd-udev-settle.service" ];
    };
  };
}