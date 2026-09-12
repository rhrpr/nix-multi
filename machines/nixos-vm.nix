# NixOS VM guest configuration (Hyprland desktop)
{
  config,
  pkgs,
  lib,
  username,
  hostname,
  isVM,
  ...
}:

{
  imports = [
    ../modules/nixos/nix-core.nix
    ../modules/vm/system.nix
    ../modules/nixos/host-users.nix
    ../modules/vm/apps.nix
    ../modules/nixos/desktop.nix
    ../modules/vm/vm-guest.nix
    ../modules/vm/gpu-guest.nix
  ];

  # VM-specific configuration
  networking.hostName = hostname;

  # Desktop environment configured in desktop.nix module

  # VM optimizations
  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;

  # NixOS version (use default from system.nix)
}
