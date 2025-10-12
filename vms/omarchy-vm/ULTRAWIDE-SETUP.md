# Omarchy VM - 3440x1440 Ultrawide Setup Guide

This guide helps you configure the Omarchy VM for optimal 3440x1440 ultrawide resolution.

## Quick Setup

```bash
# Configure VM for ultrawide (will restart VM if needed)
make omarchy-ultrawide

# Or run directly
./vms/omarchy-vm/configure-ultrawide.sh
```

## Manual Configuration Steps

### 1. VM Configuration (Automated)
The script automatically configures:
- Video device with 3440x1440 resolution capability
- Increased VRAM (65536MB) for high resolution
- Proper virtio video driver settings

### 2. Guest OS Configuration (Manual Steps in VM)

#### Install Guest Additions
```bash
# For Arch-based Omarchy
sudo pacman -S spice-vdagent

# For Debian/Ubuntu-based
sudo apt install spice-vdagent

# Enable the service
sudo systemctl enable --now spice-vdagent
```

#### Configure Display Resolution
1. **Open Display Settings** in the VM
2. **Set Resolution** to 3440x1440
3. **Apply Changes** and confirm

### 3. Virt-Viewer Client Configuration

#### Resize Window to Match VM
1. In virt-viewer: **View → Resize to VM**
2. Or press **Ctrl+Alt+R**
3. Enable **View → Scale Display → Auto resize**

#### Full Screen Mode
- Press **F11** for full screen
- Press **Ctrl+Alt+F** to release cursor

## Troubleshooting

### Resolution Not Available
If 3440x1440 isn't available in display settings:

1. **Check spice-vdagent status:**
   ```bash
   sudo systemctl status spice-vdagent
   ```

2. **Restart the service:**
   ```bash
   sudo systemctl restart spice-vdagent
   ```

3. **Check if VM has correct video config:**
   ```bash
   # On host
   export LIBVIRT_DEFAULT_URI="qemu:///session"
   virsh dumpxml omarchy | grep -A5 video
   ```

### Display Issues
- **Choppy rendering**: Disable compression in virt-viewer (View → Preferences → Spice)
- **Wrong aspect ratio**: Ensure VM display settings match 21:9 ratio
- **Poor performance**: Consider enabling GPU passthrough for native performance

### Performance Optimization
1. **Increase VM RAM** if running graphics-intensive applications
2. **Enable GPU passthrough** for gaming (requires IOMMU setup)
3. **Use multiple monitors**: Configure spice to use multiple heads

## Gaming on Ultrawide

For the best gaming experience at 3440x1440:

### Option 1: Software Rendering (Current Setup)
- ✅ Works immediately
- ⚠️ Limited 3D performance
- Good for: 2D games, productivity, development

### Option 2: GPU Passthrough (Advanced)
- ⚠️ Requires IOMMU setup and system reboot
- ✅ Native GPU performance
- ✅ Full 3440x1440 gaming support
- Good for: AAA games, VR, GPU computing

```bash
# Check if GPU passthrough is possible
ls -la /sys/kernel/iommu_groups/

# If empty, reboot may be needed after Nix configuration
sudo nixos-rebuild switch --flake .#nixos-desktop
```

## Current VM Specifications

- **Resolution**: 3440x1440 (21:9 aspect ratio)
- **Video**: Virtio with 64MB VRAM
- **Display**: SPICE protocol
- **Guest Tools**: spice-vdagent for dynamic resolution
- **Performance**: Software rendering (good for desktop, limited for gaming)

## Commands Reference

```bash
# VM management
export LIBVIRT_DEFAULT_URI="qemu:///session"
virsh start omarchy                    # Start VM
virsh shutdown omarchy                 # Stop VM gracefully
virsh domstate omarchy                 # Check VM status

# Display
virt-viewer omarchy                    # Open VM console
make omarchy-ultrawide                 # Reconfigure for ultrawide

# Testing
make omarchy-test                      # Test VM functionality
```

## Next Steps

1. **Install Omarchy** from the ISO
2. **Install spice-vdagent** in the VM
3. **Configure display** to 3440x1440
4. **Test applications** at ultrawide resolution
5. **Consider GPU passthrough** for gaming workloads

The VM is now optimized for ultrawide productivity and development work!
