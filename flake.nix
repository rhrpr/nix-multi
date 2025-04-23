{
  description = "Nix for macOS and Linux configuration";

  nixConfig = {
    substituters = [ "https://cache.nixos.org" ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
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

outputs = inputs @ { self, nixpkgs, darwin ? null, home-manager, nvchad4nix, ... }:
  let
    # Define systems to support
    supportedSystems = [ "x86_64-linux" "aarch64-darwin" ];
    
    # Helper function to generate outputs for each system
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    
    # Determine if the current system is Darwin (macOS)
    isDarwin = system: builtins.match ".*-darwin" system != null;

    username = "hrpr";
    useremail = "ryan@hrpr.dev";
    system = builtins.currentSystem;
    hostname = if system == "aarch64-darwin" then "Ryans-MacBook-Pro" 
               else if system == "x86_64-linux" then "nixos" 
               else "default-hostname";

    specialArgs = inputs // { inherit username useremail hostname; };
  in
  {
    # Darwin configurations (macOS)
    darwinConfigurations = nixpkgs.lib.optionalAttrs (isDarwin system && darwin != null) {
      ${hostname} = darwin.lib.darwinSystem {
        inherit system specialArgs;
        modules = [
          ./modules/darwin/nix-core.nix
          ./modules/darwin/system.nix
          ./modules/darwin/host-users.nix
          ./modules/darwin/apps.nix

          home-manager.darwinModules.home-manager {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = specialArgs;
              users.${username} = import ./home.nix;
              backupFileExtension = "backup";
            };
          }
        ];
      };
    };

    # NixOS configurations (Linux)
    nixosConfigurations = nixpkgs.lib.optionalAttrs (!isDarwin system) {
      ${hostname} = nixpkgs.lib.nixosSystem {
        inherit system specialArgs;
        modules = [
          ./modules/nixos/hardware-configuration.nix
          ./modules/nixos/system.nix
          ./modules/nixos/host-users.nix
          ./modules/nixos/apps.nix

          home-manager.nixosModules.home-manager {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = specialArgs;
              users.${username} = import ./home.nix;
              backupFileExtension = "backup";
            };
          }
        ];
      };
    };
  };
}