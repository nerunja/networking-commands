#!/bin/bash
# diagnose-openvpn-error.sh - Find out why OpenVPN won't start

echo "╔════════════════════════════════════════════════════════════╗"
echo "║     OpenVPN Server Diagnostics                             ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "⚠️  This script requires sudo privileges"
    echo "   Please run: sudo ./diagnose-openvpn-error.sh"
    exit 1
fi

echo "═══════════════════════════════════════════════════════════"
echo "1. Configuration File Check"
echo "═══════════════════════════════════════════════════════════"
echo ""

if [ -f /etc/openvpn/server/server.conf ]; then
    echo "✓ Configuration file exists"
    echo ""
    echo "Active configuration (non-comment lines):"
    echo "─────────────────────────────────────────────────────────"
    grep -v "^#" /etc/openvpn/server/server.conf | grep -v "^$"
else
    echo "✗ Configuration file NOT FOUND!"
    exit 1
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "2. Certificate Files Check"
echo "═══════════════════════════════════════════════════════════"
echo ""

cd /etc/openvpn/server/
for file in ca.crt server.crt server.key dh.pem ta.key; do
    if [ -f "$file" ]; then
        size=$(ls -lh "$file" | awk '{print $5}')
        perms=$(ls -l "$file" | awk '{print $1}')
        echo "  ✓ $file ($size, $perms)"
    else
        echo "  ✗ $file MISSING!"
    fi
done

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "3. Port Availability Check"
echo "═══════════════════════════════════════════════════════════"
echo ""

PORT=$(grep "^port" /etc/openvpn/server/server.conf | awk '{print $2}')
PROTO=$(grep "^proto" /etc/openvpn/server/server.conf | awk '{print $2}')

echo "Server configured for: $PORT/$PROTO"
echo ""

if ss -tulpn | grep -q ":$PORT "; then
    echo "⚠️  Port $PORT is already in use:"
    ss -tulpn | grep ":$PORT "
else
    echo "✓ Port $PORT is available"
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "4. Full Error Logs (last 50 lines)"
echo "═══════════════════════════════════════════════════════════"
echo ""

journalctl -u openvpn-server@server -n 50 --no-pager

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "5. Filter for Errors/Warnings"
echo "═══════════════════════════════════════════════════════════"
echo ""

journalctl -u openvpn-server@server -n 100 --no-pager | \
    grep -i "error\|failed\|cannot\|permission\|denied\|fatal"

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "6. Manual Start Test (detailed output)"
echo "═══════════════════════════════════════════════════════════"
echo ""

echo "Attempting to start OpenVPN manually for detailed error messages..."
echo ""

# Try to start manually (will timeout after 10 seconds)
timeout 10 openvpn --config /etc/openvpn/server/server.conf 2>&1 | head -50

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "7. System Status"
echo "═══════════════════════════════════════════════════════════"
echo ""

echo "IP Forwarding:"
if [ "$(cat /proc/sys/net/ipv4/ip_forward)" = "1" ]; then
    echo "  ✓ Enabled"
else
    echo "  ✗ Disabled (THIS IS A PROBLEM!)"
fi

echo ""
echo "TUN/TAP Support:"
if [ -c /dev/net/tun ]; then
    echo "  ✓ Available"
else
    echo "  ✗ Not available (THIS IS A PROBLEM!)"
fi

echo ""
echo "Service Status:"
systemctl status openvpn-server@server --no-pager -l | head -20

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "Diagnostics Complete"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Look for errors marked with ✗ or messages containing:"
echo "  • ERROR, FAILED, CANNOT"
echo "  • Permission denied"
echo "  • File not found"
echo "  • Address already in use"
echo ""
