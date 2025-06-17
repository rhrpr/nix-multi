
{ pkgs, lib, ... }:

{
  nix.enable = false;
  download-buffer-size = 67108864; # 64 MB (default is 64 KB)

  # enable flakes globally
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Use this instead of services.nix-daemon.enable if you
  # don't wan't the daemon service to be managed for you.
  # nix.useDaemon = true;

  nix.package = pkgs.nix;

}
