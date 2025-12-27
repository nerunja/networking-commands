#!/bin/bash
# 10-create-client.sh - Create first VPN client
# Run as regular user (NOT with sudo)

set -e  # Exit on error

echo "╔════════════════════════════════════════════════════════════╗"
echo "║     Create VPN Client Configuration                        ║"
echo "║     Step 10 of 10: Generate client certificate and config  ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Check if NOT running as root
if [ "$EUID" -eq 0 ]; then 
    echo "⚠️  Do NOT run this script with sudo!"
    echo "   Please run: ./10-create-client.sh"
    exit 1
fi

# Check if CA exists
if [ ! -f ~/openvpn-ca/pki/ca.crt ]; then
    echo "✗ Error: Certificate Authority not found!"
    echo "  Please complete the previous setup steps first"
    exit 1
fi

cd ~/openvpn-ca

echo "═══════════════════════════════════════════════════════════"
echo "Create your first VPN client..."
echo "═══════════════════════════════════════════════════════════"
echo ""

# Get client name
echo "Client naming conventions:"
echo "  • Use descriptive names: laptop, phone, tablet"
echo "  • Include username: nerunja-laptop, nerunja-phone"
echo "  • Be specific: work-laptop, personal-phone"
echo ""

read -p "Enter client name (e.g., nerunja-laptop): " CLIENT_NAME

if [ -z "$CLIENT_NAME" ]; then
    echo "✗ Error: Client name cannot be empty!"
    exit 1
fi

echo ""

# Get server address
echo "Server Address Configuration:"
echo ""
echo "Enter your server's DDNS domain or public IP address."
echo "Examples:"
echo "  • nerunja.mywire.org (DDNS)"
echo "  • vpn.yourdomain.com"
echo "  • 203.0.113.10 (Public IP)"
echo ""

read -p "Server address [nerunja.mywire.org]: " SERVER_ADDRESS
SERVER_ADDRESS=${SERVER_ADDRESS:-nerunja.mywire.org}

echo ""
echo "Creating client: $CLIENT_NAME"
echo "Server address: $SERVER_ADDRESS"
echo ""

read -p "Continue? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Client creation cancelled."
    exit 0
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "Generating client certificate..."
echo "═══════════════════════════════════════════════════════════"
echo ""

# Generate client certificate (without password for convenience)
echo "Step 1: Generating certificate request..."
echo "  Common Name prompt: Just press Enter to accept '$CLIENT_NAME'"
echo ""

./easyrsa gen-req "$CLIENT_NAME" nopass

echo ""
echo "✓ Certificate request created"
echo ""

# Sign client certificate
echo "Step 2: Signing certificate..."
echo ""
echo "You will be prompted for:"
echo "  1. Confirm details (type 'yes')"
echo "  2. CA password (the password you set earlier)"
echo ""
echo "═══════════════════════════════════════════════════════════"

./easyrsa sign-req client "$CLIENT_NAME"

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "✓ Certificate signed successfully"
echo ""

# Create client config directory
echo "Step 3: Preparing client configuration..."
mkdir -p ~/client-configs/keys

# Copy necessary files
cp pki/ca.crt ~/client-configs/keys/
cp "pki/issued/$CLIENT_NAME.crt" ~/client-configs/keys/
cp "pki/private/$CLIENT_NAME.key" ~/client-configs/keys/
cp ta.key ~/client-configs/keys/

echo "✓ Certificate files copied"
echo ""

# Get server port and protocol from server config
if [ -f /etc/openvpn/server/server.conf ]; then
    SERVER_PORT=$(sudo grep "^port" /etc/openvpn/server/server.conf | awk '{print $2}')
    SERVER_PROTO=$(sudo grep "^proto" /etc/openvpn/server/server.conf | awk '{print $2}')
else
    SERVER_PORT=1194
    SERVER_PROTO=udp
fi

# Create client configuration
echo "Step 4: Creating client configuration file..."

cat > ~/client-configs/$CLIENT_NAME.ovpn << EOF
##############################################
# OpenVPN Client Configuration
# Client: $CLIENT_NAME
# Generated: $(date)
##############################################

client
dev tun
proto $SERVER_PROTO
remote $SERVER_ADDRESS $SERVER_PORT

resolv-retry infinite
nobind
persist-key
persist-tun

remote-cert-tls server
cipher AES-256-GCM
auth SHA256
key-direction 1
compress lz4-v2

verb 3

# Uncomment to prevent DNS leaks
# block-outside-dns

# Uncomment to use custom DNS
# dhcp-option DNS 8.8.8.8
# dhcp-option DNS 8.8.4.4
EOF

# Add inline certificates
{
    echo ""
    echo "<ca>"
    cat ~/client-configs/keys/ca.crt
    echo "</ca>"
    echo ""
    echo "<cert>"
    cat ~/client-configs/keys/$CLIENT_NAME.crt
    echo "</cert>"
    echo ""
    echo "<key>"
    cat ~/client-configs/keys/$CLIENT_NAME.key
    echo "</key>"
    echo ""
    echo "<tls-auth>"
    cat ~/client-configs/keys/ta.key
    echo "</tls-auth>"
} >> ~/client-configs/$CLIENT_NAME.ovpn

echo "✓ Client configuration created"
echo ""

# Create QR code if qrencode is available
if command -v qrencode &> /dev/null; then
    echo "Step 5: Generating QR code (for mobile import)..."
    qrencode -t UTF8 < ~/client-configs/$CLIENT_NAME.ovpn > ~/client-configs/$CLIENT_NAME-qr.txt 2>/dev/null || true
    if [ -f ~/client-configs/$CLIENT_NAME-qr.txt ]; then
        echo "✓ QR code saved: ~/client-configs/$CLIENT_NAME-qr.txt"
        echo "  (Display with: cat ~/client-configs/$CLIENT_NAME-qr.txt)"
    fi
else
    echo "  (Optional: Install qrencode for QR code generation)"
    echo "    sudo apt install qrencode"
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "✓ Client created successfully!"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Client Details:"
echo "  • Name: $CLIENT_NAME"
echo "  • Server: $SERVER_ADDRESS:$SERVER_PORT"
echo "  • Protocol: $SERVER_PROTO"
echo "  • Config file: ~/client-configs/$CLIENT_NAME.ovpn"
echo ""
echo "File Information:"
FILE_SIZE=$(du -h ~/client-configs/$CLIENT_NAME.ovpn | cut -f1)
echo "  • Size: $FILE_SIZE"
echo "  • Location: ~/client-configs/$CLIENT_NAME.ovpn"
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "Security Reminder:"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "⚠️  IMPORTANT: This file contains everything needed to connect!"
echo ""
echo "Transfer securely using ONE of these methods:"
echo "  ✓ USB drive (physical transfer)"
echo "  ✓ SCP: scp ~/client-configs/$CLIENT_NAME.ovpn user@device:~/"
echo "  ✓ Password-protected zip"
echo "  ✓ Encrypted messaging (Signal, WhatsApp)"
echo ""
echo "NEVER:"
echo "  ✗ Email unencrypted"
echo "  ✗ Public cloud storage"
echo "  ✗ Unencrypted messaging"
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "How to Connect:"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Linux:"
echo "  sudo openvpn --config $CLIENT_NAME.ovpn"
echo ""
echo "Ubuntu Desktop (GUI):"
echo "  sudo nmcli connection import type openvpn file $CLIENT_NAME.ovpn"
echo ""
echo "Windows:"
echo "  1. Install OpenVPN GUI"
echo "  2. Copy .ovpn to: C:\\Program Files\\OpenVPN\\config\\"
echo "  3. Right-click OpenVPN GUI → Connect"
echo ""
echo "Android:"
echo "  1. Install 'OpenVPN for Android'"
echo "  2. Import .ovpn file"
echo "  3. Connect"
echo ""
echo "iOS:"
echo "  1. Install 'OpenVPN Connect'"
echo "  2. Import .ovpn file"
echo "  3. Connect"
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "Testing Your VPN:"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "After connecting, verify:"
echo ""
echo "1. Check VPN interface:"
echo "   ip addr show tun0"
echo ""
echo "2. Ping VPN server:"
echo "   ping 10.8.0.1"
echo ""
echo "3. Check public IP (should show server's IP):"
echo "   curl ifconfig.me"
echo ""
echo "4. Test DNS:"
echo "   nslookup google.com"
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "Creating Additional Clients:"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "To create more VPN clients, you can:"
echo ""
echo "1. Run this script again:"
echo "   ./10-create-client.sh"
echo ""
echo "2. Use the helper script (will be created below):"
echo "   ./add-client.sh laptop"
echo "   ./add-client.sh phone"
echo "   ./add-client.sh tablet"
echo ""

# Create helper script for future clients
echo "Creating helper script..."

cat > ~/add-client.sh << 'EOFSCRIPT'
#!/bin/bash
# add-client.sh - Quick client generation script

CLIENT_NAME=$1
SERVER_ADDRESS=${2:-nerunja.mywire.org}

if [ -z "$CLIENT_NAME" ]; then
    echo "Usage: ./add-client.sh <client-name> [server-address]"
    echo ""
    echo "Examples:"
    echo "  ./add-client.sh laptop"
    echo "  ./add-client.sh phone nerunja.mywire.org"
    exit 1
fi

if [ "$EUID" -eq 0 ]; then 
    echo "⚠️  Do NOT run this script with sudo!"
    exit 1
fi

cd ~/openvpn-ca || exit 1

echo "Creating client: $CLIENT_NAME"
echo ""

# Generate certificate
./easyrsa gen-req "$CLIENT_NAME" nopass
./easyrsa sign-req client "$CLIENT_NAME"

# Prepare directories
mkdir -p ~/client-configs/keys

# Copy files
cp pki/ca.crt ~/client-configs/keys/
cp "pki/issued/$CLIENT_NAME.crt" ~/client-configs/keys/
cp "pki/private/$CLIENT_NAME.key" ~/client-configs/keys/
cp ta.key ~/client-configs/keys/

# Get server config
if [ -f /etc/openvpn/server/server.conf ]; then
    SERVER_PORT=$(sudo grep "^port" /etc/openvpn/server/server.conf | awk '{print $2}')
    SERVER_PROTO=$(sudo grep "^proto" /etc/openvpn/server/server.conf | awk '{print $2}')
else
    SERVER_PORT=1194
    SERVER_PROTO=udp
fi

# Create config
cat > ~/client-configs/$CLIENT_NAME.ovpn << EOF
client
dev tun
proto $SERVER_PROTO
remote $SERVER_ADDRESS $SERVER_PORT
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
cipher AES-256-GCM
auth SHA256
key-direction 1
compress lz4-v2
verb 3
EOF

# Add certificates
{
    echo ""
    echo "<ca>"
    cat ~/client-configs/keys/ca.crt
    echo "</ca>"
    echo ""
    echo "<cert>"
    cat ~/client-configs/keys/$CLIENT_NAME.crt
    echo "</cert>"
    echo ""
    echo "<key>"
    cat ~/client-configs/keys/$CLIENT_NAME.key
    echo "</key>"
    echo ""
    echo "<tls-auth>"
    cat ~/client-configs/keys/ta.key
    echo "</tls-auth>"
} >> ~/client-configs/$CLIENT_NAME.ovpn

echo "✓ Client created: ~/client-configs/$CLIENT_NAME.ovpn"
EOFSCRIPT

chmod +x ~/add-client.sh

echo "✓ Helper script created: ~/add-client.sh"
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "✓ Setup Complete!"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Your OpenVPN server is ready to use!"
echo ""
echo "Summary:"
echo "  ✓ Server running on port $SERVER_PORT ($SERVER_PROTO)"
echo "  ✓ First client created: $CLIENT_NAME"
echo "  ✓ Config file ready: ~/client-configs/$CLIENT_NAME.ovpn"
echo "  ✓ Helper script created: ~/add-client.sh"
echo ""
echo "Next steps:"
echo "  1. Transfer $CLIENT_NAME.ovpn to your device securely"
echo "  2. Configure router port forwarding"
echo "  3. Test connection from client device"
echo "  4. Create clients for other devices using: ./add-client.sh"
echo ""
echo "Enjoy your secure VPN connection! 🔒"
echo ""
