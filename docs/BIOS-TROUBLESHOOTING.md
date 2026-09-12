# BIOS Configuration Guide for Gigabyte B660M + NVIDIA RTX 3080 Sleep/Wake Issues

> **Maintainer hardware example:** These settings are for a Gigabyte B660M,
> Intel CPU, and NVIDIA RTX 3080. Consult your motherboard and GPU
> documentation instead of applying them to different hardware.

## Overview
The Gigabyte B660M motherboard with Intel B660 chipset has several BIOS settings that commonly cause sleep/wake failures, especially with high-end NVIDIA GPUs like the RTX 3080. These settings often override OS-level power management configurations.

## Critical BIOS Settings to Check/Change

### 1. Power Management Settings
**Location: Advanced → Power Management Setup**

- **Suspend to RAM**: Set to **Enabled**
- **ACPI Suspend Type**: Set to **S3 (STR)** 
- **Deep Sleep**: Set to **Enabled** (if available)
- **ErP Ready**: Set to **Disabled** (can cause wake issues)
- **CEC 2019 Ready**: Set to **Disabled** (if available)

### 2. PCIe Configuration
**Location: Advanced → PCI Subsystem Settings or Chipset**

- **PEG Port Speed**: Set to **Auto** (not forced Gen4)a
- **PCIe ASPM Support**: Set to **Disabled** (key setting!)
- **PCIe Link State Power Management**: Set to **Disabled**
- **Above 4G Decoding**: Set to **Enabled** (for RTX 3080)
- **Re-Size BAR Support**: Set to **Enabled** (if available)

### 3. CPU Power Management
**Location: Advanced → CPU Configuration**

- **Intel SpeedStep**: Set to **Enabled**
- **C-States**: Set to **Enabled**
- **Package C State**: Set to **C6(non Retention)** or **Auto**
- **CPU C3 State**: Set to **Enabled**
- **CPU C6/C7 State**: Set to **Enabled**

### 4. Chipset Configuration
**Location: Advanced → Chipset Configuration**

- **IOAPIC 24-119 Entries**: Set to **Enabled**
- **Intel Rapid Storage Technology**: Set to **Disabled** (unless using Intel RST)
- **USB Power Share**: Set to **Disabled**

### 5. Wake-Up Configuration
**Location: Advanced → Wake Up Event Setup or USB Configuration**

- **USB Wake Up From S3**: Set to **Enabled** (for keyboard/mouse wake)
- **USB Wake Up From S4/S5**: Set to **Disabled**
- **Wake Up by PCI-E/PCI**: Set to **Disabled** (critical!)
- **Power On by Mouse**: Set to **Enabled** (if desired)
- **Power On by Keyboard**: Set to **Enabled** (if desired)

### 6. Integrated Graphics (if available)
**Location: Advanced → Integrated Graphics Configuration**

- **Primary Display**: Set to **PCIe** (forces discrete GPU as primary)
- **Internal Graphics**: Set to **Disabled** (if not using iGPU)
- **DVMT Pre-Allocated**: Set to **32M** (if iGPU enabled)

### 7. Fast Boot Settings
**Location: Boot → Fast Boot or Advanced → CSM**

- **Fast Boot**: Set to **Disabled** (can cause wake issues)
- **CSM Support**: Set to **Disabled** (UEFI only)
- **Secure Boot**: Set to **Disabled** (unless specifically needed)

## Gigabyte-Specific Settings

### Q-Flash Plus
- Make sure you have the latest BIOS version (F20+ for B660M AORUS PRO)

### Smart Fan Settings
**Location: PC Health Status → Smart Fan 5**
- Ensure fan curves don't interfere with sleep states
- **Fan Stop**: Can cause issues, consider disabling

### RGB/Lighting
**Location: Peripherals → RGB Fusion**
- **RGB Fusion**: Consider disabling during troubleshooting
- RGB can sometimes prevent proper sleep states

## Most Critical Settings for Your Issue

Based on your symptoms, focus on these **HIGH PRIORITY** settings:

1. **PCIe ASPM Support**: **DISABLED** ⚠️ CRITICAL
2. **Wake Up by PCI-E/PCI**: **DISABLED** ⚠️ CRITICAL  
3. **ErP Ready**: **DISABLED**
4. **Fast Boot**: **DISABLED**
5. **Above 4G Decoding**: **ENABLED** (for RTX 3080)

## BIOS Update Recommendation

Check your current BIOS version and consider updating:
- **B660M AORUS PRO**: Latest is F20 (as of 2024)
- **B660M DS3H**: Latest is F14
- **B660M GAMING X**: Latest is F15

## Testing Procedure

After changing BIOS settings:

1. **Save & Exit** BIOS
2. Boot into Linux and run: `make wake-sources`
3. Test with short suspend: `sleep 5 && systemctl suspend`
4. If successful, try longer suspend periods

## Common Gigabyte B660M + RTX 3080 Issues

- **PCIe ASPM conflicts** with NVIDIA power management
- **ErP Ready** causing incomplete wake sequences  
- **Fast Boot** interfering with ACPI wake sources
- **PCI-E wake events** conflicting with GPU power states

## Backup Current Settings

Before making changes, take photos/notes of current BIOS settings for rollback.
