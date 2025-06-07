{ config, pkgs, ... }:

{
  home.username = "nixos";
  home.homeDirectory = "/home/nixos";
  home.stateVersion = "24.05";
  
  # Packages for user
  home.packages = with pkgs; [
    # Browsers
    firefox
    chromium
    
    # Development
    vscode
    
    # Media
    vlc
    spotify
    
    # Office
    libreoffice
    
    # Graphics
    gimp
    inkscape
    
    # System tools
    htop
    neofetch
    
    # Wayland-specific tools
    wev                 # Event viewer
    wlr-randr          # Display configuration
  ];
  
  # Shell configuration
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;
    
    shellAliases = {
      ll = "ls -alF";
      la = "ls -A";
      l = "ls -CF";
      rebuild = "sudo nixos-rebuild switch --flake .";
      
      # Hyprland specific
      hl-reload = "hyprctl reload";
      hl-info = "hyprctl clients";
    };
  };
  
  # Git configuration
  programs.git = {
    enable = true;
    userName = "VM User";
    userEmail = "vm@example.com";
  };
  
  # Starship prompt
  programs.starship.enable = true;
  
  # Hyprland configuration
  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = true;
    
    # Copy our custom config
    extraConfig = builtins.readFile ./config/hyprland/hyprland.conf;
  };
  
  # Waybar configuration
  programs.waybar = {
    enable = true;
    settings = builtins.fromJSON (builtins.readFile ./config/waybar/config.json);
    style = builtins.readFile ./config/waybar/style.css;
  };
  
  # Rofi configuration
  programs.rofi = {
    enable = true;
    package = pkgs.rofi-wayland;
    theme = "Arc-Dark";
  };
  
  # Kitty terminal configuration
  programs.kitty = {
    enable = true;
    theme = "Tokyo Night";
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 12;
    };
    settings = {
      background_opacity = "0.9";
      window_padding_width = 8;
      confirm_os_window_close = 0;
    };
  };
  
  # Dunst notification configuration
  services.dunst = {
    enable = true;
    settings = {
      global = {
        width = 300;
        height = 300;
        offset = "30x50";
        origin = "top-right";
        transparency = 10;
        frame_color = "#eceff1";
        font = "JetBrainsMono Nerd Font 10";
      };
      
      urgency_normal = {
        background = "#37474f";
        foreground = "#eceff1";
        timeout = 10;
      };
    };
  };
  
  # GTK theming
  gtk = {
    enable = true;
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome.gnome-themes-extra;
    };
    iconTheme = {
      name = "Adwaita";
      package = pkgs.gnome.adwaita-icon-theme;
    };
  };
  
  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;
}