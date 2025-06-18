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

# Download pre-built NixOS ARM64 ISO or build if available
get_nixos_arm64_iso() {
    local iso_type="${1:-hyprland}"
    local download_dir="$HOME/VMs/ISOs"
    local iso_name="nixos-${iso_type}-aarch64.iso"
    local iso_path="$download_dir/$iso_name"
    
    mkdir -p "$download_dir"
    
    # Check if we already have the ISO
    if [[ -f "$iso_path" ]]; then
        log_success "NixOS ARM64 ISO already available at $iso_path"
        echo "$iso_path"
        return 0
    fi
    
    log_info "Getting NixOS ARM64 ISO (${iso_type})..."
    
    # Try to download a pre-built NixOS ARM64 ISO
    local nixos_iso_url="https://channels.nixos.org/nixos-unstable/latest-nixos-minimal-aarch64-linux.iso"
    if [[ "$iso_type" == "minimal" ]]; then
        log_info "Downloading NixOS minimal ARM64 ISO..."
        if curl -L -o "$iso_path" "$nixos_iso_url"; then
            log_success "NixOS minimal ARM64 ISO downloaded"
            echo "$iso_path"
            return 0
        else
            log_warn "Failed to download pre-built NixOS ISO"
        fi
    fi
    
    # Try to build locally if we have a Linux builder available
    log_info "Attempting to build NixOS ARM64 ISO locally..."
    local nix_multi_dir="$HOME/.config/nix-multi"
    if [[ -d "$nix_multi_dir" ]]; then
        cd "$nix_multi_dir"
        
        # Try building with emulation
        if nix build ".#isoImages.nixos-${iso_type}-aarch64" --extra-platforms aarch64-linux --out-link "result-iso-${iso_type}" 2>/dev/null; then
            local result_iso=$(find result-iso-${iso_type} -name "*.iso" 2>/dev/null | head -1)
            if [[ -f "$result_iso" ]]; then
                cp "$result_iso" "$iso_path"
                log_success "NixOS ARM64 ISO built and saved to $iso_path"
                echo "$iso_path"
                return 0
            fi
        fi
    fi
    
    log_warn "Could not build NixOS ARM64 ISO locally"
    return 1
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
            log_info "Attempting to get NixOS ARM64 ISO with Hyprland support..."
            iso_path=$(get_nixos_arm64_iso "hyprland")
            if [[ $? -ne 0 ]]; then
                log_warn "Falling back to NixOS minimal ISO..."
                iso_path=$(get_nixos_arm64_iso "minimal")
                if [[ $? -ne 0 ]]; then
                    log_warn "Falling back to Ubuntu ARM64 as last resort"
                    iso_path=$(download_ubuntu_arm64 2>/dev/null)
                fi
            fi
            ;;
        nixos-minimal)
            vm_name="NixOS-Minimal-VM"
            log_info "Getting NixOS minimal ARM64 ISO..."
            iso_path=$(get_nixos_arm64_iso "minimal")
            if [[ $? -ne 0 ]]; then
                log_warn "Falling back to Ubuntu ARM64"
                iso_path=$(download_ubuntu_arm64 2>/dev/null)
            fi
            ;;
        ubuntu)
            vm_name="Ubuntu-ARM64-VM"
            iso_path=$(download_ubuntu_arm64 2>/dev/null)
            ;;
        *)
            log_error "Unknown VM type: $vm_type"
            log_info "Supported types: nixos, nixos-minimal, ubuntu"
            return 1
            ;;
    esac
    
    if [[ -z "$iso_path" ]] || [[ ! -f "$iso_path" ]]; then
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
            setup_utm_vm "${2:-nixos}"
            ;;
        setup-nixos)
            setup_utm_vm "nixos"
            ;;
        setup-minimal)
            setup_utm_vm "nixos-minimal"
            ;;
        setup-ubuntu)
            setup_utm_vm "ubuntu"
            ;;
        build-iso)
            get_nixos_arm64_iso "${2:-hyprland}"
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
    setup [TYPE]      Guide for setting up VM in UTM (default: nixos)
    setup-nixos       Setup NixOS + Hyprland VM
    setup-minimal     Setup minimal NixOS VM
    setup-ubuntu      Setup Ubuntu ARM64 VM
    build-iso [TYPE]  Build NixOS ISO (hyprland or minimal)
    list              List available UTM VMs
    start NAME        Start a specific VM
    stop NAME         Stop a specific VM
    download          Download Ubuntu ARM64 ISO (fallback)
    help              Show this help message

EXAMPLES:
    $0 setup-nixos              # Setup NixOS + Hyprland VM
    $0 setup-minimal            # Setup minimal NixOS VM
    $0 build-iso hyprland       # Build NixOS + Hyprland ISO
    $0 build-iso minimal        # Build minimal NixOS ISO
    $0 start NixOS-Hyprland-VM  # Start NixOS VM
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
