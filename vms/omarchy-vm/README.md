# Omarchy VM with GPU Passthrough

This directory contains scripts and configuration for running [Omarchy Linux](https://omarchy.org/) - a gaming-focused Linux distribution - in a libvirt/KVM virtual machine with NVIDIA RTX 3080 passthrough.

## Overview

Omarchy is an Arch Linux-based gaming distribution optimized for performance with:
- Pre-configured gaming tools and drivers
- Steam, Lutris, and other gaming platforms
- Performance optimizations for gaming workloads
- Modern desktop environment tuned for gaming

**This VM setup includes:**
- **NVIDIA RTX 3080 GPU Passthrough**: Partial GPU passthrough (shared with host)
- **Host Folder Sharing**: `/home/hrpr/projects` shared via virtiofs
- **Ultrawide Display Support**: Optimized for 3440x1440 resolution
- **High Performance**: 16GB RAM, 8 CPU cores, hugepages enabled
- **Flexible Display**: Can use both host display and VM console

## Quick Start

### 1. Prerequisites

- IOMMU/VFIO enabled in kernel and BIOS
- Libvirt service running
- Omarchy ISO downloaded to `/home/hrpr/Downloads/omarchy-3.0.1.iso`
- RTX 3080 at PCI address `01:00.0` (check with `lspci | grep -i nvidia`)
- Ultrawide monitor connected to RTX 3080 (not motherboard)

### 2. Create the VM

```bash
# Using Makefile (recommended)
make omarchy-create

# Or directly
./vms/omarchy-vm/create-omarchy-vm.sh
```

### 3. Start the VM

```bash
make omarchy-start

# Or with GPU management
./vms/omarchy-vm/manage-omarchy.sh start
```

### 4. Open Console (Physical Monitor)

With GPU passthrough, you'll use the physical monitor connected to RTX 3080.
For emergency access, you can enable fallback graphics by editing the VM XML.

## VM Specifications

- **RAM**: 16GB (optimized for gaming)
- **CPU**: 8 cores (host-passthrough for native performance)
- **Disk**: 100GB qcow2 (suitable for games and applications)
- **Graphics**: NVIDIA RTX 3080 passthrough (native GPU performance)
- **Audio**: NVIDIA HD Audio + Intel HDA
- **Display**: Supports up to 3440x1440 ultrawide resolution
- **Shared Storage**: Host `/home/hrpr/projects` folder
- **Network**: NAT via default libvirt network

## GPU Passthrough Management (Partial Mode)

The VM uses partial GPU passthrough by default, allowing both host and VM to use the GPU:

```bash
# Check current GPU status
./vms/omarchy-vm/manage-omarchy.sh gpu-status

# Start VM with partial passthrough (default mode)
./vms/omarchy-vm/manage-omarchy.sh start

# For exclusive passthrough (optional):
./vms/omarchy-vm/manage-omarchy.sh gpu-bind    # Bind GPU to VFIO
./vms/omarchy-vm/manage-omarchy.sh gpu-unbind  # Return GPU to host
```

**Partial Passthrough (Recommended):**
- Both host and VM can use GPU simultaneously
- No need to bind/unbind GPU
- Host desktop remains functional
- VM gets GPU acceleration for games/compute

**Exclusive Passthrough (Advanced):**
- VM gets complete GPU control
- Host loses GPU access while VM is running
- Better performance for demanding applications
- Requires manual GPU management

## Display Setup (3440x1440 Ultrawide) - Partial Passthrough

**Physical Connection Options:**
1. **Host Primary**: Keep main monitor on motherboard (host desktop)
2. **VM Secondary**: Connect second monitor to RTX 3080 (VM display) - optional
3. **Shared Display**: Use console viewer (virt-viewer) for VM access

**In VM Setup:**
1. Boot VM and install Omarchy Linux
2. Install NVIDIA drivers in the VM:

   ```bash
   # Example for Arch-based Omarchy
   sudo pacman -S nvidia nvidia-utils
   sudo reboot
   ```

3. Configure display resolution:
   - Open display settings in Omarchy
   - Set resolution to 3440x1440 (if using RTX 3080 output)
   - Choose highest refresh rate supported (100Hz, 120Hz, etc.)
   - VM will have GPU acceleration while host retains access
4. Verify GPU is working in VM: `nvidia-smi`

**Partial Passthrough Benefits:**
- Host retains GPU access for desktop effects and applications
- VM gets GPU acceleration for games and compute workloads
- Both host and VM can run GPU applications simultaneously
- No need to bind/unbind GPU between sessions
- Easier setup than exclusive passthrough

## Shared Folder Setup

The VM shares `/home/hrpr/projects` from host to VM via virtiofs.

**In the VM (after installation):**
```bash
# Create mount point
sudo mkdir -p ~/projects

# Mount shared folder
sudo mount -t virtiofs projects ~/projects

# Verify it's working
ls ~/projects
```

**Make Permanent (add to /etc/fstab):**
```bash
echo "projects /home/$USER/projects virtiofs defaults,uid=$(id -u),gid=$(id -g) 0 0" | sudo tee -a /etc/fstab
```

## Management Commands

All commands can be run via Makefile or directly:

### Makefile Commands
```bash
make omarchy-create    # Create new VM
make omarchy-start     # Start VM
make omarchy-stop      # Stop VM
make omarchy-status    # Check status
make omarchy-console   # Open console viewer
make omarchy-gui       # Open virt-manager
```

### Direct Script Usage
```bash
./vms/omarchy-vm/manage-omarchy.sh <command>

Commands:
  create      - Create new Omarchy VM
  start       - Start the VM
  stop        - Shutdown gracefully
  force-stop  - Force stop
  restart     - Restart VM
  status      - Show VM status
  console     - Open console (virt-viewer)
  gui         - Open virt-manager
  info        - Detailed VM information
  eject-iso   - Remove installation ISO
  insert-iso  - Insert installation ISO
  destroy     - Delete VM permanently
```

## Installation Process

1. **Create and start VM**: `make omarchy-create && make omarchy-start`
2. **Open console**: `make omarchy-console`
3. **Install Omarchy**: Follow the graphical installer
4. **After installation**: Eject ISO with `./vms/omarchy-vm/manage-omarchy.sh eject-iso`
5. **Reboot**: The VM will boot from the installed system

## Gaming Performance Tips

### For Host System
- Ensure your host has good CPU and RAM
- Consider enabling CPU governor performance mode
- Ensure adequate cooling for sustained gaming loads

### In Omarchy VM
- Install guest additions if available
- Configure gaming-specific settings in Omarchy
- Use Steam's Proton compatibility layer for Windows games
- Consider gamemode and mangohud for performance monitoring

## Networking

The VM uses libvirt's default NAT network:
- VM gets automatic IP via DHCP
- Internet access through host
- SSH access possible (check VM IP with `make omarchy-status`)

## Storage

- **VM disk**: `/var/lib/libvirt/images/omarchy-gaming.qcow2`
- **Config**: Stored in libvirt's VM definition
- **Expansion**: Disk can be expanded with `qemu-img resize`

## Troubleshooting

### VM Won't Start
```bash
# Check libvirt service
sudo systemctl status libvirtd

# Check VM configuration
virsh dominfo omarchy-gaming
```

### Performance Issues
- Increase RAM allocation in create script
- Add more CPU cores
- Ensure host system has adequate resources
- Check host CPU governor: `cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor`

### Console Connection Issues
```bash
# Alternative console methods
virsh console omarchy-gaming  # Text console
virt-viewer omarchy-gaming    # GUI console
virt-manager                  # Full GUI management
```

### Networking Issues
```bash
# Check default network
sudo virsh net-list
sudo virsh net-start default  # Start if stopped
```

## Customization

### Modify VM Resources
Edit the variables in `create-omarchy-vm.sh`:
```bash
VM_RAM="16384"      # 16GB RAM
VM_VCPUS="8"        # 8 CPU cores
VM_DISK_SIZE="100G" # 100GB disk
```

### Enable GPU Passthrough (Advanced)
For better gaming performance, consider GPU passthrough:
1. Configure VFIO in your NixOS config
2. Modify the VM XML to include your GPU
3. Requires dedicated GPU for VM

## Files Structure

```
vms/omarchy-vm/
├── omarchy-vm.nix           # NixOS configuration for VM support
├── create-omarchy-vm.sh     # VM creation script
├── manage-omarchy.sh        # VM management script
└── README.md               # This file
```

## Related Documentation

- [Omarchy Linux Official Site](https://omarchy.org/)
- [Libvirt Documentation](https://libvirt.org/docs.html)
- [QEMU Documentation](https://qemu.readthedocs.io/)
- [Gaming on Linux Wiki](https://www.gamingonlinux.com/wiki/)
