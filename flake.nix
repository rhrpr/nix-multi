{
  description = "Nix for macOS configuration";

  nixConfig = {
    substituters = [ "https://cache.nixos.org" ];
  };

  inputs = {
    # Use a consistent name for nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";
    treefmt-nix.url = "github:numtide/treefmt-nix";

    nix-darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Add nix4nvchad as an input
    nvchad4nix = {
      url = "github:nix-community/nix4nvchad";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    primeagenInit = {
      url = "github:ThePrimeagen/init.lua";
      flake = false; # because it's not a flake repo
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nix-darwin,
      home-manager,
      nvchad4nix,
      treefmt-nix,
      ...
    }:
    let
      # User configuration
      username = "hrpr";
      useremail = "ryan@hrpr.dev";
      system = "aarch64-darwin";
      hostname = "Ryans-MacBook-Pro";

      # Initialize pkgs properly
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true; # Optional, if you need unfree packages
      };

      # Additional arguments to pass to modules
      specialArgs = inputs // {
        inherit username useremail hostname;
      };

      # Setup treefmt-nix with the properly instantiated pkgs
      treefmtEval = treefmt-nix.lib.evalModule pkgs {
        projectRootFile = "flake.nix";
        programs.nixfmt.enable = true;
        programs.nixfmt.package = pkgs.nixfmt-rfc-style;
      };
    in
    {
      darwinConfigurations.${hostname} = nix-darwin.lib.darwinSystem {
        inherit system specialArgs;
        modules = [
          ./modules/nix-core.nix
          ./modules/system.nix
          ./modules/apps.nix
          ./modules/host-users.nix

          home-manager.darwinModules.home-manager
          {
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

      # Updated formatter configuration using treefmt-nix
      formatter.${system} = treefmtEval.config.build.wrapper;
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-rfc-style;

      # Add checks
      checks.${system}.formatting = treefmtEval.config.build.check self;

      # Add a devShell with treefmt
      devShells.${system}.default = pkgs.mkShell {
        packages = [
          treefmtEval.config.build.wrapper
        ];
      };
    };
}
