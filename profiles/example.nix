{
  # Copy this file to profiles/<your-name>.nix and replace every value before
  # adding a host output for it in flake.nix.
  user = {
    name = "replace-me";
    email = "replace-me@example.com";
    gpuConfig = { };
    homeModules = [ ];
    userSettings.passwordlessSudo = false;
    systemSettings = {
      timeZone = "UTC";
      defaultLocale = "en_US.UTF-8";
      extraLocaleSettings = { };
    };
  };

  # Keep generated disk layouts and hardware-specific settings in separate
  # modules. Do not reuse the paths or hardware values from another machine.
  hardwareModules = {
    desktop = ./example/hardware/nixos-desktop.nix;
    vm = ./example/hardware/nixos-vm.nix;
  };
}
