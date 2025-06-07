{ pkgs, ... }:

let
  # VM management scripts
  createVMScript = pkgs.writeShellScriptBin "create-nixos-vm" ''
    ${builtins.readFile ./utm-scripts/create-vm.sh}
  '';
  
  destroyVMScript = pkgs.writeShellScriptBin "destroy-nixos-vm" ''
    VM_NAME="nixos-development"
    
    echo "Stopping VM if running..."
    utmctl stop "$VM_NAME" 2>/dev/null || true
    
    echo "Removing VM..."
    utmctl delete "$VM_NAME"
    
    echo "VM '$VM_NAME' has been removed."
  '';
  
  manageVMScript = pkgs.writeShellScriptBin "manage-nixos-vm" ''
    VM_NAME="nixos-development"
    
    case "$1" in
      start)
        echo "Starting VM: $VM_NAME"
        utmctl start "$VM_NAME"
        ;;
      stop)
        echo "Stopping VM: $VM_NAME"
        utmctl stop "$VM_NAME"
        ;;
      status)
        echo "VM Status:"
        utmctl list | grep "$VM_NAME" || echo "VM not found"
        ;;
      ssh)
        echo "Connecting to VM via SSH..."
        ssh nixos@nixos-vm
        ;;
      deploy)
        echo "Deploying NixOS configuration to VM..."
        cd ~/.config/nix-darwin/vms/nixos-vm
        nixos-rebuild switch --flake . --target-host nixos@nixos-vm --use-remote-sudo
        ;;
      rebuild)
        echo "Rebuilding VM configuration locally..."
        cd ~/.config/nix-darwin/vms/nixos-vm
        nix build .#nixosConfigurations.vm.config.system.build.toplevel
        ;;
      console)
        echo "Opening VM console..."
        utmctl console "$VM_NAME"
        ;;
      *)
        echo "Usage: manage-nixos-vm {start|stop|status|ssh|deploy|rebuild|console}"
        echo ""
        echo "Commands:"
        echo "  start    - Start the VM"
        echo "  stop     - Stop the VM"
        echo "  status   - Show VM status"
        echo "  ssh      - SSH into the VM"
        echo "  deploy   - Deploy configuration to VM"
        echo "  rebuild  - Rebuild configuration locally"
        echo "  console  - Open VM console"
        exit 1
        ;;
    esac
  '';
  
  buildVMISOScript = pkgs.writeShellScriptBin "build-vm-iso" ''
    echo "Building custom NixOS ISO for VM installation..."
    cd ~/.config/nix-darwin/vms/nixos-vm
    nix build .#packages.aarch64-linux.iso
    echo "ISO built successfully!"
    echo "ISO location: $(readlink -f result)/iso/*.iso"
  '';

in {
  # Add VM management tools to system packages
  environment.systemPackages = with pkgs; [
    # UTM and virtualization tools
    qemu
    
    # Custom VM management scripts
    createVMScript
    destroyVMScript
    manageVMScript
    buildVMISOScript
    
    # Network and SSH tools for VM communication
    openssh
    rsync
  ];
  
  # Add convenient shell aliases
  environment.shellAliases = {
    vm = "manage-nixos-vm";
    vm-create = "create-nixos-vm";
    vm-destroy = "destroy-nixos-vm";
    vm-start = "manage-nixos-vm start";
    vm-stop = "manage-nixos-vm stop";
    vm-ssh = "manage-nixos-vm ssh";
    vm-deploy = "manage-nixos-vm deploy";
    vm-status = "manage-nixos-vm status";
    vm-console = "manage-nixos-vm console";
    vm-build-iso = "build-vm-iso";
    
    # Hyprland specific
    vm-hypr-reload = "ssh nixos@nixos-vm 'hyprctl reload'";
    vm-hypr-info = "ssh nixos@nixos-vm 'hyprctl clients'";
    vm-screenshot = "ssh nixos@nixos-vm 'grim /tmp/screenshot.png && scp nixos@nixos-vm:/tmp/screenshot.png ~/Desktop/'";
  };
}