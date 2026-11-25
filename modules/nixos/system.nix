{
  pkgs,
  hostname,
  systemSettings ? { },
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
#  system.activationScripts.secureBootSetup.text = ''
#    set -euo pipefail

    # Make sure ESP path exists
#    mkdir -p /boot/EFI/nixos/keys

#    # 1) Create keys once, if missing
#    if [ ! -f /var/lib/sbctl/keys/PK.key ]; then
#      echo "[sbctl] Creating Secure Boot keys..."
#      ${pkgs.sbctl}/bin/sbctl create-keys
#    fi

    # 2) Enroll keys (include Microsoft so Windows still works)
    # If PK not in firmware, enroll.
#    if ! ls /sys/firmware/efi/efivars/PK-* >/dev/null 2>&1; then
#      echo "[sbctl] Enrolling keys (with Microsoft)..."
#      ${pkgs.sbctl}/bin/sbctl enroll-keys --microsoft || true
#    fi

    # 3) Export keys to ESP for reuse by Arch/others
#    echo "[sbctl] Exporting keys to ESP..."
#    mkdir -p /boot/EFI/nixos/keys
#    cp -r /var/lib/sbctl/keys/* /boot/EFI/nixos/keys/ 2>/dev/null || true
#    chmod -R 600 /boot/EFI/nixos/keys/* 2>/dev/null || true

    # 4) Sign executable EFI binaries (do NOT sign initrd)
#    sign_if_present() {
#      local f="$1"
#      if [ -f "$f" ]; then
#        echo "[sbctl] Signing $f"
#        ${pkgs.sbctl}/bin/sbctl sign -s "$f" || true
#      fi
#    }

    # systemd-boot + fallback
#    sign_if_present /boot/EFI/systemd/systemd-bootx64.efi
#    sign_if_present /boot/EFI/BOOT/BOOTX64.EFI

    # NixOS stub-kernel(s)
#    for k in /boot/EFI/nixos/linux-*.efi /boot/EFI/nixos/*-bzImage.efi; do
#      [ -e "$k" ] && sign_if_present "$k"
#    done

    # 5) Show a quick verification summary (non-fatal if something's missing)
#    echo "[sbctl] Verification summary:"
#    ${pkgs.sbctl}/bin/sbctl verify || true
#  '';

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
  networking = {
    hostName = hostname;
    networkmanager.enable = true;
  };

  time.timeZone = systemSettings.timeZone or "UTC";
  i18n.defaultLocale = systemSettings.defaultLocale or "en_US.UTF-8";
  i18n.extraLocaleSettings = systemSettings.extraLocaleSettings or { };

  programs = {
    firefox.enable = true;
    zsh.enable = true;
    dconf.enable = true;
  };

  services.pcscd.enable = true;

  hardware = {
    enableRedistributableFirmware = true;
    firmware = [ pkgs.linux-firmware ];
  };

  system.stateVersion = "24.11";
}
