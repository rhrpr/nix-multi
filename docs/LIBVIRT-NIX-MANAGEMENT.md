# LibVirt Host Configuration - Managed by Nix

This repository now includes comprehensive libvirt host configuration managed declaratively through Nix.

## What's Now Managed by Nix

### ✅ LibVirt Daemon Configuration
- **Service**: `libvirtd` enabled and configured
- **QEMU**: KVM package with GPU passthrough support
- **UEFI**: OVMF firmware for modern VMs
- **Security**: Unprivileged user access enabled
- **TPM**: Software TPM (swtpm) enabled

### ✅ VirtIO Filesystem Support
- **VirtioFS Daemon**: `virtiofsd` package installed
- **Shared Memory**: `/dev/shm` configured for virtiofs
- **Folder Sharing**: Ready for host ↔ VM folder sharing

### ✅ GPU Passthrough Configuration  
- **VFIO Modules**: Loaded at boot for GPU passthrough
- **NVIDIA Support**: Host + VM sharing configuration
- **Device Access**: CGroup ACL for NVIDIA devices
- **Persistence**: NVIDIA persistence daemon enabled

### ✅ Network Configuration
- **Default Network**: Automatically created and started
- **Bridge Interface**: `virbr0` trusted in firewall
- **NAT Support**: IP forwarding and NAT configured
- **DHCP/DNS**: Services enabled for VM networking

### ✅ User and Security Configuration
- **Groups**: User added to `libvirtd`, `kvm`, `qemu-libvirtd`
- **Polkit**: Password-less VM management for libvirtd group
- **Directories**: VM image directories created with correct permissions

### ✅ Comprehensive Package Installation
```nix
# Automatically installed:
- qemu_kvm, qemu_full          # Virtualization
- libvirt, virt-manager        # Management tools  
- virtiofsd                    # Folder sharing
- spice-gtk, spice-protocol    # Remote desktop
- looking-glass-client         # GPU sharing
- nvidia-docker                # Container GPU support
- bridge-utils, dnsmasq        # Networking
- And many more...
```

## Configuration Files

- **Main**: `modules/nixos/virtualization.nix` (imports libvirt-host.nix)
- **Comprehensive**: `modules/nixos/libvirt-host.nix` (all libvirt config)
- **Old Backup**: `modules/nixos/virtualization-old.nix` (backup of previous config)

## What This Enables

### 🚀 **Immediate Benefits**
1. **Declarative Configuration**: All VM host setup in Nix
2. **Reproducible**: Identical setup across deployments  
3. **Version Controlled**: All changes tracked in git
4. **Automated Services**: LibVirt network auto-created and started

### 🎯 **VM Features Ready**
- ✅ **VirtioFS**: Folder sharing between host and VMs
- ✅ **GPU Passthrough**: Partial sharing with host
- ✅ **UEFI Boot**: Modern VM firmware support
- ✅ **Spice Protocol**: High-performance remote desktop
- ✅ **Network Isolation**: Secure VM networking
- ✅ **Container Support**: NVIDIA Docker integration

## Next Steps

1. **Apply Configuration**: 
   ```bash
   sudo nixos-rebuild switch --flake .#nixos-desktop
   ```

2. **Test VM Creation**:
   ```bash
   make omarchy-create
   ```

3. **Verify Services**:
   ```bash
   systemctl status libvirtd
   virsh net-list --all
   which virtiofsd
   ```

## Advantages of Nix Management

- **No Manual Setup**: Everything configured automatically
- **Consistent State**: Always reproducible
- **Easy Rollback**: Nix generations for easy recovery  
- **Documentation**: Configuration is the documentation
- **Integration**: Works seamlessly with your existing NixOS config

The VM host is now fully managed by Nix and ready for production use!
