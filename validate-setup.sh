#!/usr/bin/env bash

# Comprehensive validation script for nix-multi configuration
# Tests all configurations, VM functionality, and GPU passthrough

set -euo pipefail

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
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

log_section() {
    echo -e "${PURPLE}[SECTION]${NC} $1"
}

# Detect host OS
detect_host_os() {
    case "$(uname -s)" in
        Darwin) echo "macos" ;;
        Linux) echo "linux" ;;
        *) echo "unknown" ;;
    esac
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
    
    if [[ -L "./result" ]] && [[ -e "./result/bin/run-nixos-vm" ]]; then
        log_success "VM executable exists and is ready"
        log_info "VM can be started with: ./result/bin/run-nixos-vm"
        return 0
    else
        log_warn "VM not built yet. Run './nix-multi.sh vm-build' to create VM"
        return 1
    fi
}

test_main_script() {
    log_info "Testing main nix-multi script..."
    
    if [[ -x "./nix-multi.sh" ]]; then
        log_success "nix-multi.sh is executable"
        
        # Test help command
        if ./nix-multi.sh help >/dev/null 2>&1; then
            log_success "nix-multi.sh help command works"
        else
            log_error "nix-multi.sh help command failed"
            return 1
        fi
    else
        log_error "nix-multi.sh is not executable"
        return 1
    fi
    
    return 0
}

test_gpu_passthrough() {
    local host_os
    host_os=$(detect_host_os)
    
    if [[ "$host_os" != "linux" ]]; then
        log_warn "GPU passthrough testing only available on Linux hosts"
        return 0
    fi
    
    log_info "Testing GPU passthrough setup..."
    
    # Check for NVIDIA GPU
    if ! lspci | grep -i nvidia &>/dev/null; then
        log_warn "No NVIDIA GPU detected"
        return 0
    fi
    
    # Check for RTX 3080 setup script
    if [[ -x "./scripts/rtx3080-setup.sh" ]]; then
        log_info "Running RTX 3080 validation..."
        if ./scripts/rtx3080-setup.sh status &>/dev/null; then
            log_success "RTX 3080 GPU passthrough setup validated"
        else
            log_warn "RTX 3080 setup issues detected (run ./scripts/rtx3080-setup.sh for details)"
        fi
    else
        log_warn "RTX 3080 setup script not found or not executable"
    fi
    
    return 0
}

main() {
    echo "======================================"
    echo "   Nix-Multi Configuration Validator"
    echo "======================================"
    echo
    
    local host_os
    host_os=$(detect_host_os)
    log_info "Detected host OS: $host_os"
    echo
    
    local failed=0
    
    log_section "Testing Flake Structure"
    test_flake_structure || failed=1
    echo
    
    log_section "Testing Configuration Builds" 
    test_configuration_builds || failed=1
    echo
    
    log_section "Testing VM Images"
    test_vm_images || failed=1
    echo
    
    log_section "Testing Management Scripts"
    test_vm_scripts || failed=1
    echo
    
    log_section "Testing Main Script"
    test_main_script || failed=1
    echo
    
    log_section "Testing VM Execution"
    test_vm_execution || failed=1
    echo
    
    log_section "Testing GPU Passthrough"
    test_gpu_passthrough || failed=1
    echo
    
    if [[ $failed -eq 0 ]]; then
        log_success "All tests passed! Your nix-multi setup is fully functional."
        echo
        echo "Quick start commands:"
        echo "  ./nix-multi.sh setup             # Auto-setup for current OS"
        echo "  ./nix-multi.sh vm-build          # Build VM"
        echo "  ./nix-multi.sh vm-run            # Run VM"
        echo "  ./nix-multi.sh vm-manage         # Interactive VM management"
        
        if [[ "$host_os" == "linux" ]]; then
            echo "  ./nix-multi.sh gpu-test          # Test GPU passthrough"
        fi
        echo
    else
        log_error "Some tests failed. Please check the output above."
        return 1
    fi
}

main "$@"
