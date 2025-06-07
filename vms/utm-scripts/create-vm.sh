#!/usr/bin/env bash
# filepath: /Users/hrpr/.config/nix-darwin/vms/utm-scripts/create-vm.sh

set -e

VM_NAME="nixos-development"
ISO_PATH="$HOME/Downloads/nixos-minimal.iso"
DISK_SIZE="50" # GB
RAM_SIZE="8192" # MB (8GB)
CPU_CORES="4"

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

debug() {
    echo -e "${BLUE}[DEBUG]${NC} $1"
}

# Check if UTM is installed and running
check_utm() {
    if ! command -v utmctl &> /dev/null; then
        error "UTM command line tools not found."
        error "Please install UTM from the Mac App Store or https://mac.getutm.app/"
        exit 1
    fi
    
    # Start UTM if not running
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

# Create VM using corrected UTM AppleScript API
create_vm_applescript() {
    log "Creating VM using UTM AppleScript API..."
    
    # Calculate disk size in bytes
    local disk_size_bytes=$((DISK_SIZE * 1024 * 1024 * 1024))
    
    cat > /tmp/create_utm_vm.applescript << APPLESCRIPT_EOF
on run
    try
        tell application "UTM"
            -- Create a new virtual machine configuration
            set newVM to make new virtual machine with properties {name:"$VM_NAME", notes:"NixOS Development VM with Hyprland"}
            
            -- Configure the virtual machine
            tell configuration of newVM
                -- Set basic system properties
                set architecture to "aarch64"
                set machine to "virt"
                set memory to $RAM_SIZE
                set cores to $CPU_CORES
                
                -- Add a disk drive (main system disk)
                make new drive with properties {interface:"virtio", image file:missing value, size:$disk_size_bytes, removable:false}
                
                -- Add CD/DVD drive with ISO
                set isoFile to POSIX file "$ISO_PATH"
                make new drive with properties {interface:"usb", image file:isoFile, removable:true}
                
                -- Configure network
                make new network with properties {mode:"shared"}
                
                -- Configure display
                make new display with properties {hardware:"virtio-gpu-pci", width:1920, height:1080}
                
                -- Configure audio
                make new sound with properties {hardware:"intel-hda"}
                
                -- Configure USB
                set usb support to true
            end tell
            
            -- Save the configuration
            save newVM
            
            return name of newVM
        end tell
        
    on error errMsg number errNum
        return "Error " & errNum & ": " & errMsg
    end try
end run
APPLESCRIPT_EOF

    # Run the AppleScript
    if VM_RESULT=$(osascript /tmp/create_utm_vm.applescript 2>&1); then
        if [[ "$VM_RESULT" == *"Error"* ]]; then
            warn "AppleScript reported error: $VM_RESULT"
            rm /tmp/create_utm_vm.applescript
            return 1
        else
            log "VM created successfully via AppleScript: $VM_RESULT"
            rm /tmp/create_utm_vm.applescript
            return 0
        fi
    else
        warn "AppleScript execution failed: $VM_RESULT"
        rm /tmp/create_utm_vm.applescript
        return 1
    fi
}

# Simplified AppleScript approach (fallback)
create_vm_simple_applescript() {
    log "Trying simplified AppleScript approach..."
    
    cat > /tmp/create_utm_simple.applescript << 'APPLESCRIPT_EOF'
tell application "UTM"
    try
        -- Create basic VM
        set newVM to make new virtual machine with properties {name:"nixos-development"}
        
        -- Basic configuration
        tell configuration of newVM
            set architecture to "aarch64"
            set memory to 8192
            set cores to 4
        end tell
        
        save newVM
        return "VM created successfully"
        
    on error errMsg
        return "Error: " & errMsg
    end try
end tell
APPLESCRIPT_EOF

    if VM_RESULT=$(osascript /tmp/create_utm_simple.applescript 2>&1); then
        log "Simple AppleScript result: $VM_RESULT"
        rm /tmp/create_utm_simple.applescript
        
        if [[ "$VM_RESULT" == *"Error"* ]]; then
            return 1
        else
            return 0
        fi
    else
        warn "Simple AppleScript failed: $VM_RESULT"
        rm /tmp/create_utm_simple.applescript
        return 1
    fi
}

# GUI automation approach (more reliable fallback)
create_vm_gui_automation() {
    log "Using GUI automation approach..."
    
    cat > /tmp/create_utm_gui.applescript << 'APPLESCRIPT_EOF'
tell application "UTM"
    activate
    delay 2
end tell

tell application "System Events"
    tell process "UTM"
        -- Wait for UTM window to appear
        repeat 20 times
            if exists window 1 then exit repeat
            delay 0.5
        end repeat
        
        if not (exists window 1) then
            error "UTM window not found"
        end if
        
        -- Try to find and click the create VM button
        set buttonFound to false
        
        -- Method 1: Look for specific button text
        try
            click button "Create a New Virtual Machine" of window 1
            set buttonFound to true
        on error
            -- Method 2: Try the first button (usually the + or create button)
            try
                click button 1 of window 1
                set buttonFound to true
            on error
                -- Method 3: Look through all buttons for one with "Create" or "New"
                try
                    repeat with btn in buttons of window 1
                        set btnName to name of btn as string
                        if btnName contains "Create" or btnName contains "New" or btnName contains "+" then
                            click btn
                            set buttonFound to true
                            exit repeat
                        end if
                    end repeat
                end try
            end try
        end try
        
        if not buttonFound then
            error "Could not find create VM button"
        end if
        
        delay 2
        
        -- Wait for and interact with the creation dialog
        repeat 10 times
            if exists sheet 1 of window 1 then exit repeat
            delay 0.5
        end repeat
        
        if not (exists sheet 1 of window 1) then
            error "VM creation dialog did not appear"
        end if
        
        -- Select Virtualize
        try
            click button "Virtualize" of sheet 1 of window 1
            delay 1
        on error
            error "Could not select Virtualize option"
        end try
        
        -- Select Linux
        try
            click button "Linux" of sheet 1 of window 1
            delay 1
        on error
            error "Could not select Linux option"
        end try
        
        return "GUI automation completed - manual configuration needed"
    end tell
end tell
APPLESCRIPT_EOF

    if GUI_RESULT=$(osascript /tmp/create_utm_gui.applescript 2>&1); then
        log "GUI automation result: $GUI_RESULT"
        rm /tmp/create_utm_gui.applescript
        return 0
    else
        warn "GUI automation failed: $GUI_RESULT"
        rm /tmp/create_utm_gui.applescript
        return 1
    fi
}

# Manual configuration guide
show_manual_configuration() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║              MANUAL VM CONFIGURATION GUIDE                ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Complete the VM configuration with these EXACT settings:"
    echo ""
    echo "📋 INFORMATION TAB:"
    echo "   • Name: $VM_NAME"
    echo "   • Notes: NixOS Development VM with Hyprland"
    echo ""
    echo "⚙️  SYSTEM TAB:"
    echo "   • Architecture: ARM64 (aarch64)"
    echo "   • System: virt-4.0"
    echo "   • Memory: $RAM_SIZE MB"
    echo "   • CPU: $CPU_CORES cores"
    echo "   • Boot Order: CD/DVD, then Hard Disk"
    echo ""
    echo "💾 DRIVES TAB:"
    echo "   Remove default drives and add:"
    echo "   Drive 1:"
    echo "   • Interface: VirtIO"
    echo "   • Size: ${DISK_SIZE}GB"
    echo "   • Image Type: Disk Image"
    echo "   • Create new blank disk"
    echo ""
    echo "   Drive 2:"
    echo "   • Interface: USB"
    echo "   • Image Type: CD/DVD"
    echo "   • Image File: $ISO_PATH"
    echo "   • Removable: ✓"
    echo ""
    echo "🌐 NETWORK TAB:"
    echo "   • Network Mode: Shared"
    echo ""
    echo "🖼️  DISPLAY TAB:"
    echo "   • Emulated Display Card: virtio-gpu-pci"
    echo "   • Resolution: 1920x1080"
    echo ""
    echo "🔊 AUDIO TAB:"
    echo "   • Emulated Audio Card: Intel HD Audio"
    echo ""
    echo "🔌 INPUT TAB:"
    echo "   • USB Support: ✓"
    echo ""
    echo "After configuration, click 'Save' to create the VM."
    echo ""
    
    read -p "Press Enter after completing the manual configuration..."
}

# Verify VM was created
verify_vm_creation() {
    log "Verifying VM creation..."
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if utmctl list 2>/dev/null | grep -q "^$VM_NAME"; then
            log "✅ VM '$VM_NAME' found!"
            utmctl status "$VM_NAME"
            return 0
        fi
        
        if [ $((attempt % 5)) -eq 0 ]; then
            echo "⏳ Attempt $attempt/$max_attempts: Still waiting for VM..."
        fi
        sleep 1
        attempt=$((attempt + 1))
    done
    
    error "❌ VM '$VM_NAME' not found after verification."
    return 1
}

# Show next steps
show_next_steps() {
    echo ""
    echo "🎉 VM Creation Successful!"
    echo ""
    echo "Next Steps:"
    echo "1. 🚀 Start the VM: vm start"
    echo "2. 🔧 Install NixOS from the ISO"
    echo "3. 🌐 Configure SSH access"
    echo "4. 📦 Deploy configuration: vm deploy"
    echo ""
    echo "Available Commands:"
    echo "   vm start/stop/status    - VM lifecycle"
    echo "   vm ssh                  - SSH into VM"
    echo "   vm deploy               - Deploy NixOS config"
    echo ""
}

# Main execution
main() {
    log "🚀 Setting up NixOS VM for development..."
    
    check_utm
    download_nixos_iso
    check_existing_vm
    
    # Try multiple approaches in order of reliability
    if create_vm_applescript; then
        log "✅ VM created using full AppleScript API"
    elif create_vm_simple_applescript; then
        log "✅ VM created using simplified AppleScript"
        echo "You'll need to configure drives and other settings manually."
        show_manual_configuration
    elif create_vm_gui_automation; then
        log "✅ VM creation initiated using GUI automation"
        show_manual_configuration
    else
        warn "❌ All automation methods failed"
        log "Opening UTM for completely manual creation..."
        open -a "UTM"
        show_manual_configuration
    fi
    
    if verify_vm_creation; then
        show_next_steps
        
        read -p "Would you like to start the VM now? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log "🚀 Starting VM..."
            utmctl start "$VM_NAME"
        fi
    else
        error "❌ VM verification failed"
        echo "Please ensure the VM was created with the exact name: $VM_NAME"
    fi
}

main "$@"