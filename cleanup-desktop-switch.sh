#!/usr/bin/env bash

# Script to clean up desktop environment conflicts before switching
# This helps resolve the xdg-desktop-portal-hyprland.service conflict

echo "Cleaning up desktop environment conflicts..."

# Stop any running XDG portal services
systemctl --user stop xdg-desktop-portal-hyprland.service 2>/dev/null || true
systemctl --user stop xdg-desktop-portal-kde.service 2>/dev/null || true
systemctl --user stop xdg-desktop-portal-wlr.service 2>/dev/null || true
systemctl --user stop xdg-desktop-portal.service 2>/dev/null || true

# Disable the services to prevent auto-restart
systemctl --user disable xdg-desktop-portal-hyprland.service 2>/dev/null || true
systemctl --user disable xdg-desktop-portal-kde.service 2>/dev/null || true
systemctl --user disable xdg-desktop-portal-wlr.service 2>/dev/null || true

# Remove any problematic symlinks
sudo rm -f /nix/store/*/user-units/xdg-desktop-portal-hyprland.service 2>/dev/null || true
sudo rm -f /nix/store/*/user-units/xdg-desktop-portal-kde.service 2>/dev/null || true

# Clean up any temporary build files
sudo rm -rf /tmp/nix-build-* 2>/dev/null || true
sudo rm -rf /tmp/nix-shell-* 2>/dev/null || true

# Clear the nix store of any failed builds
sudo nix-store --gc 2>/dev/null || true

# Restart systemd user daemon to clear any cached service definitions
systemctl --user daemon-reload

echo "Cleanup complete. You can now run nixos-rebuild."
