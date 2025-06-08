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
    
    # Configuration modes - all are available simultaneously
    # 1. "macos" - macOS with nix-darwin
    # 2. "linux-plasma" - NixOS with Plasma desktop (native Linux)
    # 3. "vm-hyprland" - NixOS Hyprland VM (runnable on both macOS and Linux)
    
    # Common special arguments for all configurations
    baseSpecialArgs = inputs // {
      inherit username useremail;
    };
    
    # VM-specific configuration
    vmSpecialArgs = baseSpecialArgs // {
      desktopManager = "hyprland";
      isVM = true;
    };
    
    # Regular Linux configuration  
    linuxSpecialArgs = baseSpecialArgs // {
      desktopManager = "plasma";
      isVM = false;
    };
    
    # macOS configuration
    macosSpecialArgs = baseSpecialArgs // {
      desktopManager = "none";
      isVM = false;
    };

    # Common home-manager configuration function
    mkHomeManagerConfig = system: extraSpecialArgs: {
      useGlobalPkgs = true;
      useUserPackages = true;
      extraSpecialArgs = extraSpecialArgs // {
        # Pass system information to avoid circular dependency
        isDarwin = system == "aarch64-darwin" || system == "x86_64-darwin";
        isLinux = system == "x86_64-linux" || system == "aarch64-linux";
      };
      users.${username} = import ./home;
      backupFileExtension = "backup";
    };

  in {
    # 1. macOS configuration with nix-darwin
    darwinConfigurations."Ryans-MacBook-Pro" = darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      specialArgs = macosSpecialArgs // { hostname = "Ryans-MacBook-Pro"; };
      modules = [
        ./modules/darwin/nix-core.nix
        ./modules/darwin/system.nix
        ./modules/darwin/host-users.nix
        ./modules/darwin/apps.nix
        ./modules/shared/vm-tools.nix  # VM tools for creating VMs on macOS
        home-manager.darwinModules.home-manager {
          home-manager = mkHomeManagerConfig "aarch64-darwin" macosSpecialArgs;
        }
      ];
    };

    # 2. NixOS configuration for native Linux with Plasma
    nixosConfigurations."nixos-plasma" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = linuxSpecialArgs // { hostname = "nixos-plasma"; };
      modules = [
        ./modules/nixos/hardware-configuration.nix
        ./modules/nixos/nix-core.nix
        ./modules/nixos/system.nix
        ./modules/nixos/host-users.nix
        ./modules/nixos/apps.nix
        ./modules/nixos/desktop.nix
        ./modules/shared/vm-tools.nix  # VM tools for creating VMs on Linux
        home-manager.nixosModules.home-manager {
          home-manager = (mkHomeManagerConfig "x86_64-linux" linuxSpecialArgs) // {
            sharedModules = [ plasma-manager.homeManagerModules.plasma-manager ];
          };
        }
      ];
    };

    # 3. NixOS VM configuration for Hyprland (runnable on both macOS and Linux)
    nixosConfigurations."nixos-vm-hyprland" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = vmSpecialArgs // { hostname = "nixos-vm-hyprland"; };
      modules = [
        ./modules/vm/hardware-configuration.nix  # VM-specific hardware config
        ./modules/nixos/nix-core.nix
        ./modules/vm/system.nix  # VM-specific system config
        ./modules/nixos/host-users.nix
        ./modules/vm/apps.nix    # VM-specific apps
        ./modules/nixos/desktop.nix
        ./modules/vm/vm-guest.nix  # VM guest utilities and optimizations
        home-manager.nixosModules.home-manager {
          home-manager = mkHomeManagerConfig "x86_64-linux" vmSpecialArgs;
        }
      ];
    };

    # 4. VM disk images for easy deployment
    vmImages = {
      # Build VM disk image for x86_64 systems (Intel Linux, macOS with QEMU)
      hyprland-vm-x86_64 = self.nixosConfigurations."nixos-vm-hyprland".config.system.build.vm;
      
      # Build VM disk image for aarch64 systems (Apple Silicon with UTM/QEMU)
      hyprland-vm-aarch64 = (nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        specialArgs = vmSpecialArgs // { hostname = "nixos-vm-hyprland-arm"; };
        modules = [
          ./modules/vm/hardware-configuration.nix
          ./modules/nixos/nix-core.nix  
          ./modules/vm/system.nix
          ./modules/nixos/host-users.nix
          ./modules/vm/apps.nix
          ./modules/nixos/desktop.nix
          ./modules/vm/vm-guest.nix
          home-manager.nixosModules.home-manager {
            home-manager = mkHomeManagerConfig "aarch64-linux" vmSpecialArgs;
          }
        ];
      }).config.system.build.vm;
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