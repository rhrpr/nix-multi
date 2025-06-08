# Nix-Multi: Unified Nix Configuration

A comprehensive Nix configuration that supports:

- **macOS hosts** with nix-darwin (VM creation and management)
- **Linux hosts** with NixOS + Plasma + RTX 3080 partial GPU passthrough  
- **Hyprland VMs** that run on both macOS and Linux hosts with shared userland configuration

## 🚀 Quick Start

### Prerequisites

- [Nix package manager](https://nixos.org/download.html) installed
- [Flakes enabled](https://nixos.wiki/wiki/Flakes#Enable_flakes) in your Nix configuration

### One-Command Setup

```bash
# Auto-setup for your current OS
./nix-multi.sh setup

# Or OS-specific setup  
./nix-multi.sh setup-macos              # macOS with nix-darwin
./nix-multi.sh setup-linux              # Linux with NixOS + GPU passthrough
```

### VM Quick Start

```bash
./nix-multi.sh vm-build                 # Build Hyprland VM
./nix-multi.sh vm-run                   # Run VM  
./nix-multi.sh vm-manage                # Interactive management
./nix-multi.sh validate                 # Test entire setup
```

## 📋 Manual Setup (Advanced)

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

### 3. VM Configuration (Hyprland Guest)

```bash
# Interactive VM manager (recommended)
./vm-manager.sh

# Or direct commands
./vm-build.sh build    # Build VM for current architecture
./vm-build.sh run      # Build and run VM
./vm-build.sh clean    # Clean build artifacts

# Specific architecture
./vm-build.sh x86_64 build   # For Intel/AMD systems
./vm-build.sh aarch64 build  # For ARM64/Apple Silicon

# Run built VM directly
./result/bin/run-nixos-vm
```

## 📁 Repository Structure

```text
nix-multi/
├── flake.nix              # Main flake configuration
├── nix-multi.sh           # Main setup and management script  
├── vm-build.sh            # VM build and management script
├── vm-manager.sh          # Interactive VM management
├── validate-setup.sh      # Comprehensive setup validation
│
├── home/                  # Home Manager configurations
│   ├── default.nix        # Entry point for home configurations
│   ├── core.nix          # Core packages and settings
│   ├── linux/            # Linux-specific home config
│   ├── macos/            # macOS-specific home config
│   └── neovim/           # Neovim configuration
│
├── modules/              # System-level modules
│   ├── darwin/           # macOS nix-darwin modules
│   ├── nixos/            # NixOS modules (shared)
│   ├── vm/               # VM-specific modules
│   └── hosts/            # Host-specific modules
│       ├── linux/        # Linux host modules
│       │   ├── gpu-passthrough.nix    # RTX 3080 partial passthrough
│       │   └── vm-management.nix      # VM tools for Linux
│       └── macos/        # macOS host modules
│           └── vm-management.nix      # VM tools for macOS
│
├── scripts/              # Utility scripts
│   └── rtx3080-setup.sh  # RTX 3080 testing and validation
│
└── templates/            # VM templates
    └── partial-gpu-passthrough-vm.xml
```

## ⚙️ Configuration Overview

### Host Configurations

**macOS (nix-darwin)**:

- **Purpose**: VM host and development environment
- **Desktop**: Native macOS with Aerospace window manager
- **Package Management**: Nix + Homebrew integration
- **VM Support**: QEMU for creating Hyprland VMs

**Linux (NixOS + Plasma)**:

- **Purpose**: GPU passthrough host and development environment
- **Desktop**: KDE Plasma with Wayland/X11
- **GPU**: RTX 3080 partial passthrough (host + VM sharing)
- **VM Support**: libvirt + KVM for high-performance VMs

### Guest Configuration

**Hyprland VM**:

- **Purpose**: Cross-platform guest system
- **Desktop**: Hyprland (Wayland tiling compositor)
- **Optimization**: VM-specific performance tuning
- **GPU Support**: Passthrough capable (when run on Linux host)

## 🎮 RTX 3080 Partial GPU Passthrough

### What is Partial GPU Passthrough?

Unlike full passthrough (which dedicates the entire GPU to a VM), partial passthrough allows:

- ✅ **Host keeps GPU access** for desktop, gaming, development
- ✅ **VMs can access GPU** for Windows gaming, GPU compute
- ✅ **Containers can use GPU** for AI/ML workloads  
- ✅ **Dynamic sharing** based on workload demands

### Your RTX 3080 Configuration

**Detected Hardware**:

- GPU: NVIDIA GA102 [GeForce RTX 3080 Lite Hash Rate] (01:00.0)
- Audio: NVIDIA GA102 High Definition Audio Controller (01:00.1)

**Automatic Configuration**:

- PCI IDs: 10de:2206 (GPU), 10de:1aef (Audio)
- PCI Addresses: 0000:01:00.0 (GPU), 0000:01:00.1 (Audio)
- Driver: NVIDIA proprietary (host), VFIO (VM access)

### Setup Steps

1. **Check Current Setup**:

```bash
# RTX 3080 specific setup checker
./scripts/rtx3080-setup.sh

# Check individual components
./scripts/rtx3080-setup.sh status     # GPU status
./scripts/rtx3080-setup.sh iommu      # IOMMU groups
./scripts/rtx3080-setup.sh container  # Container GPU access
```

2. **Rebuild System (Everything Automatic)**:

```bash
sudo nixos-rebuild switch --flake .#nixos-plasma
sudo reboot
```

**That's it!** The configuration automatically handles:

- ✅ NVIDIA drivers for host
- ✅ VFIO modules for VM access
- ✅ Docker NVIDIA runtime for containers
- ✅ IOMMU and virtualization settings
- ✅ User permissions and groups

3. **Verify Setup**:

```bash
# After reboot, verify everything works
./scripts/rtx3080-setup.sh
```

### GPU Sharing Usage

**Host Usage (Always Available)**:

```bash
nvidia-smi                    # Check GPU status
nvtop                        # Monitor GPU usage
games                        # Native Linux gaming
blender                      # GPU rendering
```

**Container Usage**:

```bash
# Run AI/ML workloads
docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi
```

**VM Usage**:

```bash
# Create Windows gaming VM
./scripts/rtx3080-setup.sh generate     # Generate VM config
virsh define rtx3080-vm-config.xml      # Import VM
virsh start RTX3080-Gaming-VM           # Start VM
```

## 🛠️ VM Features

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
# SSH into running VM (default setup)
ssh hrpr@localhost -p 22000
# Default password: nixos (change after first login)
```

## 🔧 Customization

### Adding Applications

**macOS (homebrew)**:

Edit `modules/darwin/apps.nix` - add to `brews` or `casks` arrays

**Linux/VM (nix)**:

Edit `modules/nixos/apps.nix` or `modules/vm/apps.nix` - add to `environment.systemPackages`

### Desktop Environment Changes

**Switching Linux Desktop**:

Modify `desktopManager` in flake.nix `linuxSpecialArgs`

**VM Desktop Customization**:

Edit `modules/vm/apps.nix` and Hyprland configs in `home/linux/hyprland.nix`

### User Configuration

1. Update username and email in `flake.nix`
2. Modify hostname in the respective configuration calls
3. Customize home-manager settings in `home/` directory

## 🧪 Testing & Validation

```bash
# Comprehensive validation
./nix-multi.sh validate

# Test specific components
./nix-multi.sh gpu-test         # GPU passthrough (Linux only)
nix flake check                 # Validate flake structure
```

## 📖 Learning Resources

- [NixOS & Flakes Book](https://github.com/ryan4yin/nixos-and-flakes-book) - Comprehensive Nix learning resource
- [NixOS Manual](https://nixos.org/manual/nixos/stable/) - Official NixOS documentation
- [Home Manager Manual](https://nix-community.github.io/home-manager/) - Home Manager configuration guide
- [Nix-Darwin](https://github.com/LnL7/nix-darwin) - macOS Nix configuration

## 📄 License

This configuration is provided as-is for educational and personal use. Please review and understand all configurations before applying to your system.
