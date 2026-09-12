{
  pkgs,
  hostname,
  systemSettings ? { },
  ...
}:

{
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
