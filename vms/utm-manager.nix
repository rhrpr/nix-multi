{ pkgs, ... }:

let
  # VM creation script
  createVMScript = pkgs.writeShellScriptBin "create-nixos-vm" ''
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
        echo -e "''${GREEN}[INFO]''${NC} $1"
    }

    warn() {
        echo -e "''${YELLOW}[WARN]''${NC} $1"
    }

    error() {
        echo -e "''${RED}[ERROR]''${NC} $1"
    }

    debug() {
        echo -e "''${BLUE}[DEBUG]''${NC} $1"
    }

    # Check system permissions
    check_permissions() {
        log "Checking system permissions..."
        
        # Check if System Events has accessibility permissions
        if ! osascript -e 'tell application "System Events" to get name of first process' >/dev/null 2>&1; then
            error "System Events doesn't have accessibility permissions."
            echo "Please grant accessibility permissions:"
            echo "1. Go to System Preferences → Security & Privacy → Privacy"
            echo "2. Click 'Accessibility' on the left"
            echo "3. Add and enable 'Terminal' or your terminal app"
            echo "4. Add and enable 'System Events'"
            return 1
        fi
        
        log "System permissions OK"
        return 0
    }

    # Check UTM installation and get version info
    check_utm() {
        if ! command -v utmctl &> /dev/null; then
            error "UTM command line tools not found."
            error "Please install UTM from the Mac App Store or https://mac.getutm.app/"
            exit 1
        fi
        
        # Get UTM version
        UTM_VERSION=$(osascript -e 'tell application "UTM" to get version' 2>/dev/null || echo "unknown")
        log "UTM version: $UTM_VERSION"
        
        # Check if UTM app is running
        if ! pgrep -x "UTM" > /dev/null; then
            log "Starting UTM application..."
            open -a "UTM"
            sleep 5
            
            # Wait for UTM to fully load
            local attempts=0
            while [ $attempts -lt 10 ]; do
                if pgrep -x "UTM" > /dev/null; then
                    break
                fi
                sleep 1
                attempts=$((attempts + 1))
            done
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

    # Improved AppleScript with better error handling and debugging
    create_template_vm() {
        log "Attempting automated VM creation..."
        
        if ! check_permissions; then
            return 1
        fi
        
        # Create a more robust AppleScript
        cat > /tmp/create_utm_template.applescript << 'APPLESCRIPT_EOF'
on run
    try
        tell application "UTM"
            activate
        end tell
        
        delay 3
        
        tell application "System Events"
            tell process "UTM"
                -- Wait for UTM window to appear
                set windowCount to 0
                repeat 20 times
                    try
                        set windowCount to count of windows
                        if windowCount > 0 then exit repeat
                    end try
                    delay 0.5
                end repeat
                
                if windowCount = 0 then
                    error "UTM window did not appear"
                end if
                
                -- Try different button names/locations
                set buttonClicked to false
                
                -- Method 1: Look for "Create a New Virtual Machine" button
                try
                    click button "Create a New Virtual Machine" of window 1
                    set buttonClicked to true
                    log "Clicked 'Create a New Virtual Machine' button"
                on error e1
                    log "Method 1 failed: " & e1
                end try
                
                -- Method 2: Look for "+" button
                if not buttonClicked then
                    try
                        click button 1 of window 1
                        set buttonClicked to true
                        log "Clicked first button (likely +)"
                    on error e2
                        log "Method 2 failed: " & e2
                    end try
                end if
                
                -- Method 3: Look for any button containing "Create" or "New"
                if not buttonClicked then
                    try
                        repeat with btn in buttons of window 1
                            set btnName to name of btn
                            if btnName contains "Create" or btnName contains "New" or btnName contains "+" then
                                click btn
                                set buttonClicked to true
                                log "Clicked button: " & btnName
                                exit repeat
                            end if
                        end repeat
                    on error e3
                        log "Method 3 failed: " & e3
                    end try
                end if
                
                if not buttonClicked then
                    error "Could not find create VM button"
                end if
                
                delay 2
                
                -- Look for virtualization options
                set sheetFound to false
                repeat 10 times
                    try
                        if exists sheet 1 of window 1 then
                            set sheetFound to true
                            exit repeat
                        end if
                    end try
                    delay 0.5
                end repeat
                
                if not sheetFound then
                    error "Configuration sheet did not appear"
                end if
                
                -- Try to click Virtualize
                try
                    click button "Virtualize" of sheet 1 of window 1
                    log "Clicked 'Virtualize'"
                    delay 1
                on error eVirt
                    log "Failed to click Virtualize: " & eVirt
                    error "Could not select virtualization option"
                end try
                
                -- Try to click Linux
                try
                    click button "Linux" of sheet 1 of window 1
                    log "Clicked 'Linux'"
                    delay 1
                on error eLinux
                    log "Failed to click Linux: " & eLinux
                    error "Could not select Linux option"
                end try
                
                log "Basic VM template creation initiated successfully"
                return true
                
            end tell
        end tell
        
    on error e
        log "AppleScript error: " & e
        return false
    end try
end run
APPLESCRIPT_EOF

        # Run the AppleScript with detailed output
        debug "Running AppleScript automation..."
        
        if osascript /tmp/create_utm_template.applescript > /tmp/applescript_output.log 2>&1; then
            log "AppleScript completed successfully"
            cat /tmp/applescript_output.log
            rm -f /tmp/create_utm_template.applescript /tmp/applescript_output.log
            return 0
        else
            error "AppleScript failed with output:"
            cat /tmp/applescript_output.log
            rm -f /tmp/create_utm_template.applescript /tmp/applescript_output.log
            return 1
        fi
    }

    # Show detailed manual instructions with screenshots
    show_manual_instructions() {
        echo ""
        echo "╔════════════════════════════════════════════════════════════╗"
        echo "║                    MANUAL VM CREATION                     ║"
        echo "╚════════════════════════════════════════════════════════════╝"
        echo ""
        echo "Since automated creation failed, please follow these steps:"
        echo ""
        echo "1. 🖥️  Open UTM application (should already be open)"
        echo "2. ➕ Click 'Create a New Virtual Machine' or the '+' button"
        echo "3. 🖲️  Select 'Virtualize' (for better performance)"
        echo "4. 🐧 Select 'Linux'"
        echo "5. ⚙️  Configure the following EXACT settings:"
        echo ""
        echo "   📝 Information Tab:"
        echo "      • Name: $VM_NAME"
        echo "      • Operating System: Linux"
        echo ""
        echo "   💾 System Tab:"
        echo "      • Architecture: ARM64 (Apple Silicon)"
        echo "      • System: Default (virt-4.0)"
        echo "      • Memory: ''${RAM_SIZE} MB"
        echo "      • CPU Cores: $CPU_CORES"
        echo ""
        echo "   💿 Drives Tab:"
        echo "      • Remove existing drives and add:"
        echo "      • Drive 1: VirtIO, ''${DISK_SIZE}GB (new disk)"
        echo "      • Drive 2: USB, Removable, Import: $ISO_PATH"
        echo ""
        echo "   🌐 Network Tab:"
        echo "      • Network Mode: Shared"
        echo ""
        echo "   🖼️  Display Tab:"
        echo "      • Hardware: virtio-gpu-pci"
        echo "      • Resolution: 1920x1080 or higher"
        echo ""
        echo "   🔊 Audio Tab:"
        echo "      • Hardware: intel-hda"
        echo ""
        echo "6. 💾 Click 'Save'"
        echo ""
        echo "⚠️  IMPORTANT: The VM name must be exactly '$VM_NAME' for the"
        echo "   management commands to work properly."
        echo ""
        
        read -p "Press Enter after you've created the VM manually..."
    }

    # Verify VM creation
    verify_vm_creation() {
        log "Verifying VM creation..."
        
        local max_attempts=30
        local attempt=1
        
        while [ $attempt -le $max_attempts ]; do
            if utmctl list 2>/dev/null | grep -q "^$VM_NAME"; then
                log "VM '$VM_NAME' found!"
                return 0
            fi
            
            if [ $((attempt % 5)) -eq 0 ]; then
                echo "Attempt $attempt/$max_attempts: Still waiting for VM creation..."
            fi
            sleep 2
            attempt=$((attempt + 1))
        done
        
        error "VM '$VM_NAME' not found after $max_attempts attempts."
        error "Please ensure the VM was created with the exact name: $VM_NAME"
        return 1
    }

    # Show next steps after VM creation
    show_next_steps() {
        echo ""
        echo "=== VM Creation Complete ==="
        utmctl status "$VM_NAME"
        echo ""
        echo "=== VM Management Commands ==="
        echo "vm start          - Start the VM"
        echo "vm stop           - Stop the VM"
        echo "vm status         - Check VM status"
        echo "vm ssh            - SSH into VM (after NixOS installation)"
        echo "vm deploy         - Deploy NixOS configuration"
        echo "vm ip             - Show VM IP addresses"
        echo ""
        echo "=== Installation Guide ==="
        echo "1. Start the VM: vm start"
        echo "2. Install NixOS from the ISO"
        echo "3. Set up SSH access during installation"
        echo "4. Use 'vm deploy' to apply the full NixOS configuration"
        echo ""
    }

    # Main execution
    main() {
        log "Setting up NixOS VM for development..."
        
        check_utm
        download_nixos_iso
        check_existing_vm
        
        # Try automated creation with detailed error reporting
        if create_template_vm; then
            log "✅ Automated creation successful!"
            log "Please complete the VM configuration in the UTM interface."
        else
            warn "❌ Automated creation failed."
            echo ""
            echo "This can happen due to:"
            echo "• UTM interface changes in newer versions"
            echo "• Missing accessibility permissions"
            echo "• UTM not responding quickly enough"
            echo ""
            log "Falling back to manual creation..."
        fi
        
        show_manual_instructions
        
        if verify_vm_creation; then
            show_next_steps
            
            read -p "Would you like to start the VM now? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                log "Starting VM..."
                utmctl start "$VM_NAME"
            fi
        else
            error "VM creation verification failed."
            echo "Please ensure the VM was created with the name: $VM_NAME"
        fi
    }

    main "$@"
  '';

  # Enhanced VM management script
  manageVMScript = pkgs.writeShellScriptBin "manage-nixos-vm" ''
    VM_NAME="nixos-development"
    
    case "$1" in
      create)
        echo "Creating new NixOS VM..."
        create-nixos-vm
        ;;
      start)
        echo "Starting VM: $VM_NAME"
        utmctl start "$VM_NAME"
        ;;
      stop)
        echo "Stopping VM: $VM_NAME"
        utmctl stop "$VM_NAME"
        ;;
      suspend)
        echo "Suspending VM: $VM_NAME"
        utmctl suspend "$VM_NAME"
        ;;
      status)
        echo "VM Status:"
        utmctl status "$VM_NAME"
        ;;
      list)
        echo "All VMs:"
        utmctl list
        ;;
      ip)
        echo "VM IP addresses:"
        utmctl ip-address "$VM_NAME"
        ;;
      ssh)
        echo "Connecting to VM via SSH..."
        # Try to get IP automatically
        VM_IP=$(utmctl ip-address "$VM_NAME" 2>/dev/null | head -n1 | awk '{print $1}')
        if [ -n "$VM_IP" ]; then
          ssh nixos@"$VM_IP"
        else
          echo "Could not determine VM IP. Please check 'vm ip' and connect manually."
          echo "You can also try: ssh nixos@192.168.64.x"
        fi
        ;;
      deploy)
        echo "Deploying NixOS configuration to VM..."
        VM_IP=$(utmctl ip-address "$VM_NAME" 2>/dev/null | head -n1 | awk '{print $1}')
        if [ -n "$VM_IP" ]; then
          cd ~/.config/nix-darwin/vms/nixos-vm
          nixos-rebuild switch --flake . --target-host nixos@"$VM_IP" --use-remote-sudo
        else
          echo "Could not determine VM IP. Please ensure VM is running and SSH is configured."
          echo "You can also try manually: nixos-rebuild switch --flake . --target-host nixos@<VM_IP> --use-remote-sudo"
        fi
        ;;
      rebuild)
        echo "Rebuilding VM configuration locally..."
        cd ~/.config/nix-darwin/vms/nixos-vm
        nix build .#nixosConfigurations.vm.config.system.build.toplevel
        ;;
      console)
        echo "Opening VM console..."
        # Open UTM and focus on the VM
        open -a "UTM"
        ;;
      clone)
        if [ -z "$2" ]; then
          echo "Usage: vm clone <new-vm-name>"
          exit 1
        fi
        echo "Cloning VM to: $2"
        utmctl clone "$VM_NAME" "$2"
        ;;
      delete)
        echo "Warning: This will permanently delete the VM!"
        read -p "Are you sure? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
          utmctl stop "$VM_NAME" 2>/dev/null || true
          utmctl delete "$VM_NAME"
          echo "VM deleted"
        fi
        ;;
      *)
        echo "Usage: manage-nixos-vm {create|start|stop|suspend|status|list|ip|ssh|deploy|rebuild|console|clone|delete}"
        echo ""
        echo "Commands:"
        echo "  create    - Create a new VM"
        echo "  start     - Start the VM"
        echo "  stop      - Stop the VM"
        echo "  suspend   - Suspend the VM"
        echo "  status    - Show VM status"
        echo "  list      - List all VMs"
        echo "  ip        - Show VM IP addresses"
        echo "  ssh       - SSH into the VM"
        echo "  deploy    - Deploy configuration to VM"
        echo "  rebuild   - Rebuild configuration locally"
        echo "  console   - Open VM console"
        echo "  clone     - Clone the VM"
        echo "  delete    - Delete the VM"
        exit 1
        ;;
    esac
  '';

in {
  # Add VM management tools to system packages
  environment.systemPackages = with pkgs; [
    # UTM and virtualization tools
    qemu
    
    # Custom VM management scripts
    createVMScript
    manageVMScript
    
    # Network and SSH tools for VM communication
    openssh
    rsync
  ];
  
  # Add convenient shell aliases
  environment.shellAliases = {
    vm = "manage-nixos-vm";
    vm-create = "manage-nixos-vm create";
    vm-start = "manage-nixos-vm start";
    vm-stop = "manage-nixos-vm stop";
    vm-status = "manage-nixos-vm status";
    vm-ssh = "manage-nixos-vm ssh";
    vm-deploy = "manage-nixos-vm deploy";
    vm-ip = "manage-nixos-vm ip";
    vm-console = "manage-nixos-vm console";
    vm-list = "manage-nixos-vm list";
    vm-clone = "manage-nixos-vm clone";
    vm-delete = "manage-nixos-vm delete";
  };
}