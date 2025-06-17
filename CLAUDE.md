# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Essential Commands

### Setup and Management
```bash
# One-command setup (auto-detects OS)
./nix-multi.sh setup

# Platform-specific setup
./nix-multi.sh setup-macos          # macOS with nix-darwin
./nix-multi.sh setup-linux          # Linux with NixOS + GPU passthrough

# Validate entire configuration
./nix-multi.sh validate

# Legacy rebuild (auto-detects platform)
./nix-rebuild.sh
```

### VM Operations
```bash
# VM management (recommended)
./nix-multi.sh vm-build             # Build NixOS Hyprland VM
./nix-multi.sh vm-run               # Run NixOS Hyprland VM
./nix-multi.sh vm-manage            # Interactive management

# Direct VM scripts
./vm-build.sh x86_64 build          # Build for Intel/AMD
./vm-build.sh aarch64 build         # Build for ARM64/Apple Silicon
./vm-build.sh run                   # Build and run
./vm-build.sh clean                 # Clean artifacts

# VM access
ssh hrpr@localhost -p 22000         # SSH into running VM (password: nixos)
```

### Testing and Validation
```bash
# Comprehensive testing
./validate-setup.sh                 # Test all configurations and functionality

# GPU testing (Linux only)
./nix-multi.sh gpu-test             # Test RTX 3080 partial passthrough
./scripts/rtx3080-setup.sh          # Full GPU validation
./scripts/rtx3080-setup.sh status   # Check GPU status
./scripts/rtx3080-setup.sh iommu    # Check IOMMU groups

# QEMU testing
./scripts/qemu-config.sh test x86_64     # Test QEMU availability
./scripts/qemu-config.sh config          # Show platform config
./scripts/qemu-config.sh opts x86_64 8G 4 3440x1440  # Generate QEMU options
```

### Development Environments
```bash
# Enter specialized development shells
nix develop .#flutter              # Flutter/Android development
nix develop .#python               # Python development
nix develop .#web                  # Web development (Node.js, TypeScript)
nix develop                        # Default shell with treefmt

# Code formatting
nix fmt                            # Format Nix files (nixfmt-rfc-style)
treefmt                            # Format all files
```

### Manual Nix Operations
```bash
# macOS rebuild commands
nix run nix-darwin -- switch --flake .#Ryans-MacBook-Pro    # First time
darwin-rebuild switch --flake .#Ryans-MacBook-Pro           # Subsequent

# Linux rebuild
sudo nixos-rebuild switch --flake .#nixos-plasma

# Direct VM builds
nix build .#vmImages.hyprland-vm-x86_64     # x86_64 VM image
nix build .#vmImages.hyprland-vm-aarch64    # ARM64 VM image
nix build .#vmImages.minimal-vm-aarch64     # Minimal ARM64 VM

# Flake operations
nix flake check                             # Validate flake structure
nix flake update                            # Update all inputs
```

## Architecture Overview

This is a sophisticated multi-platform Nix configuration supporting:

### Host Systems
- **macOS (nix-darwin)**: VM host with development environment, using Aerospace window manager
- **Linux (NixOS + Plasma)**: Native desktop with RTX 3080 partial GPU passthrough for VM/container sharing
- **Cross-platform VM tools**: QEMU configuration helpers and management scripts

### Guest Systems  
- **NixOS Hyprland VMs**: Full NixOS with Hyprland desktop, identical on both macOS and Linux hosts
- **Architecture support**: x86_64 (Intel/AMD) and aarch64 (ARM64/Apple Silicon)
- **GPU passthrough**: Only enabled on x86_64 Linux hosts for NVIDIA RTX 3080

### Module Organization
- **`modules/darwin/`**: macOS system configurations (apps, nix-core, system settings)
- **`modules/nixos/`**: Shared NixOS configurations (desktop, system, hardware)
- **`modules/vm/`**: VM-specific optimizations (guest tools, hardware config)
- **`modules/hosts/`**: Host-specific capabilities (GPU passthrough, VM management)
- **`modules/shared/`**: Cross-platform VM tools
- **`home/`**: Home Manager configurations with platform adaptations

### GPU Passthrough (Linux Only)
- **RTX 3080 partial passthrough**: Allows host desktop, VMs, and containers to share GPU dynamically
- **Automatic configuration**: PCI IDs, VFIO modules, NVIDIA drivers configured automatically
- **Multiple access modes**: Native gaming, container AI/ML workloads, VM Windows gaming

## Development Workflow

### Daily Development
1. **Make configuration changes** in appropriate modules
2. **Test changes**: `./nix-multi.sh validate`
3. **Apply changes**: `./nix-multi.sh setup` or `./nix-rebuild.sh`
4. **For development work**: `nix develop .#<language>`

### VM Development
1. **Build VM**: `./nix-multi.sh vm-build [arch]` (auto-detects: aarch64 on macOS, x86_64 on Linux)
2. **Test VM**: `./nix-multi.sh vm-run`
3. **Interactive management**: `./nix-multi.sh vm-manage`
4. **SSH access**: `ssh hrpr@localhost -p 22000`

### Platform-Specific VM Features
- **macOS (aarch64)**: Full NixOS Hyprland VM optimized for Apple Silicon
  - ⚠️ Note: Cross-compilation from macOS may require significant resources
  - Consider using UTM with pre-built images for faster setup
- **Linux (x86_64)**: Full NixOS Hyprland VM with NVIDIA GPU passthrough
  - ✅ Native compilation provides fastest build times
- **Both platforms**: Identical NixOS experience with Hyprland desktop environment

## Key Configuration Details

### User Configuration
- **Username**: `hrpr` (defined in flake.nix:70)
- **Email**: `ryan@hrpr.dev` (defined in flake.nix:71)

### Host Configurations
- **macOS**: `Ryans-MacBook-Pro` (aarch64-darwin)
- **Linux**: `nixos-plasma` (x86_64-linux)
- **VM**: `nixos-vm-hyprland` (x86_64-linux or aarch64-linux)

### VM Settings
- **Memory**: 6GB (macOS), 8GB (Linux)
- **CPU Cores**: 4 (both platforms)
- **Resolution**: 3440x1440 (ultrawide optimized)
- **SSH**: Port 22000 → 22 (password: nixos)

### GPU Configuration (RTX 3080)
- **Device ID**: 10de:2206 (GPU), 10de:1aef (Audio)
- **PCI Address**: 01:00 (bus address)
- **Partial passthrough**: Enabled for host/VM/container sharing

## Platform-Specific Notes

### macOS Host Features
- **Acceleration**: Hypervisor Framework (HVF)
- **Audio**: CoreAudio integration
- **Display**: Cocoa with OpenGL
- **VM Management**: QEMU-based with optimized settings

### Linux Host Features  
- **Acceleration**: KVM for near-native performance
- **Audio**: PipeWire/PulseAudio
- **Display**: GTK with OpenGL/Wayland
- **GPU Sharing**: Dynamic allocation between host/VMs/containers

## Troubleshooting

### Build Issues
1. **Check flake**: `nix flake check`
2. **Validate setup**: `./validate-setup.sh`
3. **Clean rebuild**: Remove `result` symlinks and rebuild

### VM Issues
1. **Test QEMU**: `./scripts/qemu-config.sh test x86_64`
2. **Check acceleration**: HVF (macOS) or KVM (Linux)
3. **Verify resources**: Ensure sufficient RAM/disk space

### GPU Issues (Linux)
1. **Test GPU setup**: `./scripts/rtx3080-setup.sh`
2. **Check IOMMU**: `./scripts/rtx3080-setup.sh iommu`
3. **Verify drivers**: NVIDIA (host) and VFIO (passthrough)