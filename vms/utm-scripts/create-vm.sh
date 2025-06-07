#!/usr/bin/env bash
# filepath: /Users/hrpr/.config/nix-darwin/vms/utm-scripts/create-vm.sh

set -e

VM_NAME="nixos-development"
TEMPLATE_VM="nixos-template"
ISO_PATH="$HOME/Downloads/nixos-minimal.iso"
DISK_SIZE="50" # GB
RAM_SIZE="8192" # MB (8GB)
CPU_CORES="4"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Check if UTM is installed and running
check_utm() {
    if ! command -v utmctl &> /dev/null; then
        error "UTM command line tools not found."
        error "Please install UTM from the Mac App Store or https://mac.getutm.app/"
        exit 1
    fi
    
    # Check if UTM app is running
    if ! pgrep -x "UTM" > /dev/null; then
        log "Starting UTM application..."
        open -a "UTM"
        sleep 3
    fi
    
    log "UTM is running with CLI tools available"
}

# Download NixOS ISO if not present
download_nixos_iso() {
    if [ ! -f "$ISO_PATH" ]; then
        log "Downloading NixOS minimal ISO..."
        curl -L "https://channels.nixos.org/nixos-unstable/latest-nixos-minimal-aarch64-linux.iso" -o "$ISO_PATH"
    else
        log "NixOS ISO already exists at $ISO_PATH"
    fi
}

# Check if VM already exists
check_existing_vm() {
    if utmctl list 2>/dev/null | grep -q "^$VM_NAME"; then
        warn "VM '$VM_NAME' already exists!"
        utmctl status "$VM_NAME"
        read -p "Do you want to delete it and recreate? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log "Stopping and deleting existing VM..."
            utmctl stop "$VM_NAME" 2>/dev/null || true
            sleep 2
            utmctl delete "$VM_NAME"
            log "Existing VM deleted"
        else
            log "Keeping existing VM. Use 'vm start' to start it."
            exit 0
        fi
    fi
}

# Create template VM configuration using UTM GUI automation
create_template_vm() {
    log "Creating template VM configuration..."
    
    # Create a temporary AppleScript to automate UTM VM creation
    cat > /tmp/create_utm_template.applescript << EOF
tell application "UTM"
    activate
    delay 2
end tell

tell application "System Events"
    tell process "UTM"
        -- Wait for UTM to be ready
        repeat until exists window 1
            delay 0.5
        end repeat
        
        -- Click "Create a New Virtual Machine" or "+" button
        try
            click button "Create a New Virtual Machine" of window 1
        on error
            click button 1 of window 1 -- Try the + button
        end try
        
        delay 2
        
        -- Select Virtualize
        click button "Virtualize" of sheet 1 of window 1
        delay 1
        
        -- Select Linux
        click button "Linux" of sheet 1 of window 1
        delay 1
        
        -- We'll configure the rest manually for now
        -- This creates a basic Linux VM that we can then clone
    end tell
end tell
EOF

    # Run the AppleScript
    osascript /tmp/create_utm_template.applescript || {
        warn "AppleScript automation failed. Please create the VM manually."
        show_manual_instructions
        return 1
    }
    
    rm /tmp/create_utm_template.applescript
}

# Show manual VM creation instructions
show_manual_instructions() {
    log "Please create the VM manually with these settings:"
    echo ""
    echo "=== Manual VM Creation Steps ==="
    echo "1. Open UTM application"
    echo "2. Click 'Create a New Virtual Machine'"
    echo "3. Select 'Virtualize'"
    echo "4. Select 'Linux'"
    echo "5. Configure the following settings:"
    echo "   - Name: $VM_NAME"
    echo "   - Boot ISO Image: $ISO_PATH"
    echo "   - Memory: ${RAM_SIZE}MB (8GB)"
    echo "   - CPU Cores: $CPU_CORES"
    echo "   - Storage: ${DISK_SIZE}GB"
    echo "   - Enable hardware acceleration if available"
    echo "   - Set display resolution to 1920x1080 or higher"
    echo "6. Click 'Save'"
    echo ""
    echo "=== Advanced Settings (Optional) ==="
    echo "- Network: Shared"
    echo "- Graphics: virtio-gpu-pci"
    echo "- Audio: intel-hda"
    echo "- USB: Enable USB 3.0"
    echo ""
    
    read -p "Press Enter after you've created the VM manually..."
}

# Verify VM creation
verify_vm_creation() {
    log "Verifying VM creation..."
    
    local max_attempts=10
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if utmctl list 2>/dev/null | grep -q "^$VM_NAME"; then
            log "VM '$VM_NAME' found!"
            return 0
        fi
        
        echo "Attempt $attempt/$max_attempts: VM not found yet..."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    error "VM '$VM_NAME' not found after $max_attempts attempts."
    error "Please ensure the VM was created with the exact name: $VM_NAME"
    return 1
}

# Configure VM post-creation
configure_vm() {
    log "VM created successfully!"
    
    # Show VM status
    utmctl status "$VM_NAME"
    
    log "VM configuration complete"
}

# Start the VM
start_vm() {
    log "Starting VM: $VM_NAME"
    
    if utmctl start "$VM_NAME"; then
        log "VM started successfully!"
        log "The VM is now booting from the NixOS ISO..."
        echo ""
        echo "Next steps:"
        echo "1. The VM should open in a new window"
        echo "2. Install NixOS following the installation guide"
        echo "3. Set up SSH access during installation"
        echo "4. After installation, use 'vm deploy' to apply the NixOS configuration"
    else
        error "Failed to start VM. Please check UTM GUI for details."
        return 1
    fi
}

# Show management commands
show_next_steps() {
    echo ""
    echo "=== VM Management Commands ==="
    echo "vm start          - Start the VM"
    echo "vm stop           - Stop the VM"
    echo "vm status         - Check VM status"
    echo "vm ssh            - SSH into VM (after NixOS installation)"
    echo "vm deploy         - Deploy NixOS configuration"
    echo "vm console        - Open VM console/GUI"
    echo ""
    echo "=== Installation Guide ==="
    echo "1. Boot the VM and start the NixOS installer"
    echo "2. Partition the disk (use the entire /dev/vda)"
    echo "3. Generate hardware configuration: nixos-generate-config --root /mnt"
    echo "4. Install NixOS: nixos-install"
    echo "5. Set root and user passwords"
    echo "6. Reboot and enable SSH"
    echo "7. Use 'vm deploy' to apply the full configuration"
    echo ""
}

# Main execution
main() {
    log "Setting up NixOS VM for development..."
    
    check_utm
    download_nixos_iso
    check_existing_vm
    
    # Try automated creation, fall back to manual
    if ! create_template_vm; then
        show_manual_instructions
    fi
    
    if verify_vm_creation; then
        configure_vm
        show_next_steps
        
        read -p "Would you like to start the VM now? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            start_vm
        fi
    else
        error "VM creation failed. Please try manual creation."
        show_manual_instructions
    fi
}

main "$@"