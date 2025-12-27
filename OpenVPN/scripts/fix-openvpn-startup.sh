#!/bin/bash
# fix-openvpn-startup.sh - Comprehensive fix for OpenVPN startup issues

set -e

echo "╔════════════════════════════════════════════════════════════╗"
echo "║     OpenVPN Startup Issue - Comprehensive Fix              ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "⚠️  This script requires sudo privileges"
    echo "   Please run: sudo ./fix-openvpn-startup.sh"
    exit 1
fi

echo "This script will fix common OpenVPN startup issues."
echo ""

# Stop server if running
echo "Step 1: Stopping OpenVPN server..."
systemctl stop openvpn-server@server 2>/dev/null || true
sleep 2
echo "✓ Server stopped"
echo ""

# Backup configuration
echo "Step 2: Backing up configuration..."
BACKUP_FILE="/etc/openvpn/server/server.conf.backup.$(date +%Y%m%d-%H%M%S)"
cp /etc/openvpn/server/server.conf "$BACKUP_FILE"
echo "✓ Backup saved: $BACKUP_FILE"
echo ""

# Fix 1: Update compression settings
echo "Step 3: Fixing compression configuration..."
sed -i '/^compress/d' /etc/openvpn/server/server.conf
sed -i '/^push "compress/d' /etc/openvpn/server/server.conf
sed -i '/^allow-compression/d' /etc/openvpn/server/server.conf

# Add at the end
cat >> /etc/openvpn/server/server.conf << 'EOF'

# Compression (OpenVPN 2.6+ compatible)
allow-compression yes
EOF

echo "✓ Compression fixed"
echo ""

# Fix 2: Check and fix file paths
echo "Step 4: Verifying certificate file paths..."

# Get actual filenames
cd /etc/openvpn/server/

# Check if files exist
for file in ca.crt server.crt server.key ta.key; do
    if [ ! -f "$file" ]; then
        echo "  ✗ Missing: $file"
        echo ""
        echo "ERROR: Certificate files are missing!"
        echo "Please run: sudo ./06-copy-server-files.sh"
        exit 1
    else
        echo "  ✓ Found: $file"
    fi
done

# Check for dh.pem or dh2048.pem
if [ -f "dh.pem" ]; then
    echo "  ✓ Found: dh.pem"
    DH_FILE="dh.pem"
elif [ -f "dh2048.pem" ]; then
    echo "  ✓ Found: dh2048.pem"
    DH_FILE="dh2048.pem"
else
    echo "  ✗ Missing: DH parameters file"
    echo ""
    echo "ERROR: DH parameters not found!"
    echo "Please run: ./05-generate-server-cert.sh"
    exit 1
fi

# Update config to use correct DH file
sed -i "s|^dh .*|dh $DH_FILE|" /etc/openvpn/server/server.conf
echo "  ✓ DH parameter configured: $DH_FILE"

echo ""

# Fix 3: Ensure proper permissions
echo "Step 5: Setting correct file permissions..."
chmod 600 server.key ta.key
chmod 644 ca.crt server.crt "$DH_FILE"
chown root:root *
echo "✓ Permissions set"
echo ""

# Fix 4: Enable IP forwarding
echo "Step 6: Checking IP forwarding..."
if [ "$(cat /proc/sys/net/ipv4/ip_forward)" != "1" ]; then
    echo "  Enabling IP forwarding..."
    echo 1 > /proc/sys/net/ipv4/ip_forward
    
    # Make persistent
    if [ ! -f /etc/sysctl.d/99-openvpn.conf ]; then
        cat > /etc/sysctl.d/99-openvpn.conf << 'EOF'
net.ipv4.ip_forward=1
EOF
    fi
    echo "  ✓ IP forwarding enabled"
else
    echo "  ✓ IP forwarding already enabled"
fi
echo ""

# Fix 5: Verify log directory
echo "Step 7: Checking log directory..."
mkdir -p /var/log/openvpn
chmod 755 /var/log/openvpn
echo "✓ Log directory ready"
echo ""

# Fix 6: Test configuration
echo "Step 8: Testing configuration..."
echo ""

if timeout 5 openvpn --config /etc/openvpn/server/server.conf 2>&1 | head -20; then
    :
fi

echo ""
echo "Step 9: Display current configuration..."
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "Current server.conf (active lines):"
echo "═══════════════════════════════════════════════════════════"
grep -v "^#" /etc/openvpn/server/server.conf | grep -v "^$"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Try to start
echo "Step 10: Starting OpenVPN server..."
systemctl start openvpn-server@server

# Wait for startup
sleep 3

# Check status
if systemctl is-active --quiet openvpn-server@server; then
    echo "✓ OpenVPN server started successfully!"
    echo ""
    
    # Show status
    echo "Server Status:"
    systemctl status openvpn-server@server --no-pager -l | head -15
    
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "✓ Server is running!"
    echo "═══════════════════════════════════════════════════════════"
    echo ""
    
    # Check TUN interface
    if ip addr show tun0 > /dev/null 2>&1; then
        echo "✓ TUN interface created:"
        ip addr show tun0 | grep "inet "
    fi
    
    echo ""
    echo "Next steps:"
    echo "  • View logs: sudo journalctl -u openvpn-server@server -f"
    echo "  • Create client: ./10-create-client.sh"
    
else
    echo "✗ Server failed to start!"
    echo ""
    echo "Showing recent error logs:"
    echo "═══════════════════════════════════════════════════════════"
    journalctl -u openvpn-server@server -n 30 --no-pager
    echo "═══════════════════════════════════════════════════════════"
    echo ""
    echo "Try running: sudo ./diagnose-openvpn-error.sh"
    exit 1
fi

echo ""
