#!/usr/bin/env bash

# Nix-Multi Setup and Management Script
# Handles initial setup and ongoing management for both macOS and Linux hosts

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLAKE_DIR="$SCRIPT_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

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

log_section() {
    echo -e "${PURPLE}[SECTION]${NC} $1"
}

# Detect host operating system
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

# Detect host architecture
detect_arch() {
    case "$(uname -m)" in
        x86_64|amd64)
            echo "x86_64"
            ;;
        aarch64|arm64)
            echo "aarch64"
            ;;
        *)
            log_error "Unsupported architecture: $(uname -m)"
            exit 1
            ;;
    esac
}

# Check for Nix installation
check_nix() {
    if ! command -v nix &> /dev/null; then
        log_error "Nix is not installed. Please install Nix first:"
        echo "  Linux: curl -L https://nixos.org/nix/install | sh"
        echo "  macOS: curl -L https://nixos.org/nix/install | sh"
        echo ""
        echo "After installation, restart your shell and run this script again."
        exit 1
    fi
    
    log_success "Nix installation found"
}

# Check for flakes support
check_flakes() {
    if ! nix --extra-experimental-features 'nix-command flakes' flake --help &> /dev/null; then
        log_warn "Nix flakes not enabled. Enabling flakes..."
        mkdir -p ~/.config/nix
        echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
        log_success "Nix flakes enabled"
    else
        log_success "Nix flakes support available"
    fi
}

# Setup macOS host
setup_macos() {
    log_section "Setting up macOS host configuration"
    
    local hostname
    hostname=$(scutil --get ComputerName 2>/dev/null || echo "Ryans-MacBook-Pro")
    
    log_info "Detected hostname: $hostname"
    log_info "Building nix-darwin configuration..."
    
    # Build the darwin configuration
    if nix --extra-experimental-features 'nix-command flakes' build ".#darwinConfigurations.\"$hostname\".system"; then
        log_success "macOS configuration built successfully"
        
        log_info "Activating nix-darwin configuration..."
        if sudo ./result/sw/bin/darwin-rebuild switch --flake ".#$hostname"; then
            log_success "macOS configuration activated"
        else
            log_error "Failed to activate macOS configuration"
            return 1
        fi
    else
        log_error "Failed to build macOS configuration"
        return 1
    fi
    
    log_success "macOS host setup complete!"
    echo ""
    echo "Available commands:"
    echo "  ./nix-multi.sh vm-build          # Build NixOS Hyprland VM"
    echo "  ./nix-multi.sh vm-run            # Run NixOS Hyprland VM"
    echo "  ./nix-multi.sh vm-manage         # Interactive VM management"
}

# Setup Linux host
setup_linux() {
    log_section "Setting up Linux host configuration"
    
    local hostname="${1:-nixos-hyprland}"
    
    log_info "Building NixOS configuration for hostname: $hostname"
    
    # Check if we're on NixOS
    if [[ ! -f /etc/NIXOS ]]; then
        log_error "This appears to be a non-NixOS Linux system."
        log_error "This configuration is designed for NixOS."
        log_error "Please install NixOS or use the VM configuration instead."
        return 1
    fi
    
    # Build the NixOS configuration
    if nix --extra-experimental-features 'nix-command flakes' build ".#nixosConfigurations.$hostname.config.system.build.toplevel" --no-link; then
        log_success "NixOS configuration built successfully"
        
        log_info "Activating NixOS configuration..."
        if sudo nixos-rebuild switch --flake ".#$hostname"; then
            log_success "NixOS configuration activated"
        else
            log_error "Failed to activate NixOS configuration"
            return 1
        fi
    else
        log_error "Failed to build NixOS configuration"
        return 1
    fi
    
    log_success "Linux host setup complete!"
    echo ""
    echo "Available commands:"
    echo "  ./nix-multi.sh gpu-test          # Test GPU passthrough setup"
    echo "  ./nix-multi.sh vm-build          # Build NixOS Hyprland VM"
    echo "  ./nix-multi.sh vm-run            # Run NixOS Hyprland VM with GPU passthrough"
    echo "  ./nix-multi.sh vm-manage         # Interactive VM management"
}

# Build VM
build_vm() {
    local arch="${1:-$(detect_arch)}"
    
    log_section "Building NixOS Hyprland VM for architecture: $arch"
    
    # Use the dedicated VM build script for better handling
    if [[ -f "./vm-build.sh" ]]; then
        log_info "Using dedicated VM build script for better platform support"
        ./vm-build.sh "$arch" build
    else
        # Fallback to direct nix build
        if [[ "$arch" == "x86_64" ]]; then
            log_info "Building x86_64 NixOS Hyprland VM..."
            nix --extra-experimental-features 'nix-command flakes' build ".#vmImages.hyprland-vm-x86_64"
            log_success "x86_64 NixOS Hyprland VM built successfully!"
        elif [[ "$arch" == "aarch64" ]]; then
            log_info "Building aarch64 NixOS Hyprland VM..."
            log_warn "Note: Cross-compilation may require significant build time and resources"
            nix --extra-experimental-features 'nix-command flakes' build ".#vmImages.hyprland-vm-aarch64"
            log_success "aarch64 NixOS Hyprland VM built successfully!"
        else
            log_error "Unsupported architecture: $arch"
            return 1
        fi
        
        echo "VM executable: ./result/bin/run-nixos-vm-hyprland-vm"
    fi
}

# Run VM
run_vm() {
    local host_os
    host_os=$(detect_host_os)
    
    log_section "Running NixOS Hyprland VM"
    
    if [[ ! -L "./result" ]] || [[ ! -e "./result/bin/run-nixos-vm" ]]; then
        log_warn "VM not found. Building VM first..."
        build_vm
    fi
    
    # Use the improved QEMU configuration helper if available
    if [[ -f "./scripts/qemu-config.sh" ]]; then
        log_info "Using platform-optimized QEMU configuration"
        
        if [[ "$host_os" == "linux" ]]; then
            log_info "Starting VM with GPU passthrough support..."
            log_warn "Use Ctrl+Alt+G to release mouse from VM"
            
            # Enhanced settings for Linux host with ultrawide resolution support
            export QEMU_OPTS=$(./scripts/qemu-config.sh opts "x86_64" "8G" "4" "3440x1440")
            
            # Check for GPU passthrough
            if lspci | grep -i nvidia &>/dev/null; then
                log_info "NVIDIA GPU detected - GPU passthrough should be available in VM"
            fi
            
        elif [[ "$host_os" == "macos" ]]; then
            log_info "Starting VM on macOS..."
            log_warn "Note: GPU passthrough not available on macOS"
            
            # macOS settings with HVF acceleration
            export QEMU_OPTS=$(./scripts/qemu-config.sh opts "x86_64" "6G" "4" "3440x1440")
        fi
        
        log_info "QEMU Options: $QEMU_OPTS"
    else
        # Fallback to legacy configuration
        log_warn "Using legacy QEMU configuration"
        
        if [[ "$host_os" == "linux" ]]; then
            log_info "Starting VM with GPU passthrough support..."
            log_warn "Use Ctrl+Alt+G to release mouse from VM"
            
            # Set optimal VM settings for Linux host with ultrawide resolution support
            export QEMU_OPTS="-m 8G -smp 4 -enable-kvm -device virtio-gpu-pci,xres=3440,yres=1440 -display gtk,gl=on"
            
            # Check for GPU passthrough
            if lspci | grep -i nvidia &>/dev/null; then
                log_info "NVIDIA GPU detected - GPU passthrough should be available in VM"
            fi
            
        elif [[ "$host_os" == "macos" ]]; then
            log_info "Starting VM on macOS..."
            log_warn "Note: GPU passthrough not available on macOS"
            
            # Set VM settings for macOS host with ultrawide resolution support
            export QEMU_OPTS="-m 6G -smp 2 -device virtio-gpu-pci,xres=3440,yres=1440 -display cocoa"
        fi
    fi
    
    ./result/bin/run-nixos-vm
}

# Test GPU setup (Linux only)
test_gpu() {
    local host_os
    host_os=$(detect_host_os)
    
    if [[ "$host_os" != "linux" ]]; then
        log_error "GPU testing is only available on Linux hosts"
        return 1
    fi
    
    log_section "Testing GPU passthrough setup"
    
    # Run the RTX 3080 setup script
    if [[ -f "./scripts/rtx3080-setup.sh" ]]; then
        ./scripts/rtx3080-setup.sh
    else
        log_error "RTX 3080 setup script not found"
        return 1
    fi
}

# Interactive VM management
vm_manage() {
    if [[ -f "./vm-manager.sh" ]]; then
        ./vm-manager.sh
    else
        log_error "VM manager script not found"
        return 1
    fi
}

# Show usage
usage() {
    local host_os
    host_os=$(detect_host_os)
    
    cat << EOF
Nix-Multi Setup and Management Script

USAGE:
    $0 [COMMAND] [ARGS...]

COMMANDS:
    setup               Setup host configuration (auto-detects OS)
    setup-macos         Setup macOS host with nix-darwin
    setup-linux [HOST]  Setup Linux host with NixOS (default: nixos-hyprland)
    
    vm-build [ARCH]     Build NixOS Hyprland VM (x86_64 or aarch64)
    vm-run              Run NixOS Hyprland VM
    vm-manage           Interactive VM management
    
EOF

    if [[ "$host_os" == "linux" ]]; then
        cat << EOF
    gpu-test            Test RTX 3080 GPU passthrough setup (Linux only)
    
EOF
    fi

    cat << EOF
    validate            Validate entire configuration
    help                Show this help message

EXAMPLES:
    $0 setup                    # Auto-setup for current OS
    $0 vm-build x86_64         # Build x86_64 VM
    $0 vm-run                  # Run VM
    
CURRENT SYSTEM:
    OS: $host_os
    Architecture: $(detect_arch)

EOF
}

# Validate configuration
validate_config() {
    if [[ -f "./validate-setup.sh" ]]; then
        ./validate-setup.sh
    else
        log_error "Validation script not found"
        return 1
    fi
}

# Main function
main() {
    cd "$FLAKE_DIR"
    
    local command="${1:-help}"
    
    case "$command" in
        setup)
            check_nix
            check_flakes
            local host_os
            host_os=$(detect_host_os)
            if [[ "$host_os" == "macos" ]]; then
                setup_macos
            elif [[ "$host_os" == "linux" ]]; then
                setup_linux "${2:-nixos-hyprland}"
            fi
            ;;
        setup-macos)
            check_nix
            check_flakes
            setup_macos
            ;;
        setup-linux)
            check_nix
            check_flakes
            setup_linux "${2:-nixos-hyprland}"
            ;;
        vm-build)
            check_nix
            build_vm "${2:-$(detect_arch)}"
            ;;
        vm-run)
            check_nix
            run_vm
            ;;
        vm-manage)
            vm_manage
            ;;
        gpu-test)
            test_gpu
            ;;
        validate)
            validate_config
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

main "$@"
