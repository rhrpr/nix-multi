#!/usr/bin/env bash

# VM Build and Management Script for NixOS Hyprland VM
# Supports both x86_64 and aarch64 architectures

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VM_NAME="nixos-vm-hyprland"
ARCH="${1:-$(uname -m)}"

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

# Usage information
usage() {
    cat << EOF
Usage: $0 [ARCHITECTURE] [COMMAND]

ARCHITECTURE:
    x86_64      Build for Intel/AMD systems (default)
    aarch64     Build for ARM64/Apple Silicon systems

COMMANDS:
    build       Build the VM disk image
    run         Build and run the VM
    clean       Clean build artifacts
    help        Show this help message

EXAMPLES:
    $0 x86_64 build     # Build VM for Intel/AMD
    $0 aarch64 build    # Build VM for ARM64
    $0 run              # Build and run VM (auto-detect arch)
    $0 clean            # Clean all build artifacts

EOF
}

# Check if we're on macOS or Linux
detect_host_os() {
    case "$(uname -s)" in
        Darwin)
            echo "macos"
            ;;
        Linux)
            echo "linux"
            ;;
        *)
            log_error "Unsupported operating system: $(uname -s)"
            exit 1
            ;;
    esac
}

# Normalize architecture names
normalize_arch() {
    case "$1" in
        x86_64|amd64|intel)
            echo "x86_64"
            ;;
        aarch64|arm64|apple)
            echo "aarch64"
            ;;
        *)
            log_error "Unsupported architecture: $1"
            echo "Supported: x86_64, aarch64"
            exit 1
            ;;
    esac
}

# Check if UTM is available (Apple Silicon specific)
check_utm() {
    if command -v utmctl &> /dev/null; then
        echo "true"
    else
        echo "false"
    fi
}

# Detect host architecture
detect_host_arch() {
    case "$(uname -m)" in
        x86_64|amd64)
            echo "x86_64"
            ;;
        arm64|aarch64)
            echo "aarch64"
            ;;
        *)
            log_error "Unsupported host architecture: $(uname -m)"
            exit 1
            ;;
    esac
}

# Build the VM
build_vm() {
    local arch="$1"
    local host_os
    host_os=$(detect_host_os)
    
    log_info "Building NixOS Hyprland VM for architecture: $arch"
    log_info "Host OS detected: $host_os"
    
    cd "$SCRIPT_DIR"
    
    if [[ "$arch" == "x86_64" ]]; then
        log_info "Building x86_64 VM..."
        nix --extra-experimental-features 'nix-command flakes' build .#vmImages.hyprland-vm-x86_64
        log_success "x86_64 VM built successfully!"
        echo "VM script location: ./result/bin/run-nixos-vm"
    elif [[ "$arch" == "aarch64" ]]; then
        log_info "Building aarch64 VM..."
        if [[ "$host_os" == "macos" ]]; then
            # On Apple Silicon Mac, build minimal VM optimized for UTM
            log_info "Detected Apple Silicon Mac - building minimal VM optimized for UTM"
            log_warn "For full Hyprland experience, consider using UTM with Ubuntu ARM64"
            
            if check_utm; then
                log_info "UTM detected - you can also use: ./scripts/utm-vm-setup.sh"
            fi
            
            # Build minimal ARM64 VM that's more likely to work
            log_info "Building lightweight ARM64 VM..."
            nix --extra-experimental-features 'nix-command flakes' build .#vmImages.minimal-vm-aarch64
        else
            # On Linux, try to build full Hyprland VM
            nix --extra-experimental-features 'nix-command flakes' build .#vmImages.hyprland-vm-aarch64
        fi
        log_success "aarch64 VM built successfully!"
        echo "VM script location: ./result/bin/run-nixos-vm"
    fi
}

# Run the VM
run_vm() {
    local arch="$1"
    local host_os
    host_os=$(detect_host_os)
    
    log_info "Starting VM with architecture: $arch on $host_os"
    
    # First build the VM
    build_vm "$arch"
    
    if [[ "$arch" == "x86_64" ]]; then
        if [[ -f "./result/bin/run-nixos-vm" ]]; then
            log_info "Starting x86_64 VM..."
            log_warn "VM will start with default settings. Use Ctrl+Alt+G to release mouse."
            log_warn "SSH access available on localhost:22000 (user: hrpr, password: nixos)"
            
            # Use the QEMU configuration helper if available
            if [[ -f "./scripts/qemu-config.sh" ]]; then
                log_info "Using platform-optimized QEMU configuration"
                export QEMU_OPTS=$(./scripts/qemu-config.sh opts "$arch" "6G" "4" "3440x1440")
                log_info "QEMU Options: $QEMU_OPTS"
            else
                # Fallback to platform-specific options
                if [[ "$host_os" == "macos" ]]; then
                    # macOS-specific optimizations
                    export QEMU_OPTS="-m 6G -smp 4 -accel hvf -device virtio-gpu-pci,xres=3440,yres=1440 -audiodev coreaudio,id=audio0 -device intel-hda -device hda-duplex,audiodev=audio0 -netdev user,id=net0,hostfwd=tcp::22000-:22 -device virtio-net-pci,netdev=net0"
                    log_info "Using macOS Hypervisor Framework (HVF) acceleration"
                elif [[ "$host_os" == "linux" ]]; then
                    # Linux-specific optimizations
                    export QEMU_OPTS="-m 6G -smp 4 -enable-kvm -device virtio-gpu-pci,xres=3440,yres=1440 -display gtk,gl=on -audiodev pipewire,id=audio0 -device intel-hda -device hda-duplex,audiodev=audio0 -netdev user,id=net0,hostfwd=tcp::22000-:22 -device virtio-net-pci,netdev=net0"
                    log_info "Using KVM acceleration"
                fi
            fi
            
            ./result/bin/run-nixos-vm
        else
            log_error "VM build not found. Please build first."
            exit 1
        fi
    elif [[ "$arch" == "aarch64" ]]; then
        if [[ "$host_os" == "macos" ]]; then
            log_info "For ARM64 VMs on macOS:"
            log_info "1. Use UTM (recommended) or another ARM64-capable virtualization tool"
            log_info "2. Import the built VM image from ./result/"
            log_info "3. Configure with 4GB+ RAM and 2+ CPU cores"
            log_warn "Direct QEMU launch for ARM64 not yet implemented on macOS"
            
            # Show UTM-compatible settings
            log_info "Recommended UTM settings:"
            echo "  - System: Linux"
            echo "  - Architecture: ARM64 (aarch64)"
            echo "  - Memory: 4096 MB or more"
            echo "  - CPU Cores: 2 or more"
            echo "  - Display: VirtIO GPU"
            echo "  - Network: Shared Network"
        else
            log_info "Starting aarch64 VM on Linux..."
            if [[ -f "./result/bin/run-nixos-vm" ]]; then
                # Use QEMU config helper if available, otherwise fallback
                if [[ -f "./scripts/qemu-config.sh" ]]; then
                    export QEMU_OPTS=$(./scripts/qemu-config.sh opts "$arch" "4G" "2" "1920x1080")
                else
                    # ARM64 Linux VM settings fallback
                    export QEMU_OPTS="-m 4G -smp 2 -machine virt -cpu cortex-a72 -device virtio-gpu-pci -audiodev pipewire,id=audio0 -device intel-hda -device hda-duplex,audiodev=audio0 -netdev user,id=net0,hostfwd=tcp::22000-:22 -device virtio-net-pci,netdev=net0"
                fi
                log_info "Using ARM64 virtualization"
                ./result/bin/run-nixos-vm
            else
                log_error "ARM64 VM build not found. Please build first."
                exit 1
            fi
        fi
    fi
}

# Clean build artifacts
clean_vm() {
    log_info "Cleaning VM build artifacts..."
    
    cd "$SCRIPT_DIR"
    
    # Remove nix build results
    if [[ -L "result" ]]; then
        rm result
        log_success "Removed build result symlink"
    fi
    
    # Remove VM disk images if they exist
    if [[ -f "nixos.qcow2" ]]; then
        rm nixos.qcow2
        log_success "Removed VM disk image"
    fi
    
    # Clean up any other VM-related files
    find . -name "*.qcow2" -type f -delete 2>/dev/null || true
    find . -name "*.img" -type f -delete 2>/dev/null || true
    
    log_success "VM artifacts cleaned"
}

# Check dependencies
check_dependencies() {
    local deps=("nix")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing dependencies: ${missing[*]}"
        echo "Please install the missing dependencies and try again."
        exit 1
    fi
}

# Main function
main() {
    # Parse arguments
    local arch="${1:-$(uname -m)}"
    local command="${2:-build}"
    
    # Normalize architecture
    arch=$(normalize_arch "$arch")
    
    case "$command" in
        build)
            check_dependencies
            build_vm "$arch"
            ;;
        run)
            check_dependencies
            run_vm "$arch"
            ;;
        clean)
            clean_vm
            ;;
        help|--help|-h)
            usage
            ;;
        *)
            log_error "Unknown command: $command"
            usage
            exit 1
            ;;
    esac
}

# Handle special case where first argument might be a command
if [[ $# -eq 1 ]]; then
    case "$1" in
        build|run|clean|help|--help|-h)
            main "$(uname -m)" "$1"
            exit $?
            ;;
    esac
fi

# Run main with all arguments
main "$@"
