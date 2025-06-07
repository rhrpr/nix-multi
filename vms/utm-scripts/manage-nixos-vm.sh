VM_NAME="nixos-development"
    
    # Colors
    GREEN='\033[0;32m'
    RED='\033[0;31m'
    YELLOW='\033[1;33m'
    NC='\033[0m'
    
    log() { echo -e "''${GREEN}[INFO]''${NC} $1"; }
    warn() { echo -e "''${YELLOW}[WARN]''${NC} $1"; }
    error() { echo -e "''${RED}[ERROR]''${NC} $1"; }
    
    case "$1" in
      create)
        create-nixos-vm
        ;;
      start)
        log "Starting VM: $VM_NAME"
        if utmctl start "$VM_NAME"; then
          log "VM started successfully"
          # Wait a moment for VM to initialize
          sleep 2
          # Show IP once available
          VM_IP=$(utmctl ip-address "$VM_NAME" 2>/dev/null | head -n1 | awk '{print $1}' || echo "")
          if [ -n "$VM_IP" ]; then
            log "VM IP: $VM_IP"
          fi
        else
          error "Failed to start VM"
        fi
        ;;
      stop)
        log "Stopping VM: $VM_NAME"
        utmctl stop "$VM_NAME"
        ;;
      suspend)
        log "Suspending VM: $VM_NAME"
        utmctl suspend "$VM_NAME"
        ;;
      status)
        echo "=== VM Status ==="
        utmctl status "$VM_NAME"
        echo ""
        echo "=== VM IP Addresses ==="
        utmctl ip-address "$VM_NAME" 2>/dev/null || echo "No IP addresses available (VM may be stopped)"
        ;;
      list)
        echo "=== All VMs ==="
        utmctl list
        ;;
      ip)
        echo "=== VM IP Addresses ==="
        utmctl ip-address "$VM_NAME"
        ;;
      ssh)
        log "Connecting to VM via SSH..."
        VM_IP=$(utmctl ip-address "$VM_NAME" 2>/dev/null | head -n1 | awk '{print $1}')
        if [ -n "$VM_IP" ]; then
          log "Connecting to nixos@$VM_IP"
          ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no nixos@"$VM_IP"
        else
          error "Could not determine VM IP address"
          echo "Make sure the VM is running and has network connectivity"
          echo "You can check with: vm status"
        fi
        ;;
      deploy)
        log "Deploying NixOS configuration to VM..."
        VM_IP=$(utmctl ip-address "$VM_NAME" 2>/dev/null | head -n1 | awk '{print $1}')
        if [ -n "$VM_IP" ]; then
          log "Deploying to nixos@$VM_IP"
          cd ~/.config/nix-darwin/vms/nixos-vm
          nixos-rebuild switch --flake . --target-host nixos@"$VM_IP" --use-remote-sudo
        else
          error "Could not determine VM IP address"
          echo "Ensure the VM is running and SSH is configured"
        fi
        ;;
      rebuild)
        log "Rebuilding VM configuration locally..."
        cd ~/.config/nix-darwin/vms/nixos-vm
        nix build .#nixosConfigurations.vm.config.system.build.toplevel
        log "Build complete. Use 'vm deploy' to apply to the running VM."
        ;;
      console)
        log "Opening VM console..."
        open -a "UTM"
        # Focus on the specific VM if possible
        osascript -e "tell application \"UTM\" to activate" 2>/dev/null || true
        ;;
      clone)
        if [ -z "$2" ]; then
          error "Usage: vm clone <new-vm-name>"
          exit 1
        fi
        log "Cloning VM '$VM_NAME' to '$2'"
        utmctl clone "$VM_NAME" "$2"
        log "Clone complete: $2"
        ;;
      delete)
        warn "This will permanently delete the VM '$VM_NAME'!"
        echo "Current VM status:"
        utmctl status "$VM_NAME" 2>/dev/null || echo "VM not found"
        echo ""
        read -p "Are you sure you want to delete the VM? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
          log "Stopping VM if running..."
          utmctl stop "$VM_NAME" 2>/dev/null || true
          sleep 2
          log "Deleting VM..."
          utmctl delete "$VM_NAME"
          log "VM '$VM_NAME' has been deleted"
        else
          log "VM deletion cancelled"
        fi
        ;;
      exec)
        if [ -z "$2" ]; then
          error "Usage: vm exec <command>"
          echo "Example: vm exec 'ls -la'"
          exit 1
        fi
        log "Executing command in VM: $2"
        utmctl exec "$VM_NAME" -- $2
        ;;
      *)
        echo "UTM VM Manager for NixOS"
        echo ""
        echo "Usage: vm <command> [args]"
        echo ""
        echo "Commands:"
        echo "  create              Create a new NixOS VM"
        echo "  start               Start the VM"
        echo "  stop                Stop the VM"
        echo "  suspend             Suspend the VM"
        echo "  status              Show VM status and IP"
        echo "  list                List all VMs"
        echo "  ip                  Show VM IP addresses"
        echo "  ssh                 SSH into the VM"
        echo "  deploy              Deploy NixOS configuration"
        echo "  rebuild             Rebuild config locally"
        echo "  console             Open VM console"
        echo "  clone <name>        Clone the VM"
        echo "  delete              Delete the VM"
        echo "  exec <cmd>          Execute command in VM"
        echo ""
        echo "Examples:"
        echo "  vm create           # Create new VM"
        echo "  vm start            # Start the VM"
        echo "  vm ssh              # SSH into running VM"
        echo "  vm deploy           # Deploy latest config"
        echo "  vm exec 'htop'      # Run htop in VM"
        exit 1
        ;;
    esac