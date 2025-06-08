{ pkgs, lib, ... }:

{

  # Enable Nix
  nix.enable = true;

  # Enable flakes globally
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Configure Nix daemon
  services.nix-daemon.enable = true;

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
