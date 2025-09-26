#!/usr/bin/env bash

# GPU Passthrough Management for RTX 3080
# Binds/unbinds GPU from host for VM passthrough

set -euo pipefail

# Configuration
GPU_BUS_SLOT="0000:01:00.0"
AUDIO_BUS_SLOT="0000:01:00.1"
GPU_VENDOR_ID="10de"
GPU_DEVICE_ID="2216"
AUDIO_DEVICE_ID="1aef"

# Colors
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

show_status() {
    print_color $BLUE "=== Current GPU Status ==="
    echo
    
    # Check GPU driver
    gpu_driver=$(lspci -k -s $GPU_BUS_SLOT | grep "Kernel driver in use" | awk '{print $5}' || echo "none")
    audio_driver=$(lspci -k -s $AUDIO_BUS_SLOT | grep "Kernel driver in use" | awk '{print $5}' || echo "none")
    
    print_color $GREEN "GPU Status:"
    echo "  Device: $(lspci -s $GPU_BUS_SLOT)"
    echo "  Driver: $gpu_driver"
    echo
    
    print_color $GREEN "Audio Status:"
    echo "  Device: $(lspci -s $AUDIO_BUS_SLOT)"
    echo "  Driver: $audio_driver"
    echo
    
    if [[ "$gpu_driver" == "nvidia" ]]; then
        print_color $YELLOW "GPU is bound to host (NVIDIA driver)"
        print_color $BLUE "Use 'bind-gpu' to prepare for VM passthrough"
    elif [[ "$gpu_driver" == "vfio-pci" ]]; then
        print_color $GREEN "GPU is bound to VFIO for VM passthrough"
        print_color $BLUE "Use 'unbind-gpu' to return to host"
    else
        print_color $YELLOW "GPU driver status: $gpu_driver"
    fi
}

bind_gpu_to_vfio() {
    print_color $BLUE "=== Binding GPU to VFIO for Passthrough ==="
    
    # Check if already bound
    gpu_driver=$(lspci -k -s $GPU_BUS_SLOT | grep "Kernel driver in use" | awk '{print $5}' || echo "none")
    if [[ "$gpu_driver" == "vfio-pci" ]]; then
        print_color $GREEN "GPU already bound to VFIO"
        return 0
    fi
    
    print_color $YELLOW "⚠️ This will unbind GPU from host - screen may go black!"
    read -p "Continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_color $BLUE "Cancelled"
        return 1
    fi
    
    # Unbind from current driver
    if [[ "$gpu_driver" != "none" ]]; then
        print_color $BLUE "Unbinding GPU from $gpu_driver..."
        echo "$GPU_BUS_SLOT" | sudo tee /sys/bus/pci/drivers/$gpu_driver/unbind > /dev/null || true
    fi
    
    # Unbind audio
    audio_driver=$(lspci -k -s $AUDIO_BUS_SLOT | grep "Kernel driver in use" | awk '{print $5}' || echo "none")
    if [[ "$audio_driver" != "none" ]]; then
        print_color $BLUE "Unbinding audio from $audio_driver..."
        echo "$AUDIO_BUS_SLOT" | sudo tee /sys/bus/pci/drivers/$audio_driver/unbind > /dev/null || true
    fi
    
    # Bind to VFIO
    print_color $BLUE "Binding to VFIO..."
    echo "$GPU_VENDOR_ID $GPU_DEVICE_ID" | sudo tee /sys/bus/pci/drivers/vfio-pci/new_id > /dev/null || true
    echo "$GPU_VENDOR_ID $AUDIO_DEVICE_ID" | sudo tee /sys/bus/pci/drivers/vfio-pci/new_id > /dev/null || true
    
    sleep 2
    print_color $GREEN "✓ GPU bound to VFIO for passthrough"
    show_status
}

unbind_gpu_from_vfio() {
    print_color $BLUE "=== Returning GPU to Host ==="
    
    # Unbind from VFIO
    print_color $BLUE "Unbinding from VFIO..."
    echo "$GPU_BUS_SLOT" | sudo tee /sys/bus/pci/drivers/vfio-pci/unbind > /dev/null || true
    echo "$AUDIO_BUS_SLOT" | sudo tee /sys/bus/pci/drivers/vfio-pci/unbind > /dev/null || true
    
    # Remove from VFIO
    echo "$GPU_VENDOR_ID $GPU_DEVICE_ID" | sudo tee /sys/bus/pci/drivers/vfio-pci/remove_id > /dev/null || true
    echo "$GPU_VENDOR_ID $AUDIO_DEVICE_ID" | sudo tee /sys/bus/pci/drivers/vfio-pci/remove_id > /dev/null || true
    
    # Rescan PCI bus to rebind to host drivers
    print_color $BLUE "Rescanning PCI bus..."
    echo 1 | sudo tee /sys/bus/pci/rescan > /dev/null
    
    sleep 3
    print_color $GREEN "✓ GPU returned to host"
    show_status
}

case "${1:-status}" in
    "status"|"show")
        show_status
        ;;
    "bind"|"bind-gpu")
        bind_gpu_to_vfio
        ;;
    "unbind"|"unbind-gpu")
        unbind_gpu_from_vfio
        ;;
    "help"|"-h"|"--help")
        print_color $GREEN "GPU Passthrough Management"
        echo
        echo "Usage: $0 <command>"
        echo
        echo "Commands:"
        echo "  status    - Show current GPU binding status (default)"
        echo "  bind      - Bind GPU to VFIO for VM passthrough"
        echo "  unbind    - Return GPU to host system"
        echo "  help      - Show this help"
        echo
        echo "Examples:"
        echo "  $0 status   # Check current state"
        echo "  $0 bind     # Prepare for VM (screen may go black)"
        echo "  $0 unbind   # Return to host system"
        ;;
    *)
        print_color $RED "Unknown command: $1"
        print_color $BLUE "Use '$0 help' for usage information"
        exit 1
        ;;
esac
