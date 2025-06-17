{ pkgs, lib, ... }:

{
  # Lightweight NixOS configuration optimized for ARM64 VMs on Apple Silicon
  # This configuration avoids packages that don't build well on aarch64-linux
  
  # Basic system configuration
  system.stateVersion = "24.05";
  
  # Minimal desktop environment - using Sway instead of Hyprland for better ARM64 support
  services.xserver.enable = true;
  services.displayManager.gdm.enable = true;
  
  # Use Sway (Wayland compositor) - more stable on ARM64 than Hyprland
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
  };
  
  # Essential packages that build well on ARM64
  environment.systemPackages = with pkgs; [
    # Terminal and shell
    kitty
    bash
    
    # Basic utilities
    git
    curl
    wget
    vim
    nano
    htop
    
    # Development tools
    nodejs
    python3
    
    # GUI applications (ARM64 compatible)
    firefox
    
    # System tools
    htop
    
    # Archive tools
    unzip
    zip
  ];
  
  # Enable basic networking (avoid NetworkManager for ARM64 compatibility)
  networking.dhcpcd.enable = true;
  
  # Enable sound
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = lib.mkIf (pkgs.stdenv.hostPlatform.system == "x86_64-linux") true;
    pulse.enable = true;
  };
  
  # User configuration
  users.users.nixos = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    packages = with pkgs; [
      # User-specific packages
    ];
  };
  
  # Enable sudo for wheel group
  security.sudo.wheelNeedsPassword = false;
  
  # SSH for remote management
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = true;
  };
  
  # Firewall configuration
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
  };
}
