# macOS VM Management Module
# Provides VM creation tools for macOS hosts using QEMU/UTM
{
  pkgs,
  lib,
  config,
  username,
  ...
}:

{
  # VM creation and management tools for macOS
  environment.systemPackages = with pkgs; [
    # Core virtualization for macOS
    qemu # QEMU for VM creation and management

    # VM image manipulation
    qemu-utils # QEMU disk utilities (qemu-img, etc.)

    # Utilities for VM management
    coreutils # Basic utilities
    findutils # File finding utilities
    gnused # GNU sed for text processing
    gawk # GNU awk for text processing

    # macOS-specific VM tools
    lima # Lima for Linux VMs on macOS
    colima # Container runtime for macOS

    # Development and debugging tools
    socat # Socket relay for VM networking
    netcat # Network utility for testing VM connectivity
  ];

  # macOS-specific VM environment variables
  environment.variables = {
    # QEMU system binary locations for scripts
    QEMU_SYSTEM_X86_64 = "${pkgs.qemu}/bin/qemu-system-x86_64";
    QEMU_SYSTEM_AARCH64 = "${pkgs.qemu}/bin/qemu-system-aarch64";
    QEMU_IMG = "${pkgs.qemu}/bin/qemu-img";

    # VM configuration directories
    VM_IMAGES_DIR = "/Users/${username}/VMs";
    VM_CONFIG_DIR = "/Users/${username}/.config/vms";

    # macOS VM optimization settings
    QEMU_AUDIO_DRV = "coreaudio"; # Use CoreAudio for better audio

    # Memory and performance settings for macOS
    VM_DEFAULT_MEMORY = "4G";
    VM_DEFAULT_CPUS = "4";

    # Network settings for macOS VMs
    VM_NETWORK_MODE = "user"; # User-mode networking (no root required)
  };

  # Create VM directories and configuration files on activation
  system.activationScripts.createVMDirs = {
    text = ''
            # Create VM directories
            mkdir -p /Users/${username}/VMs
            mkdir -p /Users/${username}/.config/vms
            
            # Set proper ownership
            chown ${username}:staff /Users/${username}/VMs
            chown ${username}:staff /Users/${username}/.config/vms
            
            # Create a basic QEMU configuration for macOS
            cat > /Users/${username}/.config/vms/qemu-macos.conf << 'EOF'
      # QEMU Configuration for macOS Host
      # This file contains default settings for running VMs on macOS

      # Audio configuration
      audio_driver = "coreaudio"

      # Network configuration (user-mode networking)
      network_mode = "user"
      ssh_port = "22000"
      vnc_port = "5900"

      # Default VM resources
      default_memory = "4G"
      default_cpus = "4"

      # macOS-specific optimizations
      hvf_enabled = true  # Use macOS Hypervisor Framework when available
      accel = "hvf,tcg"   # Try HVF first, fallback to TCG
      EOF
            
            chown ${username}:staff /Users/${username}/.config/vms/qemu-macos.conf
    '';
  };

  # Shell aliases for VM management on macOS
  environment.shellAliases = {
    # VM build and run commands
    vm-build-x86 = "cd ~/.config/nix-multi && ./vm-build.sh x86_64 build";
    vm-build-arm = "cd ~/.config/nix-multi && ./vm-build.sh aarch64 build";
    vm-run-x86 = "cd ~/.config/nix-multi && ./vm-build.sh x86_64 run";
    vm-run-arm = "cd ~/.config/nix-multi && ./vm-build.sh aarch64 run";
    vm-clean = "cd ~/.config/nix-multi && ./vm-build.sh clean";

    # VM management shortcuts
    vm-list = "ls -la ~/VMs/";
    vm-config = "cat ~/.config/vms/qemu-macos.conf";

    # QEMU utilities
    qemu-img-create = "qemu-img create -f qcow2";
    qemu-img-info = "qemu-img info";
    qemu-img-convert = "qemu-img convert";
  };

  # LaunchDaemon for VM networking helper (if needed)
  launchd.daemons.vm-networking = {
    serviceConfig = {
      Label = "dev.hrpr.vm-networking";
      ProgramArguments = [
        "/bin/sh"
        "-c"
        "echo 'VM networking helper loaded'"
      ];
      RunAtLoad = false; # Only load when needed
      KeepAlive = false;
    };
  };
}
