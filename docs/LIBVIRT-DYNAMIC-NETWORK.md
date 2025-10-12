# Dynamic LibVirt Network Configuration

This configuration automatically detects the host's network setup and configures LibVirt with non-conflicting IP ranges.

## How it Works

### Network Detection Logic

1. **Scans Host Networks**: Detects existing network ranges on the host
2. **Avoids Conflicts**: Chooses libvirt network that doesn't conflict with:
   - Host LAN network (e.g., 192.168.1.x)
   - Docker networks (e.g., 172.17.x.x)
   - Existing libvirt networks
3. **Fallback Options**: Multiple fallback ranges if preferred ones conflict

### Network Priority Order

The system tries these networks in order:

1. `192.168.122.0/24` (Standard libvirt default)
2. `192.168.100.0/24` (Alternative 1)
3. `192.168.200.0/24` (Alternative 2)
4. `10.0.100.0/24` (Private class A fallback)

### Current Configuration

Based on your host setup:

- **Host Network**: `192.168.1.0/24` (detected)
- **Docker Network**: `172.17.0.0/16` (detected)  
- **LibVirt Network**: `192.168.100.0/24` (automatically selected)

## Configuration Files

- **Main Config**: `/home/hrpr/.config/nix-multi/modules/nixos/libvirt-host.nix`
- **Test Script**: `/home/hrpr/.config/nix-multi/scripts/test-libvirt-network.sh`

## Management Commands

```bash
# Test network detection logic
make libvirt-test

# Apply configuration changes
make libvirt-apply

# Check current status  
make libvirt-check
```

## Benefits

1. **No Manual IP Configuration**: Automatically chooses appropriate ranges
2. **Conflict Avoidance**: Prevents network conflicts with host/docker
3. **Nix-Managed**: All configuration is declarative and version-controlled
4. **Dynamic Adaptation**: Adapts to different host network configurations
5. **Reproducible**: Same logic works across different environments

## Files Modified

- `modules/nixos/libvirt-host.nix`: Dynamic network configuration
- `modules/nixos/virtualization.nix`: Simplified to import libvirt-host
- `scripts/test-libvirt-network.sh`: Testing utility
- `Makefile`: Added libvirt management targets

## Implementation Details

The configuration uses Nix's `writeShellScript` to create runtime scripts that:

1. Detect existing network ranges using `ip route show`
2. Compare against candidate libvirt networks
3. Select first non-conflicting option
4. Generate appropriate XML configuration
5. Apply via `virsh net-define`

This approach ensures the libvirt network configuration is always compatible with your host network setup, regardless of how your networking changes over time.
