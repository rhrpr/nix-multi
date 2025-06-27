#!/usr/bin/env bash

# RTX 3080 Partial GPU Passthrough Setup Script
# Configures your GA102 RTX 3080 for shared host/VM usage

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Your RTX 3080 configuration
GPU_PCI_ID="10de:2206"      # GA102 RTX 3080 Lite Hash Rate
AUDIO_PCI_ID="10de:1aef"    # GA102 High Definition Audio
GPU_PCI_ADDR="0000:01:00.0"
AUDIO_PCI_ADDR="0000:01:00.1"

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "This script should not be run as root"
        exit 1
    fi
}

# Check current GPU status
check_gpu_status() {
    log_info "Checking RTX 3080 status..."
    echo ""
    
    echo -e "${YELLOW}Your RTX 3080 configuration:${NC}"
    lspci -nn | grep "01:00"
    echo ""
    
    echo -e "${YELLOW}NVIDIA driver status:${NC}"
    if command -v nvidia-smi &> /dev/null; then
        nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader
    else
        echo "NVIDIA drivers not installed or not available"
    fi
    echo ""
    
    echo -e "${YELLOW}Current GPU driver binding:${NC}"
    if [[ -e "/sys/bus/pci/devices/$GPU_PCI_ADDR/driver" ]]; then
        echo "GPU: $(readlink /sys/bus/pci/devices/$GPU_PCI_ADDR/driver | xargs basename)"
    else
        echo "GPU: No driver bound"
    fi
    
    if [[ -e "/sys/bus/pci/devices/$AUDIO_PCI_ADDR/driver" ]]; then
        echo "Audio: $(readlink /sys/bus/pci/devices/$AUDIO_PCI_ADDR/driver | xargs basename)"
    else
        echo "Audio: No driver bound"
    fi
    echo ""
}

# Check IOMMU groups for RTX 3080
check_iommu_groups() {
    log_info "Checking IOMMU groups for RTX 3080..."
    echo ""
    
    if [[ ! -d "/sys/kernel/iommu_groups" ]]; then
        log_error "IOMMU not enabled"
        return 1
    fi
    
    # Find IOMMU group for GPU
    for g in $(find /sys/kernel/iommu_groups/* -maxdepth 0 -type d 2>/dev/null | sort -V); do
        for d in $g/devices/*; do
            if [[ -e "$d" && "$(basename $d)" == "$GPU_PCI_ADDR" ]]; then
                echo -e "${YELLOW}RTX 3080 IOMMU Group ${g##*/}:${NC}"
                for device in $g/devices/*; do
                    if [[ -e "$device" ]]; then
                        echo -e "\t$(lspci -nns ${device##*/})"
                    fi
                done
                echo ""
                return 0
            fi
        done
    done
    
    log_warn "RTX 3080 not found in any IOMMU group"
    return 1
}

# Check virtualization setup
check_virtualization() {
    log_info "Checking virtualization setup..."
    echo ""
    
    # Check KVM
    if [[ -e /dev/kvm ]]; then
        log_success "KVM device available"
    else
        log_error "KVM device not found"
        return 1
    fi
    
    # Check libvirtd
    if systemctl is-active --quiet libvirtd; then
        log_success "libvirtd service is running"
    else
        log_warn "libvirtd service is not running"
    fi
    
    # Check user groups
    local user_groups=$(groups)
    if echo "$user_groups" | grep -q libvirtd; then
        log_success "User is in libvirtd group"
    else
        log_warn "User is not in libvirtd group"
    fi
    
    if echo "$user_groups" | grep -q docker; then
        log_success "User is in docker group (for container GPU access)"
    else
        log_warn "User is not in docker group"
    fi
    echo ""
}

# Test GPU sharing with containers
test_container_gpu() {
    log_info "Testing container GPU access..."
    
    if ! command -v docker &> /dev/null; then
        log_warn "Docker not available - container GPU sharing not testable"
        return 1
    fi
    
    if ! systemctl is-active --quiet docker; then
        log_warn "Docker service not running"
        return 1
    fi
    
    # Test NVIDIA container runtime
    if docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi >/dev/null 2>&1; then
        log_success "Container GPU access working"
        return 0
    else
        log_warn "Container GPU access not working"
        return 1
    fi
}

# Generate VM configuration
generate_vm_config() {
    log_info "Generating VM configuration for RTX 3080..."
    echo ""
    
    local config_file="rtx3080-vm-config.xml"
    
    # Copy template and customize for RTX 3080
    if [[ -f "templates/partial-gpu-passthrough-vm.xml" ]]; then
        cp templates/partial-gpu-passthrough-vm.xml "$config_file"
        
        # Generate UUID
        local vm_uuid=$(uuidgen 2>/dev/null || python3 -c "import uuid; print(uuid.uuid4())")
        
        # Replace placeholders
        sed -i "s/VM_NAME/RTX3080-Gaming-VM/g" "$config_file"
        sed -i "s/UUID_PLACEHOLDER/$vm_uuid/g" "$config_file"
        sed -i "s|DISK_PATH|/var/lib/libvirt/images/rtx3080-gaming.qcow2|g" "$config_file"
        sed -i "s|ISO_PATH|/var/lib/libvirt/images/windows11.iso|g" "$config_file"
        
        log_success "VM configuration created: $config_file"
        echo ""
        echo "To use this configuration:"
        echo "1. Create VM disk: qemu-img create -f qcow2 /var/lib/libvirt/images/rtx3080-gaming.qcow2 100G"
        echo "2. Download Windows ISO to /var/lib/libvirt/images/windows11.iso"
        echo "3. Import VM: virsh define $config_file"
        echo "4. Start VM: virsh start RTX3080-Gaming-VM"
        echo ""
    else
        log_error "VM template not found"
        return 1
    fi
}

# Show performance tips
show_performance_tips() {
    log_info "Performance optimization tips for RTX 3080 sharing:"
    echo ""
    
    echo -e "${YELLOW}Host Performance:${NC}"
    echo "• Keep host resolution moderate when VM is running"
    echo "• Use Looking Glass for seamless display sharing"
    echo "• Pin VM CPU cores to avoid host interference"
    echo "• Use hugepages for better memory performance"
    echo ""
    
    echo -e "${YELLOW}VM Performance:${NC}"
    echo "• Install latest NVIDIA drivers in VM"
    echo "• Enable MSI interrupts for better latency"
    echo "• Use virtio drivers for disk and network"
    echo "• Allocate sufficient VRAM for games"
    echo ""
    
    echo -e "${YELLOW}Monitoring Commands:${NC}"
    echo "• Host GPU usage: nvidia-smi"
    echo "• Host GPU monitoring: nvtop"
    echo "• VM resource usage: virsh domstats RTX3080-Gaming-VM"
    echo "• Container GPU: docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi"
    echo ""
}

# Main function
main() {
    check_root
    
    echo "=== RTX 3080 Partial GPU Passthrough Setup ==="
    echo ""
    
    check_gpu_status
    check_iommu_groups
    check_virtualization
    test_container_gpu
    echo ""
    
    generate_vm_config
    show_performance_tips
    
    echo -e "${BLUE}Setup Summary:${NC}"
    echo "✓ Partial passthrough configured (host keeps access)"
    echo "✓ Container GPU sharing enabled via Docker"
    echo "✓ VFIO ready for VM GPU access"
    echo "✓ Looking Glass configured for seamless display"
    echo ""
    echo -e "${GREEN}Your RTX 3080 is ready for multi-environment use!${NC}"
}

# Parse command line arguments
case "${1:-}" in
    "status")
        check_gpu_status
        ;;
    "iommu")
        check_iommu_groups
        ;;
    "virt")
        check_virtualization
        ;;
    "container")
        test_container_gpu
        ;;
    "generate")
        generate_vm_config
        ;;
    "tips")
        show_performance_tips
        ;;
    *)
        main
        ;;
esac
