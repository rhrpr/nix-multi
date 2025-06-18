{
  description = "Unified Nix configuration for macOS and Linux with VM support";

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

    hyprland = {
      url = "github:hyprwm/Hyprland";
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

    # Secret management
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.darwin.follows = "darwin";
    };
  };

  outputs = inputs @ { self, nixpkgs, agenix, ... }:
  let
    # Import system builder
    mkSystem = import ./lib/mksystem.nix inputs;
    
    # User configuration
    user = {
      name = "hrpr";
      email = "ryan@hrpr.dev";
      gpuConfig = {
        vendor = "nvidia";
        deviceId = "10de:2206";
        audioId = "10de:1aef";
        pciAddress = "01:00";
        enablePartialPassthrough = true;
      };
    };

  in {
    # macOS host (VM creation and management)
    darwinConfigurations."Ryans-MacBook-Pro" = mkSystem {
      name = "macbook-pro";
      system = "aarch64-darwin";
      inherit user;
      isDarwin = true;
    };

    # Linux desktop host with GPU passthrough
    nixosConfigurations."nixos-plasma" = mkSystem {
      name = "nixos-desktop";
      system = "x86_64-linux";
      inherit user;
    };

    # NixOS VM guests
    nixosConfigurations."nixos-vm-hyprland" = mkSystem {
      name = "nixos-vm";
      system = "x86_64-linux";
      inherit user;
      vm = true;
    };

    nixosConfigurations."nixos-vm-hyprland-arm" = mkSystem {
      name = "nixos-vm";
      system = "aarch64-linux";
      inherit user;
      vm = true;
    };

    # VM images for direct building
    vmImages = {
      hyprland-vm-x86_64 = self.nixosConfigurations."nixos-vm-hyprland".config.system.build.vm;
      hyprland-vm-aarch64 = self.nixosConfigurations."nixos-vm-hyprland-arm".config.system.build.vm;
    };

    # ISO images for UTM and other platforms
    isoImages = {
      nixos-hyprland-aarch64 = (nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        specialArgs = {
          username = user.name;
          hostname = "nixos-hyprland-live";
          isVM = true;
        };
        modules = [
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-gnome.nix"
          ./modules/vm/iso-arm64.nix
          ./modules/nixos/nix-core.nix
          ./modules/nixos/host-users.nix
          ./modules/nixos/desktop.nix
        ];
      }).config.system.build.isoImage;

      nixos-minimal-aarch64 = (nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        specialArgs = {
          username = user.name;
          hostname = "nixos-minimal-live";
          isVM = true;
        };
        modules = [
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
          ./modules/vm/iso-minimal-arm64.nix
          ./modules/nixos/nix-core.nix
        ];
      }).config.system.build.isoImage;
    };

    # Development shells
    devShells = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-darwin" ] (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            android_sdk.accept_license = true;
          };
        };
        treefmtWrapper = pkgs.treefmt;
      in {
        default = pkgs.mkShell {
          packages = [ treefmtWrapper ];
        };

        flutter = import ./devshells/flutter.nix {
          inherit pkgs treefmtWrapper;
        };

        web = import ./devshells/web.nix {
          inherit pkgs treefmtWrapper;
        };

        python = import ./devshells/python.nix {
          inherit pkgs treefmtWrapper;
        };
      }
    );

    # Formatter
    formatter = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-darwin" ] (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      in
        pkgs.nixfmt-rfc-style
    );
  };
}