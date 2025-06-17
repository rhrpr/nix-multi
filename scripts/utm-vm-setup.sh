#!/usr/bin/env bash

# UTM VM Setup Script for Apple Silicon Macs
# Creates and manages Linux VMs using UTM instead of cross-compiling QEMU

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging functions
log_info() {
    echo -e "${BLUE}[UTM]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[UTM]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[UTM]${NC} $1"
}

log_error() {
    echo -e "${RED}[UTM]${NC} $1"
}

# Check if UTM is available
check_utm() {
    if ! command -v utmctl &> /dev/null; then
        log_error "UTM not found. Please install UTM from the Mac App Store or https://mac.getutm.app/"
        exit 1
    fi
    log_success "UTM found and available"
}

# Build NixOS ARM64 ISO using Nix flake
build_nixos_arm64_iso() {
    local iso_type="${1:-hyprland}"  # hyprland or minimal
    local download_dir="$HOME/VMs/ISOs"
    local iso_name="nixos-${iso_type}-aarch64.iso"
    local iso_path="$download_dir/$iso_name"
    
    mkdir -p "$download_dir"
    
    log_info "Building NixOS ARM64 ISO (${iso_type})..."
    log_warn "This may take a while (first build can take 30+ minutes)"
    
    # Change to the nix-multi directory
    local nix_multi_dir="$HOME/.config/nix-multi"
    if [[ ! -d "$nix_multi_dir" ]]; then
        log_error "nix-multi directory not found at $nix_multi_dir"
        return 1
    fi
    
    cd "$nix_multi_dir"
    
    # Build the ISO using the Linux builder
    if nix build ".#isoImages.nixos-${iso_type}-aarch64" --out-link "result-iso-${iso_type}"; then
        # Copy the ISO to the VMs directory
        local result_iso=$(readlink -f "result-iso-${iso_type}/iso/"*.iso)
        if [[ -f "$result_iso" ]]; then
            cp "$result_iso" "$iso_path"
            log_success "NixOS ARM64 ISO built and saved to $iso_path"
            echo "$iso_path"
        else
            log_error "ISO file not found in build result"
            return 1
        fi
    else
        log_error "Failed to build NixOS ARM64 ISO"
        return 1
    fi
}

# Download Ubuntu ARM64 image (fallback option)
download_ubuntu_arm64() {
    local iso_url="https://cdimage.ubuntu.com/daily-live/current/oracular-desktop-arm64.iso"
    local iso_name="ubuntu-24.10-desktop-arm64.iso"
    local download_dir="$HOME/VMs/ISOs"
    
    mkdir -p "$download_dir"
    
    if [[ ! -f "$download_dir/$iso_name" ]]; then
        log_info "Downloading Ubuntu 24.10 ARM64 ISO..."
        log_warn "This may take a while (2-3 GB download)"
        curl -L -o "$download_dir/$iso_name" "$iso_url"
        log_success "Ubuntu ARM64 ISO downloaded"
    else
        log_success "Ubuntu ARM64 ISO already available"
    fi
    
    echo "$download_dir/$iso_name"
}

# Create UTM VM configuration
setup_utm_vm() {
    local vm_type="${1:-nixos}"  # nixos or ubuntu
    local vm_name=""
    local iso_path=""
    
    case "$vm_type" in
        nixos)
            vm_name="NixOS-Hyprland-VM"
            iso_path=$(build_nixos_arm64_iso "hyprland")
            ;;
        nixos-minimal)
            vm_name="NixOS-Minimal-VM"
            iso_path=$(build_nixos_arm64_iso "minimal")
            ;;
        ubuntu)
            vm_name="Ubuntu-ARM64-VM"
            iso_path=$(download_ubuntu_arm64)
            ;;
        *)
            log_error "Unknown VM type: $vm_type"
            log_info "Supported types: nixos, nixos-minimal, ubuntu"
            return 1
            ;;
    esac
    
    if [[ $? -ne 0 ]] || [[ ! -f "$iso_path" ]]; then
        log_error "Failed to get ISO image for $vm_type"
        return 1
    fi
    
    log_info "Setting up UTM VM: $vm_name"
    log_info "Please create the VM manually in UTM with these settings:"
    echo ""
    echo "  VM Configuration:"
    echo "  - Name: $vm_name"
    echo "  - System: Linux"
    echo "  - Architecture: ARM64 (aarch64)"
    echo "  - Memory: 6-8 GB (recommended for NixOS)"
    echo "  - CPU Cores: 4-6"
    echo "  - Storage: 60+ GB (NixOS needs more space)"
    echo "  - Boot ISO: $iso_path"
    echo "  - Graphics: virtio-gpu-gl-pci (for best performance)"
    echo "  - Network: Shared Network"
    echo ""
    echo "  Advanced Settings:"
    echo "  - Enable hardware OpenGL acceleration"
    echo "  - Enable Rosetta (if available)"
    echo "  - Set resolution to 1920x1080 or higher"
    echo ""
    log_info "After creating the VM, you can:"
    echo "  - Start it: utmctl start '$vm_name'"
    echo "  - Stop it: utmctl stop '$vm_name'"
    echo "  - List VMs: utmctl list"
    echo ""
    if [[ "$vm_type" == "nixos"* ]]; then
        log_info "NixOS Installation Notes:"
        echo "  - Default user: nixos (password: nixos)"
        echo "  - Use the installer to install to disk"
        echo "  - Enable SSH for remote management"
        echo "  - Copy your nix-multi config for persistent setup"
    fi
}

# List available VMs
list_vms() {
    log_info "Available UTM VMs:"
    utmctl list
}

# Start a VM
start_vm() {
    local vm_name="${1:-}"
    
    if [[ -z "$vm_name" ]]; then
        log_error "Please specify a VM name"
        list_vms
        exit 1
    fi
    
    log_info "Starting VM: $vm_name"
    utmctl start "$vm_name"
}

# Stop a VM
stop_vm() {
    local vm_name="${1:-}"
    
    if [[ -z "$vm_name" ]]; then
        log_error "Please specify a VM name"
        list_vms
        exit 1
    fi
    
    log_info "Stopping VM: $vm_name"
    utmctl stop "$vm_name"
}

# Main function
main() {
    local command="${1:-help}"
    
    check_utm
    
    case "$command" in
        setup)
            setup_utm_vm
            ;;
        list)
            list_vms
            ;;
        start)
            start_vm "${2:-}"
            ;;
        stop)
            stop_vm "${2:-}"
            ;;
        download)
            download_ubuntu_arm64
            ;;
        help|--help|-h)
            cat << EOF
UTM VM Setup Script for Apple Silicon Macs

USAGE:
    $0 [COMMAND] [ARGS...]

COMMANDS:
    setup       Guide for setting up Ubuntu ARM64 VM in UTM
    list        List available UTM VMs
    start NAME  Start a specific VM
    stop NAME   Stop a specific VM
    download    Download Ubuntu ARM64 ISO
    help        Show this help message

EXAMPLES:
    $0 setup                    # Setup guide for new VM
    $0 download                 # Download Ubuntu ARM64 ISO
    $0 start Ubuntu-VM          # Start a VM named "Ubuntu-VM"
    $0 list                     # List all VMs

EOF
            ;;
        *)
            log_error "Unknown command: $command"
            main help
            exit 1
            ;;
    esac
}

main "$@"
