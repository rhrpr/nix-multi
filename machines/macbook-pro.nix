# macOS host configuration (VM creation and management)
{ config, pkgs, lib, username, hostname, ... }:

{
  imports = [
    ../modules/darwin/nix-core.nix
    ../modules/darwin/system.nix
    ../modules/darwin/host-users.nix
    ../modules/darwin/apps.nix
    ../modules/darwin/secrets.nix
    ../modules/hosts/macos/vm-management.nix
    ../modules/hosts/macos/linux-builder.nix  # Enable Linux builder for VM builds
    ../modules/shared/vm-tools.nix
  ];

  # Host-specific configuration
  networking.hostName = hostname;
  
  # macOS-specific optimizations for VM hosting
  # system.stateVersion defined in system.nix
}