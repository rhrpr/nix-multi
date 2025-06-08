{ pkgs, lib, ... }:

{

  # Enable Nix
  nix.enable = true;

  # Enable flakes globally
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

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
