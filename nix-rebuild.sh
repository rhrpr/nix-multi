#!/bin/bash

read -p "Enter files to add (leave empty to skip): " files_to_add
if [ -n "$files_to_add" ]; then
  git add $files_to_add
else
  echo "No files added."
fi

read -p "Enter commit message (leave empty to skip): " commit_message
if [ -n "$commit_message" ]; then
  git commit -m "$commit_message"
else
  echo "No commit made."
fi

# Update flake at ~/.config/nix-multi
nix flake update --flake ~/.config/nix-multi/
git add flake.lock
git commit -m "Update flake.lock"
git push origin main

# Detect operating system
OS=$(uname -s)

if [ "$OS" = "Darwin" ]; then
  echo "Detected macOS"
  # macOS-specific rebuild
  darwin-rebuild switch --flake ~/.config/nix-multi#Ryans-MacBook-Pro --show-trace
elif [ "$OS" = "Linux" ]; then
  echo "Detected Linux"
  # NixOS-specific rebuild
  sudo nixos-rebuild switch --flake ~/.config/nix-multi#nixos-plasma --show-trace
else
  echo "Unsupported operating system: $OS"
  exit 1
fi