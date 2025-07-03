{ pkgs, lib, ... }:

{
  # Enable Nix and configure settings
  nix = {
    package = pkgs.nix;

    settings = {
      # Enable flakes and nix-command experimental features
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      # Connection and download settings
      connect-timeout = 5;
      stalled-download-timeout = 300;
      # Download settings to prevent buffer issues
      http-connections = 25; # Increase max HTTP connections
      # Allow more parallel downloads and builds
      max-jobs = "auto";
      # Use all available cores for building
      cores = 0;
    };

    # Use the new optimise setting instead of auto-optimise-store
    optimise.automatic = true;
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # ...existing code...
}
