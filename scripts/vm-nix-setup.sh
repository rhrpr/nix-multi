#!/usr/bin/env bash

# Script to setup Nix experimental features in VMs where /etc might be read-only
# This script provides multiple approaches to enable nix-command and flakes

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Method 1: Try to create user-level nix.conf
setup_user_nix_conf() {
    log_info "Setting up user-level Nix configuration..."
    
    mkdir -p ~/.config/nix
    cat > ~/.config/nix/nix.conf << EOF
experimental-features = nix-command flakes
max-jobs = auto
cores = 0
EOF
    
    log_success "User-level nix.conf created at ~/.config/nix/nix.conf"
}

# Method 2: Try to remount /etc as writable (requires root)
setup_system_nix_conf() {
    log_info "Attempting to setup system-level Nix configuration..."
    
    if sudo mount -o remount,rw /etc 2>/dev/null; then
        log_success "/etc remounted as writable"
        
        sudo mkdir -p /etc/nix
        echo "experimental-features = nix-command flakes" | sudo tee /etc/nix/nix.conf > /dev/null
        
        log_success "System-level nix.conf created"
        
        # Try to remount as read-only again
        sudo mount -o remount,ro /etc 2>/dev/null || log_warn "Could not remount /etc as read-only"
    else
        log_warn "Cannot remount /etc as writable"
        return 1
    fi
}

# Method 3: Use environment variables (temporary)
setup_env_variables() {
    log_info "Setting up environment variables for this session..."
    
    export NIX_CONFIG="experimental-features = nix-command flakes"
    
    cat >> ~/.bashrc << 'EOF'

# Nix experimental features
export NIX_CONFIG="experimental-features = nix-command flakes"
EOF
    
    if [ -f ~/.zshrc ]; then
        cat >> ~/.zshrc << 'EOF'

# Nix experimental features  
export NIX_CONFIG="experimental-features = nix-command flakes"
EOF
    fi
    
    log_success "Environment variables set for current and future sessions"
}

# Method 4: Check if Nix daemon supports user config
check_nix_daemon() {
    log_info "Checking Nix daemon configuration..."
    
    if systemctl is-active nix-daemon &>/dev/null; then
        log_success "Nix daemon is running"
        if systemctl show nix-daemon | grep -q "allow-import-from-derivation"; then
            log_info "Nix daemon appears to support advanced features"
        fi
    else
        log_warn "Nix daemon is not running via systemctl"
    fi
}

# Test Nix experimental features
test_nix_features() {
    log_info "Testing Nix experimental features..."
    
    if nix --help 2>/dev/null | grep -q "flakes"; then
        log_success "Nix flakes are available!"
        if nix flake --help &>/dev/null; then
            log_success "Nix flakes command works!"
        else
            log_warn "Nix flakes command not working - may need configuration"
        fi
    else
        log_error "Nix flakes not available"
        return 1
    fi
}

# Install packages to make the VM more useful
install_basic_packages() {
    log_info "Installing basic development packages..."
    
    if command -v nix-env &>/dev/null; then
        nix-env -iA nixpkgs.git nixpkgs.curl nixpkgs.wget nixpkgs.vim nixpkgs.htop 2>/dev/null || log_warn "Some packages failed to install"
        log_success "Basic packages installed"
    else
        log_warn "nix-env not available"
    fi
}

# Main setup function
main() {
    log_info "Starting Nix setup for VM environment"
    
    # Check if we're in a VM or container
    if [ -f /.dockerenv ] || grep -q "systemd-detect-virt" /proc/1/cgroup 2>/dev/null; then
        log_info "Detected containerized/VM environment"
    fi
    
    # Try different methods in order of preference
    echo "Attempting different configuration methods..."
    
    # Method 1: User config (most likely to work)
    if setup_user_nix_conf; then
        log_success "User configuration method succeeded"
    fi
    
    # Method 2: System config (if we have permissions)
    if setup_system_nix_conf; then
        log_success "System configuration method succeeded"
    fi
    
    # Method 3: Environment variables (fallback)
    setup_env_variables
    
    # Check daemon status
    check_nix_daemon
    
    # Test if everything works
    echo ""
    log_info "Testing configuration..."
    if test_nix_features; then
        log_success "Nix experimental features are working!"
        
        # Install some useful packages
        install_basic_packages
        
        echo ""
        log_success "Setup complete! You can now use:"
        echo "  nix flake --help"
        echo "  nix develop"
        echo "  nix build"
        echo ""
        log_info "To install Hyprland, try:"
        echo "  nix-env -iA nixpkgs.hyprland"
        echo "  # or use your distribution's package manager"
        
    else
        log_error "Nix experimental features are not working"
        echo ""
        log_info "You may need to:"
        echo "1. Restart your shell: exec \$SHELL"
        echo "2. Restart the Nix daemon: sudo systemctl restart nix-daemon"
        echo "3. Use environment variables: export NIX_CONFIG=\"experimental-features = nix-command flakes\""
        exit 1
    fi
}

main "$@"
