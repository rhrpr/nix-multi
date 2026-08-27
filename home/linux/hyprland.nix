{
  config,
  pkgs,
  lib,
  dots-hyprland,
  ...
}:

{
  # ---------------------------------------------------------------------------
  # end4/dots-hyprland config integration
  #
  # AGS widget system and supporting configs are linked directly from the nix
  # store path of the dots-hyprland flake input. Hyprland itself is configured
  # here in Nix with end4-style animations/decorations.
  #
  # NOTE: end4's current config targets AGS v2 (Astal framework). If nixpkgs
  # ships AGS v1, the TypeScript widgets may fail to start. Check:
  #   ags --version
  # If there are API errors, you may need to add the Astal flake as an input
  # or use an older branch of dots-hyprland that targets AGS v1.
  # ---------------------------------------------------------------------------

  # Link end4's config directories into ~/.config/
  home.file = {
    # AGS widget system - bar, notifications, launcher, overview, etc.
    ".config/ags".source = "${dots-hyprland}/.config/ags";

    # Foot terminal config (end4 uses foot as the default terminal)
    ".config/foot".source = "${dots-hyprland}/.config/foot";

    # Fastfetch config
    ".config/fastfetch".source = "${dots-hyprland}/.config/fastfetch";
  };

  # ---------------------------------------------------------------------------
  # Hyprland configuration
  # ---------------------------------------------------------------------------
  wayland.windowManager.hyprland = {
    enable = true;

    settings = {
      # -------------------------------------------------------------------------
      # NVIDIA RTX 3080 - required for Hyprland on NVIDIA
      # Display is connected directly to the RTX 3080 (not PRIME/hybrid mode)
      # -------------------------------------------------------------------------
      env = [
        "LIBVA_DRIVER_NAME,nvidia"
        "GBM_BACKEND,nvidia-drm"
        "__GLX_VENDOR_LIBRARY_NAME,nvidia"
        "WLR_NO_HARDWARE_CURSORS,1"
        "NVD_BACKEND,direct"
        "ELECTRON_OZONE_PLATFORM_HINT,auto"
        "XDG_SESSION_TYPE,wayland"
      ];

      # 3440x1440 ultrawide @ 144Hz - adjust refresh rate to your panel's max
      monitor = [ ",3440x1440@144,0x0,1" ];

      # -------------------------------------------------------------------------
      # Autostart - AGS replaces waybar/dunst
      # -------------------------------------------------------------------------
      exec-once = [
        "ags"
        "swww-daemon"
        "hypridle"
        "nm-applet --indicator"
        "blueman-applet"
        "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
      ];

      # -------------------------------------------------------------------------
      # Input
      # -------------------------------------------------------------------------
      input = {
        kb_layout = "us";
        follow_mouse = 1;
        sensitivity = 0;
        accel_profile = "flat";
      };

      # -------------------------------------------------------------------------
      # General - end4 style gaps and borders
      # -------------------------------------------------------------------------
      general = {
        gaps_in = 4;
        gaps_out = 5;
        border_size = 1;
        "col.active_border" = "rgba(b4befeff) rgba(6c7086ff) 45deg";
        "col.inactive_border" = "rgba(6c708680)";
        layout = "dwindle";
        allow_tearing = false;
      };

      # -------------------------------------------------------------------------
      # Decorations - rounded corners, blur, shadows (end4 aesthetic)
      # -------------------------------------------------------------------------
      decoration = {
        rounding = 12;
        active_opacity = 1.0;
        inactive_opacity = 1.0;

        blur = {
          enabled = true;
          size = 8;
          passes = 3;
          new_optimizations = true;
          xray = false;
          noise = "0.0117";
          contrast = "0.8917";
          brightness = "0.8172";
          vibrancy = "0.1696";
          vibrancy_darkness = "0.0";
        };

        shadow = {
          enabled = true;
          range = 30;
          render_power = 3;
          color = "rgba(0000001a)";
          color_inactive = "rgba(00000000)";
        };
      };

      # -------------------------------------------------------------------------
      # Animations - end4's smooth Material Design 3 style bezier curves
      # -------------------------------------------------------------------------
      animations = {
        enabled = true;

        bezier = [
          "linear, 0, 0, 1, 1"
          "md3_standard, 0.2, 0, 0, 1"
          "md3_decel, 0.05, 0.7, 0.1, 1"
          "md3_accel, 0.3, 0, 0.8, 0.15"
          "overshot, 0.05, 0.9, 0.1, 1.1"
          "hyprnostretch, 0.05, 0.9, 0.1, 1.0"
          "menu_decel, 0.1, 1, 0, 1"
          "menu_accel, 0.38, 0.04, 1, 0.07"
          "easeOutCirc, 0, 0.55, 0.45, 1"
          "easeOutExpo, 0.16, 1, 0.3, 1"
          "softAcDecel, 0.26, 0.26, 0.15, 1"
        ];

        animation = [
          "windows, 1, 3, md3_decel, popin 60%"
          "windowsIn, 1, 3, md3_decel, popin 60%"
          "windowsOut, 1, 3, md3_accel, popin 60%"
          "border, 1, 10, default"
          "fade, 1, 3, md3_decel"
          "layersIn, 1, 3, menu_decel, slide"
          "layersOut, 1, 1.6, menu_accel"
          "fadeLayersIn, 1, 2, menu_decel"
          "fadeLayersOut, 1, 4.5, menu_accel"
          "workspaces, 1, 7, menu_decel, slide"
          "specialWorkspace, 1, 3, md3_decel, slidevert"
        ];
      };

      # -------------------------------------------------------------------------
      # Layout
      # -------------------------------------------------------------------------
      dwindle = {
        pseudotile = true;
        preserve_split = true;
        smart_split = false;
        smart_resizing = false;
      };

      # -------------------------------------------------------------------------
      # Misc
      # -------------------------------------------------------------------------
      misc = {
        vfr = 1;
        vrr = 0;
        animate_manual_resizes = false;
        animate_mouse_windowdragging = false;
        enable_swallow = true;
        swallow_regex = "^(foot|kitty|alacritty)$";
        force_default_wallpaper = 0;
        disable_splash_rendering = true;
        focus_on_activate = true;
        initial_workspace_tracking = false;
      };

      # -------------------------------------------------------------------------
      # Gestures
      # -------------------------------------------------------------------------
      gestures = {
        workspace_swipe = true;
        workspace_swipe_fingers = 4;
        workspace_swipe_distance = 250;
        workspace_swipe_invert = true;
        workspace_swipe_min_speed_to_force = 15;
        workspace_swipe_cancel_ratio = 0.15;
        workspace_swipe_create_new = true;
      };

      # -------------------------------------------------------------------------
      # Keybinds
      # -------------------------------------------------------------------------
      "$mod" = "SUPER";

      bind = [
        # Applications
        "$mod, Return, exec, foot"
        "$mod SHIFT, Return, exec, foot"
        "$mod, E, exec, nautilus"
        "$mod, B, exec, firefox"

        # AGS panels (end4 style)
        "$mod, Tab, exec, ags -t overview"
        "$mod SHIFT, N, exec, ags -t notifications"

        # Launcher
        "$mod, Space, exec, fuzzel"

        # Window management
        "$mod, C, killactive"
        "$mod SHIFT, Q, exit"
        "$mod, F, fullscreen, 0"
        "$mod SHIFT, F, fullscreen, 1"
        "$mod, V, togglefloating"
        "$mod, P, pseudo"
        "$mod, J, togglesplit"
        "$mod, G, togglegroup"

        # Lock screen
        "$mod, Escape, exec, hyprlock"

        # Screenshot - selection to clipboard
        ", Print, exec, grim -g \"$(slurp)\" - | wl-copy"
        # Screenshot - full screen to clipboard
        "$mod, Print, exec, grim - | wl-copy"
        # Screenshot - selection to file
        "$mod SHIFT, S, exec, grim -g \"$(slurp)\" ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png"

        # Color picker
        "$mod SHIFT, C, exec, hyprpicker -a"

        # Wlogout
        "$mod SHIFT, Escape, exec, wlogout"

        # Focus movement
        "$mod, left, movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up, movefocus, u"
        "$mod, down, movefocus, d"
        "$mod, h, movefocus, l"
        "$mod, l, movefocus, r"
        "$mod, k, movefocus, u"
        "$mod, j, movefocus, d"

        # Move windows
        "$mod SHIFT, left, movewindow, l"
        "$mod SHIFT, right, movewindow, r"
        "$mod SHIFT, up, movewindow, u"
        "$mod SHIFT, down, movewindow, d"
        "$mod SHIFT, h, movewindow, l"
        "$mod SHIFT, l, movewindow, r"
        "$mod SHIFT, k, movewindow, u"
        "$mod SHIFT, j, movewindow, d"

        # Workspaces
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod, 6, workspace, 6"
        "$mod, 7, workspace, 7"
        "$mod, 8, workspace, 8"
        "$mod, 9, workspace, 9"
        "$mod, 0, workspace, 10"

        # Move active window to workspace
        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"
        "$mod SHIFT, 6, movetoworkspace, 6"
        "$mod SHIFT, 7, movetoworkspace, 7"
        "$mod SHIFT, 8, movetoworkspace, 8"
        "$mod SHIFT, 9, movetoworkspace, 9"
        "$mod SHIFT, 0, movetoworkspace, 10"

        # Special workspace (scratchpad)
        "$mod, grave, togglespecialworkspace, scratch"
        "$mod SHIFT, grave, movetoworkspace, special:scratch"

        # Scroll through workspaces
        "$mod, mouse_down, workspace, e+1"
        "$mod, mouse_up, workspace, e-1"
      ];

      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      # Resize with mod+alt+arrows
      binde = [
        "$mod ALT, right, resizeactive, 30 0"
        "$mod ALT, left, resizeactive, -30 0"
        "$mod ALT, up, resizeactive, 0 -30"
        "$mod ALT, down, resizeactive, 0 30"
      ];

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

      # -------------------------------------------------------------------------
      # Window rules
      # -------------------------------------------------------------------------
      windowrulev2 = [
        # Floating dialogs
        "float, class:^(pavucontrol)$"
        "float, class:^(blueman-manager)$"
        "float, class:^(nm-connection-editor)$"
        "float, title:^(Picture-in-Picture)$"
        "pin, title:^(Picture-in-Picture)$"
        "float, class:^(file_progress)$"
        "float, class:^(confirm)$"
        "float, class:^(dialog)$"
        "float, class:^(download)$"
        "float, class:^(notification)$"
        "float, class:^(error)$"
        "float, class:^(splash)$"
        "float, class:^(wlogout)$"
        "fullscreen, class:^(wlogout)$"
        # Idle inhibit for video
        "idleinhibit focus, class:^(mpv)$"
        "idleinhibit fullscreen, class:^(firefox)$"
        # AGS layer rules
        "blur, class:^(ags)$"
      ];
    };
  };

  # ---------------------------------------------------------------------------
  # Hyprlock - screen locker
  # ---------------------------------------------------------------------------
  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        disable_loading_bar = true;
        grace = 0;
        hide_cursor = true;
        no_fade_in = false;
      };

      background = [
        {
          path = "screenshot";
          blur_size = 7;
          blur_passes = 4;
          noise = "0.0117";
          contrast = "0.8917";
          brightness = "0.8172";
          vibrancy = "0.1696";
          vibrancy_darkness = "0.0";
        }
      ];

      input-field = [
        {
          size = "250, 50";
          position = "0, -80";
          monitor = "";
          dots_center = true;
          fade_on_empty = false;
          font_color = "rgb(cdd6f4)";
          inner_color = "rgb(1e1e2e)";
          outer_color = "rgb(313244)";
          outline_thickness = 5;
          placeholder_text = "<span foreground='##cdd6f4'> </span>";
          shadow_passes = 2;
        }
      ];

      label = [
        {
          monitor = "";
          text = ''cmd[update:1000] echo "<b>$(date +"%H:%M")</b>"'';
          color = "rgba(cdd6f4ff)";
          font_size = 64;
          font_family = "JetBrainsMono Nerd Font";
          position = "0, 160";
          halign = "center";
          valign = "center";
        }
        {
          monitor = "";
          text = ''cmd[update:1000] echo "$(date +"%A, %B %d")"'';
          color = "rgba(cdd6f4cc)";
          font_size = 18;
          font_family = "JetBrainsMono Nerd Font";
          position = "0, 80";
          halign = "center";
          valign = "center";
        }
      ];
    };
  };

  # ---------------------------------------------------------------------------
  # Hypridle - idle management
  # ---------------------------------------------------------------------------
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        after_sleep_cmd = "hyprctl dispatch dpms on";
        ignore_dbus_inhibit = false;
        lock_cmd = "pidof hyprlock || hyprlock";
      };

      listener = [
        {
          timeout = 300;
          on-timeout = "pidof hyprlock || hyprlock";
        }
        {
          timeout = 600;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
      ];
    };
  };

  # ---------------------------------------------------------------------------
  # GTK theme - Catppuccin Mocha to match end4's default palette
  # ---------------------------------------------------------------------------
  gtk = {
    enable = true;
    theme = {
      name = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    cursorTheme = {
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
    };
    gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = true;
  };

  qt = {
    enable = true;
    platformTheme.name = "gtk";
    style.name = "adwaita-dark";
  };

  # ---------------------------------------------------------------------------
  # Required packages
  # ---------------------------------------------------------------------------
  home.packages = with pkgs; [
    # AGS + dependencies (end4's widget system)
    # NOTE: check `ags --version` - end4's current config targets v2/Astal
    ags
    dart-sass # TypeScript compilation for AGS widgets
    fd # fast find, used by some AGS scripts
    gjs # JavaScript runtime for AGS

    # Hyprland ecosystem
    hyprpicker # color picker
    wlogout # logout menu

    # Terminal (end4 uses foot)
    foot

    # Launcher
    fuzzel

    # Wallpaper
    swww

    # Screenshots
    grim
    slurp
    wl-clipboard

    # Audio/brightness/media control
    brightnessctl
    playerctl
    pamixer

    # Utilities used by AGS scripts
    jq
    socat
    curl
    imagemagick

    # System info widget
    fastfetch

    # Notification library
    libnotify

    # GTK theming
    adw-gtk3
    papirus-icon-theme
    bibata-cursors

    # Fonts for AGS (Material Symbols icons used heavily in end4's widgets)
    material-symbols
    nerd-fonts.jetbrains-mono
    nerd-fonts.noto

    # Polkit agent (needed for GUI authentication prompts)
    polkit_gnome
  ];

  # Ensure ~/.config/hypr exists for hyprland to write its IPC socket
  xdg.enable = true;
}
