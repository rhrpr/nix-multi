#!/usr/bin/env bash

# Test script for dynamic libvirt network detection

echo "=== Libvirt Dynamic Network Detection Test ==="
echo

echo "Current host network configuration:"
ip route show | grep -E "^default|^192\.168\.|^10\.|^172\."
echo

echo "Current IP addresses:"
ip addr show | grep -E "inet [0-9]" | grep -v 127.0.0.1
echo

echo "Simulating libvirt network detection..."

# Get current host network ranges to avoid conflicts
HOST_RANGES=$(ip route show | grep -oE '192\.168\.[0-9]+\.0/24' | sed 's/\.0\/24$//')

echo "Detected host network ranges:"
echo "$HOST_RANGES"
echo

# Default libvirt network options in order of preference
CANDIDATES=(
  "192.168.122"  # Standard libvirt default
  "192.168.100"  # Alternative 1
  "192.168.200"  # Alternative 2  
  "10.0.100"     # Private class A fallback
)

LIBVIRT_NET="192.168.122"  # Fallback default

# Find first non-conflicting network
for net in "${CANDIDATES[@]}"; do
  if ! echo "$HOST_RANGES" | grep -q "^$net$"; then
    LIBVIRT_NET="$net"
    break
  fi
done

echo "Selected libvirt network range: $LIBVIRT_NET.0/24"
echo "Libvirt gateway would be: $LIBVIRT_NET.1"
echo "DHCP range would be: $LIBVIRT_NET.2 - $LIBVIRT_NET.254"
echo

if echo "$HOST_RANGES" | grep -q "^$LIBVIRT_NET$"; then
  echo "⚠️  WARNING: Selected network conflicts with existing host network!"
else
  echo "✓ Selected network does not conflict with host networks"
fi
