# Linux host configuration with RTX 3080 partial GPU passthrough
{ config, pkgs, lib, username, hostname, gpuConfig, ... }:

{
  imports = [
    ../modules/nixos/hardware-configuration.nix
    ../modules/nixos/nix-core.nix
    ../modules/nixos/system.nix
    ../modules/nixos/host-users.nix
    ../modules/nixos/apps.nix
    ../modules/nixos/desktop.nix
    ../modules/hosts/linux/gpu-passthrough.nix
    ../modules/hosts/linux/vm-management.nix
    ../modules/shared/vm-tools.nix
  ];

  # Host-specific configuration
  networking.hostName = hostname;
  
  # Desktop environment configured in desktop.nix module
  
  # NixOS version (use default from system.nix)
}