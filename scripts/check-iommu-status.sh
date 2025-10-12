#!/usr/bin/env bash

# IOMMU and GPU Passthrough Status Checker
set -euo pipefail

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

print_color $BLUE "=== IOMMU and GPU Passthrough Status ==="

# Check if IOMMU is enabled in kernel
print_color $BLUE "\n1. IOMMU Kernel Status:"
if sudo dmesg | grep -q "DMAR: IOMMU enabled"; then
    print_color $GREEN "✓ Intel IOMMU enabled"
else
    print_color $RED "❌ Intel IOMMU not enabled"
fi

if sudo dmesg | grep -q "AMD-Vi: AMD IOMMUv2 loaded and initialized"; then
    print_color $GREEN "✓ AMD IOMMU enabled"
else
    print_color $YELLOW "ℹ AMD IOMMU not detected (expected on Intel system)"
fi

# Check IOMMU kernel parameters
print_color $BLUE "\n2. Kernel Parameters:"
if grep -q "intel_iommu=on" /proc/cmdline; then
    print_color $GREEN "✓ intel_iommu=on"
else
    print_color $RED "❌ intel_iommu=on missing"
fi

if grep -q "iommu=pt" /proc/cmdline; then
    print_color $GREEN "✓ iommu=pt (passthrough mode)"
else
    print_color $YELLOW "⚠ iommu=pt not set"
fi

# Check VFIO modules
print_color $BLUE "\n3. VFIO Modules:"
vfio_modules=("vfio" "vfio_pci" "vfio_iommu_type1")
for module in "${vfio_modules[@]}"; do
    if lsmod | grep -q "^$module"; then
        print_color $GREEN "✓ $module loaded"
    else
        print_color $YELLOW "⚠ $module not loaded"
    fi
done

# Check GPU and its IOMMU group
print_color $BLUE "\n4. NVIDIA RTX 3080 Status:"
gpu_info=$(lspci | grep "VGA.*NVIDIA" || echo "")
if [[ -n "$gpu_info" ]]; then
    gpu_addr=$(echo "$gpu_info" | cut -d' ' -f1)
    print_color $GREEN "✓ GPU found: $gpu_info"
    print_color $BLUE "GPU address: $gpu_addr"
    
    # Find IOMMU group
    iommu_group=""
    for group in /sys/kernel/iommu_groups/*/devices/*; do
        if [[ $(basename "$group") == "0000:$gpu_addr" ]]; then
            iommu_group=$(basename $(dirname $(dirname "$group")))
            break
        fi
    done
    
    if [[ -n "$iommu_group" ]]; then
        print_color $GREEN "✓ GPU IOMMU group: $iommu_group"
        print_color $BLUE "Devices in group $iommu_group:"
        for device in /sys/kernel/iommu_groups/$iommu_group/devices/*; do
            device_addr=$(basename "$device")
            device_info=$(lspci -s ${device_addr#0000:} 2>/dev/null || echo "Unknown")
            print_color $BLUE "  - $device_addr: $device_info"
        done
    else
        print_color $RED "❌ GPU IOMMU group not found"
    fi
else
    print_color $RED "❌ NVIDIA GPU not found"
fi

# Check KVM and virtualization
print_color $BLUE "\n5. Virtualization Status:"
if [[ -e /dev/kvm ]]; then
    print_color $GREEN "✓ /dev/kvm exists"
else
    print_color $RED "❌ /dev/kvm missing"
fi

if lsmod | grep -q kvm_intel; then
    print_color $GREEN "✓ kvm_intel loaded"
elif lsmod | grep -q kvm_amd; then
    print_color $GREEN "✓ kvm_amd loaded"  
else
    print_color $RED "❌ No KVM module loaded"
fi

# Check libvirt
print_color $BLUE "\n6. Libvirt Status:"
if systemctl is-active libvirtd >/dev/null 2>&1; then
    print_color $GREEN "✓ libvirtd service running"
else
    print_color $RED "❌ libvirtd service not running"
fi

# Check current VM status if exists
VM_NAME="omarchy"
print_color $BLUE "\n7. Omarchy VM Status:"
if virsh -c qemu:///session dominfo "$VM_NAME" >/dev/null 2>&1; then
    vm_state=$(virsh -c qemu:///session domstate "$VM_NAME")
    print_color $GREEN "✓ VM exists, state: $vm_state"
    
    # Check if VM has GPU passthrough
    if virsh -c qemu:///session dumpxml "$VM_NAME" | grep -q "<hostdev.*pci"; then
        print_color $GREEN "✓ VM has PCI device passthrough configured"
    else
        print_color $YELLOW "⚠ VM does not have PCI device passthrough"
    fi
else
    print_color $YELLOW "ℹ VM does not exist"
fi

# Summary and recommendations
print_color $BLUE "\n=== Summary and Recommendations ==="

# Check if everything is ready for GPU passthrough
iommu_ready=true
gpu_found=false
vfio_ready=false

if ! sudo dmesg | grep -q "DMAR: IOMMU enabled"; then
    iommu_ready=false
fi

if lspci | grep -q "VGA.*NVIDIA"; then
    gpu_found=true
fi

if lsmod | grep -q "vfio"; then
    vfio_ready=true
fi

if [[ "$iommu_ready" == true ]] && [[ "$gpu_found" == true ]]; then
    print_color $GREEN "✅ System is ready for GPU passthrough!"
    print_color $BLUE "Next steps:"
    print_color $BLUE "1. Run: ./enable-gpu-passthrough.sh"
    print_color $BLUE "2. Install NVIDIA drivers inside the VM"
    print_color $BLUE "3. Configure display output to use passed-through GPU"
else
    print_color $RED "❌ System is not ready for GPU passthrough"
    if [[ "$iommu_ready" != true ]]; then
        print_color $YELLOW "• Enable VT-d/IOMMU in BIOS settings"
        print_color $YELLOW "• Verify intel_iommu=on kernel parameter"
    fi
    if [[ "$gpu_found" != true ]]; then
        print_color $YELLOW "• NVIDIA GPU not detected"
    fi
fi
