# System configuration builder function
# Inspired by mitchellh/nixos-config
{
  nixpkgs,
  home-manager,
  darwin,
  plasma-manager,
  hyprland,
  nvchad4nix,
  primeagenInit,
  agenix,
  ...
}:

{
  name,
  system,
  user,
  isDarwin ? false,
  vm ? false,
}:

let
  # System flags
  isLinux = !isDarwin;
  isVM = vm;

  # User configuration
  username = user.name;
  useremail = user.email;

  # GPU configuration for passthrough (only relevant for Linux hosts)
  gpuConfig = user.gpuConfig or { };

  # Common special arguments for all configurations
  specialArgs = {
    inherit username useremail gpuConfig;
    inherit
      nixpkgs
      home-manager
      darwin
      plasma-manager
      hyprland
      nvchad4nix
      primeagenInit
      agenix
      ;
    inherit isDarwin isLinux isVM;
    hostname = name;
    currentSystem = system;
    desktopManager =
      if isVM then
        if name == "nixos-vm-end4" then
          "end4-hyprland"
        else
          "hyprland"
      else if isDarwin then
        "none"
      else
        "plasma";
  };

  # Home Manager configuration
  mkHomeManagerConfig = extraSpecialArgs: {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs =
      specialArgs
      // extraSpecialArgs
      // {
        inherit isDarwin isLinux;
      };
    users.${username} = import ../users/${user.name}/home-manager.nix;
    backupFileExtension = "backup";
  };

in
if isDarwin then
  # macOS system using nix-darwin
  darwin.lib.darwinSystem {
    inherit system;
    specialArgs = specialArgs;
    modules = [
      { nixpkgs.config.allowUnfree = true; }
      ../machines/${name}.nix
      ../users/${user.name}/darwin.nix
      home-manager.darwinModules.home-manager
      {
        home-manager = mkHomeManagerConfig { };
      }
    ];
  }
else
  # NixOS system
  nixpkgs.lib.nixosSystem {
    inherit system;
    specialArgs = specialArgs;
    modules = [
      { nixpkgs.config.allowUnfree = true; }
      ../machines/${name}.nix
      ../users/${user.name}/nixos.nix
      home-manager.nixosModules.home-manager
      {
        home-manager =
          (mkHomeManagerConfig { })
          // (
            if isVM then
              { }
            else
              {
                sharedModules = [ plasma-manager.homeManagerModules.plasma-manager ];
              }
          );
      }
    ];
  }
