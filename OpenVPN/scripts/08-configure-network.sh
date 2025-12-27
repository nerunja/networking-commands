#!/bin/bash
# 08-configure-network.sh - Configure IP forwarding and firewall
# Run with sudo

set -e  # Exit on error

echo "╔════════════════════════════════════════════════════════════╗"
echo "║     Configure Network and Firewall                         ║"
echo "║     Step 8 of 10: Enable IP forwarding and NAT             ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "⚠️  This script requires sudo privileges"
    echo "   Please run: sudo ./08-configure-network.sh"
    exit 1
fi

echo "═══════════════════════════════════════════════════════════"
echo "Configuring network settings..."
echo "═══════════════════════════════════════════════════════════"
echo ""

# Get network interface
echo "Step 1: Detecting network interface..."
DEFAULT_IFACE=$(ip route | grep default | awk '{print $5}' | head -n 1)

if [ -z "$DEFAULT_IFACE" ]; then
    echo "⚠️  Could not detect default network interface"
    read -p "Enter your network interface name (e.g., eth0, wlan0): " IFACE
else
    echo "  Detected interface: $DEFAULT_IFACE"
    read -p "Use this interface? (yes/no) [yes]: " use_detected
    use_detected=${use_detected:-yes}
    
    if [ "$use_detected" = "yes" ]; then
        IFACE=$DEFAULT_IFACE
    else
        read -p "Enter network interface name: " IFACE
    fi
fi

echo "  Using interface: $IFACE"
echo ""

# Enable IP forwarding
echo "Step 2: Enabling IP forwarding..."

# Create sysctl configuration
cat > /etc/sysctl.d/99-openvpn.conf << EOF
# OpenVPN Configuration
# Enable IP forwarding for VPN routing

net.ipv4.ip_forward=1

# Optional: Enable IPv6 forwarding if needed
# net.ipv6.conf.all.forwarding=1
EOF

echo "  ✓ Created: /etc/sysctl.d/99-openvpn.conf"

# Apply settings
sysctl --system > /dev/null 2>&1
echo "  ✓ Settings applied"

# Verify
FORWARDING=$(cat /proc/sys/net/ipv4/ip_forward)
if [ "$FORWARDING" = "1" ]; then
    echo "  ✓ IP forwarding enabled"
else
    echo "  ✗ IP forwarding failed to enable!"
    exit 1
fi

echo ""

# Configure UFW firewall
echo "Step 3: Configuring firewall (UFW)..."

# Check if UFW is installed
if ! command -v ufw &> /dev/null; then
    echo "  Installing UFW..."
    apt install -y ufw
fi

# Backup existing rules
if [ -f /etc/ufw/before.rules ]; then
    cp /etc/ufw/before.rules /etc/ufw/before.rules.backup.$(date +%Y%m%d-%H%M%S)
    echo "  ✓ Backed up existing firewall rules"
fi

# Add NAT rules
echo "  Configuring NAT rules..."

# Check if NAT rules already exist
if grep -q "# START OPENVPN RULES" /etc/ufw/before.rules 2>/dev/null; then
    echo "  NAT rules already exist, updating..."
    # Remove old rules
    sed -i '/# START OPENVPN RULES/,/# END OPENVPN RULES/d' /etc/ufw/before.rules
fi

# Add new NAT rules at the top
cat > /tmp/openvpn-nat-rules << EOF
#
# rules.before
#
# Rules that should be run before the ufw command line added rules. Custom
# rules should be added to one of these chains:
#   ufw-before-input
#   ufw-before-output
#   ufw-before-forward
#

# START OPENVPN RULES
# NAT table rules
*nat
:POSTROUTING ACCEPT [0:0]
# Allow traffic from OpenVPN client to $IFACE
-A POSTROUTING -s 10.8.0.0/24 -o $IFACE -j MASQUERADE
COMMIT
# END OPENVPN RULES

EOF

# Prepend to before.rules
cat /etc/ufw/before.rules >> /tmp/openvpn-nat-rules
mv /tmp/openvpn-nat-rules /etc/ufw/before.rules

echo "  ✓ NAT rules configured for interface: $IFACE"
echo ""

# Enable forwarding in UFW
echo "  Enabling packet forwarding in UFW..."
sed -i 's/DEFAULT_FORWARD_POLICY="DROP"/DEFAULT_FORWARD_POLICY="ACCEPT"/' /etc/default/ufw
echo "  ✓ Forwarding policy set to ACCEPT"
echo ""

# Get OpenVPN port from config
VPN_PORT=$(grep "^port" /etc/openvpn/server/server.conf | awk '{print $2}')
VPN_PROTO=$(grep "^proto" /etc/openvpn/server/server.conf | awk '{print $2}')

# Allow OpenVPN port
echo "  Allowing OpenVPN port..."
ufw allow $VPN_PORT/$VPN_PROTO comment 'OpenVPN' > /dev/null 2>&1
echo "  ✓ Allowed: $VPN_PORT/$VPN_PROTO"
echo ""

# Allow SSH (if not already allowed)
echo "  Ensuring SSH is allowed..."
ufw allow 22/tcp comment 'SSH' > /dev/null 2>&1
echo "  ✓ SSH allowed"
echo ""

# Enable UFW if not already enabled
echo "Step 4: Enabling firewall..."
if ! ufw status | grep -q "Status: active"; then
    echo "y" | ufw enable > /dev/null 2>&1
    echo "  ✓ Firewall enabled"
else
    ufw reload > /dev/null 2>&1
    echo "  ✓ Firewall reloaded"
fi

echo ""

# Display firewall status
echo "Step 5: Firewall status:"
echo ""
ufw status | grep -E "Status|$VPN_PORT|22" | sed 's/^/  /'

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "✓ Network configuration completed!"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Network settings:"
echo "  ✓ IP forwarding enabled"
echo "  ✓ NAT configured for interface: $IFACE"
echo "  ✓ UFW forwarding enabled"
echo "  ✓ Port $VPN_PORT/$VPN_PROTO allowed"
echo "  ✓ SSH access maintained"
echo ""
echo "⚠️  IMPORTANT: Port Forwarding Required!"
echo ""
echo "You must configure your router to forward:"
echo "  External Port: $VPN_PORT ($VPN_PROTO)"
echo "  Internal IP: $(hostname -I | awk '{print $1}')"
echo "  Internal Port: $VPN_PORT"
echo ""
echo "Next steps:"
echo "  1. Configure router port forwarding (see above)"
echo "  2. Run with sudo: sudo ./09-start-server.sh"
echo ""
