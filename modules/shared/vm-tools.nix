{ pkgs, lib, ... }:

let
  isLinux = pkgs.stdenv.isLinux;
  isDarwin = pkgs.stdenv.isDarwin;
in
{
  # VM creation and management tools
  environment.systemPackages = with pkgs; [
    # QEMU for virtualization
    qemu
  ] ++ lib.optionals isLinux [
    # Linux-specific VM tools
    virt-manager
    virt-viewer
    libvirt
    libguestfs
    spice-gtk
    # VM image manipulation
    qemu-utils
  ] ++ lib.optionals isDarwin [
    # macOS-specific VM tools (UTM dependencies already covered by qemu)
    # Note: UTM should be installed separately from the App Store or website
  ];

  # Enable virtualization services on Linux
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

  # System configuration for better VM performance
  boot = lib.mkIf isLinux {
    kernelModules = [ "kvm-intel" "kvm-amd" "vfio-pci" ];
    kernelParams = [
      "intel_iommu=on"
      "amd_iommu=on"
    ];
  };
}
