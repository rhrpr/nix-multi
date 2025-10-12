{
  pkgs,
  lib,
  config,
  ...
}:

{
  # Enable virtualization with comprehensive libvirt host configuration
  virtualisation = {
    libvirtd = {
      enable = true;
      # Allow unprivileged user access for virt-manager
      allowUnprivileged = true;
      
      # Enable user sessions for proper desktop integration
      onBoot = "ignore";  # Don't auto-start system VMs
      onShutdown = "shutdown";
      
      qemu = {
        package = pkgs.qemu_kvm;
        runAsRoot = false;  # Changed to false for user session support
        swtpm.enable = true;
        
        # OVMF UEFI firmware for modern VMs
        ovmf = {
          enable = true;
          packages = [ pkgs.OVMFFull.fd ];
        };
        
        # QEMU configuration for user session support
        verbatimConfig = ''
          # Device access control list for user sessions
          cgroup_device_acl = [
            "/dev/null", "/dev/full", "/dev/zero",
            "/dev/random", "/dev/urandom",
            "/dev/ptmx", "/dev/kvm", "/dev/kqemu",
            "/dev/rtc","/dev/hpet", "/dev/vfio/vfio",
            "/dev/nvidia0", "/dev/nvidiactl", "/dev/nvidia-modeset",
            "/dev/nvidia-uvm", "/dev/nvidia-uvm-tools"
          ]
          
          # Allow unprivileged users to manage VMs
          unix_sock_group = "libvirtd"
          unix_sock_ro_perms = "0777"  
          unix_sock_rw_perms = "0770"
          
          # VirtIO filesystem configuration for folder sharing
          memory_backing_dir = "/dev/shm"
        '';
      };
    };
    
    # Enable Spice USB redirection for better VM interaction
    spiceUSBRedirection.enable = true;

    # Enable Docker with NVIDIA support (optional, for containers)
    docker = {
      enable = true;
      enableNvidia = true;
    };
  };

  # Boot configuration for virtualization and GPU passthrough
  boot = {
    # Kernel parameters for IOMMU and GPU sharing
    kernelParams = [
      # IOMMU configuration
      "iommu=pt"
      "intel_iommu=on"
      
      # NVIDIA configuration for host + VM sharing
      "nvidia-drm.modeset=1"
      "nvidia.NVreg_EnableGpuFirmware=0"
      "nvidia.NVreg_OpenRmEnableUnsupportedGpus=1"
      
      # PCI and virtualization optimizations
      "pci=realloc"
      "pcie_aspm=off"
      
      # KVM optimizations
      "kvm.ignore_msrs=1"
      "kvm.report_ignored_msrs=0"
      
      # Hugepages for better VM performance (4GB)
      "default_hugepagesz=1G"
      "hugepagesz=1G"
      "hugepages=4"
    ];

    # Load required kernel modules
    initrd.kernelModules = [
      "vfio"
      "vfio_iommu_type1"
      "vfio_pci"
    ];

    kernelModules = [
      "kvm-intel"      # Intel CPU virtualization
      "vhost-net"      # Network virtualization
      "nvidia"         # NVIDIA driver for host
      "nvidia_drm"     # NVIDIA DRM for display
      "nvidia_modeset" # NVIDIA mode setting
      "nvidia_uvm"     # NVIDIA Unified Memory
    ];

    # Extra module configuration
    extraModprobeConfig = ''
      # NVIDIA options for host + VM sharing
      options nvidia NVreg_OpenRmEnableUnsupportedGpus=1
      options nvidia NVreg_EnableGpuFirmware=0
      options nvidia-drm modeset=1
      
      # KVM virtualization options
      options kvm_intel nested=1
      options kvm ignore_msrs=1
    '';
  };

  # Hardware configuration for GPU sharing
  hardware = {
    # Enable OpenGL for both host and VMs
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        vaapiVdpau
        libvdpau-va-gl
      ];
    };

    # NVIDIA configuration for shared usage
    nvidia = {
      modesetting.enable = true;
      powerManagement.enable = false;
      powerManagement.finegrained = false;
      open = false; # Use proprietary driver for better VM support
      nvidiaSettings = true;
      nvidiaPersistenced = true; # Enable persistence daemon
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };
  };

  # Install comprehensive virtualization packages
  environment.systemPackages = with pkgs; [
    # Core virtualization tools
    qemu_kvm                    # Main QEMU/KVM binary
    qemu_full                   # Full QEMU with all features
    libvirt                     # Virtualization management daemon
    virt-manager                # GUI for managing VMs
    virt-viewer                 # VM console viewer
    
    # VirtIO and filesystem support
    virtiofsd                   # VirtIO filesystem daemon
    qemu                        # QEMU user tools
    qemu-utils                  # QEMU disk/image utilities
    
    # Spice support for remote desktop
    spice-gtk                   # Spice GTK client
    spice-protocol              # Spice protocol definitions
    spice-vdagent              # Spice guest agent
    
    # Windows VM support
    win-virtio                  # VirtIO drivers for Windows VMs
    win-spice                   # Spice guest tools for Windows
    
    # GPU passthrough tools
    looking-glass-client        # Looking Glass for shared GPU
    scream                      # Network audio for Windows VMs
    barrier                     # Share input devices between systems
    
    # NVIDIA monitoring and management
    nvidia-system-monitor-qt    # GUI NVIDIA monitor
    nvtopPackages.nvidia       # Terminal GPU monitor
    
    # Network and system tools
    bridge-utils               # Bridge utilities for VM networking
    dnsmasq                    # DHCP/DNS for VM networks
    pciutils                   # PCI device identification
    usbutils                   # USB device management
    
    # Container support with GPU
    nvidia-docker              # NVIDIA container runtime
  ];

  # User and group configuration
  users = {
    users = {
      hrpr = {
        extraGroups = [
          "libvirtd"      # LibVirt daemon access
          "kvm"           # KVM device access  
          "qemu-libvirtd" # QEMU process group
          "input"         # Input device passthrough
          "disk"          # Disk management
          "docker"        # Container access
        ];
      };
      
      # System user for QEMU processes
      qemu-libvirtd = {
        isSystemUser = true;
        group = "libvirtd";
        home = "/var/lib/libvirt";
        createHome = false;
      };
    };
    
    groups = {
      libvirtd = {};
      qemu-libvirtd = {};
    };
  };

  # Network configuration for VM networking
  networking = {
    firewall = {
      # Trust libvirt bridge interfaces
      trustedInterfaces = [ "virbr0" "virbr1" ];
      
      # Allow VM network services
      allowedTCPPorts = [
        # VNC ports (uncomment if needed)
        # 5900 5901 5902
      ];
      
      allowedUDPPorts = [
        67   # DHCP server for VMs
        68   # DHCP client
        53   # DNS for VMs
      ];
    };
    
    # Enable NAT for VM networking
    nat = {
      enable = true;
      internalInterfaces = [ "virbr0" "virbr1" ];
    };
  };

  # Security configuration
  security = {
    polkit.extraConfig = ''
      // Allow libvirtd group members to manage VMs without password
      polkit.addRule(function(action, subject) {
        if (action.id == "org.libvirt.unix.manage" &&
            subject.isInGroup("libvirtd")) {
            return polkit.Result.YES;
        }
      });
    '';
  };

  # Environment variables for GPU and VM support
  environment.variables = {
    # NVIDIA configuration for VM sharing
    NVIDIA_VISIBLE_DEVICES = "all";
    NVIDIA_DRIVER_CAPABILITIES = "all";
    
    # LibVirt configuration
    LIBVIRT_DEFAULT_URI = "qemu:///system";
    
    # VFIO configuration
    VFIO_USER_BIND_DIR = "/dev/vfio";
    
    # Looking Glass configuration
    LOOKING_GLASS_SHARED_MEM = "/dev/shm/looking-glass";
  };

  # Systemd services for comprehensive VM support
  systemd.services = {
    # NVIDIA persistence daemon for VM GPU sharing
    nvidia-persistenced = {
      description = "NVIDIA Persistence Daemon";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "forking";
        Restart = "always";
        PIDFile = "/var/run/nvidia-persistenced/nvidia-persistenced.pid";
        ExecStart = "${config.hardware.nvidia.package}/bin/nvidia-persistenced --verbose";
        ExecStopPost = "${pkgs.coreutils}/bin/rm -rf /var/run/nvidia-persistenced";
        User = "nvidia-persistenced";
        Group = "nvidia-persistenced";
      };
    };

    # Enhanced libvirtd service configuration
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
      
      # Automatically setup default network and directories
      postStart = let
        # Network detection script
        networkDetectionScript = pkgs.writeShellScript "detect-libvirt-network" ''
          # Get current host network ranges to avoid conflicts
          HOST_RANGES=$(${pkgs.iproute2}/bin/ip route show | ${pkgs.gnugrep}/bin/grep -oE '192\.168\.[0-9]+\.0/24' | ${pkgs.gnused}/bin/sed 's/\.0\/24$//')
          
          # Default libvirt network options in order of preference
          CANDIDATES=(
            "192.168.122"  # Standard libvirt default
            "192.168.100"  # Alternative 1
            "192.168.200"  # Alternative 2  
            "10.0.100"     # Private class A fallback
          )
          
          LIBVIRT_NET="192.168.122"  # Fallback default
          
          # Find first non-conflicting network
          for net in "''${CANDIDATES[@]}"; do
            if ! echo "$HOST_RANGES" | ${pkgs.gnugrep}/bin/grep -q "^$net$"; then
              LIBVIRT_NET="$net"
              break
            fi
          done
          
          echo "Detected host networks: $HOST_RANGES"
          echo "Selected libvirt network: $LIBVIRT_NET"
          echo "$LIBVIRT_NET"
        '';
        
        # Dynamic network XML generator  
        createNetworkXml = pkgs.writeShellScript "create-libvirt-network" ''
          LIBVIRT_NET=$(${networkDetectionScript})
          
          cat > /tmp/libvirt-network.xml << EOF
          <network>
            <name>default</name>
            <uuid>9a05da11-e96b-47f3-8253-a3a482e445f5</uuid>
            <forward mode='nat'/>
            <bridge name='virbr0' stp='on' delay='0'/>
            <mac address='52:54:00:0a:cd:21'/>
            <ip address='$LIBVIRT_NET.1' netmask='255.255.255.0'>
              <dhcp>
                <range start='$LIBVIRT_NET.2' end='$LIBVIRT_NET.254'/>
              </dhcp>
            </ip>
          </network>
          EOF
          
          ${pkgs.libvirt}/bin/virsh net-define /tmp/libvirt-network.xml
          rm -f /tmp/libvirt-network.xml
        '';
      in ''
        # Wait for libvirtd to initialize
        ${pkgs.coreutils}/bin/sleep 3
        
        # Create default network if it doesn't exist
        if ! ${pkgs.libvirt}/bin/virsh net-list --all | ${pkgs.gnugrep}/bin/grep -q "default"; then
          echo "Creating dynamic libvirt network configuration..."
          ${createNetworkXml}
        fi
        
        # Start and enable default network
        ${pkgs.libvirt}/bin/virsh net-autostart default 2>/dev/null || true
        ${pkgs.libvirt}/bin/virsh net-start default 2>/dev/null || true
      '';
    };

    # VM environment setup service
    libvirt-setup = {
      description = "Setup LibVirt VM environment";
      wantedBy = [ "multi-user.target" ];
      after = [ "libvirtd.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        # Create required directories with proper permissions
        ${pkgs.coreutils}/bin/mkdir -p /var/lib/libvirt/images
        ${pkgs.coreutils}/bin/chown qemu-libvirtd:libvirtd /var/lib/libvirt/images
        ${pkgs.coreutils}/bin/chmod 755 /var/lib/libvirt/images
        
        # Create shared memory directory for virtiofs
        ${pkgs.coreutils}/bin/mkdir -p /dev/shm
        ${pkgs.coreutils}/bin/chmod 1777 /dev/shm
        
        # Create projects directory for VM sharing
        if [ ! -d /home/hrpr/projects ]; then
          ${pkgs.coreutils}/bin/mkdir -p /home/hrpr/projects
          ${pkgs.coreutils}/bin/chown hrpr:users /home/hrpr/projects
          ${pkgs.coreutils}/bin/chmod 755 /home/hrpr/projects
        fi
        
        # Create Looking Glass shared memory (if using Looking Glass)
        ${pkgs.coreutils}/bin/mkdir -p /dev/shm
        ${pkgs.coreutils}/bin/touch /dev/shm/looking-glass || true
        ${pkgs.coreutils}/bin/chmod 660 /dev/shm/looking-glass || true
        ${pkgs.coreutils}/bin/chown hrpr:kvm /dev/shm/looking-glass || true
      '';
    };

    # Setup default user network for libvirt user sessions
    libvirt-user-network = {
      description = "Create LibVirt User Session Default Network";
      wantedBy = [ "default.target" ];
      after = [ "libvirtd.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = let
          networkXml = pkgs.writeText "user-default-network.xml" ''
            <network>
              <name>default</name>
              <uuid>41ff3e11-3f2b-4a2f-8253-a3a482e445f6</uuid>
              <forward mode='nat'/>
              <bridge name='virbr1' stp='on' delay='0'/>
              <mac address='52:54:00:1a:cd:22'/>
              <ip address='192.168.100.1' netmask='255.255.255.0'>
                <dhcp>
                  <range start='192.168.100.2' end='192.168.100.254'/>
                </dhcp>
              </ip>
            </network>
          '';
        in pkgs.writeShellScript "setup-user-network" ''
          export LIBVIRT_DEFAULT_URI="qemu:///session"
          
          # Wait for user libvirt session to be available
          timeout=30
          while [ $timeout -gt 0 ]; do
            if ${pkgs.libvirt}/bin/virsh version >/dev/null 2>&1; then
              break
            fi
            sleep 1
            timeout=$((timeout - 1))
          done
          
          # Create default network if it doesn't exist
          if ! ${pkgs.libvirt}/bin/virsh net-info default >/dev/null 2>&1; then
            ${pkgs.libvirt}/bin/virsh net-define ${networkXml}
            ${pkgs.libvirt}/bin/virsh net-autostart default
            ${pkgs.libvirt}/bin/virsh net-start default
          fi
        '';
      };
      environment = {
        LIBVIRT_DEFAULT_URI = "qemu:///session";
      };
    };
  };

  # User session configuration for libvirt  
  # NixOS provides built-in user session support
  # Just set the environment variable to use user sessions by default

  # Environment configuration for user sessions
  environment.sessionVariables = {
    LIBVIRT_DEFAULT_URI = "qemu:///session";
  };
  
  # Set shell aliases for common libvirt commands to use user session
  environment.shellAliases = {
    virt-viewer = "LIBVIRT_DEFAULT_URI=qemu:///session virt-viewer";
    virt-manager = "LIBVIRT_DEFAULT_URI=qemu:///session virt-manager";
  };
}
