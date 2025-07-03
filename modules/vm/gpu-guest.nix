# VM Guest GPU Configuration
# Optimizes GPU usage when running as a guest in a VM with GPU passthrough
{
  config,
  pkgs,
  lib,
  gpuConfig,
  ...
}:

let
  isNvidia = gpuConfig.vendor == "nvidia";
  enablePassthrough = gpuConfig.enablePartialPassthrough;
  isX86_64 = pkgs.system == "x86_64-linux";
in
{
  config = lib.mkIf (isNvidia && enablePassthrough && isX86_64) {
    # NVIDIA driver configuration for VM guest
    services.xserver.videoDrivers = [ "nvidia" ];
    hardware = {
      # Enable OpenGL for guest (updated options)
      graphics = {
        enable = true;
        enable32Bit = lib.mkIf isX86_64 true;
        extraPackages = with pkgs; [
          vaapiVdpau
          libvdpau-va-gl
        ];
      };

      # NVIDIA configuration for VM guest
      nvidia = {
        modesetting.enable = true;
        powerManagement.enable = false;
        powerManagement.finegrained = false;
        open = false; # Use proprietary driver for better compatibility
        nvidiaSettings = true;

        # Use stable driver for VMs
        package = config.boot.kernelPackages.nvidiaPackages.stable;
      };
    };

    # VM-specific GPU optimizations
    boot = {
      kernelParams = [
        # NVIDIA optimizations for VMs
        "nvidia-drm.modeset=1"
        "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
      ];

      # GPU-related kernel modules
      kernelModules = [
        "nvidia"
        "nvidia_drm"
        "nvidia_modeset"
        "nvidia_uvm"
      ];
    };

    # Environment variables for GPU in VM
    environment.variables = {
      NVIDIA_VISIBLE_DEVICES = "all";
      NVIDIA_DRIVER_CAPABILITIES = "all";
      # Force NVIDIA GPU usage
      __NV_PRIME_RENDER_OFFLOAD = "1";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    };

    # Install GPU monitoring tools
    environment.systemPackages = with pkgs; [
      nvidia-system-monitor-qt
      nvtopPackages.nvidia
      glxinfo
      vulkan-tools
    ];
  };
}
