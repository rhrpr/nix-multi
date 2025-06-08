# Unified Nix Configuration

A comprehensive Nix configuration supporting three distinct environments:

1. **macOS** - Nix-Darwin configuration with Homebrew integration
2. **Linux NixOS** - Native Linux with KDE Plasma desktop
3. **VM NixOS** - Hyprland VM for both macOS and Linux hosts using QEMU

## 🚀 Quick Start

### Prerequisites

- [Nix package manager](https://nixos.org/download.html) installed
- [Flakes enabled](https://nixos.wiki/wiki/Flakes#Enable_flakes) in your Nix configuration

### 1. macOS Configuration (Nix-Darwin)

```bash
# First time setup (requires nix-darwin)
nix run nix-darwin -- switch --flake .#Ryans-MacBook-Pro

# Subsequent updates
darwin-rebuild switch --flake .#Ryans-MacBook-Pro
```

### 2. Linux NixOS Configuration (KDE Plasma)

```bash
# Build and switch to NixOS configuration
sudo nixos-rebuild switch --flake .#nixos-plasma
```

### 3. VM Configuration (NixOS Hyprland)

```bash
# Interactive VM manager
./vm-manager.sh

# Or direct commands
./vm-build.sh build    # Build VM for current architecture
./vm-build.sh run      # Build and run VM
./vm-build.sh clean    # Clean build artifacts

# Specific architecture
./vm-build.sh x86_64 build   # For Intel/AMD systems
./vm-build.sh aarch64 build  # For ARM64/Apple Silicon
```

## 📁 Repository Structure

```
nix-multi/
├── flake.nix              # Main flake configuration
├── flake.lock             # Flake lock file
├── vm-build.sh            # VM build and management script
├── vm-manager.sh          # Interactive VM management
├── nix-rebuild.sh         # Helper for rebuilding configs
│
├── home/                  # Home Manager configurations
│   ├── default.nix        # Entry point for home configurations
│   ├── core.nix          # Core packages and settings
│   ├── linux/            # Linux-specific home config
│   ├── macos/            # macOS-specific home config
│   └── neovim/           # Neovim configuration
│
└── modules/              # System-level modules
    ├── darwin/           # macOS nix-darwin modules
    │   ├── system.nix    # macOS system configuration
    │   ├── apps.nix      # macOS applications
    │   └── host-users.nix
    ├── nixos/            # NixOS modules (shared)
    │   ├── system.nix    # Base NixOS system config
    │   ├── desktop.nix   # Desktop environment config
    │   ├── apps.nix      # Linux applications
    │   └── hardware-configuration.nix
    ├── vm/               # VM-specific modules
    │   ├── system.nix    # VM system optimizations
    │   ├── apps.nix      # VM application selection
    │   ├── hardware-configuration.nix  # VM hardware config
    │   └── vm-guest.nix  # VM guest utilities
    └── shared/           # Cross-platform modules
        └── vm-tools.nix  # QEMU and virtualization tools
```

## ⚙️ Configuration Details

### macOS (Nix-Darwin)
- **Desktop Manager**: None (native macOS)
- **Package Manager**: Nix + Homebrew integration
- **Window Manager**: Aerospace (i3-like tiling)
- **Applications**: Full suite including development tools, media apps
- **VM Support**: QEMU, UTM, VMware Fusion for creating VMs

### Linux NixOS (KDE Plasma)
- **Desktop Manager**: KDE Plasma
- **Package Manager**: Nix (pure)
- **Display Server**: Wayland/X11
- **Applications**: Linux-native development and productivity tools
- **VM Support**: libvirt, virt-manager, QEMU for VM creation

### VM NixOS (Hyprland)
- **Desktop Manager**: Hyprland (Wayland compositor)
- **Target**: Runs on both macOS and Linux hosts
- **Optimization**: VM-specific performance tuning
- **Applications**: Lightweight selection optimized for VM usage
- **Integration**: SPICE/QEMU guest tools for seamless experience

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

## 🚨 Important Notes

### First-Time Setup
- **macOS**: Requires manual nix-darwin installation first
- **Linux**: Requires existing NixOS installation
- **VM**: Can be built on any host with Nix installed

### VM Networking
- Default VM SSH port: 22000
- Default user: hrpr (configurable in flake.nix)
- Default password: nixos (change immediately)

### Security Considerations
- VM has passwordless sudo enabled for convenience
- SSH is enabled by default in VM
- Change default passwords after first login

## 📖 Learning Resources

- [NixOS & Flakes Book](https://github.com/ryan4yin/nixos-and-flakes-book) - Comprehensive Nix learning resource
- [NixOS Manual](https://nixos.org/manual/nixos/stable/) - Official NixOS documentation
- [Home Manager Manual](https://nix-community.github.io/home-manager/) - Home Manager configuration guide
- [Nix-Darwin](https://github.com/LnL7/nix-darwin) - macOS Nix configuration

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch
3. Test your changes on the relevant platform(s)
4. Submit a pull request

## 📄 License

This configuration is provided as-is for educational and personal use. Please review and understand all configurations before applying to your system.
