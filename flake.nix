{
  description = "Nix for macOS and Linux configuration";

  nixConfig = {
    substituters = [ "https://cache.nixos.org" ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    nvchad4nix = {
      url = "github:nix-community/nix4nvchad";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    primeagenInit = {
      url = "github:ThePrimeagen/init.lua";
      flake = false;
    };
  };

outputs = inputs @ { self, nixpkgs, home-manager, darwin ? null, plasma-manager ? null, nvchad4nix, primeagenInit ... }:
  let
    # Define systems to support
    supportedSystems = [ "x86_64-linux" "aarch64-darwin" ];
    
    # Get current system or default to x86_64-linux if not available
    system = builtins.currentSystem or "x86_64-linux";

    # Determine if the current system is Darwin (macOS)
    isDarwin = builtins.match ".*-darwin" system != null;

    # User configuration
    username = "hrpr";
    useremail = "ryan@hrpr.dev";
    
    # Set hostname based on system
    hostname = if system == "aarch64-darwin" then "Ryans-MacBook-Pro" 
               else if system == "x86_64-linux" then "nixos" 
               else "default-hostname";

    # Common special arguments to pass to all configurations
    specialArgs = inputs // { inherit username useremail hostname; };

    # Define home-manager configurations
    homeManagerCommonConfig = {
      useGlobalPkgs = true;
      useUserPackages = true;
      extraSpecialArgs = specialArgs;
      users.${username} = import ./home;
      backupFileExtension = "backup";
    };
    
    # Define module paths for each system type
    darwinModules = [
      ./modules/darwin/nix-core.nix
      ./modules/darwin/system.nix
      ./modules/darwin/host-users.nix
      ./modules/darwin/apps.nix
      home-manager.darwinModules.home-manager {
        home-manager = homeManagerCommonConfig // {
          # Darwin-specific home-manager settings
        };
      }
    ];
    
    nixosModules = [
      ./modules/nixos/hardware-configuration.nix
      ./modules/nixos/nix-core.nix
      ./modules/nixos/system.nix
      ./modules/nixos/host-users.nix
      ./modules/nixos/apps.nix
      home-manager.nixosModules.home-manager {
        home-manager = homeManagerCommonConfig // {
          # NixOS-specific home-manager settings
        };
      }
    ];

  in
  {
    # Darwin configurations (macOS)
    darwinConfigurations = if isDarwin && darwin != null then {
      ${hostname} = darwin.lib.darwinSystem {
        inherit system specialArgs;
        modules = darwinModules;
      };
    } else {};

    # NixOS configurations (Linux)
    nixosConfigurations = if !isDarwin then {
      ${hostname} = nixpkgs.lib.nixosSystem {
        inherit system specialArgs;
        modules = nixosModules;
      };
    } else {};
  };
}