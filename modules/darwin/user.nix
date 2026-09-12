{
  pkgs,
  lib,
  username,
  userSettings ? { },
  ...
}:

{
  users.users.${username} = {
    name = username;
    home = "/Users/${username}";
    isHidden = false;
    shell = pkgs.zsh;
  };

  security.sudo.extraConfig = lib.mkIf (userSettings.passwordlessSudo or false) ''
    %admin ALL=(ALL) NOPASSWD: ALL
  '';

  programs.zsh.enable = true;

  homebrew = {
    enable = true;
    onActivation.cleanup = "zap";
    onActivation.autoUpdate = true;
    onActivation.upgrade = true;
  };
}
