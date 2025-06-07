# NixOS Virtual Machines with UTM

A comprehensive VM management system for running NixOS virtual machines on macOS using UTM, fully integrated with your nix-darwin configuration.

## Features

- **Automated VM Creation**: Scripts to automatically create and configure NixOS VMs
- **Declarative Configuration**: Full NixOS configuration using Nix flakes
- **Hyprland Desktop**: Modern Wayland-based tiling window manager
- **Development Ready**: Pre-configured development environment with essential tools
- **Easy Management**: Simple commands to start, stop, deploy, and manage VMs
- **Host Integration**: Seamless integration with your macOS nix-darwin setup

## Directory Structure

```
vms/
├── nixos-vm/
│   ├── flake.nix                 # VM-specific flake configuration
│   ├── configuration.nix         # Main NixOS configuration
│   ├── home.nix                  # Home Manager user configuration
│   ├── vm-hardware.nix           # Hardware configuration for UTM
│   ├── modules/
│   │   ├── system.nix            # System settings and Wayland/Hyprland
│   │   ├── development.nix       # Development tools and services
│   │   └── hyprland.nix          # Hyprland window manager configuration
│   └── config/
│       ├── hyprland/
│       │   └── hyprland.conf     # Hyprland configuration
│       └── waybar/
│           ├── config.json       # Waybar status bar configuration
│           └── style.css         # Waybar styling
├── utm-scripts/
│   ├── create-vm.sh              # VM creation script
│   ├── install-nixos.sh          # Automated NixOS installation
│   └── provision-vm.sh           # Post-installation provisioning
└── utm-manager.nix               # UTM management integration for nix-darwin
```

## Quick Start

### 1. Create a New VM

```bash
# Create and configure a new NixOS VM
vm-create

# Or run the script directly
./vms/utm-scripts/create-vm.sh
```

This will:
- Download the NixOS minimal ISO (if not present)
- Create a new UTM VM with optimized settings
- Configure the VM with 8GB RAM, 4 CPU cores, and 50GB storage
- Set up networking and display for Hyprland

### 2. Install NixOS

After creating the VM:

1. Start the VM: `vm start` or through UTM GUI
2. Boot from the NixOS ISO
3. Run the installation script (once implemented) or install manually
4. Configure networking and SSH access

### 3. Deploy Configuration

Once NixOS is installed and SSH is accessible:

```bash
# Deploy the full NixOS configuration to the VM
vm deploy

# SSH into the VM
vm ssh

# Check VM status
vm status
```

## VM Management Commands

The following commands are available after integrating with your nix-darwin configuration:

```bash
# VM Lifecycle
vm start                    # Start the VM
vm stop                     # Stop the VM
vm status                   # Show VM status
vm console                  # Open VM console

# Configuration Management
vm deploy                   # Deploy NixOS configuration to VM
vm rebuild                  # Rebuild configuration locally
vm ssh                      # SSH into the VM

# Creation and Destruction
vm-create                   # Create a new VM
vm-destroy                  # Remove the VM completely

# Development
vm-build-iso               # Build custom NixOS ISO
```

## VM Configuration

### Hardware Specifications

- **CPU**: 4 cores (configurable)
- **RAM**: 8GB (configurable)
- **Storage**: 50GB virtual disk
- **Display**: 3440x1440 with virtio-gpu acceleration
- **Audio**: Intel HDA sound
- **Network**: Shared networking with host

### Software Stack

- **OS**: NixOS (latest unstable)
- **Desktop**: Hyprland (Wayland compositor)
- **Terminal**: Kitty with Tokyo Night theme
- **Status Bar**: Waybar with custom styling
- **Application Launcher**: Rofi (Wayland)
- **File Manager**: Nautilus (GUI) + Ranger (TUI)
- **Development**: VS Code, Git, Docker, and language-specific tools

### Key Bindings (Hyprland)

| Key Combination | Action |
|-----------------|--------|
| `Super + Return` | Open terminal (Kitty) |
| `Super + R` | Application launcher (Rofi) |
| `Super + Q` | Close active window |
| `Super + E` | File manager (Nautilus) |
| `Super + L` | Lock screen |
| `Super + 1-9` | Switch to workspace 1-9 |
| `Super + Shift + 1-9` | Move window to workspace 1-9 |
| `Print` | Screenshot selection |
| `Super + V` | Toggle floating mode |

## Customization

### Modifying VM Specifications

Edit the variables in create-vm.sh:

```bash
VM_NAME="nixos-development"
DISK_SIZE="50"              # GB
RAM_SIZE="8192"             # MB
CPU_CORES="4"
```

### Adding Software

Add packages to development.nix:

```nix
environment.systemPackages = with pkgs; [
  # Add your packages here
  nodejs
  python3
  go
  # ... more packages
];
```

### Customizing Hyprland

Modify hyprland.conf to change:
- Key bindings
- Window decorations
- Animations
- Workspace behavior

### User Configuration

Update home.nix to customize:
- Shell aliases and configuration
- Development tools
- GUI applications
- Dotfiles and user settings

## Network Configuration

The VM uses UTM's shared networking by default, which provides:
- Internet access through the host
- Automatic IP assignment via DHCP
- SSH access from host (typically `192.168.64.x` range)

To find your VM's IP address:
```bash
# From within the VM
ip addr show

# From the host
vm ssh "ip addr show"
```

## Backup and Recovery

### Backing Up VM State

```bash
# Stop the VM first
vm stop

# Backup the VM directory (contains disk images and configuration)
cp -r "$HOME/UTM VMs/nixos-development" "$HOME/VM-Backups/"
```

### Restoring from Backup

```bash
# Copy backup back to UTM directory
cp -r "$HOME/VM-Backups/nixos-development" "$HOME/UTM VMs/"

# Start the restored VM
vm start
```

## Troubleshooting

### VM Won't Start
- Check UTM is installed and running
- Verify VM exists: `utmctl list`
- Check system resources (RAM/CPU availability)

### Can't SSH into VM
- Ensure VM is running: `vm status`
- Check VM's IP address from console
- Verify SSH service is running in VM: `systemctl status sshd`

### Display Issues
- Hyprland may need VM-specific optimizations
- Try setting `WLR_NO_HARDWARE_CURSORS=1` environment variable
- Check UTM display settings and resolution

### Performance Issues
- Increase RAM allocation in create-vm.sh
- Enable hardware acceleration in UTM settings
- Reduce visual effects in Hyprland configuration

## Integration with nix-darwin

The VM system integrates seamlessly with your nix-darwin configuration:

1. **Commands**: All `vm-*` commands are available in your macOS shell
2. **Dependencies**: Required tools (UTM, QEMU, SSH) are automatically installed
3. **Configuration**: VM configs are version-controlled alongside your Darwin setup
4. **Development**: Same development tools and configurations across host and VM

## Contributing

To extend or modify the VM setup:

1. Update configurations in nixos-vm
2. Test changes with `vm rebuild` and `vm deploy`
3. Commit changes to version control
4. Share configurations across team members

## License

This VM configuration inherits the same license as your nix-darwin setup.