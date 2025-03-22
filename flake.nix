{
  description = "Nix for macOS configuration";

  nixConfig = {
    substituters = [ "https://cache.nixos.org" ];
  };

  inputs = {
    # Use a consistent name for nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ { self, nixpkgs, darwin, home-manager, ... }: 
    let
      # User configuration
      username = "hrpr";
      useremail = "ryan@hrpr.dev";
      system = "aarch64-darwin";
      hostname = "Ryans-MacBook-Pro";

      # Additional arguments to pass to modules
      specialArgs = inputs // { inherit username useremail hostname; };
    in {
      darwinConfigurations.${hostname} = darwin.lib.darwinSystem {
        inherit system specialArgs;
        modules = [
          ./modules/nix-core.nix
          ./modules/system.nix
          ./modules/apps.nix
          ./modules/host-users.nix

          home-manager.darwinModules.home-manager {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = specialArgs;
              users.${username} = import ./home;
              backupFileExtension = "backup";
            };
          }
        ];
      };

      formatter.${system} = nixpkgs.legacyPackages.${system}.alejandra;
    };
}
