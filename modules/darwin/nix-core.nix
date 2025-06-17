
{ pkgs, lib, ... }:

{
  nix.enable = false;

  # enable flakes globally and configure Nix settings
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    # Increase connection settings to help with download issues
    connect-timeout = 5;
    stalled-download-timeout = 300;
    # Download settings to prevent buffer issues
    http-connections = 25;  # Increase max HTTP connections
    netrc-file = "/dev/null";  # Disable netrc to avoid auth issues
    # Allow more parallel downloads and builds
    max-jobs = "auto";
    # Use all available cores for building
    cores = 0;
    # Increase substituter timeout
    substituter-connect-timeout = 10;
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Use this instead of services.nix-daemon.enable if you
  # don't wan't the daemon service to be managed for you.
  # nix.useDaemon = true;

  nix.package = pkgs.nix;

}
