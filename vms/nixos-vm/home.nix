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
    # spotify  # Not available on aarch64-linux

    # Office
    libreoffice

    # Graphics
    gimp
    inkscape

    # System tools
    htop
    neofetch

    # Wayland-specific tools
    wev # Event viewer
    wlr-randr # Display configuration
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
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 30;
        spacing = 4;
        modules-left = [
          "hyprland/workspaces"
          "hyprland/mode"
        ];
        modules-center = [ "hyprland/window" ];
        modules-right = [
          "network"
          "pulseaudio"
          "clock"
          "tray"
        ];

        "hyprland/workspaces" = {
          disable-scroll = true;
          all-outputs = true;
          format = "{icon}";
          format-icons = {
            "1" = "1";
            "2" = "2";
            "3" = "3";
            "4" = "4";
            "5" = "5";
            urgent = "";
            focused = "";
            default = "";
          };
        };

        "hyprland/window" = {
          format = "{}";
          max-length = 50;
        };

        network = {
          format-wifi = "{essid} ({signalStrength}%) ";
          format-ethernet = "{ifname}: {ipaddr}/{cidr} ";
          format-linked = "{ifname} (No IP) ";
          format-disconnected = "Disconnected ⚠";
          format-alt = "{ifname}: {ipaddr}/{cidr}";
        };

        pulseaudio = {
          format = "{volume}% {icon} {format_source}";
          format-bluetooth = "{volume}% {icon} {format_source}";
          format-bluetooth-muted = " {icon} {format_source}";
          format-muted = " {format_source}";
          format-source = "{volume}% ";
          format-source-muted = "";
          format-icons = {
            headphone = "";
            hands-free = "";
            headset = "";
            phone = "";
            portable = "";
            car = "";
            default = [
              ""
              ""
              ""
            ];
          };
          on-click = "pavucontrol";
        };

        clock = {
          format = "{:%Y-%m-%d %H:%M}";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
          format-alt = "{:%Y-%m-%d}";
        };

        tray = {
          spacing = 10;
        };
      };
    };
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
      package = pkgs.gnome-themes-extra;
    };
    iconTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };
  };

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;
}
