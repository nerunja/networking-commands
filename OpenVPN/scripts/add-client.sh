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
