#!/bin/bash
# 06-copy-server-files.sh - Copy server files to OpenVPN directory
# Run with sudo

set -e  # Exit on error

echo "╔════════════════════════════════════════════════════════════╗"
echo "║     Copy Server Files to OpenVPN Directory                 ║"
echo "║     Step 6 of 10: Install certificates and keys            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "⚠️  This script requires sudo privileges"
    echo "   Please run: sudo ./06-copy-server-files.sh"
    exit 1
fi

# Get the actual user (not root)
REAL_USER=$SUDO_USER

# Check if server files exist
if [ ! -f /home/$REAL_USER/openvpn-ca/pki/issued/server.crt ]; then
    echo "✗ Error: Server certificates not found!"
    echo "  Please run ./05-generate-server-cert.sh first"
    exit 1
fi

echo "═══════════════════════════════════════════════════════════"
echo "Copying server files..."
echo "═══════════════════════════════════════════════════════════"
echo ""

# Create directories
echo "Step 1: Creating OpenVPN directories..."
mkdir -p /etc/openvpn/server
mkdir -p /var/log/openvpn
echo "✓ Directories created"
echo ""

# Copy certificate files
echo "Step 2: Copying certificate and key files..."

cp /home/$REAL_USER/openvpn-ca/pki/ca.crt /etc/openvpn/server/
echo "  ✓ Copied: ca.crt"

cp /home/$REAL_USER/openvpn-ca/pki/issued/server.crt /etc/openvpn/server/
echo "  ✓ Copied: server.crt"

cp /home/$REAL_USER/openvpn-ca/pki/private/server.key /etc/openvpn/server/
echo "  ✓ Copied: server.key"

cp /home/$REAL_USER/openvpn-ca/pki/dh.pem /etc/openvpn/server/
echo "  ✓ Copied: dh.pem"

cp /home/$REAL_USER/openvpn-ca/ta.key /etc/openvpn/server/
echo "  ✓ Copied: ta.key"

echo ""

# Set proper permissions
echo "Step 3: Setting file permissions..."

# Private keys - only root can read/write
chmod 600 /etc/openvpn/server/server.key
echo "  ✓ server.key: 600 (owner read/write only)"

chmod 600 /etc/openvpn/server/ta.key
echo "  ✓ ta.key: 600 (owner read/write only)"

# Public certificates - readable by all
chmod 644 /etc/openvpn/server/ca.crt
echo "  ✓ ca.crt: 644 (readable)"

chmod 644 /etc/openvpn/server/server.crt
echo "  ✓ server.crt: 644 (readable)"

chmod 644 /etc/openvpn/server/dh.pem
echo "  ✓ dh.pem: 644 (readable)"

echo ""

# Set ownership
echo "Step 4: Setting file ownership..."
chown root:root /etc/openvpn/server/*
echo "✓ All files owned by root:root"
echo ""

# Verify installation
echo "Step 5: Verifying installation..."
echo ""
echo "Files in /etc/openvpn/server:"
ls -lh /etc/openvpn/server/ | tail -n +2 | awk '{print "  " $9 " (" $1 ")"}'

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "✓ Server files copied successfully!"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Security verification:"
echo "  ✓ Private keys protected (600 permissions)"
echo "  ✓ All files owned by root"
echo "  ✓ Proper directory structure"
echo ""
echo "Next steps:"
echo "  1. Run with sudo: sudo ./07-configure-server.sh"
echo ""
