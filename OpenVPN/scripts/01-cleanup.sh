#!/bin/bash
# 01-cleanup.sh - Complete cleanup of old OpenVPN installations
# Run this first to start with a clean slate

set -e  # Exit on error

echo "╔════════════════════════════════════════════════════════════╗"
echo "║     OpenVPN Complete Cleanup Script                        ║"
echo "║     Step 1 of 10: Remove old configurations                ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "⚠️  This script requires sudo privileges"
    echo "   Please run: sudo ./01-cleanup.sh"
    exit 1
fi

echo "This will remove ALL existing OpenVPN configurations."
echo "⚠️  WARNING: This cannot be undone!"
echo ""
read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "Starting cleanup process..."
echo "═══════════════════════════════════════════════════════════"
echo ""

# Stop any running OpenVPN services
echo "Step 1: Stopping OpenVPN services..."
systemctl stop openvpn-server@server 2>/dev/null || true
systemctl stop openvpn-client@* 2>/dev/null || true
systemctl disable openvpn-server@server 2>/dev/null || true
killall openvpn 2>/dev/null || true
echo "✓ OpenVPN services stopped"
echo ""

# Remove server configurations
echo "Step 2: Removing server configurations..."
if [ -d /etc/openvpn/server ]; then
    rm -rf /etc/openvpn/server/*
    echo "✓ Server configurations removed"
else
    echo "  (No server directory found)"
fi
echo ""

# Remove client configurations
echo "Step 3: Removing client configurations..."
if [ -d /etc/openvpn/client ]; then
    rm -rf /etc/openvpn/client/*
    echo "✓ Client configurations removed"
else
    echo "  (No client directory found)"
fi
echo ""

# Remove Easy-RSA directory
echo "Step 4: Removing Easy-RSA PKI..."
if [ -d /home/$SUDO_USER/openvpn-ca ]; then
    rm -rf /home/$SUDO_USER/openvpn-ca
    echo "✓ Easy-RSA directory removed"
else
    echo "  (No Easy-RSA directory found)"
fi
echo ""

# Remove client configs
echo "Step 5: Removing client config directory..."
if [ -d /home/$SUDO_USER/client-configs ]; then
    rm -rf /home/$SUDO_USER/client-configs
    echo "✓ Client configs removed"
else
    echo "  (No client configs found)"
fi
echo ""

# Remove logs
echo "Step 6: Removing log files..."
if [ -d /var/log/openvpn ]; then
    rm -rf /var/log/openvpn/*
    echo "✓ Log files removed"
else
    echo "  (No log directory found)"
fi
echo ""

# Clean up systemd
echo "Step 7: Cleaning up systemd..."
systemctl daemon-reload
echo "✓ Systemd reloaded"
echo ""

# Remove old scripts (if any)
echo "Step 8: Removing old helper scripts..."
rm -f /home/$SUDO_USER/add-vpn-client.sh 2>/dev/null || true
rm -f /home/$SUDO_USER/revoke-vpn-client.sh 2>/dev/null || true
rm -f /home/$SUDO_USER/make-client.sh 2>/dev/null || true
rm -f /home/$SUDO_USER/add-secure-client.sh 2>/dev/null || true
echo "✓ Old scripts removed"
echo ""

# Verification
echo "Step 9: Verification..."
echo ""
echo "Checking cleanup status:"

[ ! -d /etc/openvpn/server ] || [ -z "$(ls -A /etc/openvpn/server 2>/dev/null)" ] && \
    echo "  ✓ Server directory clean" || echo "  ⚠️  Server directory not empty"

[ ! -d /home/$SUDO_USER/openvpn-ca ] && \
    echo "  ✓ Easy-RSA directory clean" || echo "  ⚠️  Easy-RSA directory still exists"

[ ! -d /home/$SUDO_USER/client-configs ] && \
    echo "  ✓ Client configs directory clean" || echo "  ⚠️  Client configs still exist"

! systemctl is-active --quiet openvpn-server@server && \
    echo "  ✓ OpenVPN server stopped" || echo "  ⚠️  OpenVPN server still running"

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "✓ Cleanup completed successfully!"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Next steps:"
echo "  1. Run: sudo ./02-install-packages.sh"
echo ""
echo "Your system is now ready for a fresh OpenVPN installation."
echo ""
