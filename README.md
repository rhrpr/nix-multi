# Nix Multi-Platform Configuration

A simplified, modular Nix configuration inspired by [mitchellh/nixos-config](https://github.com/mitchellh/nixos-config) that supports:

- **macOS hosts** (nix-darwin)
- **Linux hosts** (NixOS + Plasma) with GPU passthrough
- **NixOS VMs** (Hyprland desktop) that run on both platforms
- **Omarchy Gaming VMs** (Arch Linux with RTX 3080 passthrough, Linux only)

## Quick Start

```bash
# Setup system (auto-detects platform)
make setup

# UTM-based VM workflow (recommended for macOS)
make vm-setup    # Download NixOS ISO and show UTM setup instructions
make vm-deploy   # Deploy configuration to running VM via SSH

# Enter development environment
make dev
```

## Prerequisites

### Nix Installation

This configuration uses the **[Determinate Nix Installer](https://github.com/DeterminateSystems/nix-installer)** (not the standard Nix installer). Install it with:

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

> Determinate Nix ships with flakes and nix-command enabled by default, and provides a cleaner uninstall path than the standard installer.

### nix-darwin

This configuration uses the **community nix-darwin** (`github:lnl7/nix-darwin`), not the DeterminateSystems fork. It is pulled in as a flake input and does not need to be installed separately — the first-time setup command bootstraps it:

```bash
nix run nix-darwin -- switch --flake .#Ryans-MacBook-Pro
```

## Key Design

This configuration simplifies multi-platform Nix management by:

- **Centralized system builder** using `lib/mksystem.nix`
- **Machine-specific configs** instead of complex flake outputs
- **Makefile commands** replacing shell scripts
- **Cleaner user management** with platform separation
- **Agenix secrets** for encrypted SSH key management across machines
- **Standard Nix patterns** following community practices

## Manual Setup

### 1. macOS Configuration (VM Host)

```bash
# First time setup (requires nix-darwin)
nix run nix-darwin -- switch --flake .#Ryans-MacBook-Pro

# Subsequent updates
darwin-rebuild switch --flake .#Ryans-MacBook-Pro
```

### 2. Linux NixOS Configuration (GPU Passthrough Host)

```bash
# Build and switch to NixOS configuration with RTX 3080 support
sudo nixos-rebuild switch --flake .#nixos-plasma
```

### 3. VM Configuration (UTM — Recommended)

```bash
# Download ISO and show UTM setup instructions
make vm-setup

# Deploy Nix configuration to a running VM
make vm-deploy

# SSH into a running VM
make vm-ssh

# Check VM connectivity
make vm-status
```

For detailed VM management information, see [VM Management Guide](docs/VM-MANAGEMENT.md).

### 4. VM Configuration (Legacy — Cross-compilation)

```bash
# Build NixOS VM (may have cross-compilation issues on macOS)
make vm-build

# Build and run
make vm-run

# Test QEMU configuration
./scripts/qemu-config.sh test x86_64
./scripts/qemu-config.sh config

# Run built VM directly
./result/bin/run-nixos-vm
```

## Repository Structure

```text
nix-multi/
├── flake.nix              # Main flake configuration
├── nix-multi.sh           # Main setup and management script
├── nix-rebuild.sh         # Quick rebuild helper
├── validate-setup.sh      # Comprehensive setup validation
│
├── devshells/             # Development shell environments
│   ├── flutter.nix
│   ├── python.nix
│   ├── rust.nix
│   └── web.nix
│
├── docs/                  # Extended documentation
│   ├── VM-MANAGEMENT.md
│   ├── VM-STATUS.md
│   ├── SETUP-STATUS.md
│   ├── LIBVIRT-DYNAMIC-NETWORK.md
│   ├── LIBVIRT-NIX-MANAGEMENT.md
│   └── BIOS-TROUBLESHOOTING.md
│
├── home/                  # Home Manager configurations
│   ├── core.nix           # Core packages and settings
│   ├── git.nix            # Git configuration
│   ├── zsh.nix            # Zsh shell
│   ├── starship.nix       # Starship prompt
│   ├── tmux.nix           # Tmux config
│   ├── plasma.nix         # KDE Plasma config
│   ├── steam.nix          # Steam / gaming
│   ├── aerospace/         # Aerospace window manager (macOS)
│   ├── neovim/            # Neovim configuration
│   ├── shells/            # Shell configurations
│   ├── terminals/         # Terminal emulator configs
│   ├── linux/             # Linux-specific home config
│   └── macos/             # macOS-specific home config
│
├── machines/              # Machine-specific overrides
│   └── nixos-vm.nix
│
├── modules/               # System-level modules
│   ├── darwin/            # macOS nix-darwin modules
│   ├── nixos/             # NixOS modules (shared)
│   ├── vm/                # VM-specific modules
│   ├── shared/            # Cross-platform modules (secrets, vm-tools)
│   └── hosts/             # Host-specific modules
│       ├── linux/
│       │   ├── gpu-passthrough.nix    # RTX 3080 partial passthrough
│       │   └── vm-management.nix      # VM tools for Linux
│       └── macos/
│           ├── linux-builder.nix
│           └── vm-management.nix      # VM tools for macOS
│
├── scripts/               # Utility scripts
│   ├── vm-setup.sh        # UTM VM setup and deployment
│   ├── rtx3080-setup.sh   # RTX 3080 testing and validation
│   ├── qemu-config.sh     # QEMU configuration helper
│   ├── debug-sleep.sh     # Sleep/wake diagnostics
│   ├── manage-wake-sources.sh
│   ├── check-iommu-status.sh
│   ├── check-bios-issues.sh
│   ├── bluetooth-debug.sh
│   └── test-libvirt-network.sh
│
├── secrets/               # Agenix-encrypted secrets (safe to commit)
│   └── ssh-keys/          # SSH keys for all machines
│
└── vms/                   # VM definitions and scripts
    ├── utm-manager.nix    # UTM VM manager module
    ├── utm-scripts/       # UTM lifecycle scripts
    ├── nixos-vm/          # Standalone NixOS VM flake
    └── omarchy-vm/        # Omarchy gaming VM (Linux only)
```

## Configuration Overview

### Host Configurations

**macOS (nix-darwin)**:

- **Purpose**: VM host and development environment
- **Desktop**: Native macOS with Aerospace window manager
- **Package Management**: Nix + Homebrew integration
- **VM Support**: UTM/QEMU for creating NixOS VMs

**Linux (NixOS + Plasma)**:

- **Purpose**: GPU passthrough host and development environment
- **Desktop**: KDE Plasma with Wayland/X11
- **GPU**: RTX 3080 partial passthrough (host + VM sharing)
- **VM Support**: libvirt + KVM for high-performance VMs

### Guest Configurations

**NixOS Hyprland VM**:

- **Purpose**: Cross-platform NixOS guest
- **Desktop**: Hyprland (Wayland tiling compositor)
- **Optimization**: VM-specific performance tuning
- **GPU Support**: Passthrough capable (when run on Linux host)

**Omarchy Gaming VM** (Linux only):

- **Purpose**: Arch Linux gaming environment with RTX 3080
- **RAM / CPU**: 16 GB, 8 cores
- **GPU**: NVIDIA RTX 3080 partial passthrough
- **Display**: 3440x1440 ultrawide
- See [vms/omarchy-vm/README.md](vms/omarchy-vm/README.md) for full details

## Make Commands

### Setup

```bash
make setup          # Auto-detect platform and setup
make setup-macos    # macOS with nix-darwin
make setup-linux    # NixOS with nixos-rebuild
make setup-vm       # NixOS VM configuration
make apply-libvirt  # Apply libvirt host configuration
```

### VM (UTM — Recommended)

```bash
make vm-setup       # Download NixOS ISO and show UTM setup instructions
make vm-deploy      # Deploy configuration to running VM via SSH
make vm-ssh         # SSH into running VM
make vm-status      # Check VM connectivity and status
make vm-update      # Update VM configuration
make vm-download    # Download NixOS ISO only
make vm-clean       # Remove downloaded ISO files
```

### VM (Legacy)

```bash
make vm-build       # Build NixOS VM (may have cross-compilation issues)
make vm-build-x86   # Build x86_64 VM explicitly
make vm-build-arm   # Build ARM64 VM explicitly
make vm-run         # Build and run NixOS VM
```

### Omarchy Gaming VM (Linux only)

```bash
make omarchy-create     # Create Omarchy gaming VM with RTX 3080
make omarchy-start      # Start VM (GPU passthrough enabled)
make omarchy-stop       # Stop VM
make omarchy-status     # Check VM and GPU status
make omarchy-console    # Open virt-viewer console
make omarchy-gui        # Open virt-manager
make omarchy-test       # Test VM functionality
make omarchy-ultrawide  # Configure 3440x1440 resolution
make omarchy-gpu        # Manage GPU passthrough
```

### ISO Building

```bash
make iso-build      # Build NixOS ARM64 ISO for UTM
make iso-minimal    # Build minimal NixOS ARM64 ISO
```

### LibVirt Host Management

```bash
make libvirt-test   # Test dynamic network detection
make libvirt-apply  # Apply libvirt host config via NixOS rebuild
make libvirt-check  # Check current libvirt network status
```

### Development Shells

```bash
make dev            # Default development shell
make dev-flutter    # Flutter/Android development
make dev-python     # Python development
make dev-web        # Web development (Node.js, TypeScript)
make dev-rust       # Rust development
```

### Maintenance

```bash
make check          # Validate flake configuration
make update         # Update flake inputs
make clean          # Clean build artifacts
make fmt            # Format Nix files (nixfmt-rfc-style)
```

### Debugging

```bash
make debug-sleep    # Debug sleep/wake issues
make wake-sources   # Show ACPI wake sources
make wake-fix       # Apply recommended wake source settings
make gpu-check      # Check RTX 3080 GPU passthrough status
make bluetooth-debug # Debug Bluetooth connectivity
```

## Secret Management (Agenix)

SSH keys and other secrets are encrypted with [agenix](https://github.com/ryantm/agenix) and committed to git as `.age` files. Each machine decrypts its own secrets at activation time using a dedicated identity key.

See [secrets/README.md](secrets/README.md) for full details on the setup, bootstrap procedure, and how to add/edit secrets.

### Quick Reference

```bash
# Create a new encrypted secret
nix run github:ryantm/agenix -- -e secrets/ssh-keys/new-key.age

# Edit an existing secret
nix run github:ryantm/agenix -- -e secrets/ssh-keys/id_ed25519.age

# Decrypt and view a secret (debugging)
nix run github:ryantm/agenix -- -d secrets/ssh-keys/id_ed25519.age

# Re-encrypt all secrets for all machines (after adding a new machine key)
nix run github:ryantm/agenix -- -r
```

Secrets are placed at activation time:

- macOS: `~/.ssh/<keyname>` (via `modules/darwin/secrets.nix`)
- NixOS: `/home/hrpr/.ssh/<keyname>` (via `modules/nixos/secrets.nix`)

## RTX 3080 Partial GPU Passthrough

### What is Partial GPU Passthrough?

Unlike full passthrough (which dedicates the entire GPU to a VM), partial passthrough allows:

- Host keeps GPU access for desktop, gaming, development
- VMs can access GPU for Windows gaming, GPU compute
- Containers can use GPU for AI/ML workloads
- Dynamic sharing based on workload demands

### Hardware Configuration

- GPU: NVIDIA GA102 [GeForce RTX 3080 Lite Hash Rate] (01:00.0)
- Audio: NVIDIA GA102 High Definition Audio Controller (01:00.1)
- PCI IDs: `10de:2206` (GPU), `10de:1aef` (Audio)
- Driver: NVIDIA proprietary (host), VFIO (VM access)

### Setup

```bash
# Check current GPU and IOMMU status
./scripts/rtx3080-setup.sh
./scripts/rtx3080-setup.sh status
./scripts/rtx3080-setup.sh iommu
./scripts/rtx3080-setup.sh container

# Apply configuration (everything is automatic)
sudo nixos-rebuild switch --flake .#nixos-plasma
sudo reboot

# Verify after reboot
./scripts/rtx3080-setup.sh
make gpu-check
```

The configuration automatically handles NVIDIA drivers, VFIO modules, Docker NVIDIA runtime, IOMMU settings, and user permissions.

### GPU Sharing Usage

```bash
# Host usage
nvidia-smi
nvtop

# Container AI/ML workloads
docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi

# Omarchy gaming VM
make omarchy-create
make omarchy-start
```

## VM Features

### Cross-Platform Compatibility

- **Intel/AMD (x86_64)**: Full support on both macOS and Linux
- **Apple Silicon (aarch64)**: UTM/QEMU support on macOS
- **Performance**: Optimized virtio drivers and guest tools

### VM Optimizations

- SPICE guest agent for display integration
- Virtio drivers for better I/O performance
- Shared clipboard and file transfer
- Automatic resolution adjustment
- Optimized memory and CPU usage

### Quick VM Access

```bash
# SSH into running NixOS VM (default setup)
ssh hrpr@localhost -p 22000
# Default password: nixos (change after first login)
```

## Customization

### Adding Applications

**macOS (homebrew)**:

Edit `modules/darwin/system.nix` — add to `homebrew.brews` or `homebrew.casks`

**Linux/VM (nix)**:

Edit `modules/nixos/apps.nix` or `modules/vm/apps.nix` — add to `environment.systemPackages`

### Desktop Environment Changes

**Switching Linux Desktop**:

Modify `desktopManager` in `flake.nix` `linuxSpecialArgs`

**VM Desktop Customization**:

Edit `modules/vm/apps.nix` and Hyprland configs in `home/linux/hyprland.nix`

### User Configuration

1. Update username and email in `flake.nix`
2. Modify hostname in the respective configuration calls
3. Customize home-manager settings in `home/` directory

## Testing & Validation

```bash
# Comprehensive validation
./validate-setup.sh

# Flake structure
nix flake check

# GPU passthrough (Linux only)
./nix-multi.sh gpu-test
make gpu-check

# QEMU availability
./scripts/qemu-config.sh test x86_64
./scripts/qemu-config.sh config
```

## Learning Resources

- [NixOS & Flakes Book](https://github.com/ryan4yin/nixos-and-flakes-book) - Comprehensive Nix learning resource
- [NixOS Manual](https://nixos.org/manual/nixos/stable/) - Official NixOS documentation
- [Home Manager Manual](https://nix-community.github.io/home-manager/) - Home Manager configuration guide
- [Nix-Darwin](https://github.com/LnL7/nix-darwin) - macOS Nix configuration
- [Agenix](https://github.com/ryantm/agenix) - Secret management with age encryption

## License

This configuration is provided as-is for educational and personal use. Please review and understand all configurations before applying to your system.
