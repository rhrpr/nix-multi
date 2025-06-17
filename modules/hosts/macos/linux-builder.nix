# macOS Linux Builder Module
# Enables building Linux packages/systems on macOS using Nix's linux-builder
{ pkgs, lib, config, username, ... }:

{
  # Enable the Linux builder for cross-compilation
  nix = {
    # Enable the built-in Linux builder
    linux-builder = {
      enable = true;
      
      # Customize VM resources for better performance
      maxJobs = 4;
      
      config = {
        virtualisation = {
          darwin-builder = {
            # Allocate more disk space for builds (40GB)
            diskSize = 40 * 1024;
            # Allocate more memory for builds (8GB)
            memorySize = 8 * 1024;
          };
          # Use more CPU cores for parallel builds
          cores = 6;
        };
        
        # Enable additional features for development
        nix.settings = {
          # Enable experimental features
          experimental-features = [ "nix-command" "flakes" ];
          # Use more build jobs for parallel compilation
          max-jobs = 6;
          # Enable sandbox for reproducible builds
          sandbox = true;
        };
      };
    };

    # Trust the Linux builder for remote builds
    settings = {
      trusted-users = [ "@admin" username ];
      # Enable building for different architectures
      extra-platforms = [ "x86_64-linux" "aarch64-linux" ];
      # Use binary caches for faster builds
      substituters = [
        "https://cache.nixos.org"
        "https://hyprland.cachix.org"
        "https://nix-community.cachix.org"
      ];
    };

    # Configure distributed builds to use the Linux builder
    distributedBuilds = true;
    buildMachines = [{
      hostName = "linux-builder";
      system = "x86_64-linux";
      protocol = "ssh-ng";
      maxJobs = 4;
      speedFactor = 1;
      supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
      mandatoryFeatures = [ ];
    }];
  };

  # Environment variables for build optimization
  environment.variables = {
    # Point to the Linux builder for cross-compilation
    NIX_LINUX_BUILDER = "linux-builder";
    
    # Optimize build process
    NIX_BUILD_CORES = "6";
    NIX_MAX_JOBS = "4";
    
    # Enable verbose builds for debugging
    NIX_DEBUG = "0";  # Set to 1 for debug output
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