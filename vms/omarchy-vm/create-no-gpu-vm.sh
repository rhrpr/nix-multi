#!/usr/bin/env bash

# Temporary VM Configuration Without GPU Passthrough
# This creates the VM without PCI passthrough to test other features

VM_NAME="omarchy"

print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}\033[0m"
}

YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'

print_color $YELLOW "Creating temporary VM without GPU passthrough..."
print_color $BLUE "This will allow testing of shared folders and basic VM functionality"

# Remove PCI hostdev entries from existing VM
virsh dumpxml omarchy > /tmp/omarchy-original.xml

# Create a modified version without PCI passthrough
sed '/<hostdev mode=.subsystem. type=.pci./,/<\/hostdev>/d' /tmp/omarchy-original.xml > /tmp/omarchy-no-gpu.xml

# Undefine and redefine VM
virsh undefine omarchy
virsh define /tmp/omarchy-no-gpu.xml

print_color $GREEN "VM recreated without GPU passthrough"
print_color $BLUE "You can now start the VM with: virsh start omarchy"
print_color $BLUE "And connect via: virt-viewer omarchy"

# Clean up
rm -f /tmp/omarchy-original.xml /tmp/omarchy-no-gpu.xml
