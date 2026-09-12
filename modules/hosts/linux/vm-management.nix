# Linux VM Management Module
# Provides VM creation and management tools for Linux hosts
{
  pkgs,
  lib,
  config,
  username,
  gpuConfig,
  ...
}:

{
  # Boot configuration for better VM performance (Linux only)
  boot = {
    kernelModules =
      [ "vfio-pci" ]
      ++ lib.optionals (pkgs.stdenv.hostPlatform.system == "x86_64-linux") [
        "kvm-intel"
        "kvm-amd"
      ]
      ++ lib.optionals (pkgs.stdenv.hostPlatform.system == "aarch64-linux") [
        "kvm"
      ];
    kernelParams =
      lib.optionals (pkgs.stdenv.hostPlatform.system == "x86_64-linux") [
        "intel_iommu=on"
        "amd_iommu=on"
      ]
      ++ lib.optionals (pkgs.stdenv.hostPlatform.system == "aarch64-linux") [
        "iommu.passthrough=1"
      ];
  };

  # Enable virtualization services
  virtualisation = {
    libvirtd = {
      enable = lib.mkDefault true;
      qemu = {
        package = lib.mkDefault pkgs.qemu_kvm;
        runAsRoot = lib.mkDefault true;
        swtpm.enable = lib.mkDefault true;
        # Current NixOS exposes every QEMU OVMF image automatically.
      };
    };

    # Enable SPICE USB redirection
    spiceUSBRedirection.enable = lib.mkDefault true;
  };

  # VM creation and management tools for Linux
  environment.systemPackages = with pkgs; [
    # Core virtualization tools
    qemu_kvm # KVM acceleration
    qemu_full # Full QEMU with all features
    libvirt # Virtualization management daemon
    virt-manager # GUI for managing VMs
    virt-viewer # Viewer for VMs

    # QEMU utilities
    qemu # QEMU user tools
    qemu-utils # QEMU disk/image utilities

    # Spice (remote desktop) support
    spice-gtk # Spice GTK client
    spice-protocol # Spice protocol definitions
    spice-vdagent # Spice guest agent

    # Windows guest drivers
    virtio-win # VirtIO drivers for Windows
    win-spice # Spice guest tools for Windows

    # GPU passthrough and sharing tools
    looking-glass-client # Client for Looking Glass
    scream # Network audio for Windows VMs
    input-leap # Share mouse/keyboard between host and guest

    # NVIDIA tools for monitoring and management
    nvidia-system-monitor-qt # GUI for NVIDIA monitoring
    nvtopPackages.nvidia # Terminal-based GPU monitoring

    # VFIO tools
    pciutils # For lspci to identify devices
    usbutils # For lsusb
  ];

  # Note: virtualization.libvirtd configuration is handled by gpu-passthrough.nix
  # to avoid conflicts and ensure proper GPU passthrough setup

  # Add users to required groups (complementary to gpu-passthrough.nix)
  users.users.${username} = {
    extraGroups = [
      "libvirtd"
      "kvm"
      "input" # For input devices passthrough
      "disk" # For disk management
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

}
