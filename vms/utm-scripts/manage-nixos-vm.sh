#!/usr/bin/env bash
# filepath: /Users/hrpr/.config/nix-darwin/vms/utm-scripts/manage-nixos-vm.sh

VM_NAME="nixos-development"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
debug() { echo -e "${BLUE}[DEBUG]${NC} $1"; }

case "$1" in
  create)
    # Call the create script
    if command -v create-nixos-vm &>/dev/null; then
        create-nixos-vm
    else
        error "create-nixos-vm script not found"
        exit 1
    fi
    ;;
  start)
    log "Starting VM: $VM_NAME"
    if utmctl start "$VM_NAME"; then
      log "VM started successfully"
      sleep 2
      VM_IP=$(utmctl ip-address "$VM_NAME" 2>/dev/null | head -n1 | awk '{print $1}' || echo "")
      if [ -n "$VM_IP" ]; then
        log "VM IP: $VM_IP"
      else
        debug "IP not yet available"
      fi
    else
      error "Failed to start VM"
    fi
    ;;
  stop)
    log "Stopping VM: $VM_NAME"
    if utmctl stop "$VM_NAME"; then
      log "VM stopped successfully"
    else
      error "Failed to stop VM"
    fi
    ;;
  suspend)
    log "Suspending VM: $VM_NAME"
    if utmctl suspend "$VM_NAME"; then
      log "VM suspended successfully"
    else
      error "Failed to suspend VM"
    fi
    ;;
  status)
    echo "=== VM Status ==="
    utmctl status "$VM_NAME" 2>/dev/null || echo "VM not found"
    echo ""
    echo "=== VM IP Addresses ==="
    if utmctl ip-address "$VM_NAME" 2>/dev/null; then
      echo ""
    else
      echo "No IP addresses (VM stopped or network not ready)"
    fi
    ;;
  list)
    echo "=== All UTM VMs ==="
    utmctl list
    ;;
  ip)
    echo "=== VM IP Addresses ==="
    if utmctl ip-address "$VM_NAME" 2>/dev/null; then
      log "Use 'vm ssh' to connect"
    else
      warn "No IP found - ensure VM is running"
    fi
    ;;
  ssh)
    log "Connecting via SSH..."
    VM_IP=$(utmctl ip-address "$VM_NAME" 2>/dev/null | head -n1 | awk '{print $1}')
    if [ -n "$VM_IP" ]; then
      log "Connecting to nixos@$VM_IP"
      ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no nixos@"$VM_IP"
    else
      error "Could not get VM IP"
      echo "Try: vm status"
    fi
    ;;
  deploy)
    log "Deploying NixOS configuration..."
    VM_IP=$(utmctl ip-address "$VM_NAME" 2>/dev/null | head -n1 | awk '{print $1}')
    if [ -n "$VM_IP" ] && [ -d ~/.config/nix-darwin/vms/nixos-vm ]; then
      cd ~/.config/nix-darwin/vms/nixos-vm
      nixos-rebuild switch --flake . --target-host nixos@"$VM_IP" --use-remote-sudo
    else
      error "Cannot deploy - check VM IP and config directory"
    fi
    ;;
  rebuild)
    log "Building configuration locally..."
    if [ -d ~/.config/nix-darwin/vms/nixos-vm ]; then
      cd ~/.config/nix-darwin/vms/nixos-vm
      nix build .#nixosConfigurations.vm.config.system.build.toplevel
      log "Build complete. Use 'vm deploy' to apply."
    else
      error "NixOS config directory not found"
    fi
    ;;
  console)
    log "Opening VM console..."
    open -a "UTM"
    ;;
  clone)
    if [ -z "$2" ]; then
      error "Usage: vm clone <new-name>"
      exit 1
    fi
    log "Cloning '$VM_NAME' to '$2'"
    utmctl clone "$VM_NAME" "$2"
    ;;
  delete)
    warn "This will DELETE VM '$VM_NAME' permanently!"
    read -p "Type 'DELETE' to confirm: " confirmation
    if [ "$confirmation" = "DELETE" ]; then
      utmctl stop "$VM_NAME" 2>/dev/null || true
      sleep 2
      utmctl delete "$VM_NAME"
      log "VM deleted"
    else
      log "Cancelled"
    fi
    ;;
  exec)
    if [ -z "$2" ]; then
      error "Usage: vm exec <command>"
      exit 1
    fi
    log "Executing: $2"
    utmctl exec "$VM_NAME" -- "$2"
    ;;
  *)
    echo "🖥️  NixOS VM Manager"
    echo ""
    echo "Usage: vm <command> [args]"
    echo ""
    echo "📋 Lifecycle:"
    echo "  create              Create new VM"
    echo "  start               Start VM"
    echo "  stop                Stop VM"
    echo "  suspend             Suspend VM"
    echo "  status              Show status"
    echo "  delete              Delete VM"
    echo ""
    echo "🔗 Access:"
    echo "  ssh                 SSH into VM"
    echo "  ip                  Show IP"
    echo "  console             Open GUI"
    echo ""
    echo "⚙️  Config:"
    echo "  deploy              Deploy NixOS config"
    echo "  rebuild             Build config locally"
    echo ""
    echo "🔧 Management:"
    echo "  list                List all VMs"
    echo "  clone <name>        Clone VM"
    echo "  exec <cmd>          Run command in VM"
    echo ""
    echo "🚀 Quick start:"
    echo "  vm create           # Create VM"
    echo "  vm start            # Start VM"
    echo "  vm ssh              # SSH after install"
    exit 1
    ;;
esac