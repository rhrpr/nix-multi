#!/usr/bin/env bash
# filepath: /Users/hrpr/.config/nix-darwin/vms/utm-scripts/provision-vm.sh

# Provision the VM after initial installation

set -e

VM_IP="192.168.64.10"  # Adjust based on your UTM network
VM_USER="nixos"

log() {
    echo -e "\033[0;32m[PROVISION]\033[0m $1"
}

# Wait for VM to be accessible
wait_for_vm() {
    log "Waiting for VM to be accessible..."
    
    while ! ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no $VM_USER@$VM_IP "echo 'VM is ready'" 2>/dev/null; do
        echo "Waiting for VM..."
        sleep 5
    done
    
    log "VM is accessible!"
}

# Setup SSH key
setup_ssh() {
    log "Setting up SSH access..."
    
    # Copy SSH key to VM
    ssh-copy-id -o StrictHostKeyChecking=no $VM_USER@$VM_IP
}

# Deploy initial configuration
deploy_config() {
    log "Deploying NixOS configuration..."
    
    cd ~/.config/nix-multi/vms/nixos-vm
    nixos-rebuild switch --flake . --target-host $VM_USER@$VM_IP --use-remote-sudo
}

# Install development tools
setup_development() {
    log "Setting up development environment..."
    
    ssh $VM_USER@$VM_IP "
        # Clone dotfiles or additional configurations
        git clone https://github.com/your-username/dotfiles.git ~/.config/dotfiles || true
        
        # Setup additional user configurations
        home-manager switch --flake ~/.config/nix-multi/vms/nixos-vm#$VM_USER
    "
}

main() {
    log "Provisioning NixOS VM..."
    
    wait_for_vm
    setup_ssh
    deploy_config
    setup_development
    
    log "VM provisioning complete!"
    log "You can now access your VM with: ssh $VM_USER@$VM_IP"
}

main "$@"