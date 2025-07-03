# Hardware configuration for UTM VM
{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  # Boot configuration optimized for VM
  boot = {
    initrd = {
      availableKernelModules = [
        "virtio_pci"
        "virtio_scsi"
        "ahci"
        "usbhid"
      ];
      kernelModules = [ ];
    };
    kernelModules = [ ];
    extraModulePackages = [ ];

    # Use systemd-boot for UEFI
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  # File systems
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/replace-with-actual-uuid";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/replace-with-actual-boot-uuid";
    fsType = "vfat";
  };

  # VM optimizations
  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;

  # Enable hardware acceleration where possible
  hardware.graphics.enable = true;

  # Networking
  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
