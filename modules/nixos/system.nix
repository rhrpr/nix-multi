{
  config,
  lib,
  pkgs,
  hostname,
  username,
  ...
}:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Kernel parameters for NVIDIA sleep/wake fixes
  boot.kernelParams = [
    # NVIDIA sleep/wake fixes
    "nvidia-drm.modeset=1"
    "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
    "nvidia.NVreg_TemporaryFilePath=/var/tmp"
    
    # Better sleep behavior
    "mem_sleep_default=deep"
    "acpi_sleep=nonvs"
    
    # Disable problematic ACPI wake sources
    "acpi.ec_no_wakeup=1"
  ];

  # Networking
  networking.hostName = hostname;
  networking.networkmanager.enable = true;

  # Localization
  time.timeZone = "Europe/London";
  i18n.defaultLocale = "en_GB.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_GB.UTF-8";
    LC_IDENTIFICATION = "en_GB.UTF-8";
    LC_MEASUREMENT = "en_GB.UTF-8";
    LC_MONETARY = "en_GB.UTF-8";
    LC_NAME = "en_GB.UTF-8";
    LC_NUMERIC = "en_GB.UTF-8";
    LC_PAPER = "en_GB.UTF-8";
    LC_TELEPHONE = "en_GB.UTF-8";
    LC_TIME = "en_GB.UTF-8";
  };

  # Enable essential programs
  programs = {
    firefox.enable = true;
    zsh.enable = true;
    dconf.enable = true; # Required for some GUI applications
  };

  # Services
  services = {
    # Enable Bluetooth
    blueman.enable = true; # Bluetooth manager GUI for KDE/GNOME
  };

  # SystemD sleep configuration and NVIDIA suspend/resume services
  systemd = {
    sleep.extraConfig = ''
      HibernateDelaySec=30min
      SuspendState=mem
      SuspendMode=platform
    '';

    services = {
      nvidia-suspend = {
        description = "NVIDIA system suspend actions";
        wantedBy = [ "sleep.target" ];
        before = [ "systemd-suspend.service" ];
        script = ''
          # Save NVIDIA state before suspend
          if [ -f /proc/driver/nvidia/suspend ]; then
            echo suspend > /proc/driver/nvidia/suspend
          fi
        '';
        serviceConfig = {
          Type = "oneshot";
          User = "root";
        };
      };

      nvidia-resume = {
        description = "NVIDIA system resume actions";  
        after = [ "systemd-suspend.service" ];
        wantedBy = [ "suspend.target" ];
        script = ''
          # Restore NVIDIA state after resume
          if [ -f /proc/driver/nvidia/suspend ]; then
            echo resume > /proc/driver/nvidia/suspend
          fi
          
          # Restart display manager if needed
          systemctl try-restart display-manager.service
        '';
        serviceConfig = {
          Type = "oneshot";
          User = "root";
        };
      };
    };
  };

  # NVIDIA configuration (optional - uncomment if you have NVIDIA GPU)
  hardware = {
    graphics.enable = true;
    
    # Enable Bluetooth
    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
    
    nvidia = {
      modesetting.enable = true;
      
      # Better power management for sleep/wake
      powerManagement = {
        enable = true;
        finegrained = false; # Use coarse-grained PM for better compatibility
      };
      
      # Disable GSP firmware (can cause wake issues)
      gsp.enable = false;
      
      # Force composition pipeline (can help with display issues)
      forceFullCompositionPipeline = true;
      
      open = lib.mkDefault true; # Can be overridden by GPU passthrough module
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };
  };
  services.xserver.videoDrivers = [ "nvidia" ];

  # System state version
  system.stateVersion = "24.11";
}
