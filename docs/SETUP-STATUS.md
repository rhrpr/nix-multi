# VM Setup Guide for Apple Silicon Macs

## TL;DR - Recommended Approach

For Apple Silicon Macs, **UTM is the best option** for running Linux VMs. Here's the quick setup:

```bash
# 1. Download and setup Ubuntu ARM64 VM
./scripts/utm-vm-setup.sh setup

# 2. Create VM in UTM GUI with provided ISO
# 3. Install Hyprland after Ubuntu installation:
sudo apt update && sudo apt install hyprland
```

## Why UTM over Cross-Compilation?

Cross-compiling complex NixOS configurations from aarch64-darwin to aarch64-linux requires:
- Extensive build infrastructure
- Long compilation times (hours)
- Many packages don't support cross-compilation
- Complex dependency resolution

UTM provides:
- ✅ Native ARM64 virtualization with Apple's Hypervisor Framework
- ✅ Better performance than emulation
- ✅ Easy setup through GUI
- ✅ Support for standard Linux distributions
- ✅ Shared clipboard and folders

## Current Status

### ✅ Working Configurations
- **macOS Host (Darwin)**: Full nix-darwin setup with VM management tools
- **Linux Host (NixOS)**: Complete configuration with GPU passthrough
- **QEMU Configuration**: Cross-platform QEMU helper scripts
- **UTM Integration**: Native Apple Silicon VM support

### ⚠️ Known Limitations
- **Cross-compilation**: Building complex NixOS VMs on Apple Silicon requires significant build time
- **Package Compatibility**: Some packages don't cross-compile well from darwin to linux

## Available Commands

### VM Management
```bash
# Build VMs (Intel/AMD systems)
./vm-build.sh x86_64

# UTM Setup (Apple Silicon - Recommended)
./scripts/utm-vm-setup.sh setup
./scripts/utm-vm-setup.sh list
./scripts/utm-vm-setup.sh start "VM-Name"

# QEMU Testing
./scripts/qemu-config.sh test
./scripts/qemu-config.sh config
```

### System Management
```bash
# Setup host system
./nix-multi.sh setup

# Darwin rebuild
./nix-multi.sh setup-macos

# Linux rebuild  
./nix-multi.sh setup-linux
```

## Next Steps

1. **For Apple Silicon Users**: Use UTM with Ubuntu/Fedora ARM64
2. **For Intel Macs**: Use QEMU with x86_64 NixOS VMs  
3. **For Linux Hosts**: Use full NixOS configuration with GPU passthrough

The configuration is now stable and cross-platform compatible! 🎉
