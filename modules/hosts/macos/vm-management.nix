# macOS VM Management Module
# Provides VM creation tools for macOS hosts using QEMU/UTM
{ pkgs, lib, config, username, ... }:

{
  # VM creation and management tools for macOS
  environment.systemPackages = with pkgs; [
    # Core virtualization for macOS
    qemu              # QEMU for VM creation and management
    
    # VM image manipulation
    qemu-utils        # QEMU disk utilities (qemu-img, etc.)
    
    # Utilities for VM management
    coreutils         # Basic utilities
    findutils         # File finding utilities
    gnused            # GNU sed for text processing
    gawk              # GNU awk for text processing
  ];

  # macOS-specific VM environment variables
  environment.variables = {
    # QEMU system binary location for scripts
    QEMU_SYSTEM_X86_64 = "${pkgs.qemu}/bin/qemu-system-x86_64";
    QEMU_SYSTEM_AARCH64 = "${pkgs.qemu}/bin/qemu-system-aarch64";
    
    # VM image directory
    VM_IMAGES_DIR = "/Users/${username}/VMs";
  };

  # Create VM directories on activation
  system.activationScripts.createVMDirs = {
    text = ''
      mkdir -p /Users/${username}/VMs
      chown ${username}:staff /Users/${username}/VMs
    '';
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
      RunAtLoad = false;  # Only load when needed
      KeepAlive = false;
    };
  };
}
