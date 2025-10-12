#!/usr/bin/env bash

echo "=== Bluetooth Debug Information ==="

echo "1. USB Bluetooth devices:"
lsusb | grep -i bluetooth

echo -e "\n2. Bluetooth service status:"
systemctl is-active bluetooth

echo -e "\n3. Bluetooth modules loaded:"
lsmod | grep -E "(btusb|btintel|bluetooth)"

echo -e "\n4. Recent kernel messages for Bluetooth:"
sudo dmesg | grep -i bluetooth | tail -10

echo -e "\n5. Bluetooth controllers:"
bluetoothctl list

echo -e "\n6. Check for firmware files:"
if [ -d "/lib/firmware/intel" ]; then
    echo "Intel firmware directory exists:"
    ls -la /lib/firmware/intel/ | grep ibt
else
    echo "Intel firmware directory not found"
fi

echo -e "\n7. Hardware RF kill status:"
rfkill list bluetooth

echo -e "\n8. Alternative firmware check:"
find /nix/store -name "ibt-*" -type f 2>/dev/null | head -5

echo -e "\nTo fix Intel AX211 Bluetooth firmware issue:"
echo "1. The system needs linux-firmware package (already added)"
echo "2. May require reboot to load firmware properly"
echo "3. Check BIOS settings for Bluetooth/WiFi"
