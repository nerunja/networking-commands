#!/bin/bash
# 05-generate-server-cert.sh - Generate server certificates
# Run as regular user (NOT with sudo)

set -e  # Exit on error

echo "╔════════════════════════════════════════════════════════════╗"
echo "║     Generate Server Certificates                           ║"
echo "║     Step 5 of 10: Create server cert, DH params, TLS key   ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Check if NOT running as root
if [ "$EUID" -eq 0 ]; then 
    echo "⚠️  Do NOT run this script with sudo!"
    echo "   Please run: ./05-generate-server-cert.sh"
    exit 1
fi

# Check if CA exists
if [ ! -f ~/openvpn-ca/pki/ca.crt ]; then
    echo "✗ Error: Certificate Authority not found!"
    echo "  Please run ./04-build-ca.sh first"
    exit 1
fi

cd ~/openvpn-ca

echo "═══════════════════════════════════════════════════════════"
echo "Generating server certificates and keys..."
echo "═══════════════════════════════════════════════════════════"
echo ""

# Generate server key and certificate request
echo "Step 1: Generating server certificate request..."
echo ""
echo "Common Name prompt: Just press Enter to accept 'server'"
echo ""

./easyrsa gen-req server nopass

echo ""
echo "✓ Server certificate request created"
echo ""

# Sign server certificate
echo "Step 2: Signing server certificate..."
echo ""
echo "You will be prompted for:"
echo "  1. Confirm details (type 'yes')"
echo "  2. CA password (the password you set in previous step)"
echo ""
echo "═══════════════════════════════════════════════════════════"

./easyrsa sign-req server server

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "✓ Server certificate signed"
echo ""

# Generate Diffie-Hellman parameters
echo "Step 3: Generating Diffie-Hellman parameters..."
echo ""
echo "⚠️  WARNING: This will take 5-30 minutes!"
echo "   This is CPU-intensive and normal."
echo "   You can monitor progress by watching CPU usage."
echo ""

read -p "Press Enter to start DH generation..."

echo ""
echo "Generating DH parameters (2048 bit)..."
echo "Please be patient, this takes time..."
echo ""

./easyrsa gen-dh

echo ""
echo "✓ Diffie-Hellman parameters generated"
echo ""

# Generate TLS authentication key
echo "Step 4: Generating TLS authentication key..."
openvpn --genkey secret ta.key
echo "✓ TLS authentication key generated"
echo ""

# Verify all files
echo "Step 5: Verifying server files..."
echo ""

if [ -f pki/ca.crt ]; then
    echo "  ✓ CA certificate: pki/ca.crt"
else
    echo "  ✗ Missing: pki/ca.crt"
    exit 1
fi

if [ -f pki/issued/server.crt ]; then
    echo "  ✓ Server certificate: pki/issued/server.crt"
else
    echo "  ✗ Missing: pki/issued/server.crt"
    exit 1
fi

if [ -f pki/private/server.key ]; then
    echo "  ✓ Server private key: pki/private/server.key"
else
    echo "  ✗ Missing: pki/private/server.key"
    exit 1
fi

if [ -f pki/dh.pem ]; then
    echo "  ✓ DH parameters: pki/dh.pem"
else
    echo "  ✗ Missing: pki/dh.pem"
    exit 1
fi

if [ -f ta.key ]; then
    echo "  ✓ TLS auth key: ta.key"
else
    echo "  ✗ Missing: ta.key"
    exit 1
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "✓ All server certificates and keys generated successfully!"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Generated files:"
echo "  • CA certificate"
echo "  • Server certificate (signed)"
echo "  • Server private key"
echo "  • Diffie-Hellman parameters"
echo "  • TLS authentication key"
echo ""
echo "Next steps:"
echo "  1. Run with sudo: sudo ./06-copy-server-files.sh"
echo ""
