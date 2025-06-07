#!/usr/bin/env bash
# filepath: /Users/hrpr/.config/nix-darwin/vms/utm-scripts/create-vm.sh

set -e

VM_NAME="nixos-development"
VM_DIR="$HOME/UTM VMs"
ISO_PATH="$HOME/Downloads/nixos-minimal.iso"
DISK_SIZE="50" # GB
RAM_SIZE="8192" # MB
CPU_CORES="4"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if UTM is installed
check_utm() {
    if ! command -v utmctl &> /dev/null; then
        error "UTM command line tools not found. Please install UTM first."
        exit 1
    fi
}

# Download NixOS ISO if not present
download_nixos_iso() {
    if [ ! -f "$ISO_PATH" ]; then
        log "Downloading NixOS minimal ISO..."
        curl -L "https://channels.nixos.org/nixos-unstable/latest-nixos-minimal-aarch64-linux.iso" -o "$ISO_PATH"
    else
        log "NixOS ISO already exists at $ISO_PATH"
    fi
}

# Create the VM
create_vm() {
    log "Creating UTM VM: $VM_NAME"
    
    # Create VM configuration
    cat > /tmp/nixos-vm-config.json << EOF
{
    "name": "$VM_NAME",
    "architecture": "aarch64",
    "machine": "virt-4.0",
    "memory": $RAM_SIZE,
    "cpus": $CPU_CORES,
    "drives": [
        {
            "type": "disk",
            "interface": "virtio",
            "size": "${DISK_SIZE}GB",
            "format": "qcow2"
        },
        {
            "type": "cd",
            "interface": "usb",
            "path": "$ISO_PATH",
            "removable": true
        }
    ],
    "network": [
        {
            "type": "shared"
        }
    ],
    "display": {
        "type": "virtio-gpu",
        "resolution": "3440x1440"
    },
    "sound": {
        "type": "intel-hda"
    },
    "usb": true,
    "clipboard": true
}
EOF

    # Import the VM
    utmctl import /tmp/nixos-vm-config.json
    rm /tmp/nixos-vm-config.json
    
    log "VM '$VM_NAME' created successfully!"
}

# Start the VM
start_vm() {
    log "Starting VM: $VM_NAME"
    utmctl start "$VM_NAME"
}

# Main execution
main() {
    log "Setting up NixOS VM for development..."
    
    check_utm
    download_nixos_iso
    create_vm
    
    log "VM setup complete!"
    log "You can now:"
    log "  1. Start the VM: utmctl start '$VM_NAME'"
    log "  2. Stop the VM: utmctl stop '$VM_NAME'"
    log "  3. View VM status: utmctl list"
    
    read -p "Would you like to start the VM now? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        start_vm
    fi
}

main "$@"