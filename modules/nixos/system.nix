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

  # Bootloader with manual Secure Boot support
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.systemd.enable = true;

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
    pcscd.enable = true;
  };

  # System packages for secure boot management
  environment.systemPackages = with pkgs; [
    sbctl  # Secure Boot key management tool
  ];

  # Hardware firmware
  hardware.enableRedistributableFirmware = true;
  
  # Add comprehensive firmware packages
  hardware.firmware = with pkgs; [
    linux-firmware
    # Remove intel2200BGFirmware as it's for old WiFi cards
    # rtl8761b-firmware
  ];

  # SystemD sleep configuration
  systemd = {
    sleep.extraConfig = ''
      HibernateDelaySec=30min
      SuspendState=mem
      SuspendMode=platform
    '';
  };

  # NVIDIA configuration (optional - uncomment if you have NVIDIA GPU)
  hardware = {
    graphics.enable = true;
    
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
