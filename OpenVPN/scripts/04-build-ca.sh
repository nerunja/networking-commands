#!/bin/bash
# 04-build-ca.sh - Build Certificate Authority
# Run as regular user (NOT with sudo)

set -e  # Exit on error

echo "╔════════════════════════════════════════════════════════════╗"
echo "║     Build Certificate Authority (CA)                       ║"
echo "║     Step 4 of 10: Create CA with password protection       ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Check if NOT running as root
if [ "$EUID" -eq 0 ]; then 
    echo "⚠️  Do NOT run this script with sudo!"
    echo "   Please run: ./04-build-ca.sh"
    exit 1
fi

# Check if Easy-RSA is set up
if [ ! -d ~/openvpn-ca ]; then
    echo "✗ Error: Easy-RSA not found!"
    echo "  Please run ./03-setup-easyrsa.sh first"
    exit 1
fi

cd ~/openvpn-ca

echo "═══════════════════════════════════════════════════════════"
echo "Building Certificate Authority..."
echo "═══════════════════════════════════════════════════════════"
echo ""

echo "⚠️  IMPORTANT SECURITY INFORMATION"
echo ""
echo "You will be asked to create a password for the Certificate Authority."
echo "This password is required when:"
echo "  • Adding new VPN clients"
echo "  • Signing certificates"
echo "  • Revoking certificates"
echo ""
echo "Password requirements:"
echo "  • Use a STRONG password (at least 16 characters)"
echo "  • Include uppercase, lowercase, numbers, symbols"
echo "  • DO NOT use this password anywhere else"
echo "  • SAVE THIS PASSWORD SECURELY!"
echo ""
echo "Recommended: Use a password manager to generate and store it."
echo ""

read -p "Press Enter when ready to continue..."
echo ""

echo "Step 1: Building Certificate Authority..."
echo ""
echo "You will be prompted for:"
echo "  1. CA password (enter twice)"
echo "  2. Common Name (just press Enter to accept default)"
echo ""
echo "═══════════════════════════════════════════════════════════"

# Build CA with password
./easyrsa build-ca

echo ""
echo "═══════════════════════════════════════════════════════════"
echo ""

# Verify CA was created
if [ -f pki/ca.crt ] && [ -f pki/private/ca.key ]; then
    echo "✓ Certificate Authority created successfully!"
    echo ""
    echo "Step 2: Verifying CA certificate..."
    echo ""
    
    # Display CA details
    echo "CA Certificate Details:"
    openssl x509 -in pki/ca.crt -noout -subject -issuer -dates | sed 's/^/  /'
    
    echo ""
    echo "✓ CA certificate verified"
else
    echo "✗ Error: CA creation failed!"
    exit 1
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "✓ Certificate Authority built successfully!"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "⚠️  CRITICAL REMINDERS:"
echo ""
echo "  1. Your CA password is stored ONLY in your memory"
echo "  2. Save it in a password manager NOW"
echo "  3. Without this password, you CANNOT add new VPN clients"
echo "  4. There is NO way to recover this password if lost"
echo ""
echo "CA files created:"
echo "  • Certificate: ~/openvpn-ca/pki/ca.crt"
echo "  • Private key: ~/openvpn-ca/pki/private/ca.key (password protected)"
echo ""
echo "Next steps:"
echo "  1. Run as regular user: ./05-generate-server-cert.sh"
echo "     You will need your CA password"
echo ""
