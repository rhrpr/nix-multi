# NixOS user configuration
{ config, pkgs, lib, username, useremail, isVM, ... }:

{
  # User account
  users.users.${username} = {
    isNormalUser = true;
    description = username;
    extraGroups = [ 
      "wheel" 
      "networkmanager" 
      "audio" 
      "video"
    ] ++ lib.optionals (!isVM) [
      "libvirtd"  # VM management (host only)
      "docker"    # Docker (host only)
    ];
    shell = lib.mkDefault pkgs.zsh;  # Use mkDefault so system.nix can override
    # Use hashed password for host, simple password for VM (set in vm/system.nix)
    hashedPassword = lib.mkIf (!isVM) "$6$rounds=500000$jgiCMRyGXYUX4ZNu$Hr89rwb2ud4ajuw3qZ4yd/wjlkF/qvE3e5XN/Q.X.Q9K.XxD.6xS.6Oz./U0G9/pUh9/OmhUCy5J4WQ9WpXtJ0";
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