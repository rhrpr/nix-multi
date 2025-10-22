{ pkgs, lib, ... }:

{

  # Enable Nix
  nix.enable = false;

  # Enable flakes globally
  nix.settings.experimental-features = [ "flakes" ];
  nix.settings.extra-experimental-features = [ "nix-command" ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Configure Nix daemon - NixOS manages this automatically
  # systemd.services.nix-daemon.enable = true; # Not needed in NixOS

  nix.package = pkgs.nix;

  # Garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  # Optimize store
  nix.settings.auto-optimise-store = true;

}
