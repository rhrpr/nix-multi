{ pkgs, lib, ... }:

let
  isLinux = pkgs.stdenv.isLinux;
  isDarwin = pkgs.stdenv.isDarwin;
in
{
  # Cross-platform VM creation and management tools
  environment.systemPackages = with pkgs; [
    # Core QEMU for all platforms
    qemu              # QEMU emulator and virtualizer
    qemu-utils        # QEMU disk image utilities
    
    # Cross-platform utilities
    socat             # Socket relay for VM networking
    netcat            # Network utility for testing VM connectivity
  ] ++ lib.optionals isLinux [
    # Linux-specific VM tools
    qemu_kvm          # KVM-accelerated QEMU
    qemu_full         # Full QEMU with all features
    libvirt           # Virtualization management daemon
    libguestfs        # Tools for accessing VM disk images
    virt-manager      # GUI for managing VMs
    virt-viewer       # Viewer for VMs
    spice-gtk         # Spice GTK client
    spice-protocol    # Spice protocol definitions
    spice-vdagent     # Spice guest agent
    looking-glass-client # For GPU passthrough with shared display
  ] ++ lib.optionals isDarwin [
    # macOS-specific VM tools
    lima              # Lima for Linux VMs on macOS
    colima            # Container runtime for macOS
    # Note: UTM should be installed separately from the App Store or website
  ];

  # Platform-specific environment variables
  environment.variables = lib.mkMerge [
    # Common variables for all platforms
    {
      VM_SCRIPTS_DIR = "/Users/hrpr/.config/nix-multi/scripts";
      QEMU_SYSTEM_X86_64 = "${pkgs.qemu}/bin/qemu-system-x86_64";
      QEMU_SYSTEM_AARCH64 = "${pkgs.qemu}/bin/qemu-system-aarch64";
      QEMU_IMG = "${pkgs.qemu}/bin/qemu-img";
    }
    
    # Linux-specific variables
    (lib.mkIf isLinux {
      LIBVIRT_DEFAULT_URI = "qemu:///system";
      QEMU_AUDIO_DRV = "pipewire";
      VM_ACCEL = "kvm";
    })
    
    # macOS-specific variables  
    (lib.mkIf isDarwin {
      QEMU_AUDIO_DRV = "coreaudio";
      VM_ACCEL = "hvf";
      VM_NETWORK_MODE = "user";
    })
  ];

  # Enable virtualization services on Linux only
  virtualisation = lib.mkIf isLinux {
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
      };
    };
    
    # Enable SPICE USB redirection
    spiceUSBRedirection.enable = true;
  };

  # Add user to virtualization groups on Linux
  users.groups = lib.mkIf isLinux {
    libvirtd = {};
  };

  # System configuration for better VM performance (Linux only)
  boot = lib.mkIf isLinux {
    kernelModules = [ "kvm-intel" "kvm-amd" "vfio-pci" ];
    kernelParams = [
      "intel_iommu=on"
      "amd_iommu=on"
    ];
  };
  
  # Shell aliases for VM management (cross-platform)
  environment.shellAliases = {
    # QEMU utilities (work on both platforms)
    qemu-img-create = "qemu-img create -f qcow2";
    qemu-img-info = "qemu-img info";
    qemu-img-convert = "qemu-img convert";
    qemu-config = "~/.config/nix-multi/scripts/qemu-config.sh";
    
    # VM management shortcuts
    vm-config-test = "~/.config/nix-multi/scripts/qemu-config.sh test";
    vm-config-show = "~/.config/nix-multi/scripts/qemu-config.sh config";
  } // lib.optionalAttrs isLinux {
    # Linux-specific aliases
    vm-manager = "virt-manager";
    vm-viewer = "virt-viewer";
  } // lib.optionalAttrs isDarwin {
    # macOS-specific aliases  
    vm-list = "ls -la ~/VMs/";
  };
}
    kernelModules = [ "kvm-intel" "kvm-amd" "vfio-pci" ];
    kernelParams = [
      "intel_iommu=on"
      "amd_iommu=on"
    ];
  };
}
