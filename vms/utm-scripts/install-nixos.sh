#!/usr/bin/env bash
# filepath: /Users/hrpr/.config/nix-darwin/vms/utm-scripts/install-nixos.sh

# This script runs inside the NixOS installer to set up the system

set -e

# Configuration
HOSTNAME="nixos-vm"
USERNAME="nixos"
CONFIG_REPO="https://github.com/your-username/nix-darwin.git"  # Update this
DISK="/dev/vda"

# Colors
GREEN='\033[0;32m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[INSTALL]${NC} $1"
}

# Partition the disk
partition_disk() {
    log "Partitioning disk $DISK..."
    
    parted $DISK -- mklabel gpt
    parted $DISK -- mkpart primary 512MiB -8GiB
    parted $DISK -- mkpart primary linux-swap -8GiB 100%
    parted $DISK -- mkpart ESP fat32 1MiB 512MiB
    parted $DISK -- set 3 esp on
    
    # Format partitions
    mkfs.ext4 -L nixos ${DISK}1
    mkswap -L swap ${DISK}2
    mkfs.fat -F 32 -n boot ${DISK}3
}

# Mount file systems
mount_filesystems() {
    log "Mounting file systems..."
    
    mount /dev/disk/by-label/nixos /mnt
    mkdir -p /mnt/boot
    mount /dev/disk/by-label/boot /mnt/boot
    swapon ${DISK}2
}

# Generate hardware configuration
generate_hardware_config() {
    log "Generating hardware configuration..."
    nixos-generate-config --root /mnt
}

# Clone and setup configuration
setup_configuration() {
    log "Setting up NixOS configuration..."
    
    # Clone the repository
    git clone $CONFIG_REPO /mnt/etc/nixos/nix-darwin
    
    # Copy VM configuration
    cp -r /mnt/etc/nixos/nix-darwin/vms/nixos-vm/* /mnt/etc/nixos/
    
    # Update hardware configuration
    cp /mnt/etc/nixos/hardware-configuration.nix /mnt/etc/nixos/vm-hardware.nix
}

# Install NixOS
install_nixos() {
    log "Installing NixOS..."
    nixos-install --flake /mnt/etc/nixos#vm
}

# Set user password
set_password() {
    log "Setting up user password..."
    nixos-enter --root /mnt -c "passwd $USERNAME"
}

# Main installation
main() {
    log "Starting automated NixOS installation..."
    
    partition_disk
    mount_filesystems
    generate_hardware_config
    setup_configuration
    install_nixos
    set_password
    
    log "Installation complete! You can now reboot into your new NixOS system."
    log "After reboot, the system will be accessible via SSH."
}

main "$@"