# macOS Linux Builder Module
# Enables building Linux packages/systems on macOS using Nix's linux-builder
{
  pkgs,
  lib,
  config,
  username,
  ...
}:

{
  # Enable the Linux builder for cross-compilation
  nix = {
    # Enable the built-in Linux builder
    linux-builder = {
      enable = true;
      maxJobs = 4;
      config = {
        virtualisation = {
          darwin-builder = {
            diskSize = 30 * 1024; # 30GB
            memorySize = 6 * 1024; # 6GB
          };
          cores = 4;
        };
      };
    };

    # Configure distributed builds to use the Linux builder
    distributedBuilds = true;
    buildMachines = [
      {
        hostName = "linux-builder";
        systems = [
          "x86_64-linux"
          "aarch64-linux"
        ];
        maxJobs = 4;
        speedFactor = 1;
        supportedFeatures = [
          "nixos-test"
          "benchmark"
          "big-parallel"
          "kvm"
        ];
        mandatoryFeatures = [ ];
        sshUser = "builder";
        # Let nix handle SSH key automatically for now
        protocol = "ssh-ng";
      }
    ];

    # Trust the Linux builder for remote builds
    settings = {
      trusted-users = [
        "@admin"
        username
      ];
      # Enable building for different architectures
      extra-platforms = [
        "x86_64-linux"
        "aarch64-linux"
      ];
    };
  };

  # Environment variables for build optimization
  environment.variables = {
    # Point to the Linux builder for cross-compilation
    NIX_LINUX_BUILDER = "linux-builder";

    # Optimize build process
    NIX_BUILD_CORES = "6";
    NIX_MAX_JOBS = "4";

    # Enable verbose builds for debugging
    NIX_DEBUG = "0"; # Set to 1 for debug output
  };

  # Shell aliases for Linux builder management
  environment.shellAliases = {
    # Build Linux packages/systems
    build-linux = "nix build --system x86_64-linux";
    build-arm64 = "nix build --system aarch64-linux";

    # Build specific VM images
    build-nixos-vm = "nix build .#vmImages.hyprland-vm-x86_64";
    build-nixos-vm-arm = "nix build .#vmImages.hyprland-vm-aarch64";
    build-nixos-iso = "nix build .#isoImages.nixos-hyprland-aarch64";

    # Builder management
    linux-builder-status = "nix show-config | grep linux-builder";
    linux-builder-test = "nix build --system x86_64-linux nixpkgs#hello";
  };
}
