# RMxxx RGMII Toolkit - Offline Installation Guide

This document provides complete instructions for creating and using the offline installation package for the RMxxx RGMII Toolkit.

## Overview

The offline installation solution allows you to install the RGMII Toolkit without requiring an internet connection on the target modem. All dependencies are bundled locally in a single package.

## Files Created

### 1. Main Offline Installer
- `RMxxx_rgmii_toolkit_offline.sh` - Main offline installer script

### 2. Modified Installation Scripts
- `offline_package/simpleupdates/scripts/update_simpleadmin.sh` - Simple Admin installer (offline)
- `offline_package/simpleupdates/scripts/update_simplefirewall.sh` - Simple Firewall installer (offline)
- `offline_package/simpleupdates/scripts/update_socat-at-bridge.sh` - AT Command Bridge installer (offline)
- `offline_package/simpleupdates/scripts/update_tailscale.sh` - Tailscale installer (offline)
- `offline_package/simpleupdates/scripts/update_sshd.sh` - SSH Server installer (offline)
- `offline_package/installentware.sh` - Entware installer (offline)

### 3. Package Creation Tools
- `create_offline_package.sh` - Script to assemble the offline package

## Step-by-Step Process

### Step 1: Prepare the Offline Package

1. **Run the package creation script:**
   ```bash
   ./create_offline_package.sh
   ```

2. **Manually download required external binaries:**
   
   Download the following files and place them in `/tmp/offline_package_build/binaries/`:

   - **Tailscale** (ARM version):
     ```bash
     wget https://pkgs.tailscale.com/stable/tailscale_1.90.6_arm.tgz
     tar -xzf tailscale_1.90.6_arm.tgz
     cp tailscale_1.90.6_arm/tailscale /tmp/offline_package_build/binaries/
     cp tailscale_1.90.6_arm/tailscaled /tmp/offline_package_build/binaries/
     ```

   - **TTYd** (ARMHF version):
     ```bash
     wget -O /tmp/offline_package_build/binaries/ttyd.armhf https://github.com/tsl0922/ttyd/releases/download/1.7.7/ttyd.armhf
     ```

   - **Speedtest CLI**:
     ```bash
     wget https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-armhf.tgz
     tar -xzf ookla-speedtest-1.2.0-linux-armhf.tgz
     cp speedtest /tmp/offline_package_build/binaries/
     ```

   - **Fast.com CLI**:
     ```bash
     wget -O /tmp/offline_package_build/binaries/fast https://github.com/ddo/fast/releases/download/v0.0.4/fast_linux_arm
     ```

   - **Entware packages**:
     ```bash
     mkdir -p /tmp/offline_package_build/binaries/entware
     wget -O /tmp/offline_package_build/binaries/entware/opkg http://bin.entware.net/armv7sf-k3.2/installer/opkg
     wget -O /tmp/offline_package_build/binaries/entware/opkg.conf http://bin.entware.net/armv7sf-k3.2/installer/opkg.conf
     ```

3. **Create the final package:**
   ```bash
   tar -czf offline_package.tar.gz -C /tmp offline_package_build
   ```

### Step 2: Deploy to Target Modem

1. **Copy the package to the modem:**
   ```bash
   adb push offline_package.tar.gz /tmp/
   ```

2. **Copy the main installer script:**
   ```bash
   adb push RMxxx_rgmii_toolkit_offline.sh /tmp/
   ```

3. **Make the installer executable:**
   ```bash
   adb shell "chmod +x /tmp/RMxxx_rgmii_toolkit_offline.sh"
   ```

### Step 3: Run Offline Installation

1. **Execute the offline installer:**
   ```bash
   adb shell "cd /tmp && ./RMxxx_rgmii_toolkit_offline.sh"
   ```

2. **Use the menu to install components:**
   - Option 2: Install Simple Admin (includes all dependencies)
   - Option 7: Install Tailscale
   - Option 11: Install Speedtest CLI
   - Option 12: Install Fast.com CLI
   - Option 13: Install OpenSSH Server

## Key Features of Offline Solution

### 1. No Internet Dependency
- All files are bundled locally
- No GitHub downloads required
- No external package downloads during installation

### 2. Modified Installation Scripts
All update scripts have been modified to:
- Use local files from `/tmp/offline_package/` instead of GitHub URLs
- Copy files using `cp` instead of `wget`
- Reference local binaries instead of downloading them

### 3. Package Structure
```
offline_package/
├── simpleadmin/          # Web interface files
├── simplefirewall/       # Firewall scripts
├── socat-at-bridge/      # AT command bridge
├── tailscale/            # Tailscale configuration
├── sshd/                 # SSH server config
├── simpleupdates/        # Modified update scripts
├── binaries/             # External binaries
│   ├── tailscale
│   ├── tailscaled
│   ├── ttyd.armhf
│   ├── speedtest
│   ├── fast
│   └── entware/
└── installentware.sh     # Modified Entware installer
```

## Technical Details

### Modified Script Behavior

**Original Online Scripts:**
```bash
wget -O /usrdata/simpleadmin/lighttpd.conf $GITROOT/simpleadmin/lighttpd.conf
```

**Modified Offline Scripts:**
```bash
cp "$OFFLINE_DIR/simpleadmin/lighttpd.conf" "$SIMPLE_ADMIN_DIR/lighttpd.conf"
```

### Installation Process Flow

1. **Extract Package**: Script extracts `/tmp/offline_package.tar.gz` to `/tmp/offline_package/`
2. **Local File Access**: All installation scripts reference files from `/tmp/offline_package/`
3. **Component Installation**: Each component installs from local files instead of downloading
4. **System Integration**: Systemd services and binaries are installed normally

## Limitations and Notes

### Current Limitations
- Some advanced features (uninstall, firewall management) are not fully implemented in offline version
- Entware still requires internet for package updates (but initial installation is offline)
- Package size is larger due to bundled binaries

### File Size Considerations
The complete offline package is approximately 50-100MB depending on included binaries.

### Compatibility
- Designed for ARMv7 architecture (armv7l)
- Tested on Quectel RM5xx series modems
- Requires ADB access to the modem

## Troubleshooting

### Common Issues

1. **Package not found:**
   ```
   Error: Offline package not found at /tmp/offline_package.tar.gz
   ```
   **Solution**: Ensure the package is copied to `/tmp/` on the modem

2. **Missing binaries:**
   ```
   Error: Local installation script for [component] not found
   ```
   **Solution**: Verify all required binaries are in the `binaries/` directory

3. **Permission errors:**
   ```
   Error: Failed to extract offline package
   ```
   **Solution**: Ensure the modem filesystem is mounted read-write

### Verification Steps

1. Check package extraction:
   ```bash
   adb shell "ls -la /tmp/offline_package/"
   ```

2. Verify binary permissions:
   ```bash
   adb shell "ls -la /tmp/offline_package/binaries/"
   ```

3. Test component installation:
   ```bash
   adb shell "cd /tmp/offline_package/simpleupdates/scripts && ./update_simpleadmin.sh"
   ```

## Conclusion

The offline installation solution provides a complete alternative to the online installation method, allowing deployment in environments without internet access. All components are self-contained and installation proceeds without external dependencies.