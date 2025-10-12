#!/usr/bin/env bash

# Enable GPU Passthrough for Omarchy VM
set -euo pipefail

# Configuration
VM_NAME="omarchy"
LIBVIRT_URI="qemu:///session"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

print_color $BLUE "=== Enabling GPU Passthrough for Omarchy VM ==="

# Verify IOMMU is working
print_color $BLUE "Checking IOMMU status..."
if sudo dmesg | grep -q "DMAR: IOMMU enabled"; then
    print_color $GREEN "✓ IOMMU is enabled"
else
    print_color $RED "❌ IOMMU is not enabled"
    exit 1
fi

# Check GPU IOMMU group
print_color $BLUE "Checking GPU IOMMU group..."
if [[ -d "/sys/kernel/iommu_groups/13/devices/" ]]; then
    devices=$(ls /sys/kernel/iommu_groups/13/devices/)
    print_color $GREEN "✓ IOMMU group 13 devices:"
    for device in $devices; do
        device_info=$(lspci -s ${device#0000:})
        print_color $BLUE "  - $device: $device_info"
    done
else
    print_color $RED "❌ GPU IOMMU group not found"
    exit 1
fi

# Check if VM exists and is running
if ! virsh -c "$LIBVIRT_URI" dominfo "$VM_NAME" >/dev/null 2>&1; then
    print_color $RED "❌ VM '$VM_NAME' does not exist"
    exit 1
fi

# Stop VM if running
if virsh -c "$LIBVIRT_URI" domstate "$VM_NAME" | grep -q "running"; then
    print_color $YELLOW "Stopping VM..."
    virsh -c "$LIBVIRT_URI" shutdown "$VM_NAME"
    sleep 5
    if virsh -c "$LIBVIRT_URI" domstate "$VM_NAME" | grep -q "running"; then
        print_color $YELLOW "Force stopping VM..."
        virsh -c "$LIBVIRT_URI" destroy "$VM_NAME"
    fi
fi

# Create backup of current configuration
print_color $BLUE "Backing up current VM configuration..."
BACKUP_FILE="/tmp/${VM_NAME}-backup-$(date +%Y%m%d-%H%M%S).xml"
virsh -c "$LIBVIRT_URI" dumpxml "$VM_NAME" > "$BACKUP_FILE"
print_color $GREEN "✓ Backup saved to: $BACKUP_FILE"

# Create new XML with GPU passthrough enabled
print_color $BLUE "Creating new VM configuration with GPU passthrough..."
NEW_XML_FILE="/tmp/${VM_NAME}-gpu-passthrough.xml"

# Get current XML and modify it
virsh -c "$LIBVIRT_URI" dumpxml "$VM_NAME" | sed '
    # Remove the commented GPU passthrough section
    /<!-- NVIDIA RTX 3080 GPU Passthrough/,/-->/d
    
    # Remove fallback graphics comment
    s/<!-- Fallback Graphics (enabled for partial passthrough) -->//
    
    # Add GPU passthrough devices before the closing </devices> tag
    /<\/devices>/i\
    \
    <!-- NVIDIA RTX 3080 GPU Passthrough -->\
    <hostdev mode='\''subsystem'\'' type='\''pci'\'' managed='\''yes'\''>\
      <source>\
        <address domain='\''0x0000'\'' bus='\''0x01'\'' slot='\''0x00'\'' function='\''0x0'\''/>\
      </source>\
      <address type='\''pci'\'' domain='\''0x0000'\'' bus='\''0x06'\'' slot='\''0x00'\'' function='\''0x0'\''/>\
    </hostdev>\
    \
    <hostdev mode='\''subsystem'\'' type='\''pci'\'' managed='\''yes'\''>\
      <source>\
        <address domain='\''0x0000'\'' bus='\''0x01'\'' slot='\''0x00'\'' function='\''0x1'\''/>\
      </source>\
      <address type='\''pci'\'' domain='\''0x0000'\'' bus='\''0x07'\'' slot='\''0x00'\'' function='\''0x0'\''/>\
    </hostdev>
' > "$NEW_XML_FILE"

# Update VM definition
print_color $BLUE "Updating VM definition..."
virsh -c "$LIBVIRT_URI" define "$NEW_XML_FILE"

# Clean up temporary file
rm "$NEW_XML_FILE"

print_color $GREEN "✓ GPU passthrough enabled for VM '$VM_NAME'"
print_color $BLUE "Starting VM..."
virsh -c "$LIBVIRT_URI" start "$VM_NAME"

print_color $GREEN "=== GPU Passthrough Configuration Complete ==="
print_color $YELLOW "Notes:"
print_color $BLUE "- GPU and audio devices are now passed through to the VM"
print_color $BLUE "- SPICE graphics remain available for initial setup"  
print_color $BLUE "- Install NVIDIA drivers inside the VM for full GPU acceleration"
print_color $BLUE "- VM backup saved to: $BACKUP_FILE"

# Show VM info
print_color $BLUE "VM Status:"
virsh -c "$LIBVIRT_URI" dominfo "$VM_NAME" | grep -E "(State|Memory|CPU)"
