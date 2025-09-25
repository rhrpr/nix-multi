#!/usr/bin/env bash

# Debug Sleep/Wake Issues Script
# Run this after a failed wake attempt to gather diagnostic information

set -euo pipefail

echo "=== NVIDIA Sleep/Wake Debug Information ==="
echo "Generated at: $(date)"
echo ""

echo "=== System Information ==="
echo "Kernel: $(uname -r)"
echo "Uptime: $(uptime)"
echo ""

echo "=== NVIDIA Driver Info ==="
if command -v nvidia-smi &> /dev/null; then
    nvidia-smi --query-gpu=name,driver_version,power.state,persistence_mode --format=csv,noheader,nounits
else
    echo "nvidia-smi not available"
fi
echo ""

echo "=== Current Power State ==="
echo "Available sleep states: $(cat /sys/power/state)"
echo "Current mem_sleep: $(cat /sys/power/mem_sleep)"
echo ""

echo "=== ACPI Wakeup Sources ==="
echo "Enabled wakeup devices:"
awk '$3 == "*enabled" {print $1, $4}' /proc/acpi/wakeup
echo ""

echo "=== NVIDIA Power Management ==="
echo "NVIDIA suspend state:"
if [ -f /proc/driver/nvidia/suspend ]; then
    cat /proc/driver/nvidia/suspend
else
    echo "/proc/driver/nvidia/suspend not found"
fi
echo ""

echo "=== Display Information ==="
if command -v xrandr &> /dev/null && [ -n "${DISPLAY:-}" ]; then
    echo "Connected displays:"
    xrandr --listmonitors
elif command -v wlr-randr &> /dev/null && [ -n "${WAYLAND_DISPLAY:-}" ]; then
    echo "Wayland displays:"
    wlr-randr
else
    echo "No display server or randr available"
fi
echo ""

echo "=== Kernel Modules ==="
echo "NVIDIA modules loaded:"
lsmod | grep nvidia || echo "No NVIDIA modules found"
echo ""

echo "=== Recent Sleep/Wake Logs (last 20 entries) ==="
echo "Suspend service logs:"
journalctl -u systemd-suspend.service -n 10 --no-pager --since "1 hour ago" || echo "No suspend logs found"
echo ""

echo "NVIDIA service logs:"
journalctl -u nvidia-suspend.service -u nvidia-resume.service -n 10 --no-pager --since "1 hour ago" || echo "No NVIDIA service logs found"
echo ""

echo "=== Hardware Wake Sources ==="
echo "USB devices that can wake system:"
find /sys/bus/usb/devices/*/power/wakeup -exec sh -c 'echo -n "{}: "; cat "{}"' \; 2>/dev/null | grep enabled || echo "No USB wake devices enabled"
echo ""

echo "=== PCI Power Management ==="
echo "NVIDIA GPU power control:"
find /sys/devices -name "*01:00.0*" -path "*/power/control" -exec sh -c 'echo -n "{}: "; cat "{}"' \; 2>/dev/null || echo "GPU power control not found"
echo ""

echo "=== SystemD Sleep Configuration ==="
echo "Sleep configuration:"
systemctl show systemd-suspend.service | grep FragmentPath
echo ""
if [ -f /etc/systemd/sleep.conf ]; then
    echo "Sleep config contents:"
    grep -v '^#' /etc/systemd/sleep.conf | grep -v '^$' || echo "Default sleep config"
fi
echo ""

echo "=== Test Commands ==="
echo "To test manually:"
echo "1. sudo systemctl suspend  # Standard suspend"
echo "2. echo mem | sudo tee /sys/power/state  # Direct mem suspend"
echo "3. xset dpms force off  # Display off only"
echo ""
echo "To check NVIDIA state:"
echo "1. cat /proc/driver/nvidia/suspend"
echo "2. nvidia-smi"
echo ""
echo "To disable problematic wake sources:"
echo "1. echo PEGP | sudo tee /proc/acpi/wakeup  # Toggle GPU wake"
echo "2. echo PEG1 | sudo tee /proc/acpi/wakeup  # Toggle PCIe slot wake"
echo ""

echo "=== Recommendations ==="
echo "Based on your ACPI wakeup output:"
echo "- PEG1 (PCIe slot) is enabled but PEGP (GPU) is disabled"
echo "- This can cause wake conflicts with NVIDIA GPUs"
echo "- Try disabling PEG1 wake: echo PEG1 | sudo tee /proc/acpi/wakeup"
echo "- Or enabling PEGP wake: echo PEGP | sudo tee /proc/acpi/wakeup"
