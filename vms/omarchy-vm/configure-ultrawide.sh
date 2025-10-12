#!/usr/bin/env bash

# Configure Omarchy VM for 3440x1440 Ultrawide Resolution

set -euo pipefail

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

print_color $GREEN "=== Configuring VM for 3440x1440 Resolution ==="

# Check if VM is running
VM_STATE=$(virsh domstate "$VM_NAME")
if [[ "$VM_STATE" == "running" ]]; then
    print_color $YELLOW "⚠️  VM is currently running. Changes will take effect after restart."
    read -p "Do you want to shutdown the VM now to apply changes? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_color $BLUE "Shutting down VM..."
        virsh shutdown "$VM_NAME"
        print_color $BLUE "Waiting for VM to shutdown..."
        while [[ "$(virsh domstate "$VM_NAME")" != "shut off" ]]; do
            sleep 2
        done
        RESTART_VM=true
    else
        RESTART_VM=false
    fi
else
    RESTART_VM=false
fi

print_color $BLUE "Updating VM configuration for ultrawide display..."

# Export current configuration
virsh dumpxml "$VM_NAME" > /tmp/omarchy-current.xml

# Create updated configuration with proper video settings
sed -e '
/<video>/,/<\/video>/{
  s/<model type=.virtio. heads=.1. primary=.yes.\/>/\<model type="virtio" heads="1" primary="yes" vram="65536">\<resolution x="3440" y="1440"\/>\<\/model>/
}
' /tmp/omarchy-current.xml > /tmp/omarchy-ultrawide.xml

# Apply the updated configuration
print_color $BLUE "Applying ultrawide configuration..."
virsh undefine "$VM_NAME" --nvram
virsh define /tmp/omarchy-ultrawide.xml

# Restart VM if it was running
if [[ "$RESTART_VM" == "true" ]]; then
    print_color $BLUE "Starting VM with new configuration..."
    virsh start "$VM_NAME"
fi

print_color $GREEN "✅ VM configured for 3440x1440 resolution!"
print_color $BLUE ""
print_color $BLUE "Additional steps to ensure proper resolution:"
print_color $BLUE "1. In VM: Install spice-vdagent for proper resolution detection"
print_color $BLUE "   sudo pacman -S spice-vdagent  # For Arch-based Omarchy"
print_color $BLUE "   sudo systemctl enable --now spice-vdagent"
print_color $BLUE ""
print_color $BLUE "2. In virt-viewer: Go to View > Resize to VM"
print_color $BLUE "3. In VM display settings: Set resolution to 3440x1440"
print_color $BLUE "4. For gaming: Consider using GPU passthrough for native performance"

# Clean up
rm -f /tmp/omarchy-current.xml /tmp/omarchy-ultrawide.xml
