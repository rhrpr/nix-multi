{
  description = "Unified Nix configuration for macOS (nix-darwin) and Linux (NixOS) with GPU passthrough and VM support";

  nixConfig = {
    substituters = [ 
      "https://cache.nixos.org"
      "https://hyprland.cachix.org"
      "https://nix-community.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
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
    
    # System types
    # - "macos" - macOS with nix-darwin (VM host)
    # - "linux-plasma" - NixOS with Plasma desktop + RTX 3080 partial passthrough (VM host)
    # - "vm-hyprland" - NixOS Hyprland VM (guest system)
    
    # GPU configuration (customize for your hardware)
    gpuConfig = {
      vendor = "nvidia";          # nvidia or amd
      deviceId = "10de:2206";     # RTX 3080 GPU PCI ID
      audioId = "10de:1aef";      # RTX 3080 Audio PCI ID
      pciAddress = "01:00";       # PCI bus address (without function)
      enablePartialPassthrough = true;  # Enable sharing between host and VMs
    };
    
    # Common special arguments for all configurations
    baseSpecialArgs = inputs // {
      inherit username useremail gpuConfig;
    };
    
    # VM-specific configuration (guest system)
    vmSpecialArgs = baseSpecialArgs // {
      desktopManager = "hyprland";
      isVM = true;
      hostType = "guest";
    };
    
    # Linux host configuration (with GPU passthrough capability)
    linuxSpecialArgs = baseSpecialArgs // {
      desktopManager = "plasma";
      isVM = false;
      hostType = "linux-host";
    };
    
    # macOS host configuration (VM creation only)
    macosSpecialArgs = baseSpecialArgs // {
      desktopManager = "none";
      isVM = false;
      hostType = "macos-host";
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
    # 1. macOS host configuration (VM creation and management)
    darwinConfigurations."Ryans-MacBook-Pro" = darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      specialArgs = macosSpecialArgs // { hostname = "Ryans-MacBook-Pro"; };
      modules = [
        # Configure nixpkgs to allow unfree packages
        {
          nixpkgs.config.allowUnfree = true;
        }
        ./modules/darwin/nix-core.nix
        ./modules/darwin/system.nix
        ./modules/darwin/host-users.nix
        ./modules/darwin/apps.nix
        ./modules/hosts/macos/vm-management.nix  # VM creation tools for macOS
        ./modules/shared/vm-tools.nix           # Cross-platform VM tools
        home-manager.darwinModules.home-manager {
          home-manager = mkHomeManagerConfig "aarch64-darwin" macosSpecialArgs;
        }
      ];
    };

    # 2. Linux host configuration with RTX 3080 partial GPU passthrough
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
        ./modules/hosts/linux/gpu-passthrough.nix  # RTX 3080 partial passthrough
        ./modules/hosts/linux/vm-management.nix    # VM management on Linux
        ./modules/shared/vm-tools.nix              # Cross-platform VM tools
        home-manager.nixosModules.home-manager {
          home-manager = (mkHomeManagerConfig "x86_64-linux" linuxSpecialArgs) // {
            sharedModules = [ plasma-manager.homeManagerModules.plasma-manager ];
          };
        }
      ];
    };

    # 3. Hyprland VM guest configuration (runs on both macOS and Linux hosts)
    nixosConfigurations."nixos-vm-hyprland" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = vmSpecialArgs // { hostname = "nixos-vm-hyprland"; };
      modules = [
        ./modules/vm/hardware-configuration.nix  # VM-optimized hardware config
        ./modules/nixos/nix-core.nix
        ./modules/vm/system.nix                  # VM-specific system config
        ./modules/nixos/host-users.nix
        ./modules/vm/apps.nix                    # VM-optimized apps
        ./modules/nixos/desktop.nix              # Hyprland desktop environment
        ./modules/vm/vm-guest.nix                # Guest additions and optimizations
        ./modules/vm/gpu-guest.nix               # GPU passthrough guest configuration
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
      
      # Minimal ARM64 VM optimized for Apple Silicon and UTM
      minimal-vm-aarch64 = (nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        specialArgs = vmSpecialArgs // { hostname = "nixos-minimal-arm"; };
        modules = [
          ./modules/vm/minimal-arm64.nix
          ./modules/vm/hardware-configuration.nix
          ./modules/nixos/nix-core.nix
        ];
      }).config.system.build.vm;
    };

    # Add all the devshells with treefmt support
    devShells = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-darwin" ] (system:
      let
      pkgs = nixpkgs.legacyPackages.${system};
      treefmtWrapper = pkgs.treefmt;
      in {
      default = pkgs.mkShell {
        packages = [
        treefmtWrapper
        ];
      };

      flutter = import ./devshells/flutter.nix {
        inherit pkgs;
        inherit treefmtWrapper;
      };

      web = import ./devshells/web.nix {
        inherit pkgs;
        inherit treefmtWrapper;
      };

      python = import ./devshells/python.nix {
        inherit pkgs;
        inherit treefmtWrapper;
      };
      }
    );

    # Formatter for `nix fmt`
    formatter = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-darwin" ] (system:
      nixpkgs.legacyPackages.${system}.nixfmt-rfc-style
    );
  };
}