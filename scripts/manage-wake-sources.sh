#!/bin/bash

# Wake Source Management Script for NixOS
# Helps manage ACPI wake sources for better sleep/wake reliability

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to show current wake sources
show_wake_sources() {
    print_color $BLUE "=== Current ACPI Wake Sources ==="
    cat /proc/acpi/wakeup
    echo
    
    print_color $GREEN "=== Key Wake Sources Analysis ==="
    
    # Check USB controller
    local xhci_status=$(awk '/XHCI/ {print $3}' /proc/acpi/wakeup)
    if [[ "$xhci_status" == "*enabled" ]]; then
        print_color $GREEN "✓ XHCI (USB) - enabled (good for keyboard/mouse wake)"
    else
        print_color $YELLOW "! XHCI (USB) - disabled (may prevent keyboard/mouse wake)"
    fi
    
    # Check NVIDIA GPU
    local pegp_status=$(awk '/PEGP.*pci:0000:01:00.0/ {print $3}' /proc/acpi/wakeup)
    if [[ "$pegp_status" == "*disabled" ]]; then
        print_color $GREEN "✓ PEGP (NVIDIA GPU) - disabled (good for sleep stability)"
    else
        print_color $YELLOW "! PEGP (NVIDIA GPU) - enabled (may cause wake issues)"
    fi
    
    # Check primary PCIe slot
    local peg1_status=$(awk '/PEG1/ {print $3}' /proc/acpi/wakeup)
    if [[ "$peg1_status" == "*enabled" ]]; then
        print_color $GREEN "✓ PEG1 (Primary PCIe) - enabled"
    else
        print_color $YELLOW "! PEG1 (Primary PCIe) - disabled"
    fi
    
    echo
}

# Function to toggle a wake source
toggle_wake_source() {
    local device=$1
    local current_status
    
    if ! grep -q "^$device" /proc/acpi/wakeup; then
        print_color $RED "Error: Device '$device' not found in /proc/acpi/wakeup"
        return 1
    fi
    
    current_status=$(awk "/^$device/ {print \$3}" /proc/acpi/wakeup)
    
    print_color $YELLOW "Current status of $device: $current_status"
    print_color $BLUE "Toggling wake source: $device"
    
    # Toggle the device
    echo "$device" | sudo tee /proc/acpi/wakeup > /dev/null
    
    # Show new status
    local new_status=$(awk "/^$device/ {print \$3}" /proc/acpi/wakeup)
    print_color $GREEN "New status of $device: $new_status"
}

# Function to apply recommended wake settings
apply_recommended_settings() {
    print_color $BLUE "=== Applying Recommended Wake Settings ==="
    
    # Ensure USB controller is enabled for wake (keyboard/mouse)
    local xhci_status=$(awk '/XHCI/ {print $3}' /proc/acpi/wakeup)
    if [[ "$xhci_status" != "*enabled" ]]; then
        print_color $YELLOW "Enabling XHCI (USB) for wake..."
        toggle_wake_source "XHCI"
    else
        print_color $GREEN "XHCI (USB) already enabled"
    fi
    
    # Ensure NVIDIA GPU is disabled for wake
    local pegp_status=$(awk '/PEGP.*pci:0000:01:00.0/ {print $3}' /proc/acpi/wakeup)
    if [[ "$pegp_status" == "*enabled" ]]; then
        print_color $YELLOW "Disabling PEGP (NVIDIA GPU) for wake stability..."
        toggle_wake_source "PEGP"
    else
        print_color $GREEN "PEGP (NVIDIA GPU) already disabled"
    fi
    
    print_color $GREEN "Recommended settings applied!"
    echo
}

# Function to create a systemd service for persistent wake settings
create_wake_service() {
    print_color $BLUE "=== Creating Systemd Service for Persistent Wake Settings ==="
    
    local service_content="[Unit]
Description=Configure ACPI Wake Sources
After=multi-user.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/bash -c 'echo PEGP > /proc/acpi/wakeup 2>/dev/null || true'
ExecStart=/bin/bash -c 'if ! grep -q \"XHCI.*enabled\" /proc/acpi/wakeup; then echo XHCI > /proc/acpi/wakeup; fi'

[Install]
WantedBy=multi-user.target"

    # Create temporary service file
    local temp_service="/tmp/acpi-wake-config.service"
    echo "$service_content" > "$temp_service"
    
    print_color $YELLOW "Service file created at: $temp_service"
    print_color $BLUE "To install this service system-wide, you can add it to your NixOS configuration:"
    
    echo
    cat << 'EOF'
Add to your NixOS system configuration:

systemd.services.acpi-wake-config = {
  description = "Configure ACPI Wake Sources";
  after = [ "multi-user.target" ];
  wantedBy = [ "multi-user.target" ];
  serviceConfig = {
    Type = "oneshot";
    RemainAfterExit = "yes";
    ExecStart = [
      "/bin/bash -c 'echo PEGP > /proc/acpi/wakeup 2>/dev/null || true'"
      "/bin/bash -c 'if ! grep -q \"XHCI.*enabled\" /proc/acpi/wakeup; then echo XHCI > /proc/acpi/wakeup; fi'"
    ];
  };
};
EOF
    echo
}

# Function to test suspend/resume cycle
test_suspend_resume() {
    print_color $BLUE "=== Testing Suspend/Resume Cycle ==="
    print_color $YELLOW "This will suspend your system in 5 seconds..."
    print_color $YELLOW "Make sure to save all work before continuing!"
    
    read -p "Continue with suspend test? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_color $YELLOW "Suspend test cancelled"
        return 0
    fi
    
    print_color $BLUE "Suspending in 5 seconds... Press Ctrl+C to cancel"
    for i in {5..1}; do
        echo -n "$i... "
        sleep 1
    done
    echo
    
    # Record time before suspend
    echo "$(date): Starting suspend test" >> /tmp/suspend-test.log
    
    # Suspend the system
    systemctl suspend
    
    # This will run after resume
    echo "$(date): Resumed from suspend" >> /tmp/suspend-test.log
    print_color $GREEN "System resumed successfully!"
    print_color $BLUE "Check /tmp/suspend-test.log for timing information"
}

# Main function
main() {
    local action=${1:-show}
    
    case $action in
        "show"|"status")
            show_wake_sources
            ;;
        "toggle")
            if [[ $# -lt 2 ]]; then
                print_color $RED "Usage: $0 toggle <DEVICE>"
                print_color $BLUE "Available devices:"
                awk '{print $1}' /proc/acpi/wakeup | tail -n +2
                exit 1
            fi
            toggle_wake_source "$2"
            echo
            show_wake_sources
            ;;
        "recommend"|"fix")
            apply_recommended_settings
            show_wake_sources
            ;;
        "service")
            create_wake_service
            ;;
        "test")
            test_suspend_resume
            ;;
        "help"|"-h"|"--help")
            print_color $GREEN "Wake Source Management Script"
            echo
            echo "Usage: $0 <command>"
            echo
            echo "Commands:"
            echo "  show      - Show current wake sources (default)"
            echo "  toggle    - Toggle a specific wake source"
            echo "  recommend - Apply recommended wake settings"
            echo "  service   - Show how to create persistent wake service"
            echo "  test      - Test suspend/resume cycle"
            echo "  help      - Show this help"
            echo
            echo "Examples:"
            echo "  $0 show"
            echo "  $0 toggle PEGP"
            echo "  $0 recommend"
            echo "  $0 test"
            ;;
        *)
            print_color $RED "Unknown action: $action"
            print_color $BLUE "Use '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Check if running as root for write operations
if [[ $EUID -eq 0 ]] && [[ "${1:-show}" != "show" ]] && [[ "${1:-show}" != "help" ]] && [[ "${1:-show}" != "service" ]]; then
    print_color $YELLOW "Warning: Running as root. Wake source changes will be applied."
fi

main "$@"
