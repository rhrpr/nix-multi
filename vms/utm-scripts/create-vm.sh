#!/usr/bin/env bash
# filepath: /Users/hrpr/.config/nix-darwin/vms/utm-scripts/create-vm.sh

set -e

VM_NAME="nixos-development"
ISO_PATH="$HOME/Downloads/nixos-minimal.iso"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check UTM
check_utm() {
    if ! command -v utmctl &> /dev/null; then
        error "UTM CLI not found. Install UTM from Mac App Store."
        exit 1
    fi
    
    if ! pgrep -x "UTM" > /dev/null; then
        log "Starting UTM..."
        open -a "UTM"
        sleep 3
    fi
    
    log "UTM is ready"
}

# Download ISO
download_iso() {
    if [ ! -f "$ISO_PATH" ]; then
        log "Downloading NixOS ISO..."
        curl -L "https://channels.nixos.org/nixos-unstable/latest-nixos-minimal-aarch64-linux.iso" -o "$ISO_PATH"
    else
        log "NixOS ISO exists at $ISO_PATH"
    fi
}

# Check existing VM
check_existing() {
    if utmctl list 2>/dev/null | grep -q "^$VM_NAME"; then
        warn "VM '$VM_NAME' already exists!"
        read -p "Delete and recreate? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            utmctl stop "$VM_NAME" 2>/dev/null || true
            sleep 1
            utmctl delete "$VM_NAME"
            log "Deleted existing VM"
        else
            log "Keeping existing VM. Use 'vm start' to start it."
            exit 0
        fi
    fi
}

# Simple GUI automation - just open the dialog
open_create_dialog() {
    log "Opening VM creation dialog..."
    
    cat > /tmp/open_create.applescript << 'EOF'
tell application "UTM"
    activate
    delay 1
end tell

tell application "System Events"
    tell process "UTM"
        repeat 10 times
            if exists window 1 then exit repeat
            delay 0.5
        end repeat
        
        if not (exists window 1) then
            return "No UTM window found"
        end if
        
        -- Try to click create button
        try
            click button "Create a New Virtual Machine" of window 1
            delay 1
            if exists sheet 1 of window 1 then
                click button "Virtualize" of sheet 1 of window 1
                delay 1
                click button "Linux" of sheet 1 of window 1
            end if
            return "Dialog opened"
        on error
            try
                click button 1 of window 1
                return "First button clicked"
            on error
                return "Could not find create button"
            end try
        end try
    end tell
end tell
EOF

    local result
    if result=$(osascript /tmp/open_create.applescript 2>&1); then
        log "Automation result: $result"
        rm /tmp/open_create.applescript
        return 0
    else
        warn "Automation failed: $result"
        rm /tmp/open_create.applescript
        return 1
    fi
}

# Manual setup guide
show_setup_guide() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                 MANUAL VM SETUP GUIDE                       ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Please configure the VM with these EXACT settings:"
    echo ""
    echo "📋 INFORMATION:"
    echo "   • Name: $VM_NAME"
    echo ""
    echo "⚙️  SYSTEM:"
    echo "   • Architecture: ARM64"
    echo "   • Memory: 8192 MB (8GB)"
    echo "   • CPU Cores: 4"
    echo ""
    echo "💾 DRIVES:"
    echo "   1. VirtIO Drive - 50GB (new disk image)"
    echo "   2. USB Drive - CD/DVD - $ISO_PATH"
    echo ""
    echo "🌐 NETWORK:"
    echo "   • Mode: Shared"
    echo ""
    echo "🖼️  DISPLAY:"
    echo "   • Hardware: virtio-gpu-pci"
    echo ""
    echo "💾 SAVE the VM when done!"
    echo ""
    echo "⚠️  VM name MUST be exactly: $VM_NAME"
    echo ""
    
    read -p "Press Enter when you've created and saved the VM..."
}

# Wait for VM to be created
wait_for_vm() {
    log "Waiting for VM to be created..."
    
    local attempts=0
    local max_attempts=60
    
    while [ $attempts -lt $max_attempts ]; do
        if utmctl list 2>/dev/null | grep -q "^$VM_NAME"; then
            log "✅ VM '$VM_NAME' detected!"
            utmctl status "$VM_NAME"
            return 0
        fi
        
        if [ $((attempts % 10)) -eq 0 ] && [ $attempts -gt 0 ]; then
            echo "⏳ Still waiting... ($attempts/$max_attempts)"
        fi
        
        sleep 1
        attempts=$((attempts + 1))
    done
    
    error "❌ VM not found after $max_attempts seconds"
    error "Make sure VM name is exactly: $VM_NAME"
    return 1
}

# Show completion message
show_completion() {
    echo ""
    echo "🎉 VM Setup Complete!"
    echo ""
    echo "Next steps:"
    echo "1. vm start     - Start the VM"
    echo "2. Install NixOS from the ISO"
    echo "3. vm ssh       - SSH after install"
    echo "4. vm deploy    - Deploy full config"
    echo ""
    echo "Available commands:"
    echo "  vm start/stop/status"
    echo "  vm ssh/ip/console"
    echo "  vm deploy/rebuild"
    echo ""
}

# Main function
main() {
    log "🚀 Creating NixOS Development VM..."
    
    check_utm
    download_iso
    check_existing
    
    # Try to open create dialog, fallback to manual
    if open_create_dialog; then
        log "✅ Creation dialog opened automatically"
    else
        warn "❌ Automation failed - opening UTM manually"
        open -a "UTM"
    fi
    
    show_setup_guide
    
    if wait_for_vm; then
        show_completion
        
        echo ""
        read -p "Start the VM now? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log "🚀 Starting VM..."
            if utmctl start "$VM_NAME"; then
                log "✅ VM started! Install NixOS from the ISO."
            else
                error "❌ Failed to start VM"
            fi
        fi
    else
        error "❌ VM creation failed"
        echo ""
        echo "Manual steps:"
        echo "1. Open UTM"
        echo "2. Create VM named exactly: $VM_NAME"
        echo "3. Run: vm start"
    fi
}

main "$@"