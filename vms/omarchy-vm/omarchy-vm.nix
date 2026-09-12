# Omarchy VM Configuration
# Gaming-focused Linux distribution optimized for performance

{
  pkgs,
  lib,
  config,
  ...
}:

{
  # Omarchy VM libvirt domain configuration
  virtualisation.libvirtd = {
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
        # Omarchy VM optimizations
        cgroup_device_acl = [
          "/dev/null", "/dev/full", "/dev/zero",
          "/dev/random", "/dev/urandom",
          "/dev/ptmx", "/dev/kvm", "/dev/kqemu",
          "/dev/rtc", "/dev/hpet", "/dev/vfio/vfio"
        ]

        # Audio and gaming device access
        user = "hrpr"
        group = "libvirt"
      '';
    };
  };

  # Ensure user is in libvirt group
  users.users.hrpr.extraGroups = [ "libvirt" ];

  # Gaming and virtualization packages
  environment.systemPackages = with pkgs; [
    virt-manager
    virt-viewer
    spice-gtk
    spice-protocol
    tigervnc

    # Gaming tools that might be useful with Omarchy
    gamemode
    mangohud
    steam-run
  ];

  # Enable necessary services
  services = {
    spice-vdagentd.enable = true;
  };

  # Kernel modules for gaming/virtualization
  boot.kernelModules = [
    "kvm-intel"
    "kvm-amd"
    "vfio-pci"
  ];
}
