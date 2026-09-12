{
  config,
  pkgs,
  lib,
  hostname,
  username,
  desktopManager,
  systemSettings ? { },
  ...
}:

{
  # VM-optimized system configuration - standalone without importing base system

  # Basic system configuration for VM
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Networking
  networking = {
    hostName = hostname;
    networkmanager.enable = true;
    firewall = {
      enable = true;
      # Open ports for potential VM services
      allowedTCPPorts = [ 22 ]; # SSH
    };
  };

  # Localization
  time.timeZone = systemSettings.timeZone or "UTC";
  i18n.defaultLocale = systemSettings.defaultLocale or "en_US.UTF-8";
  i18n.extraLocaleSettings = systemSettings.extraLocaleSettings or { };

  # Enable essential programs for VM
  programs = {
    firefox.enable = true;
    zsh.enable = true;
    dconf.enable = true; # Required for some GUI applications
  };

  # Optimize for VM environment
  services = {
    # Enable SPICE agent for better integration
    spice-vdagentd.enable = true;

    # Enable QEMU guest agent
    qemuGuest.enable = true;

    # Disable unnecessary services for VM
    udisks2.enable = lib.mkForce false;
    power-profiles-daemon.enable = lib.mkForce false;
    thermald.enable = lib.mkForce false;
  };

  # VM-specific boot optimizations
  boot = {
    # Faster boot times
    kernelParams = [
      "quiet"
      "loglevel=3"
      "systemd.show_status=auto"
      "rd.udev.log_level=3"
    ];

    # Optimize initrd
    initrd = {
      verbose = false;
      systemd.enable = true;
    };

    # Plymouth for better boot experience
    plymouth = lib.mkIf (desktopManager != "omarchy") {
      enable = true;
      theme = "breeze";
    };
  };

  # VM-specific hardware optimizations
  hardware = {
    # Enable hardware acceleration for VMs
    graphics = {
      enable = true;
      enable32Bit = lib.mkIf (pkgs.stdenv.hostPlatform.system == "x86_64-linux") true;
    };

    # VM doesn't need bluetooth typically - force disable all bluetooth
    bluetooth = {
      enable = lib.mkForce false;
      powerOnBoot = lib.mkForce false;
    };
  };

  # Also disable bluetooth services explicitly
  services.blueman.enable = lib.mkForce false;

  # Disable WirePlumber Bluetooth modules in VMs
  systemd.user.services."wireplumber@bluetooth" = {
    enable = lib.mkForce false;
    wantedBy = lib.mkForce [ ];
  };

  # Optimize memory usage for VM
  zramSwap = {
    enable = true;
    memoryPercent = 25;
  };

  # Enable automatic login for convenience in VM
  services.displayManager.autoLogin = {
    enable = lib.mkForce true;
    user = username;
  };

  # Enable SSH for remote access
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # System state version for VM
  system.stateVersion = "24.11";
}
