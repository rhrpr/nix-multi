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
        nix build .#nixosConfigurations.nixos-vm-hyprland.config.system.build.vm
        log_success "x86_64 VM built successfully!"
        echo "VM script location: ./result/bin/run-nixos-vm"
    elif [[ "$arch" == "aarch64" ]]; then
        log_info "Building aarch64 VM..."
        if [[ "$host_os" == "macos" ]]; then
            # On macOS, we might need to use cross-compilation or UTM
            log_warn "Building ARM64 VM on macOS - this may require UTM or cross-compilation"
            nix build .#vmImages.hyprland-vm-aarch64 --system aarch64-linux
        else
            # On Linux, try to build natively or cross-compile
            nix build .#vmImages.hyprland-vm-aarch64
        fi
        log_success "aarch64 VM built successfully!"
    fi
}

# Run the VM
run_vm() {
    local arch="$1"
    local host_os
    host_os=$(detect_host_os)
    
    log_info "Starting VM with architecture: $arch"
    
    # First build the VM
    build_vm "$arch"
    
    if [[ "$arch" == "x86_64" ]]; then
        if [[ -f "./result/bin/run-nixos-vm" ]]; then
            log_info "Starting x86_64 VM..."
            log_warn "VM will start with default settings. Use Ctrl+Alt+G to release mouse."
            log_warn "SSH access available on localhost:22000 (user: hrpr, password: nixos)"
            
            # Set memory and CPU for better performance
            export QEMU_OPTS="-m 4G -smp 4 -enable-kvm"
            
            ./result/bin/run-nixos-vm
        else
            log_error "VM build not found. Please build first."
            exit 1
        fi
    elif [[ "$arch" == "aarch64" ]]; then
        if [[ "$host_os" == "macos" ]]; then
            log_info "For ARM64 VMs on macOS, please use UTM or another virtualization tool"
            log_info "Import the built VM image into your preferred virtualization software"
        else
            log_info "Starting aarch64 VM..."
            # For ARM64 on Linux, we'd need to set up QEMU appropriately
            log_warn "ARM64 VM startup not yet implemented for Linux hosts"
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
