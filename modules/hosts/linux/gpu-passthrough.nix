# RTX 3080 Partial GPU Passthrough Module
# Enables sharing RTX 3080 between host and VMs simultaneously
{ pkgs, lib, config, username, gpuConfig, ... }:

let
  # Extract GPU configuration
  isNvidia = gpuConfig.vendor == "nvidia";
  enablePassthrough = gpuConfig.enablePartialPassthrough;
  gpuDeviceId = gpuConfig.deviceId;
  audioDeviceId = gpuConfig.audioId;
  pciAddress = gpuConfig.pciAddress;
in
{
  # Only enable if GPU passthrough is requested
  config = lib.mkIf (isNvidia && enablePassthrough) {
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
      
      # Enable Docker for container-based GPU sharing
      docker = {
        enable = true;
      };
    };
    
    # NVIDIA container toolkit for Docker GPU access
    hardware.nvidia-container-toolkit.enable = true;

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
        
        # VFIO options for partial passthrough
        options vfio enable_unsafe_noiommu_mode=1
        options vfio_iommu_type1 allow_unsafe_interrupts=1
        
        # KVM options
        options kvm_intel nested=1
        options kvm ignore_msrs=1
      '';
    };

    # Hardware configuration for partial GPU sharing
    hardware = {
      # Enable graphics for host (replaces deprecated opengl)
      graphics = {
        enable = true;
        enable32Bit = lib.mkIf (pkgs.stdenv.hostPlatform.system == "x86_64-linux") true;  # Replaces driSupport32Bit
        extraPackages = with pkgs; [
          intel-media-driver # For Intel integrated graphics (if available)
          vaapiIntel         # Hardware acceleration
          vaapiVdpau
          libvdpau-va-gl
        ];
      };

      # NVIDIA configuration for sharing
      nvidia = {
        modesetting.enable = true;
        powerManagement.enable = true;
        powerManagement.finegrained = false;
        open = false;  # Use proprietary driver for better VM support
        nvidiaSettings = true;
        package = config.boot.kernelPackages.nvidiaPackages.stable;
      };
    };

    # Environment and packages for GPU passthrough
    environment = {
      systemPackages = with pkgs; [
        # Virtualization tools
        virt-manager
        virt-viewer
        spice-gtk
        spice-protocol
        win-virtio
        win-spice
        
        # GPU monitoring and management
        nvidia-system-monitor-qt
        
        # VFIO tools
        pciutils
        libvirt
        qemu_kvm
        
        # Looking Glass for low-latency desktop sharing
        looking-glass-client
      ];
      
      # Ensure NVIDIA container runtime is available
      variables = {
        NVIDIA_VISIBLE_DEVICES = "all";
        NVIDIA_DRIVER_CAPABILITIES = "all";
      };
    };

    # Services configuration
    services = {
      # Enable X11 with NVIDIA
      xserver = {
        enable = true;
        videoDrivers = [ "nvidia" ];
      };
      
      # NVIDIA persistence is handled by hardware.nvidia.nvidiaPersistenced
      # nvidia-persistenced.enable = true;  # This option doesn't exist in newer NixOS
      
      # Enable udev rules for VFIO
      udev.extraRules = ''
        # NVIDIA GPU devices for partial passthrough
        SUBSYSTEM=="vfio", GROUP="kvm"
        KERNEL=="nvidia*", GROUP="video", MODE="0664"
        KERNEL=="nvidia_uvm", GROUP="video", MODE="0664"
        
        # Allow libvirt access to devices
        KERNEL=="vfio-*", GROUP="libvirt", MODE="0660"
      '';
    };

    # User and group configuration
    users = {
      users.${username} = {
        extraGroups = [ 
          "libvirt" 
          "kvm" 
          "input" 
          "disk" 
          "video"
          "docker"  # For NVIDIA container runtime
        ];
      };
      
      groups = {
        libvirt = {};
        kvm = {};
      };
    };

    # Security configuration
    security = {
      # Allow QEMU to access devices
      wrappers = {
        qemu-system-x86_64 = {
          source = "${pkgs.qemu_kvm}/bin/qemu-system-x86_64";
          capabilities = "cap_net_admin,cap_sys_rawio+p";
          owner = "root";
          group = "kvm";
          permissions = "u+rx,g+rx";
        };
      };
    };

    # Users and groups needed for GPU passthrough
    users = {
      users.nvidia-persistenced = {
        isSystemUser = true;
        group = "nvidia-persistenced";
      };
      groups.nvidia-persistenced = {};
    };

    # Systemd configuration
    systemd = {
      # Tmpfiles for GPU passthrough
      tmpfiles.rules = [
        "d /var/lib/libvirt/images 0755 root root -"
        "d /var/run/nvidia-persistenced 0755 nvidia-persistenced nvidia-persistenced -"
        "f /dev/shm/looking-glass 0660 ${username} kvm -"
      ];

      # Systemd services configuration
      services = {
        # Ensure libvirtd starts after network and GPU services
        libvirtd = {
          after = [ "network.target" "systemd-udev-settle.service" ];
          wants = [ "systemd-udev-settle.service" ];
        };
      };
    };
  };
}
