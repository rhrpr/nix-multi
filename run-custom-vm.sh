#!/usr/bin/env bash

# Custom VM runner with ultrawide resolution and folder sharing
# This script wraps the generated VM runner and adds our custom configuration

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Check if VM is built
if [[ ! -f "./result/bin/run-nixos-vm-hyprland-vm" ]]; then
    log_error "VM not built. Building now..."
    ./vm-build.sh x86_64 build
fi

# Ensure projects directory exists
mkdir -p ~/projects

# Get the VM runner script
VM_SCRIPT="./result/bin/run-nixos-vm-hyprland-vm"

log_info "Starting NixOS Hyprland VM with custom configuration..."
log_info "Ultrawide Resolution: 3440x1440"
log_info "Folder Sharing: ~/projects <-> /home/hrpr/projects"
log_warn "Use Ctrl+Alt+G to release mouse from VM"
log_warn "SSH access available on localhost:22000 (user: hrpr, password: nixos)"

# Create a disk image name with timestamp to avoid conflicts
DISK_IMAGE="nixos-vm-$(date +%Y%m%d-%H%M%S).qcow2"

# Read the VM script to extract the QEMU command and modify it
# We'll extract the base command and replace it with our custom options
QEMU_BASE="/nix/store/w0ckk2gs98955zp05rkm9cpdv773q2p4-qemu-host-cpu-only-9.2.3/bin/qemu-system-x86_64"

# Check if we can find qemu
if ! command -v qemu-system-x86_64 &> /dev/null; then
    # Use the nix store path
    if [[ ! -f "$QEMU_BASE" ]]; then
        # Find qemu in nix store
        QEMU_BASE=$(find /nix/store -name "qemu-system-x86_64" -type f 2>/dev/null | head -1)
        if [[ -z "$QEMU_BASE" ]]; then
            log_error "QEMU not found. Please ensure it's available."
            exit 1
        fi
    fi
else
    QEMU_BASE="qemu-system-x86_64"
fi

log_info "Using QEMU: $QEMU_BASE"

# Create temporary directory for VM
TMPDIR=$(mktemp -d nix-vm.XXXXXXXXXX --tmpdir)
mkdir -p "$TMPDIR/xchg"

# Set disk image path
NIX_DISK_IMAGE="./nixos-vm-hyprland.qcow2"

# Create disk image if it doesn't exist
if [[ ! -f "$NIX_DISK_IMAGE" ]]; then
    log_info "Creating VM disk image..."
    temp=$(mktemp)
    "$QEMU_BASE" -f raw -o size=1024M "$temp"
    mkfs.ext4 -L nixos "$temp" >/dev/null 2>&1
    "$QEMU_BASE" convert -f raw -O qcow2 "$temp" "$NIX_DISK_IMAGE"
    rm "$temp"
    log_success "VM disk image created: $NIX_DISK_IMAGE"
fi

# Extract kernel and initrd paths from the original script
KERNEL_PATH=$(grep -o '/nix/store/[^/]*/kernel' "$VM_SCRIPT" | head -1)
INITRD_PATH=$(grep -o '/nix/store/[^/]*/initrd' "$VM_SCRIPT" | head -1)
SYSTEM_PATH=$(grep -o '/nix/store/[^-]*-nixos-system-[^/]*' "$VM_SCRIPT" | head -1)

if [[ -z "$KERNEL_PATH" || -z "$INITRD_PATH" || -z "$SYSTEM_PATH" ]]; then
    log_error "Could not extract kernel/initrd paths from VM script"
    exit 1
fi

log_info "Kernel: $KERNEL_PATH"
log_info "Initrd: $INITRD_PATH"
log_info "System: $SYSTEM_PATH"

# Build custom QEMU command with ultrawide resolution and folder sharing
exec "$QEMU_BASE" \
    -machine accel=kvm:tcg \
    -cpu max \
    -name nixos-vm-hyprland \
    -m 8G \
    -smp 4 \
    -device virtio-rng-pci \
    -net nic,netdev=user.0,model=virtio \
    -netdev user,id=user.0,hostfwd=tcp::22000-:22 \
    -device virtio-gpu-pci,xres=3440,yres=1440 \
    -display gtk,gl=on \
    -virtfs local,path=/nix/store,security_model=none,mount_tag=nix-store \
    -virtfs local,path="$TMPDIR/xchg",security_model=none,mount_tag=xchg \
    -virtfs local,path="$HOME/projects",security_model=none,mount_tag=projects,id=projects \
    -drive cache=writeback,file="$NIX_DISK_IMAGE",id=drive1,if=none,index=1,werror=report \
    -device virtio-blk-pci,bootindex=1,drive=drive1,serial=root \
    -device virtio-keyboard \
    -usb \
    -device usb-tablet,bus=usb-bus.0 \
    -kernel "$KERNEL_PATH" \
    -initrd "$INITRD_PATH" \
    -append "$(cat "$SYSTEM_PATH/kernel-params") init=$SYSTEM_PATH/init regInfo=$(find /nix/store -name "closure-info" -type d | grep "$(basename "$SYSTEM_PATH")" | head -1)/registration console=ttyS0,115200n8 console=tty0" \
    "$@"
