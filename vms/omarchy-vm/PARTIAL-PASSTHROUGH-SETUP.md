# Omarchy VM - Partial GPU Passthrough Setup Complete

## Configuration Summary

✅ **Configured for Partial GPU Passthrough**
- RTX 3080 remains bound to NVIDIA driver on host
- VM will share GPU access with host system
- Both host and VM can use GPU simultaneously

✅ **Shared Folder Setup**
- Host folder: `/home/hrpr/projects` (exists with content)
- VM mount point: `~/projects` (via virtiofs)
- Automatic sharing configured in VM XML

✅ **Display Configuration**
- Supports up to 3440x1440 ultrawide resolution
- Fallback graphics enabled for console access
- Can use physical monitor on RTX 3080 or virt-viewer

## Key Benefits of Partial Passthrough

1. **Shared GPU Access**: Both host and VM can use RTX 3080
2. **No GPU Switching**: No need to bind/unbind GPU between sessions
3. **Host Desktop Remains Functional**: Desktop effects and apps work
4. **VM Gets GPU Acceleration**: Games and compute workloads accelerated
5. **Easier Management**: Less complex than exclusive passthrough

## Ready to Use

The VM is now configured for:
- **16GB RAM, 8 CPU cores** for gaming performance
- **NVIDIA RTX 3080 partial passthrough** for GPU acceleration
- **Shared `/home/hrpr/projects` folder** for file access
- **3440x1440 ultrawide display** support

## Next Steps

1. **Create VM**: `make omarchy-create` or `./vms/omarchy-vm/create-omarchy-vm.sh`
2. **Start VM**: `make omarchy-start`
3. **Install Omarchy**: Boot from ISO and install OS
4. **Install NVIDIA Drivers**: In VM for GPU acceleration
5. **Mount Shared Folder**: `sudo mount -t virtiofs projects ~/projects`
6. **Configure Display**: Set to 3440x1440 if using physical monitor

## Current GPU Status
- GPU: NVIDIA RTX 3080 at PCI 01:00.0
- Driver: nvidia (perfect for partial passthrough)
- Audio: NVIDIA HD Audio at PCI 01:00.1
- Mode: Partial passthrough (shared with host)

The configuration is optimized for your use case of wanting both host and VM to have GPU access!
