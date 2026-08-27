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
  zen-browser,
  nix-openclaw,
  llm-agents,
  spicetify-nix,
  dots-hyprland,
  ...
}:

{
  name,
  system,
  user,
  isDarwin ? false,
  vm ? false,
  desktopManager ? null, # explicit override; null = auto-detect
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
  # Resolve desktop manager: explicit param wins, otherwise auto-detect
  resolvedDesktopManager =
    if desktopManager != null then
      desktopManager
    else if isVM then
      "hyprland"
    else if isDarwin then
      "none"
    else
      "hyprland"; # default Linux desktop to Hyprland

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
      zen-browser
      nix-openclaw
      llm-agents
      spicetify-nix
      dots-hyprland
      ;
    inherit isDarwin isLinux isVM;
    hostname = name;
    currentSystem = system;
    desktopManager = resolvedDesktopManager;
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
      nix-openclaw.darwinModules.openclaw
      {
        home-manager =
          (mkHomeManagerConfig { })
          // {
            sharedModules = [ spicetify-nix.homeManagerModules.default ];
          };
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
              {
                sharedModules = [ spicetify-nix.homeManagerModules.default ];
              }
            else
              {
                sharedModules = [
                  plasma-manager.homeManagerModules.plasma-manager
                  spicetify-nix.homeManagerModules.default
                ];
              }
          );
      }
    ];
  }
