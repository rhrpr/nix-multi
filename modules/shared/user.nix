{
  pkgs,
  lib,
  username,
  isVM,
  userSettings ? { },
  ...
}:

{
  users.users.${username} = {
    isNormalUser = true;
    description = username;
    extraGroups = [
      "wheel"
      "networkmanager"
      "audio"
      "video"
    ]
    ++ lib.optionals (!isVM) [
      "libvirtd"
      "docker"
    ];
    shell = lib.mkForce pkgs.zsh;
  };

  security.sudo.wheelNeedsPassword = !(userSettings.passwordlessSudo or false);

  programs.zsh.enable = true;
  services.openssh.enable = true;
  networking.networkmanager.enable = true;

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
}
