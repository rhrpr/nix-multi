#!/usr/bin/env bash

# macOS VM Runner Script for NixOS Hyprland VM
# Uses QEMU with macOS-specific optimizations

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
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

# Check if QEMU is available
check_qemu() {
    if ! command -v qemu-system-x86_64 >/dev/null 2>&1; then
        log_error "QEMU not found. Install with: brew install qemu"
        exit 1
    fi
    
    log_info "Using QEMU: $(which qemu-system-x86_64)"
}

# Detect architecture
ARCH=$(uname -m)
log_info "Detected architecture: $ARCH"

# Set VM runner based on architecture
if [[ "$ARCH" == "arm64" ]]; then
    VM_RUNNER="./result/bin/run-nixos-vm-hyprland-vm"
    QEMU_ACCEL="hvf"  # Use Hypervisor.framework on Apple Silicon
    QEMU_CPU="host"
    MEMORY="6G"  # Less memory for Apple Silicon
else
    VM_RUNNER="./result/bin/run-nixos-vm-hyprland-vm" 
    QEMU_ACCEL="hvf"  # Use Hypervisor.framework on Intel Mac too
    QEMU_CPU="host"
    MEMORY="8G"
fi

# Check if VM was built
if [[ ! -f "$VM_RUNNER" ]]; then
    log_error "VM not built. Run 'make vm-build-macos' first."
    exit 1
fi

# Ensure projects directory exists
mkdir -p ~/projects

# Create test file if it doesn't exist
if [[ ! -f ~/projects/test-sharing.txt ]]; then
    echo "Hello from macOS host! This file should be visible in the VM." > ~/projects/test-sharing.txt
    log_info "Created test file: ~/projects/test-sharing.txt"
fi

log_info "Starting NixOS VM on macOS..."
log_info "Memory: $MEMORY"
log_info "Acceleration: $QEMU_ACCEL"
log_info "Projects folder: ~/projects -> VM:/home/hrpr/projects"
log_warn "Use Cmd+Option+G to release mouse cursor"
log_warn "SSH available on localhost:22000 (user: hrpr, password: nixos)"

# Check QEMU availability
check_qemu

# Set macOS-specific QEMU options
export QEMU_OPTS="-m $MEMORY -smp 2 -accel $QEMU_ACCEL -cpu $QEMU_CPU -device virtio-gpu-pci,xres=3440,yres=1440 -display cocoa,gl=off -virtfs local,path=$HOME/projects,security_model=none,mount_tag=projects,id=projects -netdev user,id=user.0,hostfwd=tcp::22000-:22 -device virtio-net,netdev=user.0"

# Start the VM
log_info "Launching VM with QEMU options: $QEMU_OPTS"
exec "$VM_RUNNER"
