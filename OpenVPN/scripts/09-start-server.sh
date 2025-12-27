#!/bin/bash
# 09-start-server.sh - Start OpenVPN server
# Run with sudo

set -e  # Exit on error

echo "╔════════════════════════════════════════════════════════════╗"
echo "║     Start OpenVPN Server                                   ║"
echo "║     Step 9 of 10: Start and verify server                  ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "⚠️  This script requires sudo privileges"
    echo "   Please run: sudo ./09-start-server.sh"
    exit 1
fi

echo "═══════════════════════════════════════════════════════════"
echo "Starting OpenVPN server..."
echo "═══════════════════════════════════════════════════════════"
echo ""

# Check if configuration exists
if [ ! -f /etc/openvpn/server/server.conf ]; then
    echo "✗ Error: Server configuration not found!"
    echo "  Please run sudo ./07-configure-server.sh first"
    exit 1
fi

# Stop server if already running
echo "Step 1: Stopping any existing OpenVPN instances..."
systemctl stop openvpn-server@server 2>/dev/null || true
sleep 2
echo "✓ Stopped existing instances"
echo ""

# Start server
echo "Step 2: Starting OpenVPN server..."
systemctl start openvpn-server@server

# Wait for server to start
echo "  Waiting for server to initialize..."
sleep 3

# Check status
if systemctl is-active --quiet openvpn-server@server; then
    echo "✓ OpenVPN server started successfully"
else
    echo "✗ Failed to start OpenVPN server!"
    echo ""
    echo "Showing error logs:"
    journalctl -u openvpn-server@server -n 20 --no-pager
    exit 1
fi

echo ""

# Enable auto-start on boot
echo "Step 3: Enabling auto-start on boot..."
systemctl enable openvpn-server@server > /dev/null 2>&1
echo "✓ Auto-start enabled"
echo ""

# Verify server is running
echo "Step 4: Verifying server status..."
echo ""

# Check systemd status
STATUS=$(systemctl is-active openvpn-server@server)
echo "  Service status: $STATUS"

# Check for initialization completion
if journalctl -u openvpn-server@server -n 50 --no-pager | grep -q "Initialization Sequence Completed"; then
    echo "  ✓ Server initialization: Complete"
else
    echo "  ⚠️  Warning: Initialization may not be complete"
fi

# Check TUN interface
if ip addr show tun0 > /dev/null 2>&1; then
    echo "  ✓ TUN interface: Created"
    VPN_IP=$(ip addr show tun0 | grep "inet " | awk '{print $2}')
    echo "    VPN IP: $VPN_IP"
else
    echo "  ✗ TUN interface: Not found!"
    exit 1
fi

# Check listening port
VPN_PORT=$(grep "^port" /etc/openvpn/server/server.conf | awk '{print $2}')
if ss -tulpn | grep -q ":$VPN_PORT"; then
    echo "  ✓ Listening on port: $VPN_PORT"
else
    echo "  ✗ Not listening on port: $VPN_PORT"
    exit 1
fi

echo ""

# Display detailed status
echo "Step 5: Server details..."
echo ""
echo "═══════════════════════════════════════════════════════════"
systemctl status openvpn-server@server --no-pager -l | head -20
echo "═══════════════════════════════════════════════════════════"
echo ""

# Show recent logs
echo "Recent logs:"
echo "═══════════════════════════════════════════════════════════"
journalctl -u openvpn-server@server -n 10 --no-pager
echo "═══════════════════════════════════════════════════════════"
echo ""

echo "═══════════════════════════════════════════════════════════"
echo "✓ OpenVPN server is running!"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Server Status:"
echo "  ✓ Service: Active and running"
echo "  ✓ Auto-start: Enabled"
echo "  ✓ TUN interface: UP"
echo "  ✓ Port: Listening on $VPN_PORT"
echo ""
echo "Server Details:"
echo "  • VPN Network: 10.8.0.0/24"
echo "  • Server IP: 10.8.0.1"
echo "  • Port: $VPN_PORT"
echo "  • Config: /etc/openvpn/server/server.conf"
echo "  • Logs: /var/log/openvpn/openvpn.log"
echo ""
echo "Useful commands:"
echo "  • View status:  sudo systemctl status openvpn-server@server"
echo "  • View logs:    sudo journalctl -u openvpn-server@server -f"
echo "  • Restart:      sudo systemctl restart openvpn-server@server"
echo "  • Stop:         sudo systemctl stop openvpn-server@server"
echo ""
echo "Next steps:"
echo "  1. Verify router port forwarding is configured"
echo "  2. Run as regular user: ./10-create-client.sh"
echo "     This will create your first VPN client"
echo ""
