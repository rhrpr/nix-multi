# VM Management Guide

This guide covers the cross-platform VM management features in nix-multi, supporting both macOS and Linux hosts.

> **Profile first:** VM memory, CPU count, guest user, SSH endpoint, disk
> layout, GPU settings, and display resolution must come from your own profile.
> The values below that mention the maintainer's hardware are examples only.

## Quick Start

### Build and Run VM

```bash
# Interactive VM manager (recommended)
./vm-manager.sh

# Direct commands
./vm-build.sh build      # Build VM for current architecture
./vm-build.sh run        # Build and run VM
./vm-build.sh clean      # Clean build artifacts

# Architecture-specific
./vm-build.sh x86_64 build   # For Intel/AMD systems
./vm-build.sh aarch64 build  # For ARM64/Apple Silicon
```

### Test QEMU Configuration

```bash
# Test QEMU availability and configuration
./scripts/qemu-config.sh test x86_64

# Show platform-specific configuration
./scripts/qemu-config.sh config x86_64

# Generate QEMU options
./scripts/qemu-config.sh opts x86_64 8G 4 1920x1080
```

## Platform-Specific Features

### macOS Host

**Acceleration**: Uses Hypervisor Framework (HVF) for native virtualization
**Audio**: CoreAudio integration for better sound quality
**Display**: Cocoa-based display with OpenGL acceleration
**Networking**: User-mode networking (no root required)

**Supported VMs**:
- x86_64 VMs with full acceleration
- aarch64 VMs (build only, recommend UTM for running)

**Example Configuration**:
```bash
# x86_64 VM on macOS
QEMU_OPTS="-m 6G -smp 4 -accel hvf -device virtio-gpu-pci,xres=1920,yres=1080 -audiodev coreaudio,id=audio0 -device intel-hda -device hda-duplex,audiodev=audio0"
```

### Linux Host

**Acceleration**: KVM for near-native performance
**Audio**: PipeWire/PulseAudio integration
**Display**: GTK with OpenGL acceleration
**GPU Passthrough**: Optional; configure it for your GPU and IOMMU groups

**Supported VMs**:
- x86_64 VMs with KVM acceleration
- aarch64 VMs with full support

**Example Configuration**:
```bash
# x86_64 VM on Linux with KVM
QEMU_OPTS="-m 8G -smp 4 -enable-kvm -device virtio-gpu-pci,xres=1920,yres=1080 -display gtk,gl=on -audiodev pipewire,id=audio0"
```

## VM Configuration

### Default VM Settings

- **Memory / CPU / resolution**: Set these through your VM profile or
  environment; do not rely on repository defaults.
- **SSH endpoint**: Configure `VM_SSH_USER`, `VM_SSH_HOST`, and
  `VM_SSH_PORT` when invoking `scripts/vm-setup.sh`.
- **Graphics**: VirtIO GPU with hardware acceleration

### VM Guest Features

- **SSH Access**: Use a guest account and key that you create during install.
- **Desktop**: Hyprland (Wayland tiling compositor)
- **Audio**: Full audio support with guest agent
- **Clipboard**: Shared clipboard between host and guest
- **Guest Tools**: SPICE agent and QEMU guest agent

### Customizing VM Settings

Use the QEMU configuration helper to generate custom options:

```bash
# Custom memory, CPU, and resolution
./scripts/qemu-config.sh opts x86_64 16G 8 1920x1080

# Show current platform configuration
./scripts/qemu-config.sh config
```

## Troubleshooting

### Common Issues

**VM doesn't start**:
1. Check QEMU installation: `./scripts/qemu-config.sh test`
2. Verify acceleration support (HVF on macOS, KVM on Linux)
3. Ensure sufficient disk space for VM images

**Poor performance**:
1. Verify hardware acceleration is enabled
2. Increase memory allocation if available
3. Check if other VMs are running

**Audio issues**:
1. Verify audio driver detection
2. Check host audio system (CoreAudio/PipeWire)
3. Restart VM with audio debugging

**Network connectivity**:
1. SSH: `ssh -p "$VM_SSH_PORT" "$VM_SSH_USER@$VM_SSH_HOST"`
2. Check firewall settings on host
3. Verify QEMU user networking is working

### Platform-Specific Troubleshooting

#### macOS

**HVF not available**:
```bash
# Check HVF support
sysctl kern.hv_support
```

**Permission issues**:
- Ensure QEMU has required permissions in Security & Privacy
- Grant Full Disk Access if needed for VM images

#### Linux

**KVM not available**:
```bash
# Check KVM availability
ls /dev/kvm
lsmod | grep kvm
```

**GPU passthrough issues**:
```bash
# Test GPU passthrough configuration
./scripts/rtx3080-setup.sh
```

## Advanced Usage

### Custom QEMU Options

Override default options by setting `QEMU_OPTS`:

```bash
# Custom QEMU configuration
export QEMU_OPTS="-m 16G -smp 8 -device virtio-gpu-pci,xres=1920,yres=1080"
./result/bin/run-nixos-vm
```

### Multiple VMs

Build different architectures:

```bash
# Build both architectures
./vm-build.sh x86_64 build
./vm-build.sh aarch64 build

# Run specific architecture
./vm-build.sh x86_64 run
./vm-build.sh aarch64 run
```

### VM Image Management

```bash
# List VM images
ls -la ~/VMs/

# Convert VM formats
qemu-img convert input.qcow2 output.vmdk

# Compress VM images
qemu-img convert -c -O qcow2 input.qcow2 compressed.qcow2
```

## Integration with Host Systems

### macOS Integration

- Use shared folders via QEMU 9p filesystem
- Clipboard sharing via SPICE guest tools
- USB device passthrough for peripherals

### Linux Integration

- GPU sharing for gaming and GPU compute
- Looking Glass for seamless display sharing
- USB passthrough for gaming controllers

## Performance Optimization

### Host System

- Allocate appropriate CPU cores to VM
- Use SSD storage for VM images
- Ensure sufficient RAM for both host and guest

### Guest System

- Install guest additions (included in NixOS VM)
- Use VirtIO drivers for better I/O performance
- Enable hardware acceleration in guest

### Network Performance

- Use VirtIO network drivers
- Enable multi-queue for network interfaces
- Consider SR-IOV for advanced setups

## Security Considerations

- VMs run in user-mode networking by default
- SSH access is limited to localhost
- Guest systems are isolated from host filesystem
- Consider firewall rules for production use
