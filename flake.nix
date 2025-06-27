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

    flake-utils.url = "github:numtide/flake-utils";
    treefmt-nix.url = "github:numtide/treefmt-nix";

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
      flake = false; # because it's not a flake repo
    };

    # Secret management
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.darwin.follows = "darwin";
    };
  };

  outputs = inputs @ { self, nixpkgs, agenix, darwin, treefmt-nix, flake-utils, ... }:
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

    # Setup treefmt-nix for both systems
    systems = [ "aarch64-darwin" "x86_64-linux" ];
    
    # Helper to create treefmt config for a system
    mkTreefmt = system: 
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            android_sdk.accept_license = true;
          };
        };
      in
      treefmt-nix.lib.evalModule pkgs {
        projectRootFile = "flake.nix";
        programs.nixfmt.enable = true;
        programs.nixfmt.package = pkgs.nixfmt-rfc-style;
      };

  in 
  flake-utils.lib.eachSystem systems (system:
    let
      treefmtEval = mkTreefmt system;
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          android_sdk.accept_license = true;
        };
      };
    in
    {
      # Formatters
      formatter = treefmtEval.config.build.wrapper;
      
      # Checks
      checks.formatting = treefmtEval.config.build.check self;

      # Dev shells
      devShells = {
        default = pkgs.mkShell {
          packages = [ treefmtEval.config.build.wrapper ];
        };
        
        flutter = import ./devshells/flutter.nix { 
          inherit pkgs; 
          treefmtWrapper = treefmtEval.config.build.wrapper;
        };
        
        web = import ./devshells/web.nix { 
          inherit pkgs; 
          treefmtWrapper = treefmtEval.config.build.wrapper;
        };
        
        python = import ./devshells/python.nix { 
          inherit pkgs; 
          treefmtWrapper = treefmtEval.config.build.wrapper;
        };
      };

      # Packages
      packages = {
        vm-tools = pkgs.symlinkJoin {
          name = "vm-tools";
          paths = with pkgs; [
            qemu
            qemu-utils
            socat
            netcat
          ] ++ lib.optionals pkgs.stdenv.isLinux [
            qemu_kvm
            libvirt
          ];
        };
      };
    }) //
  {
    # macOS host (VM creation and management)
    darwinConfigurations."macbook-pro" = mkSystem {
      name = "macbook-pro";
      system = "aarch64-darwin";
      inherit user;
      isDarwin = true;
    };

    # Linux desktop host with GPU passthrough
    nixosConfigurations."nixos-desktop" = mkSystem {
      name = "nixos-desktop";
      system = "x86_64-linux";
      inherit user;
    };

    # NixOS VM guests
    nixosConfigurations."vm" = mkSystem {
      name = "nixos-vm";
      system = "x86_64-linux";
      inherit user;
      vm = true;
    };
  };
}
