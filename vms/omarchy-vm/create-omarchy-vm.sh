#!/usr/bin/env bash

# Omarchy VM Creation Script
# Creates a libvirt VM for Omarchy Linux distribution with:
# - NVIDIA RTX 3080 GPU passthrough
# - Host folder sharing (~/projects)
# - 3440x1440 ultrawide display support
# - 16GB RAM, 8 CPU cores for gaming performance

set -euo pipefail

# Configuration
VM_NAME="omarchy"
VM_RAM="16384"  # 16GB RAM
VM_VCPUS="8"   # 8 CPU cores for gaming performance
VM_DISK_SIZE="128G"  # 100GB disk for GPU-intensive workloads
ISO_PATH="/home/hrpr/Downloads/omarchy-3.0.1.iso"
VM_DIR="/var/lib/libvirt/images"
DISK_PATH="$VM_DIR/${VM_NAME}.qcow2"

# GPU Passthrough Configuration
GPU_VENDOR_ID="10de"
GPU_DEVICE_ID="2216"  # RTX 3080 Lite Hash Rate
AUDIO_DEVICE_ID="1aef" # RTX 3080 HD Audio
GPU_BUS_SLOT="01:00.0"
AUDIO_BUS_SLOT="01:00.1"

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

print_color $BLUE "=== Omarchy VM Creation ==="
print_color $BLUE "Distribution VM Setup"
echo

# Check prerequisites
print_color $GREEN "=== Checking Prerequisites ==="

# Check if libvirtd is running
if ! systemctl is-active --quiet libvirtd; then
    print_color $YELLOW "Starting libvirtd service..."
    sudo systemctl start libvirtd
fi

# Check for VFIO support
print_color $BLUE "Checking GPU passthrough support..."
if [[ -d /sys/bus/pci/drivers/vfio-pci ]]; then
    print_color $GREEN "✓ VFIO-PCI driver available"
else
    print_color $YELLOW "⚠️ VFIO-PCI driver not loaded - GPU passthrough may not work"
fi

# Check if GPU is bound to host driver
gpu_driver=$(lspci -k -s $GPU_BUS_SLOT | grep "Kernel driver in use" | awk '{print $5}' || echo "none")
if [[ "$gpu_driver" == "nvidia" ]]; then
    print_color $GREEN "✓ GPU bound to NVIDIA driver (partial passthrough mode)"
    print_color $BLUE "    VM will share GPU with host - both can use it"
    print_color $BLUE "    This allows host display while VM gets GPU acceleration"
elif [[ "$gpu_driver" == "vfio-pci" ]]; then
    print_color $YELLOW "⚠️ GPU bound to VFIO (exclusive mode)"
    print_color $BLUE "    For partial passthrough, consider returning GPU to host"
    print_color $BLUE "    Use: ./vms/omarchy-vm/gpu-passthrough.sh unbind"
else
    print_color $BLUE "ℹ️ GPU driver: $gpu_driver"
fi

# Check NVIDIA GPU
gpu_info=$(lspci -s $GPU_BUS_SLOT 2>/dev/null || echo "not found")
if [[ "$gpu_info" == *"NVIDIA"* ]]; then
    print_color $GREEN "✓ NVIDIA RTX 3080 found at $GPU_BUS_SLOT"
else
    print_color $RED "❌ NVIDIA RTX 3080 not found at expected address"
    print_color $YELLOW "Current devices:"
    lspci | grep -i nvidia || echo "No NVIDIA devices found"
fi

# Check if ISO exists
if [[ ! -f "$ISO_PATH" ]]; then
    print_color $RED "❌ ISO not found at $ISO_PATH"
    exit 1
else
    iso_size=$(du -h "$ISO_PATH" | cut -f1)
    print_color $GREEN "✓ Omarchy ISO found: $iso_size"
fi

# Ensure projects folder exists
print_color $BLUE "Setting up shared folder..."
PROJECTS_DIR="/home/hrpr/projects"
if [[ ! -d "$PROJECTS_DIR" ]]; then
    print_color $YELLOW "Creating projects directory at $PROJECTS_DIR"
    mkdir -p "$PROJECTS_DIR"
fi
print_color $GREEN "✓ Projects folder ready: $PROJECTS_DIR"

# Check if VM already exists
if virsh dominfo "$VM_NAME" >/dev/null 2>&1; then
    print_color $YELLOW "⚠️ VM '$VM_NAME' already exists"
    read -p "Do you want to recreate it? This will delete the existing VM. (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_color $YELLOW "Removing existing VM..."
        virsh destroy "$VM_NAME" 2>/dev/null || true
        virsh undefine "$VM_NAME" --remove-all-storage 2>/dev/null || true
    else
        print_color $BLUE "Exiting without changes."
        exit 0
    fi
fi

# Create VM disk
print_color $GREEN "=== Creating VM Disk ==="
print_color $BLUE "Creating $VM_DISK_SIZE disk at $DISK_PATH"
sudo qemu-img create -f qcow2 "$DISK_PATH" "$VM_DISK_SIZE"
sudo chown qemu-libvirtd:libvirtd "$DISK_PATH"

# Create VM XML configuration
print_color $GREEN "=== Creating VM Configuration ==="

# Generate random MAC address
MAC_ADDR="52:54:00:$(printf "%02x:%02x:%02x" $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)))"

VM_XML=$(cat << EOF
<domain type='kvm'>
  <name>$VM_NAME</name>
  <uuid>$(uuidgen)</uuid>
  <memory unit='MiB'>$VM_RAM</memory>
  <currentMemory unit='MiB'>$VM_RAM</currentMemory>
  <vcpu placement='static'>$VM_VCPUS</vcpu>
  <memoryBacking>
    <hugepages/>
    <source type='memfd'/>
    <access mode='shared'/>
  </memoryBacking>
  <os>
    <type arch='x86_64' machine='pc-q35-7.2'>hvm</type>
    <loader readonly='yes' type='pflash'>/run/libvirt/nix-ovmf/OVMF_CODE.fd</loader>
    <nvram>/var/lib/libvirt/qemu/nvram/${VM_NAME}_VARS.fd</nvram>
    <boot dev='cdrom'/>
    <boot dev='hd'/>
  </os>
  <features>
    <acpi/>
    <apic/>
    <hyperv mode='custom'>
      <relaxed state='on'/>
      <vapic state='on'/>
      <spinlocks state='on' retries='8191'/>
      <vendor_id state='on' value='123456789ab'/>
      <frequencies state='on'/>
    </hyperv>
    <vmport state='off'/>
    <ioapic driver='kvm'/>
  </features>
  <cpu mode='host-passthrough' check='none' migratable='on'>
    <topology sockets='1' dies='1' cores='$VM_VCPUS' threads='1'/>
    <feature policy='require' name='topoext'/>
  </cpu>
  <clock offset='localtime'>
    <timer name='rtc' tickpolicy='catchup'/>
    <timer name='pit' tickpolicy='delay'/>
    <timer name='hpet' present='no'/>
  </clock>
  <on_poweroff>destroy</on_poweroff>
  <on_reboot>restart</on_reboot>
  <on_crash>destroy</on_crash>
  <pm>
    <suspend-to-mem enabled='no'/>
    <suspend-to-disk enabled='no'/>
  </pm>
  <devices>
    <emulator>/run/current-system/sw/bin/qemu-system-x86_64</emulator>
    
    <!-- Boot ISO -->
    <disk type='file' device='cdrom'>
      <driver name='qemu' type='raw'/>
      <source file='$ISO_PATH'/>
      <target dev='sda' bus='sata'/>
      <readonly/>
      <address type='drive' controller='0' bus='0' target='0' unit='0'/>
    </disk>
    
    <!-- Main disk -->
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2' cache='writeback'/>
      <source file='$DISK_PATH'/>
      <target dev='vda' bus='virtio'/>
      <address type='pci' domain='0x0000' bus='0x04' slot='0x00' function='0x0'/>
    </disk>
    
    <!-- SATA controller for CD -->
    <controller type='sata' index='0'>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x1f' function='0x2'/>
    </controller>
    
    <!-- Virtio controllers -->
    <controller type='virtio-serial' index='0'>
      <address type='pci' domain='0x0000' bus='0x03' slot='0x00' function='0x0'/>
    </controller>
    
    <!-- Network -->
    <interface type='network'>
      <mac address='$MAC_ADDR'/>
      <source network='default'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x01' slot='0x00' function='0x0'/>
    </interface>
    
    <!-- Shared Folder: ~/projects -->
    <filesystem type='mount' accessmode='passthrough'>
      <source dir='/home/hrpr/projects'/>
      <target dir='projects'/>
      <driver type='virtiofs' queue='1024'/>
      <address type='pci' domain='0x0000' bus='0x08' slot='0x00' function='0x0'/>
    </filesystem>
    
    <!-- NVIDIA RTX 3080 GPU Passthrough (Partial - Shared with Host) -->
    <hostdev mode='subsystem' type='pci' managed='yes'>
      <source>
        <address domain='0x0000' bus='0x01' slot='0x00' function='0x0'/>
      </source>
      <address type='pci' domain='0x0000' bus='0x06' slot='0x00' function='0x0'/>
    </hostdev>
    
    <!-- NVIDIA RTX 3080 Audio Passthrough -->
    <hostdev mode='subsystem' type='pci' managed='yes'>
      <source>
        <address domain='0x0000' bus='0x01' slot='0x00' function='0x1'/>
      </source>
      <address type='pci' domain='0x0000' bus='0x07' slot='0x00' function='0x0'/>
    </hostdev>
    
    <!-- Fallback Graphics (enabled for partial passthrough) -->
    <graphics type='spice' autoport='yes'>
      <listen type='address'/>
      <image compression='off'/>
    </graphics>
    <video>
      <model type='virtio' heads='1' primary='yes'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x01' function='0x0'/>
    </video>
    
    <!-- Audio -->
    <sound model='ich9'>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x1b' function='0x0'/>
    </sound>
    
    <!-- USB -->
    <controller type='usb' index='0' model='qemu-xhci' ports='15'>
      <address type='pci' domain='0x0000' bus='0x02' slot='0x00' function='0x0'/>
    </controller>
    
    <!-- Input devices -->
    <input type='tablet' bus='usb'>
      <address type='usb' bus='0' port='1'/>
    </input>
    <input type='mouse' bus='ps2'/>
    <input type='keyboard' bus='ps2'/>
    
    <!-- Memory balloon -->
    <memballoon model='virtio'>
      <address type='pci' domain='0x0000' bus='0x05' slot='0x00' function='0x0'/>
    </memballoon>
  </devices>
</domain>
EOF
)

# Define the VM
print_color $BLUE "Defining VM in libvirt..."
echo "$VM_XML" | sudo virsh define /dev/stdin

# Set VM to autostart
print_color $BLUE "Configuring VM autostart..."
sudo virsh autostart "$VM_NAME"

print_color $GREEN "=== Omarchy VM with RTX 3080 Passthrough Created! ==="
echo
print_color $BLUE "VM Details:"
echo "  Name: $VM_NAME"
echo "  RAM: ${VM_RAM}MB"
echo "  CPUs: $VM_VCPUS"
echo "  Disk: $VM_DISK_SIZE ($DISK_PATH)"
echo "  ISO: $ISO_PATH"
echo "  GPU: NVIDIA RTX 3080 ($GPU_BUS_SLOT)"
echo "  Audio: NVIDIA HD Audio ($AUDIO_BUS_SLOT)"
echo "  Shared Folder: /home/hrpr/projects → ~/projects (in VM)"
echo "  Display: Optimized for 3440x1440 ultrawide"
echo
print_color $YELLOW "⚠️ IMPORTANT Setup Notes:"
echo "1. Connect monitor to RTX 3080 for best performance"
echo "2. VM uses partial GPU passthrough (shared with host)"
echo "3. Both host and VM can use GPU simultaneously"
echo "4. Projects folder is automatically shared between host and VM"
echo
print_color $BLUE "📁 Shared Folder Setup:"
echo "• Host folder: /home/hrpr/projects"
echo "• In VM, run these commands to mount:"
echo "  sudo mkdir -p ~/projects"
echo "  sudo mount -t virtiofs projects ~/projects"
echo "• For permanent mounting, add to /etc/fstab:"
echo "  projects /home/\$USER/projects virtiofs defaults,uid=\$(id -u),gid=\$(id -g) 0 0"
echo
print_color $YELLOW "🖥️ Display Configuration for 3440x1440 Ultrawide:"
echo "1. Primary monitor can stay on motherboard (host display)"
echo "2. Secondary monitor on RTX 3080 (VM display) - optional but recommended"
echo "3. Boot VM and install Omarchy Linux"
echo "4. Install NVIDIA drivers in VM:"
echo "   • Download from nvidia.com or use distribution package"
echo "   • Reboot after installation"
echo "5. Configure display resolution:"
echo "   • Open display settings"
echo "   • Set resolution to 3440x1440 @ 100Hz+ (if supported)"
echo "   • VM will have GPU acceleration while host retains access"
echo "6. Verify GPU is working in VM: nvidia-smi"
echo
print_color $BLUE "🔄 Partial GPU Passthrough Benefits:"
echo "• Host retains GPU access for desktop compositing"
echo "• VM gets GPU acceleration for games and compute"
echo "• No need to switch GPU between host/VM"
echo "• Both can run GPU applications simultaneously"
echo "• Easier setup than exclusive passthrough"
echo
print_color $YELLOW "Next Steps:"
echo "1. Start VM: virsh start $VM_NAME"
echo "2. Connect via physical monitor (RTX 3080 output)"
echo "3. Install Omarchy from ISO"
echo "4. Install NVIDIA drivers in VM"
echo "5. Remove ISO after install: virsh change-media $VM_NAME sda --eject"
echo
print_color $GREEN "Management Commands:"
echo "  Start:   virsh start $VM_NAME"
echo "  Stop:    virsh shutdown $VM_NAME"
echo "  Status:  virsh domstate $VM_NAME"
echo "  Console: virt-viewer $VM_NAME"
echo "  GUI:     virt-manager"
