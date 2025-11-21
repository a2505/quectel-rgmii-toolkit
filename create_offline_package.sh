#!/bin/bash

# Script to create offline installation package for RMxxx RGMII Toolkit
# This script bundles all required files into a single tar.gz package

echo "Creating offline installation package for RMxxx RGMII Toolkit..."
echo "================================================================"

# Create temporary directory for package assembly
PACKAGE_DIR="offline_package"
TEMP_DIR="/tmp/offline_package_build"
rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR"

# Copy all required files from the current repository
echo "Copying repository files..."

# Copy main toolkit script
cp RMxxx_rgmii_toolkit_offline.sh "$TEMP_DIR/"

# Copy all component directories
cp -r simpleadmin "$TEMP_DIR/"
cp -r simplefirewall "$TEMP_DIR/"
cp -r socat-at-bridge "$TEMP_DIR/"
cp -r tailscale "$TEMP_DIR/"
cp -r sshd "$TEMP_DIR/"
cp -r simpleupdates "$TEMP_DIR/"

# Copy installentware script
cp installentware.sh "$TEMP_DIR/"

# Create binaries directory for external binaries
mkdir -p "$TEMP_DIR/binaries"

echo "================================================================"
echo "OFFLINE PACKAGE CREATION INSTRUCTIONS:"
echo "================================================================"
echo ""
echo "The offline package structure has been created in: $TEMP_DIR"
echo ""
echo "IMPORTANT: You need to manually download and place the following"
echo "external binaries in the $TEMP_DIR/binaries/ directory:"
echo ""
echo "1. Tailscale binaries:"
echo "   - Download from: https://pkgs.tailscale.com/stable/tailscale_1.90.6_arm.tgz"
echo "   - Extract and copy 'tailscale' and 'tailscaled' to binaries/"
echo ""
echo "2. TTYd binary:"
echo "   - Download from: https://github.com/tsl0922/ttyd/releases/download/1.7.7/ttyd.armhf"
echo "   - Copy as 'ttyd.armhf' to binaries/"
echo ""
echo "3. Speedtest CLI:"
echo "   - Download from: https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-armhf.tgz"
echo "   - Extract and copy 'speedtest' to binaries/"
echo ""
echo "4. Fast.com CLI:"
echo "   - Download from: https://github.com/ddo/fast/releases/download/v0.0.4/fast_linux_arm"
echo "   - Copy as 'fast' to binaries/"
echo ""
echo "5. Entware packages:"
echo "   - Download opkg and opkg.conf from: http://bin.entware.net/armv7sf-k3.2/installer/"
echo "   - Create 'entware' directory in binaries/ and place them there"
echo ""
echo "After placing all binaries, run the following command to create the final package:"
echo "tar -czf offline_package.tar.gz -C /tmp offline_package_build"
echo ""
echo "Then copy offline_package.tar.gz to the target modem's /tmp/ directory"
echo "and run: ./RMxxx_rgmii_toolkit_offline.sh"
echo "================================================================"

# Create a simple README for the package
cat > "$TEMP_DIR/README.md" << 'EOF'
# RMxxx RGMII Toolkit - Offline Installation Package

This package contains all files needed for offline installation of the RMxxx RGMII Toolkit.

## Usage Instructions:

1. Copy this entire package to the target modem's /tmp/ directory
2. Extract the package: `tar -xzf offline_package.tar.gz -C /tmp/`
3. Run the offline installer: `./RMxxx_rgmii_toolkit_offline.sh`

## Package Contents:

- simpleadmin/ - Simple Admin web interface
- simplefirewall/ - Simple firewall with TTL management
- socat-at-bridge/ - AT command bridge services
- tailscale/ - Tailscale VPN client
- sshd/ - OpenSSH server configuration
- simpleupdates/ - Update scripts for all components
- binaries/ - External binary dependencies
- installentware.sh - Entware package manager installer

## External Dependencies Required:

The following external binaries must be manually downloaded and placed in the binaries/ directory:

- tailscale, tailscaled (from Tailscale ARM package)
- ttyd.armhf (TTYd ARM binary)
- speedtest (Speedtest CLI)
- fast (Fast.com CLI)
- opkg, opkg.conf (Entware package manager)

## Notes:

- This package is designed for ARMv7 architecture (armv7l)
- All installation scripts have been modified to use local files
- No internet connection is required during installation
EOF

echo "Package assembly completed. Follow the instructions above to complete the package."