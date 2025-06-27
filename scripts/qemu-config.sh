#!/usr/bin/env bash

# QEMU Configuration Helper Script
# Provides platform-specific QEMU configuration for both macOS and Linux

set -euo pipefail

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[QEMU]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[QEMU]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[QEMU]${NC} $1"
}

log_error() {
    echo -e "${RED}[QEMU]${NC} $1"
}

# Detect host OS
detect_host_os() {
    case "$(uname -s)" in
        Darwin)
            echo "macos"
            ;;
        Linux)
            echo "linux"
            ;;
        *)
            log_error "Unsupported operating system: $(uname -s)"
            exit 1
            ;;
    esac
}

# Get platform-specific QEMU binary
get_qemu_binary() {
    local arch="$1"
    local host_os="$2"
    
    case "$arch" in
        x86_64)
            if [[ "$host_os" == "macos" ]]; then
                echo "qemu-system-x86_64"
            else
                echo "qemu-system-x86_64"
            fi
            ;;
        aarch64)
            if [[ "$host_os" == "macos" ]]; then
                echo "qemu-system-aarch64"
            else
                echo "qemu-system-aarch64"
            fi
            ;;
        *)
            log_error "Unsupported architecture: $arch"
            exit 1
            ;;
    esac
}

# Get platform-specific acceleration
get_acceleration() {
    local arch="$1"
    local host_os="$2"
    
    case "$host_os" in
        macos)
            echo "hvf"  # Hypervisor Framework
            ;;
        linux)
            if [[ "$arch" == "x86_64" ]]; then
                echo "kvm"  # KVM for x86_64
            else
                echo "tcg"  # TCG for ARM64 on Linux (unless native ARM64 host)
            fi
            ;;
        *)
            echo "tcg"  # Fallback to software emulation
            ;;
    esac
}

# Get platform-specific audio driver
get_audio_driver() {
    local host_os="$1"
    
    case "$host_os" in
        macos)
            echo "coreaudio"
            ;;
        linux)
            # Check for available audio systems
            if command -v pipewire &> /dev/null; then
                echo "pipewire"
            elif command -v pulseaudio &> /dev/null; then
                echo "pa"
            else
                echo "alsa"
            fi
            ;;
        *)
            echo "none"
            ;;
    esac
}

# Detect host display resolution
detect_host_resolution() {
    local host_os="$1"
    
    case "$host_os" in
        macos)
            # Get primary display resolution on macOS
            if command -v system_profiler &> /dev/null; then
                local resolution
                resolution=$(system_profiler SPDisplaysDataType | grep -E "Resolution:" | head -1 | sed 's/.*Resolution: //' | sed 's/ x /x/' | sed 's/ Retina//' | sed 's/ [A-Za-z].*//')
                if [[ -n "$resolution" && "$resolution" =~ ^[0-9]+x[0-9]+$ ]]; then
                    echo "$resolution"
                    return
                fi
            fi
            
            # Fallback: try osascript
            if command -v osascript &> /dev/null; then
                local width height
                width=$(osascript -e 'tell application "Finder" to get bounds of window of desktop' | cut -d',' -f3 | tr -d ' ')
                height=$(osascript -e 'tell application "Finder" to get bounds of window of desktop' | cut -d',' -f4 | tr -d ' ')
                if [[ -n "$width" && -n "$height" ]]; then
                    echo "${width}x${height}"
                    return
                fi
            fi
            ;;
        linux)
            # Try various methods to get display resolution on Linux
            
            # Method 1: xrandr (X11)
            if command -v xrandr &> /dev/null && [[ -n "${DISPLAY:-}" ]]; then
                local resolution
                resolution=$(xrandr --current | grep -E "^\s+[0-9]+x[0-9]+" | head -1 | awk '{print $1}')
                if [[ -n "$resolution" ]]; then
                    echo "$resolution"
                    return
                fi
            fi
            
            # Method 2: wlr-randr (Wayland)
            if command -v wlr-randr &> /dev/null && [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
                local resolution
                resolution=$(wlr-randr | grep -E "^\s+[0-9]+x[0-9]+" | head -1 | awk '{print $1}')
                if [[ -n "$resolution" ]]; then
                    echo "$resolution"
                    return
                fi
            fi
            
            # Method 3: swaymsg (Sway/Wayland)
            if command -v swaymsg &> /dev/null; then
                local resolution
                resolution=$(swaymsg -t get_outputs | grep -oE '"current_mode":\{"width":[0-9]+,"height":[0-9]+' | head -1 | sed 's/"current_mode":{"width"://; s/,"height":/x/')
                if [[ -n "$resolution" ]]; then
                    echo "$resolution"
                    return
                fi
            fi
            
            # Method 4: hyprctl (Hyprland)
            if command -v hyprctl &> /dev/null; then
                local resolution
                resolution=$(hyprctl monitors | grep -E "^\s+[0-9]+x[0-9]+" | head -1 | awk '{print $1}')
                if [[ -n "$resolution" ]]; then
                    echo "$resolution"
                    return
                fi
            fi
            
            # Method 5: parse /sys/class/drm (fallback)
            if [[ -d "/sys/class/drm" ]]; then
                for mode_file in /sys/class/drm/*/modes; do
                    if [[ -r "$mode_file" ]]; then
                        local resolution
                        resolution=$(head -1 "$mode_file" 2>/dev/null)
                        if [[ -n "$resolution" && "$resolution" =~ ^[0-9]+x[0-9]+$ ]]; then
                            echo "$resolution"
                            return
                        fi
                    fi
                done
            fi
            ;;
    esac
    
    # Fallback to common ultrawide resolution
    echo "3440x1440"
}

# Get platform-specific display options
get_display_options() {
    local host_os="$1"
    
    case "$host_os" in
        macos)
            echo "cocoa,gl=on"
            ;;
        linux)
            # Check if we have X11 or Wayland
            if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
                echo "gtk,gl=on"
            elif [[ -n "${DISPLAY:-}" ]]; then
                echo "gtk,gl=on"
            else
                echo "vnc=:1"  # Fallback to VNC
            fi
            ;;
        *)
            echo "vnc=:1"
            ;;
    esac
}

# Generate complete QEMU options
generate_qemu_opts() {
    local arch="$1"
    local host_os="$2"
    local memory="${3:-6G}"
    local cpus="${4:-4}"
    local resolution="${5:-$(detect_host_resolution "$host_os")}"
    
    local accel
    local audio_driver
    local display_opts
    
    accel=$(get_acceleration "$arch" "$host_os")
    audio_driver=$(get_audio_driver "$host_os")
    display_opts=$(get_display_options "$host_os")
    
    # Split resolution
    local width height
    width=$(echo "$resolution" | cut -d'x' -f1)
    height=$(echo "$resolution" | cut -d'x' -f2)
    
    # Base options
    local opts="-m $memory -smp $cpus"
    
    # Add acceleration
    if [[ "$host_os" == "macos" ]]; then
        opts="$opts -accel $accel"
    else
        opts="$opts -enable-$accel"
    fi
    
    # Add graphics
    opts="$opts -device virtio-gpu-pci,xres=$width,yres=$height"
    opts="$opts -display $display_opts"
    
    # Add audio
    if [[ "$audio_driver" != "none" ]]; then
        opts="$opts -audiodev $audio_driver,id=audio0"
        opts="$opts -device intel-hda -device hda-duplex,audiodev=audio0"
    fi
    
    # Add networking with SSH port forwarding
    opts="$opts -netdev user,id=net0,hostfwd=tcp::22000-:22"
    opts="$opts -device virtio-net-pci,netdev=net0"
    
    # Add USB support
    opts="$opts -device qemu-xhci -device usb-tablet"
    
    # Platform-specific optimizations
    if [[ "$host_os" == "macos" ]]; then
        # macOS-specific options
        opts="$opts -machine q35"
        opts="$opts -device ich9-intel-hda -device hda-duplex"
    else
        # Linux-specific options
        opts="$opts -machine q35,accel=$accel"
        opts="$opts -cpu host"
    fi
    
    echo "$opts"
}

# Show QEMU configuration
show_config() {
    local arch="${1:-x86_64}"
    local host_os
    host_os=$(detect_host_os)
    
    log_info "QEMU Configuration for $arch on $host_os"
    echo
    
    echo "Architecture: $arch"
    echo "Host OS: $host_os"
    echo "QEMU Binary: $(get_qemu_binary "$arch" "$host_os")"
    echo "Acceleration: $(get_acceleration "$arch" "$host_os")"
    echo "Audio Driver: $(get_audio_driver "$host_os")"
    echo "Display: $(get_display_options "$host_os")"
    echo
    
    echo "Generated QEMU Options:"
    generate_qemu_opts "$arch" "$host_os"
    echo
}

# Test QEMU availability
test_qemu() {
    local arch="${1:-x86_64}"
    local host_os
    host_os=$(detect_host_os)
    
    local qemu_bin
    qemu_bin=$(get_qemu_binary "$arch" "$host_os")
    
    log_info "Testing QEMU availability..."
    
    if command -v "$qemu_bin" &> /dev/null; then
        log_success "$qemu_bin is available"
        
        # Test version
        local version
        version=$("$qemu_bin" --version | head -n1)
        echo "Version: $version"
        
        # Test acceleration support
        local accel
        accel=$(get_acceleration "$arch" "$host_os")
        
        if [[ "$host_os" == "macos" && "$accel" == "hvf" ]]; then
            if sysctl kern.hv_support 2>/dev/null | grep -q "1"; then
                log_success "Hypervisor Framework (HVF) is supported"
            else
                log_warn "Hypervisor Framework (HVF) may not be supported"
            fi
        elif [[ "$host_os" == "linux" && "$accel" == "kvm" ]]; then
            if [[ -e "/dev/kvm" ]]; then
                log_success "KVM acceleration is available"
            else
                log_warn "KVM acceleration not available, will use software emulation"
            fi
        fi
        
        return 0
    else
        log_error "$qemu_bin not found"
        return 1
    fi
}

# Main function
main() {
    case "${1:-help}" in
        config|show-config)
            show_config "${2:-x86_64}"
            ;;
        test)
            test_qemu "${2:-x86_64}"
            exit $?
            ;;
        opts|options)
            generate_qemu_opts "${2:-x86_64}" "$(detect_host_os)" "${3:-6G}" "${4:-4}" "${5:-3440x1440}"
            ;;
        help|--help|-h)
            cat << EOF
QEMU Configuration Helper Script

Usage: $0 [COMMAND] [ARGS...]

Commands:
    config [ARCH]           Show QEMU configuration for architecture
    test [ARCH]             Test QEMU availability and acceleration
    opts [ARCH] [MEM] [CPU] [RES]  Generate QEMU options
    help                    Show this help

Architecture: x86_64 (default) or aarch64
Memory: RAM size (default: 6G)
CPU: CPU cores (default: 4)  
Resolution: Width x Height (default: 3440x1440)

Examples:
    $0 config x86_64        # Show x86_64 config
    $0 test aarch64         # Test ARM64 QEMU
    $0 opts x86_64 8G 6 1920x1080  # Generate options

EOF
            ;;
        *)
            log_error "Unknown command: $1"
            main help
            exit 1
            ;;
    esac
}

main "$@"
