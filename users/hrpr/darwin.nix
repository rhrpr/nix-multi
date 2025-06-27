# macOS user configuration
{ config, pkgs, lib, username, ... }:

{
  # User account
  users.users.${username} = {
    name = username;
    home = "/Users/${username}";
    isHidden = false;
    shell = pkgs.zsh;
  };

  # Enable sudo without password for admin users (macOS uses different syntax)
  security.sudo.extraConfig = ''
    %admin ALL=(ALL) NOPASSWD: ALL
  '';

  # macOS-specific user environment
  programs.zsh.enable = true;
  
  # Homebrew integration (optional)
  homebrew = {
    enable = true;
    onActivation.cleanup = "zap";
    onActivation.autoUpdate = true;
    onActivation.upgrade = true;
  };
}