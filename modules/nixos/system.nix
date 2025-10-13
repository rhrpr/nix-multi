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

  # UEFI + systemd-boot
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";
  boot.initrd.systemd.enable = true;

  # Tools we need
  environment.systemPackages = with pkgs; [
    sbctl efibootmgr
  ];

  # Export & sign on every switch. Idempotent, safe to re-run.
  system.activationScripts.secureBootSetup.text = ''
    set -euo pipefail

    # Make sure ESP path exists
    mkdir -p /boot/EFI/nixos/keys

    # 1) Create keys once, if missing
    if [ ! -f /var/lib/sbctl/keys/PK.key ]; then
      echo "[sbctl] Creating Secure Boot keys..."
      ${pkgs.sbctl}/bin/sbctl create-keys
    fi

    # 2) Enroll keys (include Microsoft so Windows still works)
    # If PK not in firmware, enroll.
    if ! ls /sys/firmware/efi/efivars/PK-* >/dev/null 2>&1; then
      echo "[sbctl] Enrolling keys (with Microsoft)..."
      ${pkgs.sbctl}/bin/sbctl enroll-keys --microsoft || true
    fi

    # 3) Export keys to ESP for reuse by Arch/others
    echo "[sbctl] Exporting keys to ESP..."
    mkdir -p /boot/EFI/nixos/keys
    cp -r /var/lib/sbctl/keys/* /boot/EFI/nixos/keys/ 2>/dev/null || true
    chmod -R 600 /boot/EFI/nixos/keys/* 2>/dev/null || true

    # 4) Sign executable EFI binaries (do NOT sign initrd)
    sign_if_present() {
      local f="$1"
      if [ -f "$f" ]; then
        echo "[sbctl] Signing $f"
        ${pkgs.sbctl}/bin/sbctl sign -s "$f" || true
      fi
    }

    # systemd-boot + fallback
    sign_if_present /boot/EFI/systemd/systemd-bootx64.efi
    sign_if_present /boot/EFI/BOOT/BOOTX64.EFI

    # NixOS stub-kernel(s)
    for k in /boot/EFI/nixos/linux-*.efi /boot/EFI/nixos/*-bzImage.efi; do
      [ -e "$k" ] && sign_if_present "$k"
    done

    # 5) Show a quick verification summary (non-fatal if something's missing)
    echo "[sbctl] Verification summary:"
    ${pkgs.sbctl}/bin/sbctl verify || true
  '';

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
