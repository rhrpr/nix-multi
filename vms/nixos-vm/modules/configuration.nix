{ config, pkgs, ... }:

{
  imports = [
    ../vm-hardware.nix
    ./system.nix
    ./development.nix
    ./hyperland.nix # Add Hyprland module
  ];

  # System settings
  system.stateVersion = "24.05";

  # Boot configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Networking
  networking.hostName = "nixos-vm";
  networking.networkmanager.enable = true;

  # Users
  users.users.nixos = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "docker"
      "video"
      "audio"
    ];
    shell = pkgs.zsh;
  };

  # Enable sudo for wheel group
  security.sudo.wheelNeedsPassword = false;

  # Basic services
  services.openssh.enable = true;

  # Enable flakes
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nixpkgs.config.allowUnfree = true;

  # Additional environment packages
  environment.systemPackages = with pkgs; [
    vim
    git
    wget
    curl
  ];
}
