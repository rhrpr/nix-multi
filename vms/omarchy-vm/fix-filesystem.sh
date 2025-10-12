#!/usr/bin/env bash

# Fix Omarchy VM to use virtio-9p instead of virtiofs

set -euo pipefail

VM_NAME="omarchy"

echo "=== Fixing Omarchy VM Configuration ==="
echo "Replacing virtiofs with virtio-9p for better compatibility"
echo

# Export current configuration
virsh dumpxml "$VM_NAME" > /tmp/omarchy-current.xml

# Create fixed configuration with virtio-9p
sed -E '
/<filesystem type=.mount. accessmode=.passthrough.>/,/<\/filesystem>/{
  s/<driver type=.virtiofs. queue=.[0-9]+.\/>//
  s/<filesystem type=.mount. accessmode=.passthrough.>/<filesystem type="mount" accessmode="mapped">/
  s/<address type=.pci.[^>]*\/>//
  /<\/target>/a\
      <driver type="path" wrpolicy="immediate"/>
}
' /tmp/omarchy-current.xml > /tmp/omarchy-fixed.xml

# Also remove memoryBacking shared memory requirement (not needed for 9p)
sed -i '/<source type=.memfd.\/>/d' /tmp/omarchy-fixed.xml
sed -i '/<access mode=.shared.\/>/d' /tmp/omarchy-fixed.xml

echo "Generated new VM configuration:"
echo "- Replaced virtiofs with virtio-9p"
echo "- Removed shared memory requirements"
echo "- Using 'mapped' access mode for better security"
echo

# Show the filesystem section of the new config
echo "New filesystem configuration:"
grep -A6 -B1 '<filesystem type=' /tmp/omarchy-fixed.xml
echo

# Apply the new configuration
echo "Applying fixed configuration..."
virsh undefine "$VM_NAME"
virsh define /tmp/omarchy-fixed.xml

echo "✅ VM configuration updated successfully!"
echo
echo "The shared folder will be available in the VM as:"
echo "- Mount point: /projects (virtio-9p tag: 'projects')"
echo "- In VM: sudo mount -t 9p -o trans=virtio,version=9p2000.L projects /mnt/projects"
echo "- Or add to /etc/fstab: projects /mnt/projects 9p trans=virtio,version=9p2000.L,rw 0 0"

# Clean up
rm -f /tmp/omarchy-current.xml /tmp/omarchy-fixed.xml
