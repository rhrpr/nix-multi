#!/usr/bin/env bash

# Comprehensive validation script for nix-multi configuration
# Tests all three configurations and VM functionality

set -euo pipefail

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

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

test_flake_structure() {
    log_info "Testing flake structure..."
    if nix flake check --quiet 2>/dev/null; then
        log_success "Flake structure is valid"
        return 0
    else
        log_error "Flake structure validation failed"
        return 1
    fi
}

test_configuration_builds() {
    log_info "Testing configuration builds..."
    
    # Test NixOS Plasma configuration
    if nix build .#nixosConfigurations.nixos-plasma.config.system.build.toplevel --dry-run --quiet >/dev/null 2>&1; then
        log_success "NixOS Plasma configuration builds successfully"
    else
        log_error "NixOS Plasma configuration build failed"
        return 1
    fi
    
    # Test VM configuration
    if nix build .#nixosConfigurations.nixos-vm-hyprland.config.system.build.toplevel --dry-run --quiet >/dev/null 2>&1; then
        log_success "NixOS VM configuration builds successfully"
    else
        log_error "NixOS VM configuration build failed"
        return 1
    fi
    
    return 0
}

test_vm_images() {
    log_info "Testing VM image builds..."
    
    # Test x86_64 VM image
    if nix build .#vmImages.hyprland-vm-x86_64 --dry-run --quiet >/dev/null 2>&1; then
        log_success "x86_64 VM image builds successfully"
    else
        log_error "x86_64 VM image build failed"
        return 1
    fi
    
    # Test aarch64 VM image
    if nix build .#vmImages.hyprland-vm-aarch64 --dry-run --quiet >/dev/null 2>&1; then
        log_success "aarch64 VM image builds successfully"
    else
        log_error "aarch64 VM image build failed"
        return 1
    fi
    
    return 0
}

test_vm_scripts() {
    log_info "Testing VM management scripts..."
    
    # Test vm-build.sh
    if [[ -x "./vm-build.sh" ]]; then
        log_success "vm-build.sh is executable"
    else
        log_error "vm-build.sh is not executable"
        return 1
    fi
    
    # Test vm-manager.sh
    if [[ -x "./vm-manager.sh" ]]; then
        log_success "vm-manager.sh is executable"
    else
        log_error "vm-manager.sh is not executable"
        return 1
    fi
    
    # Test help output
    if ./vm-build.sh help >/dev/null 2>&1; then
        log_success "vm-build.sh help command works"
    else
        log_error "vm-build.sh help command failed"
        return 1
    fi
    
    return 0
}

test_vm_execution() {
    log_info "Testing VM execution capability..."
    
    if [[ -L "./result" ]] && [[ -e "./result/bin/run-nixos-vm-hyprland-vm" ]]; then
        log_success "VM executable exists and is ready"
        log_info "VM can be started with: ./result/bin/run-nixos-vm-hyprland-vm"
        return 0
    else
        log_warn "VM not built yet. Run './vm-build.sh build' to create VM"
        return 1
    fi
}

main() {
    echo "======================================"
    echo "   Nix-Multi Configuration Validator"
    echo "======================================"
    echo
    
    local failed=0
    
    test_flake_structure || failed=1
    echo
    
    test_configuration_builds || failed=1
    echo
    
    test_vm_images || failed=1
    echo
    
    test_vm_scripts || failed=1
    echo
    
    test_vm_execution || failed=1
    echo
    
    if [[ $failed -eq 0 ]]; then
        log_success "All tests passed! Your nix-multi setup is fully functional."
        echo
        echo "Quick start commands:"
        echo "  ./vm-manager.sh           # Interactive VM management"
        echo "  ./vm-build.sh build       # Build VM for current architecture"
        echo "  ./vm-build.sh run         # Build and run VM"
        echo
    else
        log_error "Some tests failed. Please check the output above."
        return 1
    fi
}

main "$@"
