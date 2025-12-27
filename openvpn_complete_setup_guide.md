# Complete OpenVPN Server Setup Guide - From Scratch

## Table of Contents
1. [Overview](#overview)
2. [Understanding Password Protection](#understanding-password-protection)
3. [Complete Cleanup](#complete-cleanup)
4. [Installation](#installation)
5. [Certificate Authority Setup](#certificate-authority-setup)
6. [Server Certificate Generation](#server-certificate-generation)
7. [Server Configuration](#server-configuration)
8. [Network Configuration](#network-configuration)
9. [Firewall Configuration](#firewall-configuration)
10. [Starting the Server](#starting-the-server)
11. [Client Certificate Generation](#client-certificate-generation)
12. [Client Configuration](#client-configuration)
13. [Router Port Forwarding](#router-port-forwarding)
14. [Testing and Verification](#testing-and-verification)
15. [Adding New Clients](#adding-new-clients)
16. [Troubleshooting](#troubleshooting)
17. [Maintenance](#maintenance)

---

## Overview

This guide provides a complete, step-by-step manual setup of an OpenVPN server with:

- **Secure CA with password protection** - Required when adding new VPN clients
- **Passwordless client certificates** - No password needed when connecting
- **DDNS support** - Use domain name instead of IP address
- **Complete manual configuration** - Full control over all settings

### Your Configuration
- **Domain:** nerunja.mywire.org
- **Current Public IP:** 117.192.213.198
- **VPN Network:** 10.8.0.0/24
- **Server IP (VPN):** 10.8.0.1
- **Protocol:** UDP
- **Port:** 1194

---

## Understanding Password Protection

### What the CA Password Does

**CA Password (Certificate Authority):**
- Protects your Certificate Authority private key
- Required **every time you sign a new certificate** (add new VPN client)
- Prevents unauthorized creation of valid VPN certificates
- **You WANT this** for security

**When you'll need the CA password:**
- Adding a new VPN client (laptop, phone, tablet)
- Signing certificates
- Revoking compromised certificates

### What Client Certificate Passwords Do

**Client Certificate Password:**
- Would be required **every time a client connects** to VPN
- Annoying for daily use
- **You DON'T want this** for convenience

### Recommended Setup (Used in This Guide)

✅ **CA with password** - Security when managing certificates  
✅ **Client certificates without password** - Convenience when connecting  

This is the perfect balance of security and usability!

---

## Complete Cleanup

Start with a clean slate by removing all previous OpenVPN configurations.

```bash
# Stop any running OpenVPN services
sudo systemctl stop openvpn-server@server 2>/dev/null
sudo systemctl disable openvpn-server@server 2>/dev/null
sudo killall openvpn 2>/dev/null

# Remove old server configurations
sudo rm -rf /etc/openvpn/server/*
sudo rm -rf /etc/openvpn/client/*

# Remove old Easy-RSA directory
sudo rm -rf ~/openvpn-ca

# Remove old client configs
sudo rm -rf ~/client-configs

# Remove old logs
sudo rm -rf /var/log/openvpn/*

# Clean up systemd
sudo systemctl daemon-reload

# Verify cleanup
echo "Checking for leftover files..."
ls /etc/openvpn/server/ 2>/dev/null || echo "✓ Server directory clean"
ls ~/openvpn-ca 2>/dev/null || echo "✓ Easy-RSA directory clean"

echo "✓ Complete cleanup done - ready for fresh installation"
```

---

## Installation

Install OpenVPN and Easy-RSA for certificate management.

```bash
# Update package list
sudo apt update

# Install OpenVPN and Easy-RSA
sudo apt install -y openvpn easy-rsa

# Verify installation
openvpn --version

# Expected output:
# OpenVPN 2.6.x x86_64-pc-linux-gnu

# Check Easy-RSA
ls /usr/share/easy-rsa/

echo "✓ Installation complete"
```

---

## Certificate Authority Setup

Create and configure the Certificate Authority (CA) that will sign all certificates.

### Create Easy-RSA Directory

```bash
# Create Easy-RSA directory structure
make-cadir ~/openvpn-ca

# Navigate to directory
cd ~/openvpn-ca

# Verify structure
ls -la
# You should see: easyrsa, vars, x509-types, etc.
```

### Configure Variables

```bash
# Edit the vars file
nano vars
```

**Add/modify these lines in the vars file:**

```bash
# Easy-RSA 3.x configuration

# Country, Province, City
set_var EASYRSA_REQ_COUNTRY    "IN"
set_var EASYRSA_REQ_PROVINCE   "Tamil Nadu"
set_var EASYRSA_REQ_CITY       "Chennai"

# Organization details
set_var EASYRSA_REQ_ORG        "HomeVPN"
set_var EASYRSA_REQ_EMAIL      "admin@nerunja.mywire.org"
set_var EASYRSA_REQ_OU         "IT Department"

# Key settings
set_var EASYRSA_KEY_SIZE       2048
set_var EASYRSA_CA_EXPIRE      3650    # 10 years
set_var EASYRSA_CERT_EXPIRE    3650    # 10 years

# Cryptographic digest
set_var EASYRSA_DIGEST         "sha256"
```

**Save and exit:** `Ctrl+O`, `Enter`, `Ctrl+X`

### Initialize PKI

```bash
# Initialize the Public Key Infrastructure
./easyrsa init-pki

# Expected output:
# init-pki complete; you may now create a CA or requests.

# Verify PKI directory created
ls -la pki/
```

### Build Certificate Authority (WITH PASSWORD)

```bash
# Build CA with password protection
./easyrsa build-ca

# You'll be prompted for:
# 1. Enter New CA Key Passphrase: [ENTER A STRONG PASSWORD]
# 2. Re-Enter New CA Key Passphrase: [ENTER SAME PASSWORD]
# 3. Common Name (eg: your name or server's hostname) [Easy-RSA CA]: 
#    [Press Enter or type: HomeVPN-CA]
```

**⚠️ IMPORTANT: Save your CA password securely!**

You'll need this password every time you:
- Create a new VPN client certificate
- Sign certificates
- Revoke certificates

```bash
# Verify CA was created
ls -la pki/ca.crt
ls -la pki/private/ca.key

# View CA certificate details
openssl x509 -in pki/ca.crt -text -noout | head -20

echo "✓ Certificate Authority created successfully"
```

---

## Server Certificate Generation

Generate certificates specifically for the VPN server.

### Generate Server Key and Certificate Request

```bash
# Make sure you're in the Easy-RSA directory
cd ~/openvpn-ca

# Generate server certificate request WITHOUT password
./easyrsa gen-req server nopass

# Prompts:
# Common Name (eg: your user, host, or server name) [server]:
# [Just press Enter or type: server]

# The 'nopass' means the server key won't be encrypted
# This is OK because the key file itself is protected by file permissions
```

### Sign Server Certificate

```bash
# Sign the server certificate
./easyrsa sign-req server server

# Prompts:
# 1. Confirm request details: yes [type 'yes']
# 2. Enter pass phrase for /home/user/openvpn-ca/pki/private/ca.key:
#    [ENTER YOUR CA PASSWORD]

# Expected output:
# Certificate created at: /home/user/openvpn-ca/pki/issued/server.crt
```

### Generate Diffie-Hellman Parameters

```bash
# Generate DH parameters (THIS TAKES 5-30 MINUTES)
./easyrsa gen-dh

# You'll see:
# Generating DH parameters, 2048 bit long safe prime
# This is going to take a long time
# .................+...........+.............

# Be patient! This is CPU-intensive
# You can monitor in another terminal with: top | grep openssl

# Expected output:
# DH parameters of size 2048 created at /home/user/openvpn-ca/pki/dh.pem
```

### Generate TLS Authentication Key

```bash
# Generate HMAC signature for additional security
openvpn --genkey secret ta.key

# Verify it was created
ls -la ta.key

# This adds an additional layer of security
# Packets without the proper HMAC signature are dropped immediately
```

### Verify All Server Files

```bash
# Check all required files exist
echo "Checking server certificate files..."

ls -lh pki/ca.crt           # Certificate Authority certificate
ls -lh pki/issued/server.crt  # Server certificate
ls -lh pki/private/server.key # Server private key
ls -lh pki/dh.pem           # Diffie-Hellman parameters
ls -lh ta.key               # TLS authentication key

echo "✓ All server certificate files created"
```

---

## Server Configuration

Copy certificates to OpenVPN directory and create server configuration.

### Copy Server Files

```bash
# Create OpenVPN server directory
sudo mkdir -p /etc/openvpn/server
sudo mkdir -p /var/log/openvpn

# Copy certificate and key files
sudo cp pki/ca.crt /etc/openvpn/server/
sudo cp pki/issued/server.crt /etc/openvpn/server/
sudo cp pki/private/server.key /etc/openvpn/server/
sudo cp pki/dh.pem /etc/openvpn/server/
sudo cp ta.key /etc/openvpn/server/

# Set proper permissions (CRITICAL for security)
sudo chmod 600 /etc/openvpn/server/server.key    # Private key - owner read/write only
sudo chmod 600 /etc/openvpn/server/ta.key        # TLS auth key - owner read/write only
sudo chmod 644 /etc/openvpn/server/ca.crt        # Public cert - readable
sudo chmod 644 /etc/openvpn/server/server.crt    # Public cert - readable
sudo chmod 644 /etc/openvpn/server/dh.pem        # DH params - readable

# Verify files and permissions
ls -lah /etc/openvpn/server/

echo "✓ Server files copied with proper permissions"
```

### Create Server Configuration File

```bash
# Create server configuration
sudo nano /etc/openvpn/server/server.conf
```

**Paste this complete configuration:**

```bash
########################################
# OpenVPN Server Configuration
########################################

# Network Settings
port 1194                      # OpenVPN port
proto udp                      # UDP protocol (faster than TCP)
dev tun                        # TUN device (routed IP tunnel)

# SSL/TLS Configuration
ca ca.crt                      # Certificate Authority certificate
cert server.crt                # Server certificate
key server.key                 # Server private key (keep secret!)
dh dh.pem                      # Diffie-Hellman parameters
tls-auth ta.key 0              # TLS authentication (0=server, 1=client)

# VPN Network Configuration
server 10.8.0.0 255.255.255.0  # VPN subnet
ifconfig-pool-persist /var/log/openvpn/ipp.txt  # Remember client IPs

# Push Routes and DNS to Clients
push "redirect-gateway def1 bypass-dhcp"  # Route all traffic through VPN
push "dhcp-option DNS 8.8.8.8"           # Google DNS primary
push "dhcp-option DNS 8.8.4.4"           # Google DNS secondary

# Client Configuration
client-to-client               # Allow clients to see each other
keepalive 10 120               # Ping every 10s, timeout after 120s

# Security Settings
cipher AES-256-GCM             # Encryption cipher
auth SHA256                    # HMAC authentication
data-ciphers AES-256-GCM:AES-128-GCM:AES-256-CBC  # Allowed ciphers

# Compression (optional - can improve speed)
compress lz4-v2                # LZ4 compression
push "compress lz4-v2"         # Push compression to clients

# User/Group (run with reduced privileges)
user nobody                    # Run as nobody user
group nogroup                  # Run as nogroup group

# Persistence Options
persist-key                    # Don't re-read keys on restart
persist-tun                    # Don't close/reopen TUN device on restart

# Logging
status /var/log/openvpn/openvpn-status.log  # Status log (shows connected clients)
log-append /var/log/openvpn/openvpn.log     # Server log
verb 3                                       # Verbosity level (0-9)

# Performance
max-clients 10                 # Maximum number of concurrent clients

# Explicit exit notification (UDP only)
explicit-exit-notify 1
```

**Save and exit:** `Ctrl+O`, `Enter`, `Ctrl+X`

### Verify Configuration Syntax

```bash
# Test configuration syntax (don't actually start server yet)
sudo openvpn --config /etc/openvpn/server/server.conf --verb 3 &
sleep 5
sudo killall openvpn

# Or just check the config loads
sudo openvpn --config /etc/openvpn/server/server.conf --test-crypto

echo "✓ Server configuration created"
```

---

## Network Configuration

Enable IP forwarding so the server can route traffic between VPN and internet.

### Enable IP Forwarding

```bash
# Create sysctl configuration for OpenVPN
sudo tee /etc/sysctl.d/99-openvpn.conf > /dev/null <<EOF
# Enable IP forwarding for OpenVPN
net.ipv4.ip_forward=1

# Optional: Enable IPv6 forwarding if needed
# net.ipv6.conf.all.forwarding=1
EOF

# Apply configuration immediately
sudo sysctl --system

# Verify IP forwarding is enabled (should return 1)
cat /proc/sys/net/ipv4/ip_forward

# Should show: 1

echo "✓ IP forwarding enabled"
```

### Verify Routing Configuration

```bash
# View current routing table
ip route show

# View default gateway
ip route | grep default

# Note your network interface (usually eth0, enp0s3, or wlan0)
# You'll need this for firewall configuration
```

---

## Firewall Configuration

Configure UFW (Uncomplicated Firewall) to allow VPN traffic and enable NAT.

### Identify Network Interface

```bash
# Get your default network interface
ip route | grep default

# Example output:
# default via 192.168.1.1 dev eth0 proto dhcp metric 100

# In this example, the interface is 'eth0'
# Common interfaces: eth0, enp0s3, wlan0, ens33

# Store it for next steps
INTERFACE=$(ip route | grep default | awk '{print $5}')
echo "Your network interface: $INTERFACE"
```

### Configure UFW NAT Rules

```bash
# Edit UFW before rules
sudo nano /etc/ufw/before.rules
```

**Add these lines at the VERY TOP of the file (before the *filter section):**

```bash
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

# IMPORTANT: Replace 'eth0' with YOUR network interface
# Use the interface from the previous step
-A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE

COMMIT
# END OPENVPN RULES

# Don't delete these required lines, or other rules will not be executed
*filter
```

**⚠️ CRITICAL: Replace `eth0` with your actual interface name!**

**Save and exit:** `Ctrl+O`, `Enter`, `Ctrl+X`

### Enable Forwarding in UFW

```bash
# Edit UFW default configuration
sudo nano /etc/default/ufw
```

**Find and change this line:**

```bash
# Change from:
DEFAULT_FORWARD_POLICY="DROP"

# Change to:
DEFAULT_FORWARD_POLICY="ACCEPT"
```

**Save and exit:** `Ctrl+O`, `Enter`, `Ctrl+X`

### Configure UFW Rules

```bash
# Allow OpenVPN port (UDP 1194)
sudo ufw allow 1194/udp comment 'OpenVPN'

# Allow SSH (if not already allowed)
sudo ufw allow 22/tcp comment 'SSH'

# Reload firewall to apply changes
sudo ufw disable
sudo ufw enable

# You'll see: "Firewall is active and enabled on system startup"

# Verify rules
sudo ufw status verbose

# Should show:
# 1194/udp    ALLOW IN    OpenVPN
# 22/tcp      ALLOW IN    SSH
```

### Verify NAT Configuration

```bash
# Check NAT rules
sudo iptables -t nat -L POSTROUTING -v -n

# Should show MASQUERADE rule for 10.8.0.0/24

# If needed, manually add NAT rule:
# sudo iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE

echo "✓ Firewall configured"
```

---

## Starting the Server

Start the OpenVPN server and enable it to run on boot.

### Start OpenVPN Server

```bash
# Start the OpenVPN server
sudo systemctl start openvpn-server@server

# Check status (should show "active (running)")
sudo systemctl status openvpn-server@server

# Look for these key indicators:
# Active: active (running)
# Status: "Initialization Sequence Completed"
```

### Enable Auto-Start on Boot

```bash
# Enable service to start automatically on boot
sudo systemctl enable openvpn-server@server

# Verify it's enabled
sudo systemctl is-enabled openvpn-server@server

# Should return: enabled

echo "✓ OpenVPN server started and enabled on boot"
```

### View Server Logs

```bash
# View last 50 lines of logs
sudo journalctl -u openvpn-server@server -n 50 --no-pager

# Real-time log monitoring
sudo journalctl -u openvpn-server@server -f

# Press Ctrl+C to stop monitoring

# View OpenVPN log file
sudo tail -f /var/log/openvpn/openvpn.log
```

### Verify Server is Running

```bash
# Check if tun0 interface was created
ip addr show tun0

# Should show:
# tun0: <POINTOPOINT,MULTICAST,NOARP,UP,LOWER_UP>
# inet 10.8.0.1/24 ...

# Check if server is listening on port 1194
sudo ss -tulpn | grep 1194

# Should show:
# udp   LISTEN  0.0.0.0:1194   *:*   users:(("openvpn",pid=...))

# Check OpenVPN status file
sudo cat /var/log/openvpn/openvpn-status.log

echo "✓ Server is running successfully"
```

---

## Client Certificate Generation

Create certificates for VPN clients (laptop, phone, etc.).

### Generate First Client Certificate

```bash
# Navigate to Easy-RSA directory
cd ~/openvpn-ca

# Generate client certificate request WITHOUT password
./easyrsa gen-req client1 nopass

# Prompts:
# Common Name (eg: your user, host, or server name) [client1]:
# [Just press Enter or type: client1]

# The 'nopass' means client won't need password to connect
```

### Sign Client Certificate

```bash
# Sign the client certificate
./easyrsa sign-req client client1

# Prompts:
# 1. Confirm request details: yes [type 'yes']
# 2. Enter pass phrase for /home/user/openvpn-ca/pki/private/ca.key:
#    [ENTER YOUR CA PASSWORD]

# Expected output:
# Certificate created at: /home/user/openvpn-ca/pki/issued/client1.crt
```

### Verify Client Certificate

```bash
# Check client certificate files
ls -lh pki/issued/client1.crt
ls -lh pki/private/client1.key

# Verify certificate details
openssl x509 -in pki/issued/client1.crt -text -noout | grep "Subject:"

# Verify cert and key match
CERT_HASH=$(openssl x509 -noout -modulus -in pki/issued/client1.crt | openssl md5)
KEY_HASH=$(openssl rsa -noout -modulus -in pki/private/client1.key 2>/dev/null | openssl md5)

echo "Certificate hash: $CERT_HASH"
echo "Private key hash: $KEY_HASH"

if [ "$CERT_HASH" = "$KEY_HASH" ]; then
    echo "✓ Certificate and key match perfectly"
else
    echo "✗ ERROR: Certificate and key do not match!"
fi
```

---

## Client Configuration

Create the .ovpn configuration file for clients.

### Prepare Client Files

```bash
# Create directory for client configurations
mkdir -p ~/client-configs/keys

# Copy client certificates and keys
cp pki/ca.crt ~/client-configs/keys/
cp pki/issued/client1.crt ~/client-configs/keys/
cp pki/private/client1.key ~/client-configs/keys/
cp ta.key ~/client-configs/keys/

# Verify files were copied
ls -lh ~/client-configs/keys/

echo "✓ Client files prepared"
```

### Create Client Configuration File

```bash
# Create client configuration with DDNS domain
cat > ~/client-configs/client1.ovpn << 'EOF'
##############################################
# OpenVPN Client Configuration
##############################################

client                         # Client mode
dev tun                        # TUN device
proto udp                      # UDP protocol

# Server Settings - Using DDNS domain
remote nerunja.mywire.org 1194

# Connection Settings
resolv-retry infinite          # Never give up trying to connect
nobind                         # Don't bind to specific local port

# Persistence
persist-key                    # Don't re-read keys on restart
persist-tun                    # Don't close/reopen TUN on restart

# Security
remote-cert-tls server         # Verify server certificate
cipher AES-256-GCM             # Encryption cipher
auth SHA256                    # HMAC authentication
key-direction 1                # TLS auth direction (opposite of server)

# Compression (must match server)
compress lz4-v2

# Logging
verb 3                         # Verbosity level

# Uncomment if you want to ignore server-pushed routes
# route-nopull

# Uncomment to use custom DNS instead of server-pushed
# dhcp-option DNS 8.8.8.8
EOF

echo "✓ Base client configuration created"
```

### Add Inline Certificates

```bash
# Add certificates inline to create single-file config
{
    echo ""
    echo "<ca>"
    cat ~/client-configs/keys/ca.crt
    echo "</ca>"
    echo ""
    echo "<cert>"
    cat ~/client-configs/keys/client1.crt
    echo "</cert>"
    echo ""
    echo "<key>"
    cat ~/client-configs/keys/client1.key
    echo "</key>"
    echo ""
    echo "<tls-auth>"
    cat ~/client-configs/keys/ta.key
    echo "</tls-auth>"
} >> ~/client-configs/client1.ovpn

echo "✓ Complete client configuration created: ~/client-configs/client1.ovpn"
```

### Verify Client Configuration

```bash
# Check file size (should be around 5-10KB)
ls -lh ~/client-configs/client1.ovpn

# Verify it contains all sections
grep -c "<ca>" ~/client-configs/client1.ovpn        # Should be 1
grep -c "<cert>" ~/client-configs/client1.ovpn      # Should be 1
grep -c "<key>" ~/client-configs/client1.ovpn       # Should be 1
grep -c "<tls-auth>" ~/client-configs/client1.ovpn  # Should be 1

# Check DDNS domain is present
grep "remote" ~/client-configs/client1.ovpn

# Should show: remote nerunja.mywire.org 1194

echo "✓ Client configuration verified"
```

---

## Router Port Forwarding

Configure your router to forward VPN traffic to your server.

### Port Forwarding Configuration

**You need to configure your router to forward UDP port 1194 to your Ubuntu server.**

#### Step 1: Find Your Server's Local IP

```bash
# Get your server's local IP address
hostname -I | awk '{print $1}'

# Or
ip addr show | grep "inet " | grep -v 127.0.0.1

# Example output: 192.168.1.100
# This is your server's LOCAL IP address
```

#### Step 2: Access Router Admin Panel

1. Open web browser
2. Go to router IP (usually `192.168.1.1` or `192.168.0.1`)
3. Login with router credentials

#### Step 3: Configure Port Forwarding

**Location varies by router, commonly found in:**
- Port Forwarding
- Virtual Server
- NAT
- Advanced Settings

**Add this rule:**

| Setting | Value |
|---------|-------|
| Service Name | OpenVPN |
| External Port | 1194 |
| Internal Port | 1194 |
| Internal IP | 192.168.1.100 (your server's local IP) |
| Protocol | UDP |
| Status | Enabled |

**Save/Apply changes**

### Verify Port Forwarding

```bash
# From an external network (mobile data, different network):
# Use online port checker tool

# Visit: https://www.yougetsignal.com/tools/open-ports/
# Or: https://canyouseeme.org/

# Enter:
# Address: nerunja.mywire.org
# Port: 1194
# Protocol: UDP

# Should show: "Port 1194 is open"
```

### Test DDNS Resolution

```bash
# Check if DDNS is working
nslookup nerunja.mywire.org

# Should show your public IP: 117.192.213.198

# Verify it matches your current public IP
curl -4 ifconfig.me

# Both should match

# Test from different locations
ping nerunja.mywire.org

echo "✓ DDNS and port forwarding configured"
```

---

## Testing and Verification

Test your VPN setup before deploying to clients.

### Server-Side Verification

```bash
# 1. Server Status
sudo systemctl status openvpn-server@server

# Should show: Active: active (running)

# 2. TUN Interface
ip addr show tun0

# Should show: 10.8.0.1/24

# 3. Listening Port
sudo ss -tulpn | grep 1194

# Should show OpenVPN listening on UDP 1194

# 4. IP Forwarding
cat /proc/sys/net/ipv4/ip_forward

# Should return: 1

# 5. NAT Rules
sudo iptables -t nat -L POSTROUTING -v -n

# Should show MASQUERADE rule

# 6. Firewall
sudo ufw status | grep 1194

# Should show: 1194/udp ALLOW OpenVPN

# 7. Recent Logs
sudo journalctl -u openvpn-server@server -n 20 --no-pager

# Should show: Initialization Sequence Completed
```

### Client Configuration Test

#### Transfer Client Config

```bash
# Option 1: Copy to USB drive
cp ~/client-configs/client1.ovpn /media/usb/

# Option 2: Transfer via SCP to another machine
scp ~/client-configs/client1.ovpn user@laptop:~/

# Option 3: Display as QR code (for mobile)
sudo apt install qrencode
cat ~/client-configs/client1.ovpn | qrencode -t UTF8

# Option 4: Email to yourself (if file is small enough)
# Or use file sharing service (encrypted)
```

#### Test from Client Device

**Linux Client:**
```bash
# Install OpenVPN
sudo apt install openvpn

# Connect using the config file
sudo openvpn --config client1.ovpn

# You should see:
# Initialization Sequence Completed

# Press Ctrl+C to disconnect
```

**Ubuntu Desktop (GUI):**
```bash
# Import the configuration
sudo nmcli connection import type openvpn file client1.ovpn

# Connect via Network Manager GUI
# Click Network icon → VPN → client1 → Connect

# Or connect via command line
nmcli connection up client1
```

**Windows:**
1. Download OpenVPN GUI from https://openvpn.net/community-downloads/
2. Install OpenVPN
3. Copy `client1.ovpn` to `C:\Program Files\OpenVPN\config\`
4. Run OpenVPN GUI as Administrator
5. Right-click system tray icon → Connect

**Android:**
1. Install "OpenVPN for Android" from Play Store
2. Open app → + → Import
3. Select `client1.ovpn` file
4. Tap to connect

**iOS:**
1. Install "OpenVPN Connect" from App Store
2. Transfer .ovpn file via iTunes/iCloud/Email
3. Open in OpenVPN Connect
4. Import and connect

### Verify Connection

**On Client Device:**

```bash
# Check VPN interface
ip addr show tun0

# Should show: 10.8.0.x (where x is 2-254)

# Ping VPN server
ping 10.8.0.1

# Should receive replies from server

# Check public IP (should show server's IP)
curl ifconfig.me

# Should show: 117.192.213.198 (your server's public IP)

# Test DNS resolution
nslookup google.com

# Should use VPN DNS (8.8.8.8)

# Trace route to verify traffic goes through VPN
traceroute 8.8.8.8
# or
mtr 8.8.8.8

# First hop should be 10.8.0.1
```

**On Server:**

```bash
# Check connected clients
sudo cat /var/log/openvpn/openvpn-status.log

# Look for CLIENT_LIST section showing connected clients

# Watch logs in real-time
sudo journalctl -u openvpn-server@server -f

# You should see:
# client1/117.x.x.x:port MULTI: Learn: 10.8.0.6 -> client1/117.x.x.x:port
```

### Performance Test

```bash
# On client, test download speed through VPN
wget -O /dev/null http://speedtest.tele2.net/100MB.zip

# Test ping latency
ping -c 10 8.8.8.8

# Test bandwidth
sudo apt install iperf3

# On server:
iperf3 -s

# On client:
iperf3 -c 10.8.0.1
```

---

## Adding New Clients

Easily add more VPN clients (laptop, phone, tablet, etc.).

### Manual Method

```bash
# Navigate to Easy-RSA directory
cd ~/openvpn-ca

# Replace 'laptop' with your client name
CLIENT_NAME="laptop"

# Generate certificate request
./easyrsa gen-req $CLIENT_NAME nopass

# Sign certificate (requires CA password)
./easyrsa sign-req client $CLIENT_NAME

# Copy certificates
cp pki/ca.crt ~/client-configs/keys/
cp pki/issued/$CLIENT_NAME.crt ~/client-configs/keys/
cp pki/private/$CLIENT_NAME.key ~/client-configs/keys/
cp ta.key ~/client-configs/keys/

# Create client config
cat > ~/client-configs/$CLIENT_NAME.ovpn << 'EOF'
client
dev tun
proto udp
remote nerunja.mywire.org 1194
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

echo "✓ Client $CLIENT_NAME created: ~/client-configs/$CLIENT_NAME.ovpn"
```

### Automated Script Method

**Create the script:**

```bash
nano ~/add-vpn-client.sh
```

**Paste this script:**

```bash
#!/bin/bash
# add-vpn-client.sh - Automated VPN client generation

CLIENT_NAME=$1

# Check if client name provided
if [ -z "$CLIENT_NAME" ]; then
    echo "Usage: ./add-vpn-client.sh <client-name>"
    echo ""
    echo "Examples:"
    echo "  ./add-vpn-client.sh laptop"
    echo "  ./add-vpn-client.sh phone"
    echo "  ./add-vpn-client.sh tablet"
    exit 1
fi

# Navigate to Easy-RSA directory
cd ~/openvpn-ca || exit 1

echo "========================================="
echo "Adding VPN Client: $CLIENT_NAME"
echo "========================================="
echo ""

# Generate certificate request
echo "Step 1: Generating certificate request..."
./easyrsa gen-req "$CLIENT_NAME" nopass

echo ""
echo "Step 2: Signing certificate (requires CA password)..."
./easyrsa sign-req client "$CLIENT_NAME"

# Create client configs directory
mkdir -p ~/client-configs/keys

# Copy certificates
echo ""
echo "Step 3: Copying certificates..."
cp pki/ca.crt ~/client-configs/keys/
cp "pki/issued/$CLIENT_NAME.crt" ~/client-configs/keys/
cp "pki/private/$CLIENT_NAME.key" ~/client-configs/keys/
cp ta.key ~/client-configs/keys/

# Create client configuration
echo ""
echo "Step 4: Creating client configuration..."
cat > ~/client-configs/$CLIENT_NAME.ovpn << 'EOF'
client
dev tun
proto udp
remote nerunja.mywire.org 1194
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

echo ""
echo "========================================="
echo "✓ SUCCESS!"
echo "========================================="
echo ""
echo "Client configuration created:"
echo "  ~/client-configs/$CLIENT_NAME.ovpn"
echo ""
echo "Transfer this file to your device and import it."
echo ""
echo "File size: $(du -h ~/client-configs/$CLIENT_NAME.ovpn | cut -f1)"
echo "========================================="
```

**Make it executable:**

```bash
chmod +x ~/add-vpn-client.sh
```

**Usage:**

```bash
# Add new clients
~/add-vpn-client.sh laptop
~/add-vpn-client.sh phone
~/add-vpn-client.sh tablet
~/add-vpn-client.sh work-laptop

# You'll need to enter CA password for each client
```

### List All Clients

```bash
# List all issued certificates
ls -la ~/openvpn-ca/pki/issued/

# List all client configs
ls -lh ~/client-configs/*.ovpn

# View currently connected clients
sudo cat /var/log/openvpn/openvpn-status.log | grep CLIENT_LIST
```

---

## Troubleshooting

Common issues and their solutions.

### Server Won't Start

```bash
# Check detailed error messages
sudo journalctl -u openvpn-server@server -n 100 --no-pager

# Test configuration syntax
sudo openvpn --config /etc/openvpn/server/server.conf

# Common issues:

# 1. Port already in use
sudo ss -tulpn | grep 1194
# Kill conflicting process
sudo killall openvpn

# 2. Missing certificate files
ls -la /etc/openvpn/server/

# 3. Wrong file permissions
sudo chmod 600 /etc/openvpn/server/server.key
sudo chmod 600 /etc/openvpn/server/ta.key

# 4. Configuration syntax error
sudo nano /etc/openvpn/server/server.conf
# Check for typos, especially in file paths
```

### Client Can't Connect

```bash
# Server side checks:

# 1. Server running?
sudo systemctl status openvpn-server@server

# 2. Firewall allows port?
sudo ufw status | grep 1194

# 3. Port forwarding configured?
# Check router settings

# 4. DDNS resolving correctly?
nslookup nerunja.mywire.org

# Client side checks:

# 1. Verify server address
grep "remote" client1.ovpn

# 2. Check client logs
sudo openvpn --config client1.ovpn --verb 4

# 3. Test with public IP instead of domain
# Edit .ovpn file: remote 117.192.213.198 1194

# 4. Try TCP instead of UDP (if UDP is blocked)
# Server: change to 'proto tcp' and restart
# Client: change to 'proto tcp' in .ovpn
```

### No Internet Through VPN

```bash
# Check IP forwarding
cat /proc/sys/net/ipv4/ip_forward
# Should return 1

# Check NAT rules
sudo iptables -t nat -L POSTROUTING -v -n
# Should show MASQUERADE rule

# Manually add NAT if missing
sudo iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE

# Make persistent
sudo apt install iptables-persistent
sudo netfilter-persistent save

# Test from client
ping 10.8.0.1  # Ping VPN server
ping 8.8.8.8   # Ping internet
```

### DNS Not Working

```bash
# Server side - check DNS push
grep "push \"dhcp-option DNS" /etc/openvpn/server/server.conf

# Should show:
# push "dhcp-option DNS 8.8.8.8"
# push "dhcp-option DNS 8.8.4.4"

# Client side - check DNS
cat /etc/resolv.conf

# Test DNS
nslookup google.com

# Force DNS in client config
# Add to .ovpn file:
# dhcp-option DNS 8.8.8.8
# dhcp-option DNS 8.8.4.4
```

### Certificate Errors

```bash
# Verify certificate and key match
CERT_HASH=$(openssl x509 -noout -modulus -in client1.crt | openssl md5)
KEY_HASH=$(openssl rsa -noout -modulus -in client1.key | openssl md5)

echo "Cert: $CERT_HASH"
echo "Key:  $KEY_HASH"
# Should be identical

# Check certificate expiration
openssl x509 -in client1.crt -noout -dates

# Regenerate if needed
cd ~/openvpn-ca
./easyrsa revoke client1
./easyrsa gen-req client1 nopass
./easyrsa sign-req client client1
```

### Connection Drops

```bash
# Increase keepalive
# Edit server.conf:
keepalive 10 60

# Use TCP instead of UDP
proto tcp

# Adjust MTU
# Add to client config:
mssfix 1400
```

### Slow Performance

```bash
# Disable compression
# Comment out in server.conf:
# compress lz4-v2

# Use faster cipher
cipher AES-128-GCM

# Check server resources
top
htop

# Check bandwidth
iperf3 -s  # On server
iperf3 -c 10.8.0.1  # On client
```

---

## Maintenance

### View Logs

```bash
# Real-time server logs
sudo journalctl -u openvpn-server@server -f

# Last 100 lines
sudo journalctl -u openvpn-server@server -n 100

# OpenVPN log file
sudo tail -f /var/log/openvpn/openvpn.log

# Status file (connected clients)
sudo cat /var/log/openvpn/openvpn-status.log

# Search logs for specific client
sudo grep "client1" /var/log/openvpn/openvpn.log
```

### Monitor Connected Clients

```bash
# View connected clients
sudo cat /var/log/openvpn/openvpn-status.log

# Parse and display nicely
sudo cat /var/log/openvpn/openvpn-status.log | grep "CLIENT_LIST" | awk -F',' '{printf "%-20s %-15s %-20s %s\n", $2, $3, $4, $5}'

# Count connected clients
sudo cat /var/log/openvpn/openvpn-status.log | grep -c "CLIENT_LIST"
```

### Revoke Client Certificate

```bash
# Navigate to Easy-RSA
cd ~/openvpn-ca

# Revoke certificate (e.g., lost phone)
./easyrsa revoke client1

# Generate Certificate Revocation List
./easyrsa gen-crl

# Copy CRL to server
sudo cp pki/crl.pem /etc/openvpn/server/

# Add to server.conf
sudo nano /etc/openvpn/server/server.conf
# Add line:
crl-verify crl.pem

# Restart server
sudo systemctl restart openvpn-server@server

# The revoked certificate will no longer be able to connect
```

### Backup Configuration

```bash
# Create backup directory
mkdir -p ~/openvpn-backup

# Backup Easy-RSA (certificates)
tar -czf ~/openvpn-backup/openvpn-ca-$(date +%Y%m%d).tar.gz ~/openvpn-ca

# Backup server configuration
sudo tar -czf ~/openvpn-backup/openvpn-server-$(date +%Y%m%d).tar.gz /etc/openvpn/server

# Backup client configurations
tar -czf ~/openvpn-backup/client-configs-$(date +%Y%m%d).tar.gz ~/client-configs

# List backups
ls -lh ~/openvpn-backup/

# Copy backups to external drive or cloud storage
```

### Restore from Backup

```bash
# Stop server
sudo systemctl stop openvpn-server@server

# Restore Easy-RSA
tar -xzf ~/openvpn-backup/openvpn-ca-20241227.tar.gz -C ~/

# Restore server config
sudo tar -xzf ~/openvpn-backup/openvpn-server-20241227.tar.gz -C /

# Restart server
sudo systemctl start openvpn-server@server
```

### Update OpenVPN

```bash
# Update package list
sudo apt update

# Upgrade OpenVPN
sudo apt upgrade openvpn

# Check new version
openvpn --version

# Restart service
sudo systemctl restart openvpn-server@server
```

### Renew Certificates

```bash
# Check certificate expiration
cd ~/openvpn-ca
openssl x509 -in pki/issued/server.crt -noout -dates

# To renew, generate new certificates
./easyrsa gen-req server-new nopass
./easyrsa sign-req server server-new

# Copy to server directory
sudo cp pki/issued/server-new.crt /etc/openvpn/server/server.crt
sudo cp pki/private/server-new.key /etc/openvpn/server/server.key

# Restart server
sudo systemctl restart openvpn-server@server
```

### Log Rotation

```bash
# Create logrotate config
sudo nano /etc/logrotate.d/openvpn
```

**Add:**

```bash
/var/log/openvpn/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 640 root root
    sharedscripts
    postrotate
        systemctl reload openvpn-server@server > /dev/null 2>&1 || true
    endscript
}
```

### Performance Monitoring

```bash
# Install monitoring tools
sudo apt install iftop nethogs vnstat

# Monitor VPN interface bandwidth
sudo iftop -i tun0

# Monitor per-process network usage
sudo nethogs tun0

# Network statistics
vnstat -i tun0
vnstat -i tun0 -l  # Live traffic
```

---

## Quick Reference Commands

### Server Management

```bash
# Start server
sudo systemctl start openvpn-server@server

# Stop server
sudo systemctl stop openvpn-server@server

# Restart server
sudo systemctl restart openvpn-server@server

# Check status
sudo systemctl status openvpn-server@server

# View logs
sudo journalctl -u openvpn-server@server -f

# Enable auto-start
sudo systemctl enable openvpn-server@server

# Disable auto-start
sudo systemctl disable openvpn-server@server
```

### Client Management

```bash
# Add new client
cd ~/openvpn-ca
./easyrsa gen-req clientname nopass
./easyrsa sign-req client clientname

# List all clients
ls ~/openvpn-ca/pki/issued/

# Revoke client
./easyrsa revoke clientname
./easyrsa gen-crl
sudo cp pki/crl.pem /etc/openvpn/server/

# View connected clients
sudo cat /var/log/openvpn/openvpn-status.log
```

### Troubleshooting

```bash
# Check if server is running
sudo systemctl status openvpn-server@server

# Check TUN interface
ip addr show tun0

# Check listening port
sudo ss -tulpn | grep 1194

# Check IP forwarding
cat /proc/sys/net/ipv4/ip_forward

# Check NAT rules
sudo iptables -t nat -L POSTROUTING

# Check firewall
sudo ufw status

# Test DNS
nslookup nerunja.mywire.org

# Test configuration
sudo openvpn --config /etc/openvpn/server/server.conf
```

---

## Security Checklist

- [x] CA password protected
- [x] Client certificates without password (for convenience)
- [x] Strong encryption (AES-256-GCM)
- [x] TLS authentication enabled
- [x] Server runs as nobody:nogroup
- [x] Proper file permissions (600 for keys)
- [x] Firewall configured
- [x] Only necessary ports open
- [x] DDNS for dynamic IP
- [x] Logging enabled
- [x] CRL support configured
- [x] Regular backups
- [x] Certificate expiration monitoring

---

## Summary

### What You Have Now

✅ **Fully functional OpenVPN server**  
✅ **CA with password protection** - Required when adding new clients  
✅ **Passwordless client certificates** - No password when connecting  
✅ **DDNS integration** - Use nerunja.mywire.org instead of IP  
✅ **Complete manual setup** - Full control over configuration  
✅ **Automated client generation script** - Easy to add new devices  
✅ **Proper security** - Strong encryption and authentication  

### Your VPN Details

- **Server Domain:** nerunja.mywire.org
- **Port:** 1194 UDP
- **VPN Network:** 10.8.0.0/24
- **Server VPN IP:** 10.8.0.1
- **DNS Servers:** 8.8.8.8, 8.8.4.4
- **Encryption:** AES-256-GCM
- **Authentication:** SHA256

### Next Steps

1. **Test the VPN** from a client device
2. **Create additional client certificates** for other devices
3. **Set up regular backups** of certificates and configuration
4. **Monitor logs** for security and troubleshooting
5. **Update regularly** to keep software current

---

## Additional Resources

### Official Documentation
- **OpenVPN**: https://openvpn.net/community-resources/
- **Easy-RSA**: https://easy-rsa.readthedocs.io/
- **Ubuntu Server Guide**: https://ubuntu.com/server/docs

### Community Support
- **OpenVPN Forum**: https://forums.openvpn.net/
- **Ubuntu Forums**: https://ubuntuforums.org/
- **Reddit**: r/OpenVPN

### Security Resources
- **CVE Database**: https://cve.mitre.org/
- **OpenVPN Security**: https://openvpn.net/security/
- **Best Practices**: https://openvpn.net/community-resources/reference-manual-for-openvpn-2-6/

---

**Last Updated:** December 27, 2024  
**OpenVPN Version:** 2.6.x  
**Compatible With:** Ubuntu 22.04 LTS, 24.04 LTS  

---

*This guide provides a complete manual setup of OpenVPN with proper security and DDNS integration. Always keep your CA password secure and back up your certificates regularly.*
