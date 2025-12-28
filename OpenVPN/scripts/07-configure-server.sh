#!/bin/bash
# 07-configure-server.sh - Create OpenVPN server configuration
# Run with sudo

set -e  # Exit on error

echo "╔════════════════════════════════════════════════════════════╗"
echo "║     Configure OpenVPN Server                               ║"
echo "║     Step 7 of 10: Create server configuration file         ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "⚠️  This script requires sudo privileges"
    echo "   Please run: sudo ./07-configure-server.sh"
    exit 1
fi

# Check if server files exist
if [ ! -f /etc/openvpn/server/server.key ]; then
    echo "✗ Error: Server files not found!"
    echo "  Please run sudo ./06-copy-server-files.sh first"
    exit 1
fi

echo "═══════════════════════════════════════════════════════════"
echo "Creating server configuration..."
echo "═══════════════════════════════════════════════════════════"
echo ""

# Get configuration preferences
echo "Server Configuration Options:"
echo ""

read -p "VPN port [1194]: " port
port=${port:-1194}

read -p "Protocol (udp/tcp) [udp]: " protocol
protocol=${protocol:-udp}

echo ""
echo "DNS Server Options:"
echo "  1. Google (8.8.8.8, 8.8.4.4) - Fast, widely used"
echo "  2. Cloudflare (1.1.1.1, 1.0.0.1) - Privacy-focused (Default)"
echo "  3. Quad9 (9.9.9.9, 149.112.112.112) - Security-focused, blocks malware"
echo "  4. Custom"
echo ""
read -p "Select DNS option [1-4] (default: 2): " dns_choice
dns_choice=${dns_choice:-2}

case $dns_choice in
    1)
        dns1="8.8.8.8"
        dns2="8.8.4.4"
        ;;
    2)
        dns1="1.1.1.1"
        dns2="1.0.0.1"
        ;;
    3)
        dns1="9.9.9.9"
        dns2="149.112.112.112"
        ;;
    4)
        read -p "DNS server 1: " dns1
        read -p "DNS server 2: " dns2
        ;;
esac

echo ""
read -p "Maximum clients [10]: " max_clients
max_clients=${max_clients:-10}

echo ""
echo "Configuration summary:"
echo "  Port:         $port"
echo "  Protocol:     $protocol"
echo "  DNS 1:        $dns1"
echo "  DNS 2:        $dns2"
echo "  Max clients:  $max_clients"
echo ""

read -p "Continue with these settings? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Configuration cancelled."
    exit 0
fi

echo ""
echo "Step 1: Creating server configuration file..."

# Create server configuration
cat > /etc/openvpn/server/server.conf << EOF
########################################
# OpenVPN Server Configuration
# Generated on: $(date)
########################################

# Network Settings
port $port
proto $protocol
dev tun

# SSL/TLS Configuration
ca ca.crt
cert server.crt
key server.key
dh dh.pem
tls-auth ta.key 0

# VPN Network Configuration
server 10.8.0.0 255.255.255.0
ifconfig-pool-persist /var/log/openvpn/ipp.txt

# Push Routes and DNS to Clients
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS $dns1"
push "dhcp-option DNS $dns2"

# Client Configuration
client-to-client
keepalive 10 120

# Security Settings
cipher AES-256-GCM
auth SHA256
data-ciphers AES-256-GCM:AES-128-GCM:AES-256-CBC

# Compression
allow-compression yes
compress lz4-v2
push "compress lz4-v2"

# User/Group (run with reduced privileges)
user nobody
group nogroup

# Persistence Options
persist-key
persist-tun

# Logging
status /var/log/openvpn/openvpn-status.log
log-append /var/log/openvpn/openvpn.log
verb 3

# Performance
max-clients $max_clients

# Explicit exit notification (UDP only)
explicit-exit-notify 1
EOF

echo "✓ Server configuration created"
echo ""

# Verify configuration syntax
echo "Step 2: Verifying configuration syntax..."
if openvpn --config /etc/openvpn/server/server.conf --test-crypto 2>&1 | tee /tmp/openvpn-test.log | grep -q "FAILED"; then
    echo "✗ Configuration test failed!"
    cat /tmp/openvpn-test.log
    rm -f /tmp/openvpn-test.log
    exit 1
else
    echo "✓ Configuration syntax valid"
    if grep -qi "warning" /tmp/openvpn-test.log; then
        echo "⚠️  Warnings detected:"
        grep -i "warning" /tmp/openvpn-test.log
    fi
    rm -f /tmp/openvpn-test.log
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "✓ Server configuration completed!"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Configuration file: /etc/openvpn/server/server.conf"
echo ""
echo "Server settings:"
echo "  • Port: $port ($protocol)"
echo "  • VPN subnet: 10.8.0.0/24"
echo "  • Server IP: 10.8.0.1"
echo "  • DNS: $dns1, $dns2"
echo "  • Encryption: AES-256-GCM"
echo "  • Max clients: $max_clients"
echo ""
echo "Next steps:"
echo "  1. Run with sudo: sudo ./08-configure-network.sh"
echo ""
