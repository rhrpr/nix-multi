{
  description = "Unified Nix configuration for macOS (nix-darwin) and Linux (NixOS) with desktop manager switching";

  nixConfig = {
    substituters = [ 
      "https://cache.nixos.org"
      "https://hyprland.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    # macOS support
    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Home Manager for dotfiles management
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # KDE Plasma configuration
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    # Hyprland support
    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Neovim configuration
    nvchad4nix = {
      url = "github:nix-community/nix4nvchad";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    primeagenInit = {
      url = "github:ThePrimeagen/init.lua";
      flake = false;
    };
  };

  outputs = inputs @ { 
    self, 
    nixpkgs, 
    home-manager, 
    darwin, 
    plasma-manager, 
    hyprland,
    nvchad4nix, 
    primeagenInit,
    ... 
  }:
  let
    # User configuration - customize these
    username = "hrpr";
    useremail = "ryan@hrpr.dev";
    
    # Common special arguments for all configurations
    baseSpecialArgs = inputs // {
      inherit username useremail;
      # Desktop manager selection (plasma/hyprland for Linux)
      desktopManager = "plasma"; # Change this to "hyprland" for Hyprland
    };

    # Common home-manager configuration function
    mkHomeManagerConfig = system: {
      useGlobalPkgs = true;
      useUserPackages = true;
      extraSpecialArgs = baseSpecialArgs // {
        # Pass system information to avoid circular dependency
        isDarwin = system == "aarch64-darwin" || system == "x86_64-darwin";
        isLinux = system == "x86_64-linux" || system == "aarch64-linux";
      };
      users.${username} = import ./home;
      backupFileExtension = "backup";
    };

  in {
    # macOS configuration
    darwinConfigurations."Ryans-MacBook-Pro" = darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      specialArgs = baseSpecialArgs // { hostname = "Ryans-MacBook-Pro"; };
      modules = [
        ./modules/darwin/nix-core.nix
        ./modules/darwin/system.nix
        ./modules/darwin/host-users.nix
        ./modules/darwin/apps.nix
        home-manager.darwinModules.home-manager {
          home-manager = mkHomeManagerConfig "aarch64-darwin";
        }
      ];
    };

    # NixOS configuration
    nixosConfigurations."nixos" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = baseSpecialArgs // { hostname = "nixos"; };
      modules = [
        ./modules/nixos/hardware-configuration.nix
        ./modules/nixos/nix-core.nix
        ./modules/nixos/system.nix
        ./modules/nixos/host-users.nix
        ./modules/nixos/apps.nix
        ./modules/nixos/desktop.nix
        home-manager.nixosModules.home-manager {
          home-manager = (mkHomeManagerConfig "x86_64-linux") // {
            sharedModules = [ plasma-manager.homeManagerModules.plasma-manager ];
          };
        }
      ];
    };

    # Development shells and formatting
    devShells = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-darwin" ] (system:
      let pkgs = nixpkgs.legacyPackages.${system}; in
      pkgs.mkShell {
        buildInputs = with pkgs; [
          nixfmt-rfc-style
          nil
          statix
        ];
      }
    );

    # Formatter for `nix fmt`
    formatter = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-darwin" ] (system:
      nixpkgs.legacyPackages.${system}.nixfmt-rfc-style
    );
  };
}