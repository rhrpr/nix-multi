#!/usr/bin/env bash
# NixOS VM Setup Helper for UTM
# This script helps set up a NixOS VM in UTM and deploy the configuration

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Configuration
VM_NAME="${VM_NAME:-nixos-vm}"
VM_SSH_PORT="${VM_SSH_PORT:-22000}"
VM_SSH_USER="${VM_SSH_USER:-${USER:?Set VM_SSH_USER to the guest account name}}"
VM_SSH_HOST="${VM_SSH_HOST:-localhost}"
VM_MEMORY_MB="${VM_MEMORY_MB:-6144}"
VM_CPU_CORES="${VM_CPU_CORES:-4}"
VM_STORAGE_GB="${VM_STORAGE_GB:-30}"
VM_NIXOS_CONFIG="${VM_NIXOS_CONFIG:-nixos-vm-arm64}"
ISO_DIR="$ROOT_DIR/vm-iso"
NIXOS_ISO_URL="https://channels.nixos.org/nixos-unstable/latest-nixos-minimal-aarch64-linux.iso"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Function to check if VM is accessible
check_vm() {
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -o ConnectTimeout=5 -p "$VM_SSH_PORT" "$VM_SSH_USER@$VM_SSH_HOST" \
        'echo "VM accessible"' >/dev/null 2>&1
}

# Function to download NixOS ISO
download_iso() {
    log "Downloading NixOS ARM64 ISO..."
    mkdir -p "$ISO_DIR"
    
    if [ -f "$ISO_DIR/nixos-minimal-aarch64.iso" ]; then
        log "ISO already exists at $ISO_DIR/nixos-minimal-aarch64.iso"
        return 0
    fi
    
    info "Downloading from $NIXOS_ISO_URL"
    curl -L -o "$ISO_DIR/nixos-minimal-aarch64.iso" "$NIXOS_ISO_URL"
    log "ISO downloaded successfully!"
}

# Function to show UTM setup instructions
show_utm_instructions() {
    echo ""
    info "=== UTM VM Setup Instructions ==="
    echo ""
    echo "1. Open UTM and create a new VM:"
    echo "   - Click 'Create a New Virtual Machine'"
    echo "   - Choose 'Virtualize'"
    echo "   - Operating System: Linux"
    echo ""
    echo "2. Configure VM settings:"
    echo "   - Name: $VM_NAME"
    echo "   - Memory: $VM_MEMORY_MB MB"
    echo "   - CPU Cores: $VM_CPU_CORES"
    echo "   - Storage: $VM_STORAGE_GB GB"
    echo ""
    echo "3. Boot configuration:"
    echo "   - Boot ISO Image: $ISO_DIR/nixos-minimal-aarch64.iso"
    echo "   - Boot from CD/DVD: Enabled"
    echo ""
    echo "4. Network configuration:"
    echo "   - Network Mode: Shared Network"
    echo "   - Port Forward: Host Port $VM_SSH_PORT -> Guest Port 22"
    echo ""
    echo "5. Start the VM and install NixOS:"
    echo "   - Follow the NixOS installation guide"
    echo "   - Create user '$VM_SSH_USER' and configure key-based SSH access"
    echo "   - Enable SSH: sudo systemctl enable --now sshd"
    echo ""
    echo "6. After installation, run: $0 deploy"
    echo ""
}

# Function to prepare VM for deployment
prepare_vm() {
    log "Preparing VM for configuration deployment..."
    
    # Check if git is available, install if needed
    ssh -t -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -p "$VM_SSH_PORT" "$VM_SSH_USER@$VM_SSH_HOST" \
        'which git >/dev/null || (echo "Installing git..." && sudo nix-env -iA nixos.git)'
    
    # Enable flakes if needed
    ssh -t -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -p "$VM_SSH_PORT" "$VM_SSH_USER@$VM_SSH_HOST" \
        'sudo mkdir -p /etc/nix && echo "experimental-features = nix-command flakes" | sudo tee -a /etc/nix/nix.conf'
    
    log "VM prepared successfully!"
}

# Function to deploy configuration
deploy_config() {
    log "Deploying NixOS configuration to VM..."
    
    if ! check_vm; then
        error "Cannot connect to VM. Make sure it's running and SSH is enabled."
        echo "Try: ssh -p $VM_SSH_PORT $VM_SSH_USER@$VM_SSH_HOST"
        exit 1
    fi
    
    # Prepare VM
    prepare_vm
    
    # Create tarball of configuration
    log "Creating configuration archive..."
    cd "$ROOT_DIR"
    tar czf /tmp/nix-multi-config.tar.gz \
        --exclude='.git' --exclude='result*' --exclude='vm-iso' \
        --exclude='*.qcow2' --exclude='.DS_Store' \
        --exclude='__pycache__' --exclude='*.pyc' .
    
    # Copy configuration to VM
    log "Copying configuration to VM..."
    scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -P "$VM_SSH_PORT" /tmp/nix-multi-config.tar.gz "$VM_SSH_USER@$VM_SSH_HOST":~/
    
    # Extract and apply configuration
    log "Applying NixOS configuration..."
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -p "$VM_SSH_PORT" "$VM_SSH_USER@$VM_SSH_HOST" \
        "cd ~ && rm -rf nix-multi && tar xzf nix-multi-config.tar.gz && cd nix-multi && sudo nixos-rebuild switch --flake .#$VM_NIXOS_CONFIG"
    
    # Cleanup
    rm -f /tmp/nix-multi-config.tar.gz
    
    log "Configuration deployed successfully!"
    info "You can now SSH to the VM with: ssh -p $VM_SSH_PORT $VM_SSH_USER@$VM_SSH_HOST"
}

# Function to SSH into VM
ssh_vm() {
    log "Connecting to VM..."
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -p "$VM_SSH_PORT" "$VM_SSH_USER@$VM_SSH_HOST"
}

# Function to check VM status
check_status() {
    log "Checking VM status..."
    if check_vm; then
        # Get VM info
        ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
            -p "$VM_SSH_PORT" "$VM_SSH_USER@$VM_SSH_HOST" \
            'echo "✅ VM is running!" && echo "System: $(uname -a)" && echo "NixOS: $(nixos-version)" && echo "User: $(whoami)"'
    else
        warn "❌ VM is not accessible on $VM_SSH_HOST:$VM_SSH_PORT"
        echo "Make sure:"
        echo "1. VM is running in UTM"
        echo "2. SSH is enabled: sudo systemctl enable --now sshd"
        echo "3. Port forwarding is configured: $VM_SSH_PORT -> 22"
    fi
}

# Main script logic
case "${1:-help}" in
    "download")
        download_iso
        ;;
    "setup")
        download_iso
        show_utm_instructions
        ;;
    "deploy")
        deploy_config
        ;;
    "ssh")
        ssh_vm
        ;;
    "status")
        check_status
        ;;
    "help"|*)
        echo "NixOS VM Setup Helper"
        echo ""
        echo "Usage: $0 <command>"
        echo ""
        echo "Commands:"
        echo "  download  - Download NixOS ISO"
        echo "  setup     - Download ISO and show UTM setup instructions"
        echo "  deploy    - Deploy NixOS configuration to running VM"
        echo "  ssh       - SSH into running VM"
        echo "  status    - Check VM status"
        echo "  help      - Show this help"
        echo ""
        echo "Workflow:"
        echo "1. $0 setup       # Download ISO and get instructions"
        echo "2. Create VM in UTM using the instructions"
        echo "3. $0 deploy      # Deploy configuration to VM"
        echo "4. $0 ssh         # SSH into configured VM"
        ;;
esac