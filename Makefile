# Nix Multi-Platform Configuration Management
# Inspired by mitchellh/nixos-config

# Detect the operating system and environment
UNAME := $(shell uname)
ARCH := $(shell uname -m)

# Detect if running in a VM
IS_VM := $(shell if [ -f /sys/class/dmi/id/product_name ] && grep -qi "qemu\|kvm\|virtual\|vmware" /sys/class/dmi/id/product_name 2>/dev/null; then echo "true"; else echo "false"; fi)

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
	@echo "  setup-vm       - Setup VM configuration"
	@echo "  apply-libvirt  - Apply libvirt host configuration (requires rebuild)"
	@echo ""
	@echo "VM Commands:"
	@echo "  vm-setup       - Download NixOS ISO and setup UTM VM"
	@echo "  vm-deploy      - Deploy configuration to running VM via SSH"
	@echo "  vm-create      - Create UTM VM from downloaded ISO"
	@echo "  vm-ssh         - SSH into running VM"
	@echo "  vm-build       - Build NixOS VM (legacy - has cross-compilation issues)"
	@echo "  vm-run         - Build and run NixOS VM (legacy)"
	@echo "  omarchy-create - Create Omarchy gaming VM with RTX 3080 passthrough"
	@echo "  omarchy-start  - Start Omarchy VM (GPU passthrough enabled)"
	@echo "  omarchy-stop   - Stop Omarchy VM"
	@echo "  omarchy-status - Check Omarchy VM and GPU status"
	@echo "  omarchy-test   - Test Omarchy VM functionality"
	@echo "  omarchy-ultrawide - Configure VM for 3440x1440 resolution"
	@echo "  omarchy-gpu    - Manage GPU passthrough for Omarchy VM"
	@echo ""
	@echo "LibVirt Host Management:"
	@echo "  libvirt-test   - Test dynamic network detection"
	@echo "  libvirt-apply  - Apply libvirt host configuration via NixOS"
	@echo "  libvirt-check  - Check current libvirt network status"
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
	@echo "  dev-rust       - Enter Rust development shell"
	@echo ""
	@echo "AI Agent Operations:"
	@echo "  ai             - Start or reattach to Herdr"
	@echo "  ai-status      - List persistent Herdr sessions"
	@echo "  ai-integrations - Show native restore integrations"
	@echo "  ai-setup       - Install Herdr agent integrations"
	@echo "  ai-doctor      - Validate the native CLI stack"
	@echo ""
	@echo "Maintenance:"
	@echo "  check          - Check flake configuration"
	@echo "  update         - Update flake inputs"
	@echo "  clean          - Clean build artifacts"
	@echo "  fmt            - Format Nix files"
	@echo ""
	@echo "Debugging & Maintenance:"
	@echo "  debug-sleep    - Debug sleep/wake issues (run after failed wake)"
	@echo "  wake-sources   - Manage ACPI wake sources for better sleep/wake"
	@echo "  gpu-check      - Check RTX 3080 passthrough status"

# Auto-detect setup
.PHONY: setup
setup:
ifeq ($(UNAME),Darwin)
	@$(MAKE) setup-macos
else ifeq ($(IS_VM),true)
	@echo "Detected VM environment, using VM configuration..."
	@$(MAKE) setup-vm
else
	@echo "Detected hardware environment, using desktop configuration..."
	@$(MAKE) setup-linux
endif

# Linux setup  
.PHONY: setup-linux
setup-linux: enable-flakes  
	@echo "Setting up NixOS configuration..."
	@# Fix Git ownership issue when running with sudo
	@if [ "$$EUID" -eq 0 ]; then \
		git config --global --add safe.directory /home/hrpr/.config/nix-multi; \
	fi
	nix build .#nixosConfigurations.$(LINUX_CONFIG).config.system.build.toplevel --no-link
	sudo nixos-rebuild switch --flake .#$(LINUX_CONFIG)

.PHONY: enable-flakes
enable-flakes:
	@echo "Enabling Nix experimental features..."
	@mkdir -p ~/.config/nix
	@if ! grep -q "experimental-features.*nix-command.*flakes" ~/.config/nix/nix.conf 2>/dev/null; then \
		echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf; \
		echo "✓ Experimental features enabled for user"; \
	else \
		echo "✓ Experimental features already enabled for user"; \
	fi
	@if command -v sudo >/dev/null 2>&1; then \
		if sudo mkdir -p /etc/nix 2>/dev/null; then \
			if ! sudo grep -q "experimental-features.*nix-command.*flakes" /etc/nix/nix.conf 2>/dev/null; then \
				if echo "experimental-features = nix-command flakes" | sudo tee -a /etc/nix/nix.conf >/dev/null 2>&1; then \
					echo "✓ Experimental features enabled system-wide"; \
				else \
					echo "! Could not write to /etc/nix/nix.conf (read-only filesystem?)"; \
				fi; \
			else \
				echo "✓ Experimental features already enabled system-wide"; \
			fi; \
		else \
			echo "! Could not create /etc/nix directory (read-only filesystem?)"; \
		fi; \
	else \
		echo "! sudo not available, skipping system-wide configuration"; \
	fi

.PHONY: setup-macos
setup-macos: enable-flakes
	@echo "Setting up macOS configuration..."
	nix build .#darwinConfigurations.$(MACOS_CONFIG).system
	sudo ./result/sw/bin/darwin-rebuild switch --flake .#$(MACOS_CONFIG)

.PHONY: setup-vm
setup-vm: enable-flakes
	@echo "Setting up NixOS VM configuration..."
	@# Fix Git ownership issue when running with sudo
	@if [ "$$EUID" -eq 0 ]; then \
		git config --global --add safe.directory /home/hrpr/.config/nix-multi; \
	fi
	nix build .#nixosConfigurations.$(VM_CONFIG).config.system.build.toplevel --no-link
	sudo nixos-rebuild switch --flake .#$(VM_CONFIG)

# Apply libvirt host configuration
.PHONY: apply-libvirt
apply-libvirt:
	@echo "Applying LibVirt host configuration..."
	@echo "This will rebuild the NixOS system with comprehensive libvirt support"
	@sudo nixos-rebuild switch --flake .#nixos-desktop
	@echo "LibVirt host configuration applied successfully!"
	@echo ""
	@echo "Verifying services..."
	@systemctl status libvirtd --no-pager || true
	@virsh net-list --all || true
	@echo ""
	@echo "LibVirt is now fully managed by Nix!"

# Test NixOS configuration
.PHONY: test-config
test-config:
	@echo "Testing NixOS configuration..."
	@sudo nixos-rebuild dry-build --flake .#nixos-desktop

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

.PHONY: dev-rust
dev-rust:
	nix develop .#rust

# AI agent terminal runtime
.PHONY: ai ai-status ai-integrations ai-setup ai-doctor
ai:
	herdr

ai-status:
	herdr session list

ai-integrations:
	herdr integration status

ai-setup:
	herdr-agent-setup

ai-doctor:
	ai-agent-doctor

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

# Debugging and maintenance targets
.PHONY: debug-sleep
debug-sleep:
	@echo "Running sleep/wake diagnostic script..."
	@./scripts/debug-sleep.sh

.PHONY: wake-sources
wake-sources:
	@echo "Managing ACPI wake sources..."
	@./scripts/manage-wake-sources.sh show

.PHONY: wake-fix
wake-fix:
	@echo "Applying recommended wake source settings..."
	@sudo ./scripts/manage-wake-sources.sh recommend

.PHONY: gpu-check
gpu-check:
	@echo "Checking RTX 3080 GPU status..."
	@lspci | grep -i nvidia || echo "No NVIDIA GPU found"
	@nvidia-smi 2>/dev/null || echo "nvidia-smi not available or GPU not accessible"
	@cat /proc/driver/nvidia/version 2>/dev/null || echo "NVIDIA driver not loaded"

# VM Management (UTM-based)
VM_SSH_PORT = 22000
VM_SSH_USER = hrpr
VM_SSH_HOST = localhost
VM_NAME = nixos-hyprland
ISO_DIR = ./vm-iso
NIXOS_ISO_URL = https://channels.nixos.org/nixos-unstable/latest-nixos-minimal-aarch64-linux.iso

.PHONY: vm-setup
vm-setup:
	@./scripts/vm-setup.sh setup

.PHONY: vm-download
vm-download:
	@./scripts/vm-setup.sh download

.PHONY: vm-ssh
vm-ssh:
	@./scripts/vm-setup.sh ssh

.PHONY: vm-deploy
vm-deploy:
	@./scripts/vm-setup.sh deploy

.PHONY: vm-update
vm-update:
	@./scripts/vm-setup.sh deploy

.PHONY: vm-status
vm-status:
	@./scripts/vm-setup.sh status

.PHONY: vm-clean
vm-clean:
	@echo "Cleaning VM ISO downloads..."
	@rm -rf $(ISO_DIR)

# Omarchy VM Management
.PHONY: omarchy-create
omarchy-create:
	@echo "Creating Omarchy gaming VM..."
	@./vms/omarchy-vm/manage-omarchy.sh create

.PHONY: omarchy-start
omarchy-start:
	@echo "Starting Omarchy VM (user session)..."
	@export LIBVIRT_DEFAULT_URI="qemu:///session" && ./vms/omarchy-vm/manage-omarchy.sh start

.PHONY: omarchy-stop
omarchy-stop:
	@echo "Stopping Omarchy VM (user session)..."
	@export LIBVIRT_DEFAULT_URI="qemu:///session" && ./vms/omarchy-vm/manage-omarchy.sh stop

.PHONY: omarchy-status
omarchy-status:
	@echo "Checking Omarchy VM status (user session)..."
	@export LIBVIRT_DEFAULT_URI="qemu:///session" && ./vms/omarchy-vm/manage-omarchy.sh status

.PHONY: omarchy-console
omarchy-console:
	@echo "Opening Omarchy VM console (user session)..."
	@export LIBVIRT_DEFAULT_URI="qemu:///session" && ./vms/omarchy-vm/manage-omarchy.sh console

.PHONY: omarchy-gui
omarchy-gui:
	@echo "Opening virt-manager for VM management..."
	@./vms/omarchy-vm/manage-omarchy.sh gui

.PHONY: omarchy-gpu
omarchy-gpu:
	@echo "Managing GPU passthrough for Omarchy VM..."
	@./vms/omarchy-vm/gpu-passthrough.sh status
	@echo ""
	@echo "GPU Management Commands:"
	@echo "  ./vms/omarchy-vm/gpu-passthrough.sh bind   - Bind RTX 3080 to VM"
	@echo "  ./vms/omarchy-vm/gpu-passthrough.sh unbind - Return RTX 3080 to host"
	@echo "  make omarchy-start                         - Start VM with GPU"

.PHONY: omarchy-test
omarchy-test:
	@echo "Testing Omarchy VM functionality..."
	@export LIBVIRT_DEFAULT_URI="qemu:///session" && echo "VM Status: $$(virsh domstate omarchy 2>/dev/null || echo 'not running')"
	@echo "Shared folder test:"
	@ls -la /home/hrpr/projects | head -3
	@echo ""
	@echo "VM Console: virt-viewer omarchy (user session)"
	@echo "Shared folder mount (in VM): sudo mount -t 9p -o trans=virtio,version=9p2000.L projects ~/projects"

.PHONY: omarchy-ultrawide
omarchy-ultrawide:
	@echo "Configuring Omarchy VM for 3440x1440 ultrawide resolution..."
	@./vms/omarchy-vm/configure-ultrawide.sh

# LibVirt Host Management
.PHONY: libvirt-test
libvirt-test:
	@echo "Testing dynamic libvirt network detection..."
	@./scripts/test-libvirt-network.sh

.PHONY: libvirt-apply
libvirt-apply:
	@echo "Applying libvirt host configuration via NixOS rebuild..."
	@sudo nixos-rebuild switch --flake .#nixos-desktop

.PHONY: libvirt-check
libvirt-check:
	@echo "Current libvirt network status:"
	@virsh net-list --all 2>/dev/null || echo "LibVirt not running or not accessible"
	@echo ""
	@echo "Current network bridges:"
	@ip addr show | grep -E "(virbr|docker)" || echo "No virtual bridges found"
	@echo ""
	@echo "LibVirt daemon status:"
	@systemctl is-active libvirtd 2>/dev/null || echo "LibVirt daemon not running"
# Bluetooth debugging
bluetooth-debug:
	@./scripts/bluetooth-debug.sh

