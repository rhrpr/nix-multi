#!/usr/bin/env bash

# Create Omarchy VM in User Session
# This script creates the VM properly in user session with correct paths

set -euo pipefail

# Configuration
export LIBVIRT_DEFAULT_URI="qemu:///session"
VM_NAME="omarchy"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_color() {
    echo -e "${1}${2}${NC}"
}

print_color $GREEN "=== Creating Omarchy VM in User Session ==="

# Clean up any existing VM
if virsh dominfo "$VM_NAME" >/dev/null 2>&1; then
    print_color $YELLOW "Removing existing VM..."
    virsh destroy "$VM_NAME" 2>/dev/null || true
    virsh undefine "$VM_NAME" --nvram 2>/dev/null || true
fi

# Create user directories
USER_LIBVIRT_DIR="$HOME/.local/share/libvirt"
mkdir -p "$USER_LIBVIRT_DIR/images"
mkdir -p "$USER_LIBVIRT_DIR/qemu/nvram"

# Move existing disk if it exists in system location
SYSTEM_DISK="/var/lib/libvirt/images/omarchy.qcow2"
USER_DISK="$USER_LIBVIRT_DIR/images/omarchy.qcow2"

if [[ -f "$SYSTEM_DISK" && ! -f "$USER_DISK" ]]; then
    print_color $BLUE "Moving VM disk to user location..."
    cp "$SYSTEM_DISK" "$USER_DISK"
fi

print_color $GREEN "✅ VM setup complete for user session!"
print_color $BLUE "Now you can:"
print_color $BLUE "1. Recreate the VM: make omarchy-create"  
print_color $BLUE "2. Start the VM: virsh start omarchy"
print_color $BLUE "3. Connect: virt-viewer omarchy"
print_color $BLUE ""
print_color $BLUE "All commands will now use user session (qemu:///session)"
