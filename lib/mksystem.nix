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
  hermes-agent,
  spicetify-nix,
  dots-hyprland,
  omarchy, # upstream omacom/omarchy dotfiles (flake = false)
  omarchy-nix,
  ...
}:

{
  name,
  system,
  user,
  machine ? name,
  isDarwin ? false,
  vm ? false,
  hardwareModule ? null,
  desktopManager ? null, # "end4" | "omarchy" | "plasma"; null = auto-detect
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
  homeModules = user.homeModules or [ ];
  systemSettings = user.systemSettings or { };
  userSettings = user.userSettings or { };

  # Common special arguments for all configurations
  # Resolve desktop manager: explicit param wins, otherwise auto-detect
  resolvedDesktopManager =
    if desktopManager != null then
      desktopManager
    else if isVM then
      "omarchy"
    else if isDarwin then
      "none"
    else
      "omarchy"; # default Linux desktop to Omarchy

  isOmarchy = resolvedDesktopManager == "omarchy";
  supportsSpicetify = system != "aarch64-linux";

  specialArgs = {
    inherit
      username
      useremail
      gpuConfig
      homeModules
      systemSettings
      userSettings
      supportsSpicetify
      ;
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
      hermes-agent
      spicetify-nix
      dots-hyprland
      omarchy
      omarchy-nix
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
    users.${username} = import ../home;
    backupFileExtension = "backup";
  };

in
assert nixpkgs.lib.assertMsg (builtins.elem resolvedDesktopManager [
  "none"
  "end4"
  "hyprland"
  "omarchy"
  "plasma"
]) "Unknown desktopManager: ${resolvedDesktopManager}. Choose end4, omarchy, or plasma.";
if isDarwin then
  # macOS system using nix-darwin
  darwin.lib.darwinSystem {
    inherit system;
    specialArgs = specialArgs;
    modules = [
      { nixpkgs.config.allowUnfree = true; }
      ../machines/${machine}.nix
      ../modules/darwin/user.nix
      home-manager.darwinModules.home-manager
      nix-openclaw.darwinModules.openclaw
      {
        home-manager = (mkHomeManagerConfig { }) // {
          sharedModules = nixpkgs.lib.optional supportsSpicetify spicetify-nix.homeManagerModules.default;
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
      ../machines/${machine}.nix
      ../modules/shared/user.nix
    ]
    ++ nixpkgs.lib.optional (hardwareModule != null) hardwareModule
    ++ nixpkgs.lib.optionals isOmarchy [
      omarchy-nix.nixosModules.default
      ../modules/nixos/omarchy.nix
    ]
    ++ [
      home-manager.nixosModules.home-manager
      {
        home-manager = (mkHomeManagerConfig { }) // {
          sharedModules =
            nixpkgs.lib.optional supportsSpicetify spicetify-nix.homeManagerModules.default
            ++ nixpkgs.lib.optionals (resolvedDesktopManager == "plasma") [
              plasma-manager.homeManagerModules.plasma-manager
            ]
            ++ nixpkgs.lib.optionals isOmarchy [
              omarchy-nix.homeManagerModules.default
              { omarchy.enable = true; }
            ];
        };
      }
    ];
  }
