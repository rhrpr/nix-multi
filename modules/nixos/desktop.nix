{
  config,
  lib,
  pkgs,
  desktopManager ? "plasma",
  hyprland,
  isVM ? false,
  ...
}:

let
  isPlasma = desktopManager == "plasma";
  isHyprland = desktopManager == "hyprland";
in
{
  imports =
    [
      # Import Hyprland module if selected
    ]
    ++ lib.optionals isHyprland [
      hyprland.nixosModules.default
    ];

  # Common desktop configuration
  services.xserver = {
    enable = !isHyprland; # Disable X11 for Hyprland (uses Wayland)
    xkb = {
      layout = "us";
      variant = "";
    };
  };

  # Display manager configuration
  services.displayManager = lib.mkMerge [
    # Common display manager settings
    {
      autoLogin.enable = false;
    }

    # Plasma-specific configuration
    (lib.mkIf isPlasma {
      sddm = {
        enable = true;
        wayland.enable = true;
      };
    })

    # Hyprland-specific configuration
    (lib.mkIf isHyprland {
      # Use GDM or SDDM for Hyprland
      sddm = {
        enable = true;
        wayland.enable = true;
      };
    })
  ];

  # Desktop environment configuration
  services.desktopManager = lib.mkIf isPlasma {
    plasma6.enable = true;
  };

  # Hyprland configuration
  programs.hyprland = lib.mkIf isHyprland {
    enable = true;
    xwayland.enable = true;
    package = hyprland.packages.${pkgs.system}.hyprland;
  };

  # Ensure clean switching between desktop environments
  # Explicitly disable conflicting services to prevent systemd service collisions
  systemd.user.services = lib.mkMerge [
    # Disable Hyprland services when using Plasma
    (lib.mkIf isPlasma {
      xdg-desktop-portal-hyprland = {
        enable = lib.mkForce false;
        wantedBy = lib.mkForce [ ];
        after = lib.mkForce [ ];
        wants = lib.mkForce [ ];
      };
    })

    # Disable KDE services when using Hyprland
    (lib.mkIf isHyprland {
      xdg-desktop-portal-kde = {
        enable = lib.mkForce false;
        wantedBy = lib.mkForce [ ];
        after = lib.mkForce [ ];
        wants = lib.mkForce [ ];
      };

      # Also disable wlr portal service to prevent conflicts
      xdg-desktop-portal-wlr = {
        enable = lib.mkForce false;
        wantedBy = lib.mkForce [ ];
        after = lib.mkForce [ ];
        wants = lib.mkForce [ ];
      };
    })
  ];

  # Disable conflicting packages at the system level
  environment.systemPackages =
    with pkgs;
    [
      # Common desktop packages
      xdg-utils
      xdg-user-dirs

      # Wayland utilities
      wl-clipboard
      wayland-utils

      # Screen sharing and remote desktop
      kdePackages.xwaylandvideobridge

      # Font packages
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-emoji
      liberation_ttf
      fira-code
      fira-code-symbols
    ]
    ++ lib.optionals isHyprland (
      [
        # Hyprland core utilities
        swww # wallpaper daemon
        grim # screenshot
        slurp # screen selection
        wf-recorder # screen recording
        brightnessctl
        playerctl
        pamixer
        networkmanagerapplet
        pavucontrol
        wlogout
        hyprlock
        hypridle
        hyprpicker

        # end4/dots-hyprland toolchain
        ags # widget system (bar, notifications, launcher, overview)
        foot # terminal (end4's default)
        fuzzel # application launcher

        # File management
        file-roller
        nautilus

        # GNOME utilities (used by some AGS widgets)
        gnome-calculator
        gnome-calendar
        gnome-clocks
        gnome-weather
      ]
      ++ lib.optionals (!isVM) [
        # Bluetooth manager (only on physical systems)
        blueman
      ]
    )
    ++ lib.optionals isPlasma [
      # Additional Plasma packages
      kdePackages.kate
      kdePackages.kdeconnect-kde
      kdePackages.okular
      kdePackages.ark
      kdePackages.dolphin
      kdePackages.konsole
      kdePackages.spectacle
    ];

  # Wayland support
  environment.sessionVariables = lib.mkMerge [
    (lib.mkIf (isPlasma || isHyprland) {
      NIXOS_OZONE_WL = "1"; # Enable Wayland support in Chromium/Electron apps
      MOZ_ENABLE_WAYLAND = "1"; # Enable Wayland support in Firefox
    })
    # NVIDIA-specific Wayland/Hyprland env vars (set at login, not just in hyprland.conf)
    (lib.mkIf isHyprland {
      LIBVA_DRIVER_NAME = "nvidia";
      GBM_BACKEND = "nvidia-drm";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      WLR_NO_HARDWARE_CURSORS = "1";
      NVD_BACKEND = "direct";
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
    })
  ];

  # Security and authentication
  security = {
    polkit.enable = true;
    rtkit.enable = true;
    pam.services = {
      gdm.enableGnomeKeyring = lib.mkIf isHyprland true;
      login.enableGnomeKeyring = lib.mkIf isHyprland true;
    };
  };

  # Audio configuration
  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = lib.mkIf (pkgs.stdenv.hostPlatform.system == "x86_64-linux") true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;
    
    # Bluetooth audio support
    wireplumber.configPackages = [
      (pkgs.writeTextDir "share/wireplumber/bluetooth.lua.d/51-bluez-config.lua" ''
        bluez_monitor.properties = {
          ["bluez5.enable-sbc-xq"] = true,
          ["bluez5.enable-msbc"] = true,
          ["bluez5.enable-hw-volume"] = true,
          ["bluez5.headset-roles"] = "[ hsp_hs hsp_ag hfp_hf hfp_ag ]"
        }
      '')
    ];
  };

  # Graphics and hardware acceleration
  hardware.graphics = {
    enable = true;
    enable32Bit = lib.mkIf (pkgs.stdenv.hostPlatform.system == "x86_64-linux") true;
  };

  # XDG portal configuration - configured to handle switching between desktop environments
  xdg.portal = {
    enable = true;
    # Only include the portals we actually need for the current desktop
    extraPortals =
      with pkgs;
      if isPlasma then
        [
          kdePackages.xdg-desktop-portal-kde
          xdg-desktop-portal-gtk
        ]
      else if isHyprland then
        [
          # Use the portal from Hyprland flake instead of nixpkgs to avoid conflicts
          hyprland.packages.${pkgs.system}.xdg-desktop-portal-hyprland
          xdg-desktop-portal-gtk
        ]
      else
        [
          xdg-desktop-portal-gtk
        ];

    # Explicit configuration to prevent conflicts
    config =
      if isPlasma then
        {
          common = {
            default = [ "kde" ];
            "org.freedesktop.impl.portal.FileChooser" = [ "kde" ];
            "org.freedesktop.impl.portal.AppChooser" = [ "kde" ];
            "org.freedesktop.impl.portal.Print" = [ "kde" ];
            "org.freedesktop.impl.portal.Screenshot" = [ "kde" ];
          };
        }
      else if isHyprland then
        {
          common = {
            default = [ "hyprland" ];
            "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
            "org.freedesktop.impl.portal.AppChooser" = [ "gtk" ];
            "org.freedesktop.impl.portal.Print" = [ "gtk" ];
            "org.freedesktop.impl.portal.Screenshot" = [ "hyprland" ];
          };
          hyprland = {
            default = [
              "hyprland"
              "gtk"
            ];
          };
        }
      else
        {
          common = {
            default = [ "gtk" ];
          };
        };

    # Disable wlr portal to avoid conflicts with hyprland portal
    wlr.enable = false;
  };

  # Fonts configuration
  fonts = {
    packages =
      with pkgs;
      [
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-emoji
        liberation_ttf
        fira-code
        fira-code-symbols
        nerd-fonts.fira-code
        nerd-fonts.jetbrains-mono
        font-awesome
      ]
      ++ lib.optionals isHyprland [
        # Required by end4's AGS widgets (icon font)
        material-symbols
      ];

    fontconfig = {
      enable = true;
      defaultFonts = {
        serif = [ "Noto Serif" ];
        sansSerif = [ "Noto Sans" ];
        monospace = [ "Fira Code" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };

  # Network configuration
  networking.networkmanager.enable = true;

  # Bluetooth support (disabled in VMs)
  hardware.bluetooth = lib.mkIf (!isVM) {
    enable = true;
    powerOnBoot = true;
    # Additional settings for better compatibility
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
        Experimental = true;
      };
    };
  };
  services.blueman.enable = lib.mkIf (!isVM) true;

  # Printing support
  services.printing = {
    enable = true;
    drivers = with pkgs; [ cups-pdf-to-pdf ];
  };
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # Thunar file manager for Hyprland
  programs.thunar = lib.mkIf isHyprland {
    enable = true;
    plugins = with pkgs.xfce; [
      thunar-archive-plugin
      thunar-volman
    ];
  };

  services.gvfs.enable = lib.mkIf isHyprland true; # Trash and mount support
  services.tumbler.enable = lib.mkIf isHyprland true; # Thumbnail support

  # Gaming support (optional, x86_64 only)
  programs.steam = lib.mkIf (pkgs.stdenv.hostPlatform.system == "x86_64-linux") {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };
  programs.gamemode.enable = lib.mkIf (pkgs.stdenv.hostPlatform.system == "x86_64-linux") true;
}
