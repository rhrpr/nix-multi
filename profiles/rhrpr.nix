{
  # This is the repository maintainer's profile. Forks should replace it with
  # their own profile based on profiles/example.nix.
  user = {
    name = "hrpr";
    email = "ryan@hrpr.dev";
    gpuConfig = {
      vendor = "nvidia";
      deviceId = "10de:2206";
      audioId = "10de:1aef";
      pciAddress = "01:00";
      enablePartialPassthrough = true;
    };
    homeModules = [ ./rhrpr/ssh.nix ];
    systemSettings = {
      timeZone = "Europe/London";
      defaultLocale = "en_GB.UTF-8";
      extraLocaleSettings = {
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
    };
  };

  hardwareModules = {
    desktop = ./rhrpr/hardware/nixos-desktop.nix;
    vm = ./rhrpr/hardware/nixos-vm.nix;
  };
}
