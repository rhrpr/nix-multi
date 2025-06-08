{ pkgs, lib, ... }:

{
  # Enable virtualization
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
      };
    };
    spiceUSBRedirection.enable = true;
  };

  # Install virtualization packages
  environment.systemPackages = with pkgs; [
    # Core virtualization tools
    qemu_kvm         # Main QEMU/KVM binary
    libvirt          # Virtualization management daemon
    virt-manager     # GUI for managing VMs
    virt-viewer      # Viewer for VMs

    # QEMU utilities
    qemu             # QEMU user tools
    qemu-utils       # QEMU disk/image utilities

    # Spice (remote desktop) support
    # spice            # Spice server
    spice-gtk        # Spice GTK client
    spice-protocol   # Spice protocol definitions
    spice-vdagent    # Spice guest agent

    # Windows guest drivers
    win-virtio       # VirtIO drivers for Windows
    win-spice        # Spice guest tools for Windows

    # GPU passthrough
    looking-glass-client # Client for Looking Glass (GPU passthrough)
  ];

  # Add users to libvirtd group
  users.users.hrpr = {
    extraGroups = [ "libvirtd" ];
  };
}