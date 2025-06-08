# VM-specific hardware configuration for NixOS Hyprland VM
# This is optimized for QEMU/KVM virtualization
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  # VM-specific boot configuration
  boot = {
    initrd = {
      availableKernelModules = [ 
        "ata_piix" "uhci_hcd" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod"
        "virtio_blk" "virtio_balloon" "virtio_rng" "virtio_console"
      ];
      kernelModules = [ ];
    };
    
    kernelModules = [ "kvm-intel" "kvm-amd" ];
    extraModulePackages = [ ];
    
    # Use GRUB for better compatibility with VMs
    loader = {
      grub = {
        enable = true;
        device = "/dev/vda";  # Virtual disk
        useOSProber = false;
      };
      systemd-boot.enable = lib.mkForce false;
    };
  };

  # VM-optimized filesystem layout
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
    };
    
    "/boot" = {
      device = "/dev/disk/by-label/boot";
      fsType = "ext4";
    };
  };

  # Swap configuration for VM
  swapDevices = [
    { device = "/dev/disk/by-label/swap"; }
  ];

  # Network configuration for VM
  networking = {
    useDHCP = lib.mkDefault true;
    interfaces = {
      ens3.useDHCP = lib.mkDefault true;  # Common VM interface name
      enp0s3.useDHCP = lib.mkDefault true;  # Alternative VM interface name
    };
  };

  # VM-specific hardware platform
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  
  # Enable microcode updates for better VM performance
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
