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
    
    # System-specific configurations
    systems = {
      "aarch64-darwin" = {
        hostname = "Ryans-MacBook-Pro";
        isDarwin = true;
      };
      "x86_64-linux" = {
        hostname = "nixos";
        isDarwin = false;
      };
    };

    # Helper function to create system configurations
    mkSystem = system: config:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        systemConfig = systems.${system};
        
        # Common special arguments for all configurations
        specialArgs = inputs // {
          inherit username useremail;
          inherit (systemConfig) hostname;
          # Desktop manager selection (plasma/hyprland for Linux)
          desktopManager = "plasma"; # Change this to "hyprland" for Hyprland
        };

        # Common home-manager configuration
        homeManagerConfig = {
          useGlobalPkgs = true;
          useUserPackages = true;
          extraSpecialArgs = specialArgs;
          users.${username} = import ./home;
          backupFileExtension = "backup";
        };

      in {
        inherit system specialArgs;
        modules = if systemConfig.isDarwin then [
          # macOS modules
          ./modules/darwin/nix-core.nix
          ./modules/darwin/system.nix
          ./modules/darwin/host-users.nix
          ./modules/darwin/apps.nix
          home-manager.darwinModules.home-manager {
            home-manager = homeManagerConfig;
          }
        ] else [
          # Linux modules
          ./modules/nixos/hardware-configuration.nix
          ./modules/nixos/nix-core.nix
          ./modules/nixos/system.nix
          ./modules/nixos/host-users.nix
          ./modules/nixos/apps.nix
          ./modules/nixos/desktop.nix
          home-manager.nixosModules.home-manager {
            home-manager = homeManagerConfig // {
              sharedModules = [ plasma-manager.homeManagerModules.plasma-manager ];
            };
          }
        ];
      };

    # Generate configurations for all supported systems
    darwinConfigurations = nixpkgs.lib.mapAttrs (system: config:
      if config.isDarwin then
        darwin.lib.darwinSystem (mkSystem system config)
      else null
    ) systems;

    nixosConfigurations = nixpkgs.lib.mapAttrs (system: config:
      if !config.isDarwin then
        nixpkgs.lib.nixosSystem (mkSystem system config)
      else null
    ) systems;

  in {
    # Filter out null configurations
    darwinConfigurations = nixpkgs.lib.filterAttrs (_: v: v != null) darwinConfigurations;
    nixosConfigurations = nixpkgs.lib.filterAttrs (_: v: v != null) nixosConfigurations;

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