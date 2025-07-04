{
  config,
  pkgs,
  lib,
  ...
}:

{
  # End-4 dots-hyprland inspired configuration
  # Adapted from https://github.com/end-4/dots-hyprland
  
  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      # Monitor configuration for VM
      monitor = [
        ",3440x1440@60,0x0,1"
        ",preferred,auto,1"
      ];

      # Startup applications
      exec-once = [
        "dunst"
        "nm-applet --indicator"
        "hyprpaper"
        # End-4 style would use quickshell here, but we'll use waybar for now
        "waybar"
      ];

      # Input configuration
      input = {
        kb_layout = "us";
        kb_variant = "";
        kb_model = "";
        kb_options = "";
        kb_rules = "";
        follow_mouse = 1;
        touchpad = {
          natural_scroll = "yes";
          disable_while_typing = true;
          drag_lock = true;
        };
        sensitivity = 0;
        accel_profile = "flat";
      };

      # General appearance (end-4 style)
      general = {
        gaps_in = 4;
        gaps_out = 8;
        border_size = 2;
        # Material You inspired colors
        "col.active_border" = "rgb(7c4dff) rgb(448aff) 45deg";
        "col.inactive_border" = "rgba(565f89aa)";
        resize_on_border = true;
        allow_tearing = false;
        layout = "dwindle";
      };

      # Decoration (Material Design 3 inspired)
      decoration = {
        rounding = 12;
        
        blur = {
          enabled = true;
          size = 8;
          passes = 3;
          new_optimizations = true;
          xray = true;
          ignore_opacity = true;
        };
        
        drop_shadow = true;
        shadow_range = 20;
        shadow_render_power = 3;
        "col.shadow" = "rgba(00000044)";
        
        # Dimming
        dim_inactive = false;
        dim_strength = 0.1;
        dim_special = 0.8;
      };

      # Animations (smooth and modern)
      animations = {
        enabled = true;
        
        bezier = [
          "wind, 0.05, 0.9, 0.1, 1.05"
          "winIn, 0.1, 1.1, 0.1, 1.1"
          "winOut, 0.3, -0.3, 0, 1"
          "liner, 1, 1, 1, 1"
        ];
        
        animation = [
          "windows, 1, 6, wind, slide"
          "windowsIn, 1, 6, winIn, slide"
          "windowsOut, 1, 5, winOut, slide"
          "windowsMove, 1, 5, wind, slide"
          "border, 1, 1, liner"
          "borderangle, 1, 30, liner, loop"
          "fade, 1, 10, default"
          "workspaces, 1, 5, wind"
        ];
      };

      # Layout configuration
      dwindle = {
        pseudotile = true;
        preserve_split = true;
        smart_split = true;
        smart_resizing = true;
      };

      master = {
        new_is_master = true;
        smart_resizing = true;
      };

      # Gestures
      gestures = {
        workspace_swipe = true;
        workspace_swipe_fingers = 3;
        workspace_swipe_distance = 300;
        workspace_swipe_invert = true;
        workspace_swipe_min_speed_to_force = 30;
        workspace_swipe_cancel_ratio = 0.5;
        workspace_swipe_create_new = true;
      };

      # Group configuration
      group = {
        "col.border_active" = "rgb(7c4dff)";
        "col.border_inactive" = "rgba(565f89aa)";
        "col.border_locked_active" = "rgb(ff4081)";
        "col.border_locked_inactive" = "rgba(565f89aa)";
        groupbar = {
          font_family = "JetBrainsMono Nerd Font";
          font_size = 10;
          gradients = true;
          render_titles = true;
          scrolling = true;
        };
      };

      # Misc settings
      misc = {
        force_default_wallpaper = 0;
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        mouse_move_enables_dpms = true;
        enable_swallow = true;
        swallow_regex = "^(kitty|foot|Alacritty)$";
        focus_on_activate = true;
        vrr = 1;
      };

      # Window rules (end-4 style)
      windowrule = [
        "float, ^(pavucontrol)$"
        "float, ^(blueman-manager)$"
        "float, ^(nm-applet)$"
        "float, ^(chromium)$"
        "float, ^(thunar)$"
        "float, title:^(btop)$"
        "float, title:^(update-sys)$"
        
        # Opacity rules
        "opacity 0.8 0.8, ^(kitty)$"
        "opacity 0.8 0.8, ^(thunar)$"
        "opacity 0.8 0.8, ^(code)$"
        
        # Workspace rules
        "workspace 2, ^(firefox)$"
        "workspace 3, ^(thunar)$"
        "workspace 4, ^(code)$"
        "workspace 5, ^(discord)$"
        "workspace 6, ^(obs)$"
        "workspace 7, ^(steam)$"
        "workspace 8, ^(spotify)$"
        "workspace 9, ^(gimp)$"
        "workspace 10, ^(virt-manager)$"
      ];

      # Layer rules
      layerrule = [
        "blur, rofi"
        "blur, notifications"
        "blur, waybar"
        "ignorezero, waybar"
        "blur, gtk-layer-shell"
        "ignorezero, gtk-layer-shell"
      ];

      # Keybindings (end-4 style)
      "$mainMod" = "SUPER";
      "$altMod" = "ALT";
      "$shiftMod" = "SHIFT";

      bind = [
        # Applications
        "$mainMod, Return, exec, kitty"
        "$mainMod, E, exec, thunar"
        "$mainMod, D, exec, rofi -show drun"
        "$mainMod, period, exec, rofi -show emoji"
        "$mainMod $shiftMod, Return, exec, rofi -show run"
        "$mainMod, B, exec, firefox"
        "$mainMod, C, exec, code"
        
        # Window management
        "$mainMod, Q, killactive"
        "$mainMod, M, exit"
        "$mainMod, V, togglefloating"
        "$mainMod, P, pseudo"
        "$mainMod, J, togglesplit"
        "$mainMod, F, fullscreen"
        "$mainMod $shiftMod, F, fullscreen, 1"
        "$mainMod, G, togglegroup"
        "$mainMod, Tab, changegroupactive, f"
        "$mainMod $shiftMod, Tab, changegroupactive, b"
        
        # Focus movement
        "$mainMod, left, movefocus, l"
        "$mainMod, right, movefocus, r"
        "$mainMod, up, movefocus, u"
        "$mainMod, down, movefocus, d"
        "$mainMod, h, movefocus, l"
        "$mainMod, l, movefocus, r"
        "$mainMod, k, movefocus, u"
        "$mainMod, j, movefocus, d"
        
        # Window movement
        "$mainMod $shiftMod, left, movewindow, l"
        "$mainMod $shiftMod, right, movewindow, r"
        "$mainMod $shiftMod, up, movewindow, u"
        "$mainMod $shiftMod, down, movewindow, d"
        "$mainMod $shiftMod, h, movewindow, l"
        "$mainMod $shiftMod, l, movewindow, r"
        "$mainMod $shiftMod, k, movewindow, u"
        "$mainMod $shiftMod, j, movewindow, d"
        
        # Workspace switching
        "$mainMod, 1, workspace, 1"
        "$mainMod, 2, workspace, 2"
        "$mainMod, 3, workspace, 3"
        "$mainMod, 4, workspace, 4"
        "$mainMod, 5, workspace, 5"
        "$mainMod, 6, workspace, 6"
        "$mainMod, 7, workspace, 7"
        "$mainMod, 8, workspace, 8"
        "$mainMod, 9, workspace, 9"
        "$mainMod, 0, workspace, 10"
        
        # Move to workspace
        "$mainMod $shiftMod, 1, movetoworkspace, 1"
        "$mainMod $shiftMod, 2, movetoworkspace, 2"
        "$mainMod $shiftMod, 3, movetoworkspace, 3"
        "$mainMod $shiftMod, 4, movetoworkspace, 4"
        "$mainMod $shiftMod, 5, movetoworkspace, 5"
        "$mainMod $shiftMod, 6, movetoworkspace, 6"
        "$mainMod $shiftMod, 7, movetoworkspace, 7"
        "$mainMod $shiftMod, 8, movetoworkspace, 8"
        "$mainMod $shiftMod, 9, movetoworkspace, 9"
        "$mainMod $shiftMod, 0, movetoworkspace, 10"
        
        # Special workspaces
        "$mainMod, S, togglespecialworkspace, magic"
        "$mainMod $shiftMod, S, movetoworkspace, special:magic"
        "$mainMod, grave, togglespecialworkspace, dropdown"
        "$mainMod $shiftMod, grave, movetoworkspace, special:dropdown"
        
        # Scroll through workspaces
        "$mainMod, mouse_down, workspace, e+1"
        "$mainMod, mouse_up, workspace, e-1"
        
        # Screenshot
        ", Print, exec, grim -g \"$(slurp)\" - | wl-copy"
        "$mainMod, Print, exec, grim - | wl-copy"
        "SHIFT, Print, exec, grim -g \"$(slurp)\" ~/Pictures/Screenshots/$(date +'%Y%m%d_%H%M%S_grim.png')"
        
        # Screen lock
        "$mainMod, L, exec, hyprlock"
        
        # System
        "$mainMod $shiftMod, R, exec, hyprctl reload"
        "$mainMod $shiftMod, Q, exec, wlogout"
        
        # Rofi menus
        "$mainMod, R, exec, rofi -show drun"
        "$mainMod $shiftMod, R, exec, rofi -show run"
        "$mainMod, T, exec, rofi -show window"
        "$mainMod, X, exec, rofi -show p -modi p:rofi-power-menu"
        
        # Color picker
        "$mainMod $shiftMod, C, exec, hyprpicker -a"
      ];

      # Mouse bindings
      bindm = [
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
      ];

      # Media and function keys
      bindel = [
        ", XF86AudioRaiseVolume, exec, pamixer -i 5"
        ", XF86AudioLowerVolume, exec, pamixer -d 5"
        ", XF86AudioMute, exec, pamixer -t"
        ", XF86AudioPlay, exec, playerctl play-pause"
        ", XF86AudioPause, exec, playerctl play-pause"
        ", XF86AudioNext, exec, playerctl next"
        ", XF86AudioPrev, exec, playerctl previous"
        ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"
        ", XF86MonBrightnessUp, exec, brightnessctl set 5%+"
      ];

      # Resize mode
      bind = [
        "$mainMod, R, submap, resize"
      ];
      
      submap = [
        "resize"
        "binde, right, resizeactive, 10 0"
        "binde, left, resizeactive, -10 0"
        "binde, up, resizeactive, 0 -10"
        "binde, down, resizeactive, 0 10"
        "bind, escape, submap, reset"
        "submap, reset"
      ];
    };
  };

  # End-4 style packages
  home.packages = with pkgs; [
    # Core applications
    kitty
    firefox
    thunar
    
    # Rofi and extensions
    rofi-wayland
    rofi-power-menu
    rofi-emoji
    
    # Media
    mpv
    imv
    
    # Utilities
    wl-clipboard
    wtype
    hyprpicker
    grim
    slurp
    
    # Audio
    pamixer
    playerctl
    pavucontrol
    
    # Brightness
    brightnessctl
    
    # Lock screen
    hyprlock
    
    # Logout menu
    wlogout
    
    # Wallpaper
    hyprpaper
    
    # Notification daemon
    dunst
    
    # System info
    fastfetch
    
    # Development
    git
    neovim
    vscode
    
    # Archive utilities
    unzip
    zip
    
    # Network
    networkmanager
    
    # File manager
    yazi
    
    # Terminal multiplexer
    tmux
    
    # Shell
    zsh
    starship
    
    # Fonts
    (nerdfonts.override { fonts = [ "JetBrainsMono" "FiraCode" "Meslo" ]; })
  ];

  # Configure rofi
  programs.rofi = {
    enable = true;
    package = pkgs.rofi-wayland;
    theme = "Arc-Dark";
    extraConfig = {
      modi = "drun,run,window,ssh";
      icon-theme = "Papirus";
      show-icons = true;
      terminal = "kitty";
      drun-display-format = "{icon} {name}";
      location = 0;
      disable-history = false;
      hide-scrollbar = true;
      display-drun = "   Apps ";
      display-run = "   Run ";
      display-window = " 﩯  Window";
      display-Network = " 󰤨  Network";
      sidebar-mode = true;
    };
  };

  # Configure waybar (simplified version)
  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 32;
        spacing = 4;
        margin-top = 8;
        margin-left = 16;
        margin-right = 16;
        
        modules-left = [
          "hyprland/workspaces"
          "hyprland/submap"
        ];
        modules-center = [ "hyprland/window" ];
        modules-right = [
          "pulseaudio"
          "network"
          "cpu"
          "memory"
          "battery"
          "clock"
          "tray"
        ];
        
        "hyprland/workspaces" = {
          disable-scroll = true;
          all-outputs = true;
          format = "{icon}";
          format-icons = {
            "1" = "󰲠";
            "2" = "󰲢";
            "3" = "󰲤";
            "4" = "󰲦";
            "5" = "󰲨";
            "6" = "󰲪";
            "7" = "󰲬";
            "8" = "󰲮";
            "9" = "󰲰";
            "10" = "󰿬";
            "focused" = "";
            "default" = "";
          };
          persistent_workspaces = {
            "1" = [];
            "2" = [];
            "3" = [];
            "4" = [];
            "5" = [];
          };
        };
        
        "hyprland/window" = {
          format = "{}";
          max-length = 50;
          separate-outputs = true;
        };
        
        tray = {
          spacing = 10;
        };
        
        clock = {
          format = "{:%H:%M}";
          format-alt = "{:%Y-%m-%d}";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
        };
        
        cpu = {
          format = "{usage}% ";
          tooltip = false;
        };
        
        memory = {
          format = "{}% ";
        };
        
        battery = {
          states = {
            warning = 30;
            critical = 15;
          };
          format = "{capacity}% {icon}";
          format-charging = "{capacity}% ";
          format-plugged = "{capacity}% ";
          format-alt = "{time} {icon}";
          format-icons = ["" "" "" "" ""];
        };
        
        network = {
          format-wifi = "{essid} ({signalStrength}%) ";
          format-ethernet = "{ipaddr}/{cidr} ";
          tooltip-format = "{ifname} via {gwaddr} ";
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
            default = ["" "" ""];
          };
          on-click = "pavucontrol";
        };
      };
    };
    
    style = ''
      * {
        border: none;
        border-radius: 0;
        font-family: "JetBrainsMono Nerd Font", monospace;
        font-size: 11px;
        min-height: 0;
      }
      
      window#waybar {
        background-color: rgba(30, 30, 46, 0.8);
        border-radius: 16px;
        color: #cdd6f4;
        transition-property: background-color;
        transition-duration: 0.5s;
      }
      
      #workspaces button {
        padding: 0 8px;
        background-color: transparent;
        color: #cdd6f4;
        border-radius: 8px;
        margin: 4px 2px;
        transition: all 0.3s ease;
      }
      
      #workspaces button:hover {
        background: rgba(205, 214, 244, 0.1);
        color: #7c4dff;
      }
      
      #workspaces button.active {
        background-color: #7c4dff;
        color: #1e1e2e;
      }
      
      #workspaces button.urgent {
        background-color: #f38ba8;
        color: #1e1e2e;
      }
      
      #clock, #battery, #cpu, #memory, #network, #pulseaudio, #tray, #window {
        padding: 0 12px;
        margin: 4px 2px;
        border-radius: 8px;
        background-color: rgba(205, 214, 244, 0.1);
        color: #cdd6f4;
        transition: all 0.3s ease;
      }
      
      #clock:hover, #battery:hover, #cpu:hover, #memory:hover, #network:hover, #pulseaudio:hover {
        background-color: rgba(205, 214, 244, 0.2);
      }
      
      #battery.charging, #battery.plugged {
        color: #a6e3a1;
      }
      
      #battery.critical:not(.charging) {
        background-color: #f38ba8;
        color: #1e1e2e;
        animation-name: blink;
        animation-duration: 0.5s;
        animation-timing-function: linear;
        animation-iteration-count: infinite;
        animation-direction: alternate;
      }
      
      @keyframes blink {
        to {
          background-color: rgba(243, 139, 168, 0.5);
        }
      }
      
      #network.disconnected {
        background-color: #f38ba8;
        color: #1e1e2e;
      }
      
      #pulseaudio.muted {
        background-color: rgba(205, 214, 244, 0.1);
        color: #6c7086;
      }
    '';
  };

  # Configure kitty terminal
  programs.kitty = {
    enable = true;
    theme = "Tokyo Night";
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 11;
    };
    settings = {
      background_opacity = "0.8";
      window_padding_width = 8;
      confirm_os_window_close = 0;
      enable_audio_bell = false;
      cursor_shape = "beam";
      cursor_blink_interval = 0;
      scrollback_lines = 10000;
      url_style = "curly";
      open_url_modifiers = "kitty_mod";
      copy_on_select = true;
      strip_trailing_spaces = "smart";
      tab_bar_style = "powerline";
      tab_powerline_style = "slanted";
      tab_title_template = "{title}";
      active_tab_foreground = "#1e1e2e";
      active_tab_background = "#7c4dff";
      inactive_tab_foreground = "#cdd6f4";
      inactive_tab_background = "#313244";
    };
  };

  # Configure dunst for notifications
  services.dunst = {
    enable = true;
    settings = {
      global = {
        monitor = 0;
        follow = "mouse";
        geometry = "350x5-15+46";
        indicate_hidden = "yes";
        shrink = "no";
        transparency = 10;
        notification_height = 0;
        separator_height = 2;
        padding = 12;
        horizontal_padding = 12;
        frame_width = 2;
        frame_color = "#7c4dff";
        separator_color = "frame";
        sort = "yes";
        idle_threshold = 120;
        font = "JetBrainsMono Nerd Font 10";
        line_height = 0;
        markup = "full";
        format = "<b>%s</b>\\n%b";
        alignment = "left";
        show_age_threshold = 60;
        word_wrap = "yes";
        ellipsize = "middle";
        ignore_newline = "no";
        stack_duplicates = true;
        hide_duplicate_count = false;
        show_indicators = "yes";
        icon_position = "left";
        max_icon_size = 48;
        sticky_history = "yes";
        history_length = 20;
        always_run_script = true;
        corner_radius = 12;
        mouse_left_click = "close_current";
        mouse_middle_click = "do_action";
        mouse_right_click = "close_all";
      };
      
      urgency_low = {
        background = "#1e1e2e";
        foreground = "#cdd6f4";
        timeout = 5;
      };
      
      urgency_normal = {
        background = "#1e1e2e";
        foreground = "#cdd6f4";
        timeout = 10;
      };
      
      urgency_critical = {
        background = "#1e1e2e";
        foreground = "#f38ba8";
        frame_color = "#f38ba8";
        timeout = 0;
      };
    };
  };
}