#!/bin/bash
# 02-install-packages.sh - Install OpenVPN and required packages
# Run after 01-cleanup.sh

set -e  # Exit on error

echo "╔════════════════════════════════════════════════════════════╗"
echo "║     Install OpenVPN and Dependencies                       ║"
echo "║     Step 2 of 10: Package installation                     ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "⚠️  This script requires sudo privileges"
    echo "   Please run: sudo ./02-install-packages.sh"
    exit 1
fi

echo "This will install OpenVPN, Easy-RSA, and related packages."
echo ""

echo "═══════════════════════════════════════════════════════════"
echo "Starting package installation..."
echo "═══════════════════════════════════════════════════════════"
echo ""

# Update package list
echo "Step 1: Updating package list..."
apt update
echo "✓ Package list updated"
echo ""

# Install OpenVPN
echo "Step 2: Installing OpenVPN..."
apt install -y openvpn
echo "✓ OpenVPN installed"
echo ""

# Install Easy-RSA
echo "Step 3: Installing Easy-RSA..."
apt install -y easy-rsa
echo "✓ Easy-RSA installed"
echo ""

# Install optional but useful packages
echo "Step 4: Installing additional utilities..."
apt install -y \
    net-tools \
    iptables \
    iptables-persistent \
    curl \
    wget
echo "✓ Additional utilities installed"
echo ""

# Verify installations
echo "Step 5: Verifying installations..."
echo ""

OPENVPN_VERSION=$(openvpn --version | head -n 1)
echo "  OpenVPN: $OPENVPN_VERSION"

if [ -d /usr/share/easy-rsa ]; then
    echo "  Easy-RSA: Installed at /usr/share/easy-rsa"
else
    echo "  ⚠️  Easy-RSA: Not found!"
    exit 1
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "✓ Package installation completed successfully!"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Installed components:"
echo "  • OpenVPN server and client"
echo "  • Easy-RSA for certificate management"
echo "  • Network utilities"
echo "  • Firewall tools"
echo ""
echo "Next steps:"
echo "  1. Run as regular user: ./03-setup-easyrsa.sh"
echo "     (Do NOT use sudo for this step)"
echo ""
