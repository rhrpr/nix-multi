{
  description = "NixOS VM Configuration for UTM";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      system = "aarch64-linux"; # For Apple Silicon, use "x86_64-linux" for Intel
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      nixosConfigurations.vm = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.nixos = import ./home.nix;
          }
        ];
      };

      # ISO generation for initial VM setup
      packages.${system}.iso = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
          {
            # Enable SSH for remote configuration
            services.openssh.enable = true;
            services.openssh.settings.PermitRootLogin = "yes";
            users.users.root.openssh.authorizedKeys.keys = [
              # Add your SSH public key here
            ];
          }
        ];
      };
    };
}