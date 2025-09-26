{
  pkgs,
  lib,
  config,
  ...
}:

{
  # Import comprehensive LibVirt host configuration
  imports = [
    ./libvirt-host.nix
  ];

  # This module now focuses on importing the comprehensive libvirt host configuration.
  # All libvirt, QEMU, GPU passthrough, and VM networking configuration is managed
  # declaratively through Nix in the libvirt-host.nix module.
  #
  # This ensures that:
  # - LibVirt daemon is properly configured with GPU passthrough support
  # - VirtioFS is available for folder sharing
  # - Default network is automatically created and started
  # - All required packages and services are installed
  # - Users are in the correct groups for VM management
  # - Security policies allow password-less VM management
}
