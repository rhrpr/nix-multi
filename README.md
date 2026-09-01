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

## AI Agent Command Centre

The macOS configuration uses **Herdr** as the single agent-aware terminal
multiplexer. It installs Claude Code, Codex CLI, Gemini CLI, GitHub Copilot CLI,
Hermes Agent, Google Antigravity, Antigravity CLI, and the LM Studio integration.

```bash
herdr-agent-setup # install native restore integrations
ai-agent-doctor   # validate CLIs, sessions, integrations, and local inference
herdr             # or: ai
```

See [Durable multi-agent development workflow](docs/AI-AGENT-WORKFLOW.md) for
subscription routing, parallel worktrees, model handoffs, and reboot restoration.

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
├── flake.nix                          # Main flake — defines all host configs and outputs
├── Makefile                           # Primary interface for all make commands
├── nix-multi.sh                       # Legacy setup and management script
├── nix-rebuild.sh                     # Quick rebuild helper for Darwin/NixOS
├── validate-setup.sh                  # Comprehensive setup validation
├── cleanup-desktop-switch.sh          # Utility for desktop environment migration
├── run-custom-vm.sh                   # Run a custom QEMU VM directly
│
├── lib/
│   └── mksystem.nix                   # mkSystem builder — shared logic used in flake.nix
│                                      # to assemble Darwin and NixOS host configs
│
├── devshells/                         # Nix development shell environments (`nix develop .#<name>`)
│   ├── flutter.nix                    # Flutter / Android dev shell
│   ├── python.nix                     # Python dev shell
│   ├── rust.nix                       # Rust dev shell
│   └── web.nix                        # Node.js / TypeScript dev shell
│
├── docs/                              # Extended documentation
│   ├── VM-MANAGEMENT.md               # VM management workflow guide
│   ├── VM-STATUS.md                   # VM status reference
│   ├── SETUP-STATUS.md                # Setup completion notes
│   ├── LIBVIRT-DYNAMIC-NETWORK.md     # libvirt dynamic network configuration
│   ├── LIBVIRT-NIX-MANAGEMENT.md      # Managing libvirt via Nix modules
│   └── BIOS-TROUBLESHOOTING.md        # BIOS/UEFI compatibility troubleshooting
│
├── home/                              # Home Manager configurations (user-space)
│   ├── core.nix                       # Core packages shared across all platforms
│   ├── git.nix                        # Git identity and settings
│   ├── zsh.nix                        # Zsh shell config
│   ├── starship.nix                   # Starship prompt
│   ├── tmux.nix                       # Tmux config
│   ├── plasma.nix                     # KDE Plasma home config
│   ├── steam.nix                      # Steam and gaming packages
│   ├── vscode.nix                     # VSCode home config entry point
│   ├── vscode-shared.nix              # Shared VSCode extensions and settings
│   ├── ghostty.nix                    # Ghostty terminal config (top-level entry)
│   ├── aerospace/
│   │   └── aerospace.toml             # Aerospace window manager config (macOS)
│   ├── neovim/                        # Neovim configuration
│   │   ├── nvim.nix                   # Neovim Nix module
│   │   └── lua/custom/                # Custom Lua configs (init, mappings, plugins)
│   ├── plasma/
│   │   └── plasma.conf                # KDE Plasma settings file (applied via Home Manager)
│   ├── shells/
│   │   └── default.nix                # Shell configuration module
│   ├── terminals/                     # Terminal emulator configurations
│   │   ├── default.nix                # Terminal module entry point
│   │   ├── ghostty.nix                # Ghostty config
│   │   ├── iterm2.nix                 # iTerm2 config (macOS)
│   │   └── tmux.nix                   # Tmux config
│   ├── linux/                         # Linux-specific home config
│   │   ├── default.nix                # Linux home entry point
│   │   ├── browser.nix                # Browser configuration
│   │   ├── plasma.nix                 # KDE Plasma home config (Linux)
│   │   └── vscode.nix                 # Linux VSCode config
│   └── macos/                         # macOS-specific home config
│       ├── default.nix                # macOS home entry point
│       └── vscode.nix                 # macOS VSCode config
│
├── machines/                          # Machine-specific configuration overrides
│   └── nixos-vm.nix                   # NixOS VM machine config
│
├── modules/                           # System-level Nix modules
│   ├── darwin/                        # macOS nix-darwin modules
│   │   ├── nix-core.nix               # Nix daemon settings, trusted users, substituters
│   │   └── system.nix                 # macOS system preferences, Homebrew, app installs
│   ├── nixos/                         # NixOS modules shared across native and VM hosts
│   │   ├── apps.nix                   # System packages
│   │   ├── nix-core.nix               # Nix settings and garbage collection
│   │   ├── system.nix                 # Core system config (locale, fonts, services)
│   │   ├── host-users.nix             # User accounts, groups, sudo rules
│   │   ├── hardware-configuration.nix # Hardware detection and kernel modules
│   │   ├── libvirt-host.nix           # libvirt / KVM host configuration
│   │   ├── virtualization.nix         # Active virtualization stack config
│   │   ├── virtualization-clean.nix   # Clean-room virtualization config (alternate)
│   │   └── virtualization-old.nix     # Legacy virtualization config (archived)
│   ├── vm/                            # VM guest-specific modules
│   │   ├── apps.nix                   # VM-specific packages
│   │   ├── system.nix                 # VM system config
│   │   ├── vm-guest.nix               # Guest tools — SPICE agent, virtio, clipboard
│   │   ├── hardware-configuration.nix # VM hardware config
│   │   ├── gpu-guest.nix              # GPU passthrough guest config (VFIO consumer)
│   │   ├── iso-arm64.nix              # Full ARM64 ISO builder for UTM
│   │   ├── iso-minimal-arm64.nix      # Minimal ARM64 ISO builder
│   │   └── minimal-arm64.nix          # Minimal ARM64 system config
│   ├── shared/                        # Cross-platform modules
│   │   ├── secrets.nix                # Agenix secret path declarations
│   │   └── vm-tools.nix               # VM management CLI tools (cross-platform)
│   └── hosts/                         # Host capability modules (loaded per-host in flake.nix)
│       ├── linux/
│       │   ├── gpu-passthrough.nix    # RTX 3080 VFIO partial passthrough config
│       │   └── vm-management.nix      # libvirt VM management tools for Linux host
│       └── macos/
│           ├── linux-builder.nix      # darwin.linux-builder for cross-compilation
│           └── vm-management.nix      # UTM / QEMU VM management tools for macOS host
│
├── scripts/                           # Utility shell scripts
│   ├── vm-setup.sh                    # UTM VM setup and SSH-based config deployment
│   ├── utm-vm-setup.sh                # UTM-specific VM creation helper
│   ├── vm-nix-setup.sh                # NixOS configuration bootstrap inside a VM
│   ├── rtx3080-setup.sh               # RTX 3080 validation, IOMMU, and driver checks
│   ├── qemu-config.sh                 # QEMU option generator and availability tester
│   ├── debug-sleep.sh                 # Sleep / wake diagnostics (macOS)
│   ├── manage-wake-sources.sh         # ACPI wake source management
│   ├── check-iommu-status.sh          # IOMMU group inspection (Linux)
│   ├── check-bios-issues.sh           # BIOS / UEFI compatibility checker
│   ├── bluetooth-debug.sh             # Bluetooth diagnostics
│   └── test-libvirt-network.sh        # libvirt network connectivity test
│
├── secrets/                           # Agenix-encrypted secrets (safe to commit)
│   ├── ssh-keys/                      # SSH keys encrypted per-machine with age
│   │   ├── id_ed25519.age             # Primary SSH identity key
│   │   ├── id_rsa.age                 # RSA key (legacy)
│   │   ├── github.age                 # GitHub deploy key
│   │   ├── proxmox.age                # Proxmox host key
│   │   ├── proxmox-nodes.age          # Proxmox cluster node keys
│   │   ├── raspberry_pi.age           # Raspberry Pi key
│   │   ├── agenix-macos.age           # macOS machine identity for agenix decryption
│   │   └── agenix-nixos.age           # NixOS machine identity for agenix decryption
│   └── README.md                      # Secret management instructions and bootstrap guide
│
└── vms/                               # VM definitions and management
    ├── utm-manager.nix                # UTM VM manager Nix module
    ├── utm-scripts/                   # UTM lifecycle automation scripts
    │   ├── create-vm.sh               # Create UTM VM from ISO
    │   ├── install-nixos.sh           # Install NixOS into the VM disk
    │   ├── manage-nixos-vm.sh         # VM lifecycle management (start/stop/snapshot)
    │   └── provision-vm.sh            # Post-install provisioning (SSH keys, config)
    ├── nixos-vm/                      # Standalone NixOS VM flake (self-contained)
    │   ├── flake.nix                  # VM-specific flake with its own inputs
    │   ├── home.nix                   # Home Manager config for VM user
    │   ├── vm-hardware.nix            # VM hardware config (virtio, display, memory)
    │   ├── config/                    # Desktop config files (applied at build time)
    │   │   ├── hyprland/hyprland.conf # Hyprland compositor config
    │   │   └── waybar/                # Waybar status bar config and styles
    │   └── modules/                   # VM NixOS system modules
    │       ├── configuration.nix      # Main NixOS configuration
    │       ├── system.nix             # System settings (locale, time, services)
    │       ├── development.nix        # Dev tools and languages
    │       └── hyperland.nix          # Hyprland system-level setup
    └── omarchy-vm/                    # Omarchy gaming VM — Linux host only
        ├── omarchy-vm.nix             # libvirt VM definition (XML + Nix)
        ├── create-omarchy-vm.sh       # VM creation script (disk, network, GPU)
        ├── manage-omarchy.sh          # VM start/stop/status management
        ├── gpu-passthrough.sh         # Toggle GPU between host and VM
        ├── enable-gpu-passthrough.sh  # Enable VFIO passthrough for RTX 3080
        ├── configure-ultrawide.sh     # Configure 3440x1440 display in VM
        ├── create-no-gpu-vm.sh        # Create VM without GPU (for testing)
        ├── fix-filesystem.sh          # Filesystem repair utility
        ├── setup-user-session.sh      # User session bootstrap inside VM
        └── README.md                  # Omarchy VM full setup documentation
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
make fmt            # Format Nix files (nixfmt)
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

The desktop is selected via the `desktopManager` string, set automatically in `lib/mksystem.nix` based on host type:

| Host | Default desktop | Value |
|------|----------------|-------|
| `nixos-desktop` / `nixos-plasma` | KDE Plasma 6 | `"plasma"` |
| `vm` / `nixos-vm-hyprland` | Hyprland | `"hyprland"` |
| macOS | none | `"none"` |

Both desktops are fully supported — system services, XDG portals, and Home Manager configs all switch on this value. To change the desktop for `nixos-desktop`:

**Option A — add a `desktop` parameter to `mkSystem` (recommended):**

1. In `lib/mksystem.nix`, accept the new parameter and use it:

   ```nix
   { name, system, user, isDarwin ? false, vm ? false, desktop ? null }:
   # ...
   desktopManager =
     if desktop != null then desktop
     else if isVM then "hyprland"
     else if isDarwin then "none"
     else "plasma";
   ```

2. In `flake.nix`, pass `desktop` to the relevant host:

   ```nix
   nixosConfigurations."nixos-desktop" = mkSystem {
     name = "nixos-desktop";
     system = "x86_64-linux";
     inherit user;
     desktop = "hyprland";   # or "plasma"
   };
   ```

**Option B — quick change (affects all non-VM Linux hosts):**

In `lib/mksystem.nix`, change the fallback string from `"plasma"` to `"hyprland"` in the `desktopManager` assignment.

**VM Desktop Customization**:

Edit `home/linux/hyprland.nix` for Hyprland home config, or `home/linux/plasma.nix` for Plasma. System-level desktop options (portals, services, packages) live in `modules/nixos/desktop.nix`.

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
