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

# Download Ubuntu ARM64 image (good alternative to NixOS for Apple Silicon)
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

# Create UTM VM configuration (would normally be done via UTM GUI)
setup_utm_vm() {
    local vm_name="Ubuntu-Hyprland-VM"
    
    log_info "Setting up UTM VM: $vm_name"
    log_info "Please create the VM manually in UTM with these settings:"
    echo "  - System: Linux"
    echo "  - Architecture: ARM64 (aarch64)"
    echo "  - Memory: 4-8 GB"
    echo "  - Storage: 50+ GB"
    echo "  - Boot ISO: $(download_ubuntu_arm64)"
    echo ""
    log_info "After creating the VM, you can:"
    echo "  - Start it: utmctl start '$vm_name'"
    echo "  - Stop it: utmctl stop '$vm_name'"
    echo "  - List VMs: utmctl list"
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
