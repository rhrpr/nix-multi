# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.

## Essential Commands

### Setup and Management
```bash
# One-command setup (auto-detects OS)
make setup

# Platform-specific setup  
make setup-macos                    # macOS with nix-darwin
make setup-linux                    # Linux with NixOS + GPU passthrough

# Validate entire configuration
make check

# Legacy scripts (still available)
./nix-multi.sh setup
./nix-rebuild.sh
```

### VM Operations (UTM-based - Recommended)
```bash
# New UTM-based workflow (no cross-compilation issues)
make vm-setup                       # Download NixOS ISO and show UTM setup instructions
make vm-deploy                      # Deploy configuration to running VM via SSH
make vm-ssh                         # SSH into running VM
make vm-status                      # Check VM connectivity and status
make vm-update                      # Update VM configuration

# Manual workflow with helper script
./scripts/vm-setup.sh setup         # Download ISO and show setup instructions
./scripts/vm-setup.sh deploy        # Deploy configuration
./scripts/vm-setup.sh ssh           # SSH to VM
./scripts/vm-setup.sh status        # Check VM status

# VM access
ssh hrpr@localhost -p 22000         # SSH into running VM (password: nixos)
```

### VM Operations (Legacy - Cross-compilation)
```bash
# Legacy VM building (may have cross-compilation issues on macOS)
make vm-build                       # Build NixOS Hyprland VM (auto-detects arch)
make vm-run                         # Build and run NixOS Hyprland VM
make vm-build-x86                   # Build x86_64 VM
make vm-build-arm                   # Build ARM64 VM

# ISO building
make iso-build                      # Build NixOS ARM64 ISO for UTM
make iso-minimal                    # Build minimal NixOS ISO
```

### Secret Management (Agenix)
```bash
# Create new encrypted secrets
nix run github:ryantm/agenix -- -e secrets/new-secret.age

# Edit existing secrets
nix run github:ryantm/agenix -- -e secrets/ssh-keys/id_ed25519.age

# Decrypt and view secrets (for debugging)
nix run github:ryantm/agenix -- -d secrets/ssh-keys/id_ed25519.age

# After system rebuild, encrypted secrets are automatically placed at configured paths
# Darwin: /Users/hrpr/.ssh/id_ed25519_agenix
# NixOS: /home/hrpr/.ssh/id_ed25519_agenix
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
make dev                           # Default development shell
make dev-flutter                   # Flutter/Android development
make dev-python                    # Python development
make dev-web                       # Web development (Node.js, TypeScript)

# Code formatting
make fmt                           # Format Nix files (nixfmt)
treefmt                            # Format all files (when in dev shell)

# Legacy commands (still available)
nix develop .#flutter
nix develop .#python
nix fmt
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
- **macOS (aarch64)**: Multiple virtualization options for Apple Silicon
  - 🚀 **UTM (Recommended)**: Native ARM64 NixOS ISOs with Hyprland
  - 🔧 **Linux Builder**: Cross-compilation using darwin.linux-builder
  - 📦 **Pre-built ISOs**: Available for both full and minimal configurations
- **Linux (x86_64)**: Full NixOS Hyprland VM with NVIDIA GPU passthrough
  - ✅ Native compilation provides fastest build times
  - 🎮 GPU passthrough for gaming and compute workloads
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