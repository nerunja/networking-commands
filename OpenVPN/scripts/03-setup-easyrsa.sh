#!/bin/bash
# 03-setup-easyrsa.sh - Setup Easy-RSA and configure variables
# Run as regular user (NOT with sudo)

set -e  # Exit on error

echo "╔════════════════════════════════════════════════════════════╗"
echo "║     Easy-RSA Setup and Configuration                       ║"
echo "║     Step 3 of 10: Certificate Authority preparation        ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Check if NOT running as root
if [ "$EUID" -eq 0 ]; then 
    echo "⚠️  Do NOT run this script with sudo!"
    echo "   Please run: ./03-setup-easyrsa.sh"
    exit 1
fi

echo "This will set up Easy-RSA for certificate management."
echo ""

echo "═══════════════════════════════════════════════════════════"
echo "Setting up Easy-RSA..."
echo "═══════════════════════════════════════════════════════════"
echo ""

# Create Easy-RSA directory
echo "Step 1: Creating Easy-RSA directory..."
cd ~
make-cadir ~/openvpn-ca
echo "✓ Easy-RSA directory created at: ~/openvpn-ca"
echo ""

# Navigate to directory
cd ~/openvpn-ca

# Configure variables
echo "Step 2: Configuring Easy-RSA variables..."
echo ""

# Prompt for organization details
echo "Please provide your organization details:"
echo "(Press Enter to use default values shown in brackets)"
echo ""

read -p "Country (2 letter code) [IN]: " country
country=${country:-IN}

read -p "Province/State [Tamil Nadu]: " province
province=${province:-Tamil Nadu}

read -p "City [Chennai]: " city
city=${city:-Chennai}

read -p "Organization [HomeVPN]: " org
org=${org:-HomeVPN}

read -p "Email [admin@nerunja.mywire.org]: " email
email=${email:-admin@nerunja.mywire.org}

read -p "Organizational Unit [IT]: " ou
ou=${ou:-IT}

echo ""
echo "Writing configuration..."

# Create vars file
cat > vars << EOF
# Easy-RSA 3.x Variables Configuration
# Generated on: $(date)

# Organizational Information
set_var EASYRSA_REQ_COUNTRY    "$country"
set_var EASYRSA_REQ_PROVINCE   "$province"
set_var EASYRSA_REQ_CITY       "$city"
set_var EASYRSA_REQ_ORG        "$org"
set_var EASYRSA_REQ_EMAIL      "$email"
set_var EASYRSA_REQ_OU         "$ou"

# Key Settings
set_var EASYRSA_KEY_SIZE       2048
set_var EASYRSA_CA_EXPIRE      3650
set_var EASYRSA_CERT_EXPIRE    3650

# Cryptographic Settings
set_var EASYRSA_DIGEST         "sha256"

# Advanced Settings (optional)
# set_var EASYRSA_BATCH         "yes"
# set_var EASYRSA_REQ_CN        "HomeVPN-CA"
EOF

echo "✓ Variables configured"
echo ""

# Display configuration
echo "Step 3: Configuration summary:"
echo ""
echo "  Country:      $country"
echo "  Province:     $province"
echo "  City:         $city"
echo "  Organization: $org"
echo "  Email:        $email"
echo "  OU:           $ou"
echo ""
echo "  Key Size:     2048 bits"
echo "  Expiration:   3650 days (10 years)"
echo "  Digest:       SHA256"
echo ""

# Initialize PKI
echo "Step 4: Initializing PKI (Public Key Infrastructure)..."
./easyrsa init-pki
echo "✓ PKI initialized"
echo ""

# Verify structure
echo "Step 5: Verifying directory structure..."
echo ""
if [ -d "pki" ] && [ -f "easyrsa" ] && [ -f "vars" ]; then
    echo "✓ Easy-RSA structure verified:"
    echo "  • PKI directory: ~/openvpn-ca/pki"
    echo "  • Easy-RSA script: ~/openvpn-ca/easyrsa"
    echo "  • Variables file: ~/openvpn-ca/vars"
else
    echo "✗ Error: Easy-RSA structure incomplete!"
    exit 1
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "✓ Easy-RSA setup completed successfully!"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Next steps:"
echo "  1. Run as regular user: ./04-build-ca.sh"
echo "     You will be asked to set a CA password"
echo "     ⚠️  IMPORTANT: Save this password securely!"
echo ""
