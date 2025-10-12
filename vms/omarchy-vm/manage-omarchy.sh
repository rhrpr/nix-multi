#!/usr/bin/env bash

# Omarchy VM Management Script
# Easy control of the Omarchy VM

set -euo pipefail

VM_NAME="omarchy"
ISO_PATH="/home/hrpr/Downloads/omarchy-3.0.1.iso"

# LibVirt connection (user session)
LIBVIRT_URI="qemu:///session"
export LIBVIRT_DEFAULT_URI="$LIBVIRT_URI"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_color() {
    echo -e "${1}${2}${NC}"
}

show_usage() {
    print_color $GREEN "Omarchy VM Management"
    echo
    echo "Usage: $0 <command>"
    echo
    echo "Commands:"
    echo "  create    - Create new Omarchy VM with RTX 3080 passthrough"
    echo "  start     - Start the VM (GPU will be bound to VM)"
    echo "  stop      - Shutdown the VM gracefully"
    echo "  force-off - Force power off the VM"
    echo "  status    - Show VM and GPU status"
    echo "  console   - Open VM console (virt-viewer)"
    echo "  gui       - Open virt-manager GUI"
    echo "  bind-gpu  - Bind GPU to VM for passthrough"
    echo "  unbind-gpu- Return GPU to host system"
    echo "  gpu-status- Show GPU binding status"
    echo "  force-stop - Force stop the VM"
    echo "  restart   - Restart the VM"
    echo "  status    - Show VM status"
    echo "  console   - Open VM console (virt-viewer)"
    echo "  gui       - Open virt-manager GUI"
    echo "  info      - Show detailed VM information"
    echo "  eject-iso - Remove the installation ISO"
    echo "  insert-iso - Insert the installation ISO"
    echo "  destroy   - Delete the VM (WARNING: Permanent!)"
    echo "  help      - Show this help"
}

vm_exists() {
    virsh --connect "$LIBVIRT_URI" dominfo "$VM_NAME" >/dev/null 2>&1
}

case "${1:-help}" in
    "create")
        print_color $BLUE "Creating Omarchy VM..."
        ./vms/omarchy-vm/create-omarchy-vm.sh
        ;;
        
    "start")
        if vm_exists; then
            if [[ "$(virsh domstate "$VM_NAME")" == "running" ]]; then
                print_color $YELLOW "VM is already running"
            else
                print_color $BLUE "Starting Omarchy VM with RTX 3080 passthrough..."
                print_color $YELLOW "💡 Tip: Connect monitor to RTX 3080 outputs (not motherboard)"
                virsh start "$VM_NAME"
                print_color $GREEN "✓ VM started successfully"
                print_color $BLUE "VM should appear on RTX 3080 connected displays"
                print_color $YELLOW "If no display, check GPU binding: $0 gpu-status"
            fi
        else
            print_color $RED "❌ VM '$VM_NAME' not found. Create it first with: $0 create"
            exit 1
        fi
        ;;
        
    "stop")
        if vm_exists; then
            if [[ "$(virsh domstate "$VM_NAME")" == "shut off" ]]; then
                print_color $YELLOW "VM is already stopped"
            else
                print_color $BLUE "Stopping Omarchy VM gracefully..."
                virsh shutdown "$VM_NAME"
                print_color $GREEN "✓ Shutdown command sent"
            fi
        else
            print_color $RED "❌ VM not found"
            exit 1
        fi
        ;;
        
    "force-stop")
        if vm_exists; then
            print_color $YELLOW "Force stopping Omarchy VM..."
            virsh destroy "$VM_NAME" 2>/dev/null || true
            print_color $GREEN "✓ VM force stopped"
        else
            print_color $RED "❌ VM not found"
            exit 1
        fi
        ;;
        
    "restart")
        if vm_exists; then
            print_color $BLUE "Restarting Omarchy VM..."
            virsh reboot "$VM_NAME"
            print_color $GREEN "✓ Restart command sent"
        else
            print_color $RED "❌ VM not found"
            exit 1
        fi
        ;;
        
    "status")
        if vm_exists; then
            state=$(virsh domstate "$VM_NAME")
            print_color $GREEN "VM Status: $state"
            
            if [[ "$state" == "running" ]]; then
                print_color $BLUE "VM Information:"
                virsh dominfo "$VM_NAME" | grep -E "(CPU|Memory|State)"
            fi
        else
            print_color $RED "❌ VM not found"
        fi
        ;;
        
    "console")
        if vm_exists; then
            if [[ "$(virsh domstate "$VM_NAME")" == "running" ]]; then
                print_color $BLUE "Opening VM console..."
                virt-viewer "$VM_NAME" >/dev/null 2>&1 &
            else
                print_color $YELLOW "VM is not running. Start it first with: $0 start"
            fi
        else
            print_color $RED "❌ VM not found"
            exit 1
        fi
        ;;
        
    "gui")
        print_color $BLUE "Opening virt-manager GUI..."
        virt-manager >/dev/null 2>&1 &
        ;;
        
    "info")
        if vm_exists; then
            print_color $GREEN "=== Omarchy VM Information ==="
            virsh dominfo "$VM_NAME"
            echo
            print_color $GREEN "=== Network Interfaces ==="
            virsh domifaddr "$VM_NAME" 2>/dev/null || echo "No network information available"
        else
            print_color $RED "❌ VM not found"
            exit 1
        fi
        ;;
        
    "eject-iso")
        if vm_exists; then
            print_color $BLUE "Ejecting installation ISO..."
            virsh change-media "$VM_NAME" sda --eject 2>/dev/null || print_color $YELLOW "No media to eject"
            print_color $GREEN "✓ ISO ejected"
        else
            print_color $RED "❌ VM not found"
            exit 1
        fi
        ;;
        
    "insert-iso")
        if vm_exists; then
            if [[ -f "$ISO_PATH" ]]; then
                print_color $BLUE "Inserting Omarchy ISO..."
                virsh change-media "$VM_NAME" sda "$ISO_PATH"
                print_color $GREEN "✓ ISO inserted"
            else
                print_color $RED "❌ ISO not found at $ISO_PATH"
                exit 1
            fi
        else
            print_color $RED "❌ VM not found"
            exit 1
        fi
        ;;
        
    "destroy")
        if vm_exists; then
            print_color $RED "⚠️ WARNING: This will permanently delete the VM and all its data!"
            read -p "Are you sure you want to destroy '$VM_NAME'? (type 'DELETE' to confirm): " confirm
            if [[ "$confirm" == "DELETE" ]]; then
                print_color $YELLOW "Destroying VM..."
                virsh destroy "$VM_NAME" 2>/dev/null || true
                virsh undefine "$VM_NAME" --remove-all-storage
                print_color $GREEN "✓ VM destroyed"
            else
                print_color $BLUE "Cancelled."
            fi
        else
            print_color $RED "❌ VM not found"
        fi
        ;;
        
    "bind-gpu")
        print_color $BLUE "Binding RTX 3080 to VM for passthrough..."
        ./gpu-passthrough.sh bind
        ;;
        
    "unbind-gpu")
        print_color $BLUE "Returning RTX 3080 to host system..."
        ./gpu-passthrough.sh unbind
        ;;
        
    "gpu-status")
        ./gpu-passthrough.sh status
        ;;
        
    "help"|"-h"|"--help")
        show_usage
        ;;
        
    *)
        print_color $RED "Unknown command: $1"
        echo
        show_usage
        exit 1
        ;;
esac
