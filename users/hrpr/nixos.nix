# NixOS user configuration
{
  config,
  pkgs,
  lib,
  username,
  useremail,
  isVM,
  ...
}:

{
  # User account
  users.users.${username} = {
    isNormalUser = true;
    description = username;
    extraGroups =
      [
        "wheel"
        "networkmanager"
        "audio"
        "video"
      ]
      ++ lib.optionals (!isVM) [
        "libvirtd" # VM management (host only)
        "docker" # Docker (host only)
      ];
    shell = lib.mkForce pkgs.zsh; # Force zsh over system default (bash)
  };

  # Sudo configuration
  security.sudo.wheelNeedsPassword = false;

  # NixOS-specific user environment
  programs.zsh.enable = true;

  # Enable common services
  services.openssh.enable = true;
  networking.networkmanager.enable = true;

  # Audio (sound.enable is deprecated)
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
}
