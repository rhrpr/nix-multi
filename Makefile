# Nix Multi-Platform Configuration Management
# Inspired by mitchellh/nixos-config

# Detect the operating system
UNAME := $(shell uname)
ARCH := $(shell uname -m)

# Configuration names
MACOS_CONFIG = Ryans-MacBook-Pro
LINUX_CONFIG = nixos-plasma
VM_CONFIG = nixos-vm-hyprland

# Default target
.PHONY: help
help:
	@echo "Nix Multi-Platform Configuration"
	@echo ""
	@echo "Setup Commands:"
	@echo "  setup          - Setup system (auto-detects platform)"
	@echo "  setup-macos    - Setup macOS with nix-darwin"
	@echo "  setup-linux    - Setup Linux with NixOS"
	@echo ""
	@echo "VM Commands:"
	@echo "  vm-build       - Build NixOS VM (auto-detects architecture)"
	@echo "  vm-run         - Build and run NixOS VM"
	@echo "  vm-build-x86   - Build x86_64 VM"
	@echo "  vm-build-arm   - Build ARM64 VM"
	@echo ""
	@echo "ISO Commands:"
	@echo "  iso-build      - Build NixOS ISO for current architecture"
	@echo "  iso-minimal    - Build minimal NixOS ISO"
	@echo ""
	@echo "Development:"
	@echo "  dev            - Enter default development shell"
	@echo "  dev-flutter    - Enter Flutter development shell"
	@echo "  dev-web        - Enter Web development shell"
	@echo "  dev-python     - Enter Python development shell"
	@echo ""
	@echo "Maintenance:"
	@echo "  check          - Check flake configuration"
	@echo "  update         - Update flake inputs"
	@echo "  clean          - Clean build artifacts"
	@echo "  fmt            - Format Nix files"

# Auto-detect setup
.PHONY: setup
setup:
ifeq ($(UNAME),Darwin)
	@$(MAKE) setup-macos
else
	@$(MAKE) setup-linux
endif

# macOS setup
.PHONY: setup-macos
setup-macos:
	@echo "Setting up macOS configuration..."
	nix run nix-darwin -- switch --flake .#$(MACOS_CONFIG)

# Linux setup  
.PHONY: setup-linux
setup-linux:
	@echo "Setting up Linux configuration..."
	sudo nixos-rebuild switch --flake .#$(LINUX_CONFIG)

# VM building
.PHONY: vm-build
vm-build:
ifeq ($(ARCH),arm64)
	@$(MAKE) vm-build-arm
else
	@$(MAKE) vm-build-x86
endif

.PHONY: vm-build-x86
vm-build-x86:
	@echo "Building x86_64 VM..."
	nix build .#vmImages.hyprland-vm-x86_64

.PHONY: vm-build-arm
vm-build-arm:
	@echo "Building ARM64 VM..."
	nix build .#vmImages.hyprland-vm-aarch64

.PHONY: vm-run
vm-run: vm-build
	@echo "Starting VM..."
	./result/bin/run-nixos-vm

# ISO building
.PHONY: iso-build
iso-build:
	@echo "Building NixOS ISO for ARM64..."
	nix build .#isoImages.nixos-hyprland-aarch64

.PHONY: iso-minimal
iso-minimal:
	@echo "Building minimal NixOS ISO..."
	nix build .#isoImages.nixos-minimal-aarch64

# Development shells
.PHONY: dev
dev:
	nix develop

.PHONY: dev-flutter
dev-flutter:
	nix develop .#flutter

.PHONY: dev-web
dev-web:
	nix develop .#web

.PHONY: dev-python
dev-python:
	nix develop .#python

# Maintenance
.PHONY: check
check:
	nix flake check

.PHONY: update
update:
	nix flake update

.PHONY: clean
clean:
	rm -rf result*
	nix-collect-garbage

.PHONY: fmt
fmt:
	nix fmt