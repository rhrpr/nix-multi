#!/usr/bin/env bash

# Quick VM Management Script
# Provides shortcuts for common VM operations

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[VM]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[VM]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[VM]${NC} $1"
}

show_menu() {
    cat << EOF
${GREEN}NixOS Hyprland VM Manager${NC}

Choose an option:
1) Build VM (x86_64)
2) Build VM (aarch64) 
3) Run VM (x86_64)
4) Run VM (aarch64)
5) Clean build artifacts
6) Show VM status
7) SSH into running VM
8) Exit

EOF
}

ssh_to_vm() {
    log_info "Attempting to connect to VM via SSH..."
    log_warn "Default VM SSH connection: ssh hrpr@localhost -p 22000"
    log_warn "Default password: nixos (change after first login)"
    
    if command -v ssh &> /dev/null; then
        ssh hrpr@localhost -p 22000 || {
            log_warn "Connection failed. Make sure VM is running and SSH is enabled."
            log_warn "Try: ./vm-build.sh run"
        }
    else
        log_warn "SSH not found. Please install OpenSSH client."
    fi
}

show_status() {
    log_info "Checking VM status..."
    
    if [[ -L "$SCRIPT_DIR/result" ]]; then
        log_success "VM build found: $(readlink "$SCRIPT_DIR/result")"
    else
        log_warn "No VM build found. Use option 1 or 3 to build."
    fi
    
    # Check for running QEMU processes
    if pgrep -f qemu >/dev/null 2>&1; then
        log_success "QEMU processes detected (VM may be running)"
        pgrep -f qemu | while read -r pid; do
            echo "  PID: $pid"
        done
    else
        log_warn "No QEMU processes found (VM not running)"
    fi
    
    # Check for VM disk images
    if ls *.qcow2 >/dev/null 2>&1; then
        log_info "VM disk images found:"
        ls -lh *.qcow2
    fi
}

main() {
    cd "$SCRIPT_DIR"
    
    while true; do
        show_menu
        read -rp "Enter your choice [1-8]: " choice
        
        case $choice in
            1)
                log_info "Building x86_64 VM..."
                ./vm-build.sh x86_64 build
                ;;
            2)
                log_info "Building aarch64 VM..."
                ./vm-build.sh aarch64 build
                ;;
            3)
                log_info "Running x86_64 VM..."
                ./vm-build.sh x86_64 run
                ;;
            4)
                log_info "Running aarch64 VM..."
                ./vm-build.sh aarch64 run
                ;;
            5)
                log_info "Cleaning build artifacts..."
                ./vm-build.sh clean
                ;;
            6)
                show_status
                ;;
            7)
                ssh_to_vm
                ;;
            8)
                log_success "Goodbye!"
                exit 0
                ;;
            *)
                log_warn "Invalid choice. Please enter 1-8."
                ;;
        esac
        
        echo
        read -rp "Press Enter to continue..."
        clear
    done
}

main "$@"
