# Comprehensive OpenVPN Guide for Ubuntu Linux

## Table of Contents
1. [Introduction](#introduction)
2. [Installation](#installation)
3. [OpenVPN Client Setup](#openvpn-client-setup)
4. [OpenVPN Server Setup](#openvpn-server-setup)
5. [Certificate Management](#certificate-management)
6. [Configuration Options](#configuration-options)
7. [Security Hardening](#security-hardening)
8. [Client Configurations](#client-configurations)
9. [Troubleshooting](#troubleshooting)
10. [Advanced Configurations](#advanced-configurations)
11. [Monitoring and Logging](#monitoring-and-logging)
12. [Platform-Specific Clients](#platform-specific-clients)
13. [Practical Examples](#practical-examples)

---

## Introduction

OpenVPN is a robust, open-source VPN solution that creates secure point-to-point or site-to-site connections. It uses SSL/TLS for key exchange and can traverse firewalls and NAT.

### Key Features
- **Strong encryption**: AES-256, RSA-4096
- **Cross-platform**: Linux, Windows, macOS, iOS, Android
- **Flexible authentication**: Certificates, username/password, 2FA
- **NAT-friendly**: Works through firewalls and NAT
- **Scalable**: Suitable for both small home setups and enterprise deployments

### Use Cases
- Secure remote access to home/office network
- Bypass geo-restrictions and censorship
- Protect traffic on public WiFi
- Site-to-site VPN tunnels
- Secure access to cloud resources

---

## Installation

### Ubuntu Desktop/Server

```bash
# Update package list
sudo apt update

# Install OpenVPN
sudo apt install openvpn

# Install Network Manager integration (Desktop only)
sudo apt install network-manager-openvpn network-manager-openvpn-gnome

# Install Easy-RSA for certificate management
sudo apt install easy-rsa

# Verify installation
openvpn --version
```

### Install from Official Repository (Latest Version)

```bash
# Add OpenVPN repository
wget -O - https://swupdate.openvpn.net/repos/repo-public.gpg | sudo apt-key add -
echo "deb http://build.openvpn.net/debian/openvpn/stable $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/openvpn.list

# Update and install
sudo apt update
sudo apt install openvpn

# Verify version
openvpn --version
```

### Additional Tools

```bash
# For monitoring
sudo apt install iftop nethogs

# For DNS management
sudo apt install resolvconf

# For compression support
sudo apt install lz4 liblz4-tool
```

---

## OpenVPN Client Setup

### Method 1: Network Manager GUI (Easiest for Desktop)

#### Import .ovpn Configuration File

```bash
# Via GUI
# 1. Click Network icon in system tray
# 2. Settings → Network → VPN → + (Add VPN)
# 3. Select "Import from file..."
# 4. Browse to your .ovpn file
# 5. Enter credentials if prompted
# 6. Click "Add" or "Save"

# Via command line
sudo nmcli connection import type openvpn file /path/to/config.ovpn

# List imported VPN connections
nmcli connection show

# Connect to VPN
nmcli connection up "VPN-Connection-Name"

# Disconnect
nmcli connection down "VPN-Connection-Name"

# Delete VPN connection
nmcli connection delete "VPN-Connection-Name"
```

#### Manual Configuration in Network Manager

1. **Open Network Settings**
   - Settings → Network → VPN → + → OpenVPN

2. **Basic Configuration**:
   ```
   Gateway: vpn.example.com (or IP address)
   Type: Password / Certificates / Password with Certificates
   Username: your_username (if required)
   Password: your_password (if required)
   ```

3. **Advanced Settings**:
   - **General**: Use compression, custom key size
   - **Security**: Cipher, HMAC authentication
   - **TLS Settings**: TLS mode, verify peer certificate
   - **IPv4/IPv6**: DNS servers, routes

### Method 2: Command Line (Full Control)

#### Basic Connection

```bash
# Connect using .ovpn file
sudo openvpn --config /path/to/config.ovpn

# Connect with authentication file
sudo openvpn --config config.ovpn --auth-user-pass credentials.txt

# Run in background (daemon mode)
sudo openvpn --config config.ovpn --daemon

# With custom log file
sudo openvpn --config config.ovpn --log /var/log/openvpn-client.log

# Specify custom DNS
sudo openvpn --config config.ovpn --dhcp-option DNS 8.8.8.8 --dhcp-option DNS 8.8.4.4
```

#### Create Authentication File

```bash
# Create credentials file (username and password)
cat > ~/vpn-credentials.txt << EOF
your_username
your_password
EOF

# Secure the file
chmod 600 ~/vpn-credentials.txt

# Reference in .ovpn file
# Add this line to your .ovpn configuration:
auth-user-pass /home/yourusername/vpn-credentials.txt
```

### Method 3: Systemd Service (Auto-start on Boot)

```bash
# Create directory for client configs
sudo mkdir -p /etc/openvpn/client

# Copy your configuration (remove .ovpn extension)
sudo cp your-config.ovpn /etc/openvpn/client/your-config.conf

# Start the VPN
sudo systemctl start openvpn-client@your-config

# Enable auto-start on boot
sudo systemctl enable openvpn-client@your-config

# Check status
sudo systemctl status openvpn-client@your-config

# View logs
sudo journalctl -u openvpn-client@your-config -f

# Stop VPN
sudo systemctl stop openvpn-client@your-config

# Disable auto-start
sudo systemctl disable openvpn-client@your-config

# Restart VPN
sudo systemctl restart openvpn-client@your-config
```

### Managing Multiple VPN Configurations

```bash
# List all VPN configurations
ls /etc/openvpn/client/

# Show active OpenVPN connections
systemctl list-units | grep openvpn

# Connect to specific VPN
sudo systemctl start openvpn-client@work-vpn
sudo systemctl start openvpn-client@home-vpn

# Switch between VPNs
sudo systemctl stop openvpn-client@work-vpn
sudo systemctl start openvpn-client@home-vpn

# Status of all OpenVPN services
systemctl status 'openvpn-client@*'
```

### Verify VPN Connection

```bash
# Check your IP before connecting
curl ifconfig.me
curl ipinfo.io

# Connect to VPN, then check again
curl ifconfig.me

# Check VPN interface
ip addr show tun0

# View routing table
ip route show

# Check DNS resolution
nslookup google.com
dig google.com

# DNS leak test
curl https://www.dnsleaktest.com/

# Detailed connection info
ip -s link show tun0

# Test with specific DNS server
nslookup google.com 8.8.8.8

# Check if traffic is going through VPN
traceroute 8.8.8.8
mtr 8.8.8.8
```

---

## OpenVPN Server Setup

### Quick Setup with Script (Recommended for Home/Small Office)

```bash
# Download OpenVPN installation script
wget https://git.io/vpn -O openvpn-install.sh

# Make executable
chmod +x openvpn-install.sh

# Run the script
sudo ./openvpn-install.sh
```

**Script will prompt for:**
- IP address or hostname (auto-detected)
- Protocol: UDP (faster) or TCP (more reliable through firewalls)
- Port: 1194 (default) or custom
- DNS server: Google (8.8.8.8), Cloudflare (1.1.1.1), or custom
- Client name

**Script features:**
- Automatic certificate generation
- Firewall configuration
- Client .ovpn file creation
- Easy client management (add/remove)
- Server uninstallation option

**Managing clients with script:**
```bash
# Run script again to manage
sudo ./openvpn-install.sh

# Options:
# 1) Add a new client
# 2) Revoke an existing client
# 3) Remove OpenVPN
# 4) Exit
```

### Manual Server Setup (Complete Control)

#### Step 1: Install OpenVPN and Easy-RSA

```bash
# Install packages
sudo apt update
sudo apt install openvpn easy-rsa

# Create CA directory
make-cadir ~/openvpn-ca
cd ~/openvpn-ca

# Alternative: Copy Easy-RSA
mkdir ~/easy-rsa
cp -r /usr/share/easy-rsa/* ~/easy-rsa/
cd ~/easy-rsa
```

#### Step 2: Configure Certificate Authority Variables

```bash
# Edit vars file
nano vars
```

**Configure these variables:**
```bash
# Easy-RSA 3.x format
set_var EASYRSA_REQ_COUNTRY    "IN"
set_var EASYRSA_REQ_PROVINCE   "Tamil Nadu"
set_var EASYRSA_REQ_CITY       "Chennai"
set_var EASYRSA_REQ_ORG        "HomeVPN"
set_var EASYRSA_REQ_EMAIL      "admin@itekk.in"
set_var EASYRSA_REQ_OU         "IT Department"
set_var EASYRSA_KEY_SIZE       4096
set_var EASYRSA_CA_EXPIRE      3650
set_var EASYRSA_CERT_EXPIRE    3650

# Cryptographic settings
set_var EASYRSA_DIGEST         "sha512"
```

#### Step 3: Build Certificate Authority (CA)

```bash
# Initialize PKI
./easyrsa init-pki

# Build CA (you'll be asked for a passphrase - optional but recommended)
./easyrsa build-ca nopass

# Or with passphrase protection
./easyrsa build-ca
# Enter and confirm CA passphrase
```

#### Step 4: Generate Server Certificate and Key

```bash
# Generate server key and certificate request
./easyrsa gen-req server nopass

# Sign the server certificate
./easyrsa sign-req server server

# Verify certificate
openssl x509 -in pki/issued/server.crt -text -noout
```

#### Step 5: Generate Diffie-Hellman Parameters

```bash
# Generate DH parameters (this takes time - 5-30 minutes)
./easyrsa gen-dh

# Monitor progress in another terminal
top | grep openssl
```

#### Step 6: Generate TLS Authentication Key

```bash
# Generate HMAC key for additional security
openvpn --genkey secret ta.key

# Or use tls-crypt (recommended over tls-auth)
openvpn --genkey secret tls-crypt.key
```

#### Step 7: Generate Client Certificates

```bash
# Generate client certificate (no password)
./easyrsa gen-req client1 nopass

# Sign client certificate
./easyrsa sign-req client client1

# Repeat for additional clients
./easyrsa gen-req client2 nopass
./easyrsa sign-req client client2
```

#### Step 8: Copy Files to OpenVPN Directory

```bash
# Create directories
sudo mkdir -p /etc/openvpn/server
sudo mkdir -p /etc/openvpn/client/keys
sudo mkdir -p /var/log/openvpn

# Copy server files
sudo cp pki/ca.crt /etc/openvpn/server/
sudo cp pki/issued/server.crt /etc/openvpn/server/
sudo cp pki/private/server.key /etc/openvpn/server/
sudo cp pki/dh.pem /etc/openvpn/server/
sudo cp ta.key /etc/openvpn/server/

# Set permissions
sudo chmod 600 /etc/openvpn/server/server.key
sudo chmod 600 /etc/openvpn/server/ta.key

# Copy client files for later distribution
sudo cp pki/ca.crt /etc/openvpn/client/keys/
sudo cp pki/issued/client1.crt /etc/openvpn/client/keys/
sudo cp pki/private/client1.key /etc/openvpn/client/keys/
sudo cp ta.key /etc/openvpn/client/keys/
```

#### Step 9: Create Server Configuration

```bash
# Copy sample configuration
sudo cp /usr/share/doc/openvpn/examples/sample-config-files/server.conf /etc/openvpn/server/

# Edit configuration
sudo nano /etc/openvpn/server/server.conf
```

**Basic Server Configuration:**
```bash
# Network settings
port 1194
proto udp
dev tun

# Certificates and keys
ca ca.crt
cert server.crt
key server.key
dh dh.pem

# TLS authentication
tls-auth ta.key 0
# Or use tls-crypt (recommended)
# tls-crypt tls-crypt.key

# VPN subnet
server 10.8.0.0 255.255.255.0

# Maintain client IP assignments
ifconfig-pool-persist /var/log/openvpn/ipp.txt

# Push routes to clients
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DNS 8.8.4.4"

# Alternative DNS (Cloudflare)
# push "dhcp-option DNS 1.1.1.1"
# push "dhcp-option DNS 1.0.0.1"

# Enable client-to-client communication
client-to-client

# Keep connection alive
keepalive 10 120

# Compression (choose one)
compress lz4-v2
push "compress lz4-v2"
# Or
# comp-lzo
# push "comp-lzo"

# Security settings
cipher AES-256-GCM
auth SHA512
tls-version-min 1.2

# Maximum number of clients
max-clients 10

# Run with reduced privileges
user nobody
group nogroup

# Persist keys and tunnel
persist-key
persist-tun

# Logging
status /var/log/openvpn/openvpn-status.log
log-append /var/log/openvpn/openvpn.log
verb 3

# Explicit exit notify (for UDP only)
explicit-exit-notify 1
```

**Advanced Server Configuration Options:**
```bash
# Custom port
port 443
proto tcp

# Specific network interface
local 192.168.1.100

# Duplicate CN (allow same cert for multiple connections)
duplicate-cn

# Client-specific configurations
client-config-dir /etc/openvpn/ccd

# Topology (subnet is recommended)
topology subnet

# IPv6 support
server-ipv6 fd00:8::/64
push "route-ipv6 2000::/3"

# Management interface
management localhost 7505

# Custom routes
push "route 192.168.2.0 255.255.255.0"

# Block outside DNS
push "block-outside-dns"

# Push specific domain suffix
push "dhcp-option DOMAIN example.com"

# Connection scripts
script-security 2
up /etc/openvpn/scripts/up.sh
down /etc/openvpn/scripts/down.sh
client-connect /etc/openvpn/scripts/client-connect.sh
client-disconnect /etc/openvpn/scripts/client-disconnect.sh
```

#### Step 10: Enable IP Forwarding

```bash
# Edit sysctl configuration
sudo nano /etc/sysctl.conf

# Uncomment or add:
net.ipv4.ip_forward=1

# For IPv6 (if needed)
net.ipv6.conf.all.forwarding=1

# Apply changes
sudo sysctl -p

# Verify
cat /proc/sys/net/ipv4/ip_forward  # Should return 1
```

#### Step 11: Configure Firewall

**Using UFW (Uncomplicated Firewall):**

```bash
# Allow OpenVPN through firewall
sudo ufw allow 1194/udp
# Or for TCP
# sudo ufw allow 1194/tcp

# Get your default network interface
ip route | grep default
# Example output: default via 192.168.1.1 dev eth0

# Edit UFW before rules
sudo nano /etc/ufw/before.rules
```

**Add NAT rules at the top:**
```bash
# NAT table rules
*nat
:POSTROUTING ACCEPT [0:0]

# Replace eth0 with your interface
-A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE

COMMIT
```

**Enable packet forwarding in UFW:**
```bash
sudo nano /etc/default/ufw

# Change to:
DEFAULT_FORWARD_POLICY="ACCEPT"
```

**Reload UFW:**
```bash
sudo ufw disable
sudo ufw enable

# Check status
sudo ufw status verbose
```

**Using iptables directly:**

```bash
# Enable NAT (replace eth0 with your interface)
sudo iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE

# Allow forwarding from tun0 to eth0
sudo iptables -A FORWARD -i tun0 -o eth0 -j ACCEPT
sudo iptables -A FORWARD -i eth0 -o tun0 -m state --state RELATED,ESTABLISHED -j ACCEPT

# Allow OpenVPN port
sudo iptables -A INPUT -p udp --dport 1194 -j ACCEPT

# Save rules
sudo apt install iptables-persistent
sudo netfilter-persistent save
```

#### Step 12: Start OpenVPN Server

```bash
# Start server
sudo systemctl start openvpn-server@server

# Enable on boot
sudo systemctl enable openvpn-server@server

# Check status
sudo systemctl status openvpn-server@server

# View logs
sudo journalctl -u openvpn-server@server -f

# Real-time log monitoring
sudo tail -f /var/log/openvpn/openvpn.log

# Check if tun0 interface is up
ip addr show tun0

# Verify server is listening
sudo netstat -tulpn | grep 1194
sudo ss -tulpn | grep 1194
```

---

## Certificate Management

### Creating Additional Client Certificates

```bash
# Navigate to Easy-RSA directory
cd ~/openvpn-ca

# Generate new client key and request
./easyrsa gen-req client3 nopass

# Sign the certificate
./easyrsa sign-req client client3

# Copy to appropriate location
sudo cp pki/issued/client3.crt /etc/openvpn/client/keys/
sudo cp pki/private/client3.key /etc/openvpn/client/keys/
```

### Revoking Client Certificates

```bash
# Revoke certificate
cd ~/openvpn-ca
./easyrsa revoke client1

# Generate Certificate Revocation List (CRL)
./easyrsa gen-crl

# Copy CRL to server
sudo cp pki/crl.pem /etc/openvpn/server/

# Add to server.conf
sudo nano /etc/openvpn/server/server.conf
# Add:
crl-verify crl.pem

# Restart server
sudo systemctl restart openvpn-server@server
```

### Renewing Certificates

```bash
# Check certificate expiration
openssl x509 -in pki/issued/client1.crt -noout -enddate

# Revoke old certificate
./easyrsa revoke client1

# Generate new certificate with same name
./easyrsa gen-req client1 nopass
./easyrsa sign-req client client1

# Generate new CRL
./easyrsa gen-crl

# Update server
sudo cp pki/crl.pem /etc/openvpn/server/
sudo systemctl restart openvpn-server@server
```

### Certificate Information

```bash
# View certificate details
openssl x509 -in pki/issued/server.crt -text -noout

# Check certificate validity dates
openssl x509 -in pki/issued/server.crt -noout -dates

# Verify certificate against CA
openssl verify -CAfile pki/ca.crt pki/issued/server.crt

# List all issued certificates
./easyrsa show-cert server
./easyrsa show-cert client1
```

### Backup and Restore

```bash
# Backup PKI directory
tar -czf openvpn-ca-backup-$(date +%Y%m%d).tar.gz ~/openvpn-ca

# Backup server configuration
sudo tar -czf openvpn-server-backup-$(date +%Y%m%d).tar.gz /etc/openvpn/server

# Restore
tar -xzf openvpn-ca-backup-20240101.tar.gz
sudo tar -xzf openvpn-server-backup-20240101.tar.gz -C /
```

---

## Configuration Options

### Client Configuration File (.ovpn)

**Basic Client Configuration:**
```bash
client
dev tun
proto udp
remote vpn.example.com 1194

# Retry connection indefinitely
resolv-retry infinite

# Don't bind to local port
nobind

# Downgrade privileges (Linux/Unix only)
user nobody
group nogroup

# Persist keys and tunnel
persist-key
persist-tun

# Verify server certificate
remote-cert-tls server

# Enable compression
compress lz4-v2

# Security
cipher AES-256-GCM
auth SHA512

# TLS authentication
key-direction 1

# Logging
verb 3

# Silence repeated messages
mute 20
```

**With Inline Certificates (Single File):**
```bash
<ca>
-----BEGIN CERTIFICATE-----
[CA certificate content]
-----END CERTIFICATE-----
</ca>

<cert>
-----BEGIN CERTIFICATE-----
[Client certificate content]
-----END CERTIFICATE-----
</cert>

<key>
-----BEGIN PRIVATE KEY-----
[Client private key content]
-----END PRIVATE KEY-----
</key>

<tls-auth>
-----BEGIN OpenVPN Static key V1-----
[TLS-auth key content]
-----END OpenVPN Static key V1-----
</tls-auth>
```

### Common Configuration Directives

#### Network Settings
```bash
# Device type
dev tun           # IP tunnel
dev tap           # Ethernet bridge

# Protocol
proto udp         # Fast, less reliable
proto tcp         # Slower, more reliable

# Port
port 1194
lport 1194        # Local port
rport 1194        # Remote port

# Multiple remote servers
remote vpn1.example.com 1194
remote vpn2.example.com 1194
remote-random     # Randomly choose remote

# Proxy settings
http-proxy proxy.example.com 8080
http-proxy-retry
socks-proxy proxy.example.com 1080
```

#### Security Settings
```bash
# Encryption ciphers
cipher AES-256-GCM
cipher AES-128-GCM
cipher AES-256-CBC

# Data channel cipher
data-ciphers AES-256-GCM:AES-128-GCM:AES-256-CBC

# Authentication
auth SHA512
auth SHA256
auth SHA1

# TLS version
tls-version-min 1.2
tls-version-max 1.3

# TLS cipher restrictions
tls-cipher TLS-ECDHE-RSA-WITH-AES-256-GCM-SHA384

# Certificate verification
verify-x509-name server_name name
remote-cert-tls server
```

#### Routing and DNS
```bash
# Redirect gateway
redirect-gateway def1
redirect-gateway def1 bypass-dhcp

# Don't redirect gateway (split tunnel)
# (comment out redirect-gateway)

# Custom routes
route 192.168.10.0 255.255.255.0

# DNS servers
dhcp-option DNS 8.8.8.8
dhcp-option DNS 8.8.4.4

# Domain suffix
dhcp-option DOMAIN example.com

# Block DNS leaks (Windows)
block-outside-dns

# WINS servers
dhcp-option WINS 192.168.1.10
```

#### Connection Management
```bash
# Keepalive
keepalive 10 60

# Connection timeout
connect-timeout 30
connect-retry 5
connect-retry-max 10

# Reconnection
persist-remote-ip
float

# MTU settings
mtu-disc yes
mssfix 1420
fragment 1300
```

#### Compression
```bash
# LZ4 compression (recommended)
compress lz4-v2

# LZO compression (legacy)
comp-lzo

# No compression
compress

# Asymmetric compression
compress lz4
push "compress lz4-v2"
```

---

## Security Hardening

### Best Security Practices

#### 1. Strong Encryption

```bash
# Server config
cipher AES-256-GCM
data-ciphers AES-256-GCM:AES-192-GCM:AES-128-GCM
auth SHA512
tls-version-min 1.2
tls-cipher TLS-ECDHE-RSA-WITH-AES-256-GCM-SHA384:TLS-DHE-RSA-WITH-AES-256-GCM-SHA384
dh dh.pem
```

#### 2. Use TLS-Crypt (Better than TLS-Auth)

```bash
# Generate tls-crypt key
openvpn --genkey secret tls-crypt.key

# Server config
tls-crypt tls-crypt.key

# Client config
tls-crypt tls-crypt.key
```

#### 3. Certificate-Based Authentication Only

```bash
# Disable username/password
# Don't add auth-user-pass to client config
# Don't add plugin authentication to server config
```

#### 4. Run with Least Privileges

```bash
# Server config
user nobody
group nogroup
persist-key
persist-tun
```

#### 5. Limit Client Privileges

```bash
# Server config
client-to-client          # Only if needed
max-clients 10
duplicate-cn no           # Force unique certificates
```

#### 6. Enable Logging and Monitoring

```bash
# Detailed logging
verb 4

# Status file
status /var/log/openvpn/openvpn-status.log 10

# Separate log for each client
log-append /var/log/openvpn/openvpn.log

# Connection logging
client-connect /etc/openvpn/scripts/client-connect.sh
client-disconnect /etc/openvpn/scripts/client-disconnect.sh
```

#### 7. Firewall Rules

```bash
# Only allow necessary ports
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp  # SSH
sudo ufw allow 1194/udp  # OpenVPN
sudo ufw enable

# Rate limiting
sudo ufw limit 1194/udp
```

#### 8. Regular Updates

```bash
# Update OpenVPN
sudo apt update
sudo apt upgrade openvpn

# Update scripts
cd ~/openvpn-ca
git pull  # If installed from source

# Rotate logs
sudo logrotate /etc/logrotate.d/openvpn
```

### Two-Factor Authentication (2FA)

**Install Google Authenticator PAM module:**

```bash
# Install libpam-google-authenticator
sudo apt install libpam-google-authenticator

# Create PAM configuration
sudo nano /etc/pam.d/openvpn

# Add:
auth required pam_google_authenticator.so
```

**Configure server to use PAM:**
```bash
# Server config
plugin /usr/lib/openvpn/openvpn-plugin-auth-pam.so openvpn
```

**Setup 2FA for users:**
```bash
# Run as each VPN user
google-authenticator

# Follow prompts:
# - Yes to time-based tokens
# - Scan QR code with authenticator app
# - Save emergency codes
# - Yes to update .google_authenticator file
# - Yes to disallow reuse
# - Yes to rate limiting
```

**Client configuration:**
```bash
# Add to client config
auth-user-pass
# Will prompt for username and OTP password
```

---

## Client Configurations

### Generate Client Configuration Files

**Manual Method:**

```bash
# Create base configuration
cat > ~/client1.ovpn << EOF
client
dev tun
proto udp
remote YOUR_SERVER_IP_OR_DOMAIN 1194
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
cipher AES-256-GCM
auth SHA512
key-direction 1
compress lz4-v2
verb 3
EOF

# Add certificates inline
echo "<ca>" >> ~/client1.ovpn
cat /etc/openvpn/client/keys/ca.crt >> ~/client1.ovpn
echo "</ca>" >> ~/client1.ovpn

echo "<cert>" >> ~/client1.ovpn
cat /etc/openvpn/client/keys/client1.crt >> ~/client1.ovpn
echo "</cert>" >> ~/client1.ovpn

echo "<key>" >> ~/client1.ovpn
cat /etc/openvpn/client/keys/client1.key >> ~/client1.ovpn
echo "</key>" >> ~/client1.ovpn

echo "<tls-auth>" >> ~/client1.ovpn
cat /etc/openvpn/client/keys/ta.key >> ~/client1.ovpn
echo "</tls-auth>" >> ~/client1.ovpn
```

**Automated Script:**

```bash
#!/bin/bash
# make-client-config.sh

CLIENT_NAME=$1
SERVER_ADDRESS=$2
SERVER_PORT=${3:-1194}

if [ -z "$CLIENT_NAME" ] || [ -z "$SERVER_ADDRESS" ]; then
    echo "Usage: $0 <client-name> <server-address> [port]"
    exit 1
fi

OUTPUT_FILE="${CLIENT_NAME}.ovpn"
KEY_DIR="/etc/openvpn/client/keys"

cat > "$OUTPUT_FILE" << EOF
client
dev tun
proto udp
remote $SERVER_ADDRESS $SERVER_PORT
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
cipher AES-256-GCM
auth SHA512
key-direction 1
compress lz4-v2
verb 3
EOF

echo "<ca>" >> "$OUTPUT_FILE"
sudo cat "$KEY_DIR/ca.crt" >> "$OUTPUT_FILE"
echo "</ca>" >> "$OUTPUT_FILE"

echo "<cert>" >> "$OUTPUT_FILE"
sudo cat "$KEY_DIR/${CLIENT_NAME}.crt" >> "$OUTPUT_FILE"
echo "</cert>" >> "$OUTPUT_FILE"

echo "<key>" >> "$OUTPUT_FILE"
sudo cat "$KEY_DIR/${CLIENT_NAME}.key" >> "$OUTPUT_FILE"
echo "</key>" >> "$OUTPUT_FILE"

echo "<tls-auth>" >> "$OUTPUT_FILE"
sudo cat "$KEY_DIR/ta.key" >> "$OUTPUT_FILE"
echo "</tls-auth>" >> "$OUTPUT_FILE"

echo "Client configuration created: $OUTPUT_FILE"
```

**Usage:**
```bash
chmod +x make-client-config.sh
sudo ./make-client-config.sh client1 vpn.itekk.in 1194
```

### Client-Specific Configurations (CCD)

```bash
# Create CCD directory
sudo mkdir -p /etc/openvpn/ccd

# Add to server.conf
client-config-dir /etc/openvpn/ccd

# Create client-specific config
sudo nano /etc/openvpn/ccd/client1

# Assign static IP
ifconfig-push 10.8.0.10 255.255.255.0

# Push specific routes
push "route 192.168.10.0 255.255.255.0"

# Block internet access (LAN only)
push "route 0.0.0.0 0.0.0.0 net_gateway"

# Custom DNS for this client
push "dhcp-option DNS 192.168.1.1"

# Disable compression for this client
compress

# Allow access to specific subnet
iroute 10.10.0.0 255.255.255.0
```

**Restart server to apply:**
```bash
sudo systemctl restart openvpn-server@server
```

---

## Troubleshooting

### Connection Issues

#### Can't Connect to Server

```bash
# Check if server is running
sudo systemctl status openvpn-server@server

# Check if port is open
sudo netstat -tulpn | grep 1194
sudo ss -tulpn | grep 1194

# Test connectivity
telnet vpn.example.com 1194
nc -zv vpn.example.com 1194

# Check firewall
sudo ufw status
sudo iptables -L -n -v

# View server logs
sudo journalctl -u openvpn-server@server -n 50
sudo tail -f /var/log/openvpn/openvpn.log

# Check routing
ip route show

# Verify certificates
openssl verify -CAfile ca.crt client1.crt
```

#### Authentication Failed

```bash
# Client side: Check credentials
cat ~/vpn-credentials.txt

# Server side: Check PAM configuration (if using)
sudo cat /etc/pam.d/openvpn

# Verify certificate dates
openssl x509 -in client1.crt -noout -dates

# Check CRL
openssl crl -in /etc/openvpn/server/crl.pem -noout -text

# Enable debug logging
# Add to config:
verb 6
```

#### Connection Drops Frequently

```bash
# Increase keepalive
keepalive 10 60

# Use TCP instead of UDP
proto tcp

# Check MTU
# Client config:
mssfix 1200
fragment 1300

# Disable compression (if causing issues)
compress

# Check for packet loss
ping -c 100 10.8.0.1
mtr 10.8.0.1
```

### Network Issues

#### No Internet Through VPN

```bash
# Verify IP forwarding on server
cat /proc/sys/net/ipv4/ip_forward  # Should be 1
sudo sysctl -w net.ipv4.ip_forward=1

# Check NAT rules
sudo iptables -t nat -L POSTROUTING -v

# Verify client received correct routes
ip route show

# Test connectivity from server
ping -I tun0 8.8.8.8

# Client side: Check gateway
ip route get 8.8.8.8
```

#### DNS Not Working

```bash
# Check DNS configuration
cat /etc/resolv.conf

# Install resolvconf
sudo apt install resolvconf

# Server config: Push DNS
push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DNS 8.8.4.4"

# Client: Update resolv.conf manually
sudo nano /etc/resolv.conf
# Add:
nameserver 8.8.8.8

# Test DNS
nslookup google.com
dig google.com
```

#### Split Tunnel Not Working

```bash
# Remove redirect-gateway from client config
# Comment out:
# redirect-gateway def1

# Add specific routes only
route 192.168.1.0 255.255.255.0

# Verify routing table
ip route show
```

### Performance Issues

#### Slow Connection

```bash
# Enable compression
compress lz4-v2

# Adjust MTU
mssfix 1400
fragment 1400

# Use faster cipher
cipher AES-128-GCM

# Switch to UDP
proto udp

# Increase buffers
sndbuf 524288
rcvbuf 524288

# Disable TLS renegotiation
reneg-sec 0
```

#### High CPU Usage

```bash
# Check compression
# Disable if causing issues
compress

# Use hardware-accelerated cipher
cipher AES-128-GCM

# Reduce logging
verb 2

# Monitor processes
top | grep openvpn
htop
```

### Certificate Issues

#### Certificate Expired

```bash
# Check expiration
openssl x509 -in client1.crt -noout -enddate

# Generate new certificate
cd ~/openvpn-ca
./easyrsa revoke client1
./easyrsa gen-req client1 nopass
./easyrsa sign-req client client1

# Update CRL
./easyrsa gen-crl
sudo cp pki/crl.pem /etc/openvpn/server/

# Restart server
sudo systemctl restart openvpn-server@server
```

#### Certificate Verification Failed

```bash
# Verify against CA
openssl verify -CAfile ca.crt client1.crt

# Check certificate chain
openssl x509 -in client1.crt -text -noout

# Ensure correct CN
openssl x509 -in client1.crt -noout -subject

# Check server certificate usage
openssl x509 -in server.crt -noout -purpose
```

---

## Advanced Configurations

### Site-to-Site VPN

**Server 1 (10.8.0.0/24):**
```bash
# Server config
server 10.8.0.0 255.255.255.0
route 10.9.0.0 255.255.255.0
push "route 10.9.0.0 255.255.255.0"

# Client-specific config for Site2
# /etc/openvpn/ccd/site2
iroute 10.9.0.0 255.255.255.0
```

**Server 2 (10.9.0.0/24) - Acts as Client:**
```bash
# Client config connecting to Server 1
client
remote server1.example.com 1194
route 10.8.0.0 255.255.255.0

# Add local network route on Server 2's router
route add -net 10.8.0.0/24 gw 10.9.0.1
```

### Multi-Server Setup (Load Balancing)

**Client Configuration:**
```bash
remote vpn1.example.com 1194
remote vpn2.example.com 1194
remote vpn3.example.com 1194
remote-random  # Randomly choose server

# Or use round-robin
# (don't add remote-random)
```

### IPv6 Support

**Server Configuration:**
```bash
# Enable IPv6
server-ipv6 fd00:abcd::/64

# Push IPv6 routes
push "route-ipv6 2000::/3"
push "route-ipv6 fd00::/8"

# IPv6 DNS
push "dhcp-option DNS6 2001:4860:4860::8888"
```

**Enable IPv6 forwarding:**
```bash
sudo nano /etc/sysctl.conf
# Add:
net.ipv6.conf.all.forwarding=1

sudo sysctl -p
```

### Management Interface

**Enable management interface:**
```bash
# Server config
management localhost 7505

# Or allow remote management (insecure!)
management 0.0.0.0 7505
```

**Connect to management interface:**
```bash
telnet localhost 7505

# Commands:
help
status
kill <client-id>
signal SIGUSR1  # Soft restart
signal SIGTERM  # Shutdown
```

### Custom Routing Scripts

**Connection scripts:**
```bash
sudo mkdir -p /etc/openvpn/scripts

# Create up script
sudo nano /etc/openvpn/scripts/up.sh
```

```bash
#!/bin/bash
# up.sh - Executed when connection is established

echo "VPN connection established at $(date)" >> /var/log/openvpn/events.log
echo "Virtual IP: $ifconfig_local" >> /var/log/openvpn/events.log

# Add custom routes
ip route add 192.168.100.0/24 via $route_vpn_gateway

# Update firewall
iptables -A FORWARD -i tun0 -j ACCEPT
```

**Make executable:**
```bash
sudo chmod +x /etc/openvpn/scripts/up.sh

# Add to server config
script-security 2
up /etc/openvpn/scripts/up.sh
```

### Multi-Factor Authentication Script

**Learn-address script for logging:**
```bash
sudo nano /etc/openvpn/scripts/learn-address.sh
```

```bash
#!/bin/bash
# learn-address.sh

action=$1  # add, update, delete
address=$2
common_name=$3

case "$action" in
    add|update)
        echo "$(date): $common_name connected from $address" >> /var/log/openvpn/connections.log
        ;;
    delete)
        echo "$(date): $common_name disconnected from $address" >> /var/log/openvpn/connections.log
        ;;
esac

exit 0
```

```bash
sudo chmod +x /etc/openvpn/scripts/learn-address.sh

# Add to server config
learn-address /etc/openvpn/scripts/learn-address.sh
```

---

## Monitoring and Logging

### Log Management

```bash
# View real-time logs
sudo tail -f /var/log/openvpn/openvpn.log

# View systemd logs
sudo journalctl -u openvpn-server@server -f

# Search logs
sudo grep "client1" /var/log/openvpn/openvpn.log

# View status file
cat /var/log/openvpn/openvpn-status.log
```

### Log Rotation

```bash
# Create logrotate config
sudo nano /etc/logrotate.d/openvpn
```

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

### Monitoring Tools

**Built-in status:**
```bash
# Enable management interface
management localhost 7505

# Connect and check status
telnet localhost 7505
> status
```

**Using vnstat for bandwidth:**
```bash
# Install vnstat
sudo apt install vnstat

# Monitor tun0 interface
sudo vnstat -i tun0 -l  # Live traffic
sudo vnstat -i tun0 -h  # Hourly stats
sudo vnstat -i tun0 -d  # Daily stats
```

**Using iftop for real-time monitoring:**
```bash
# Install iftop
sudo apt install iftop

# Monitor VPN interface
sudo iftop -i tun0
```

**Connection statistics script:**
```bash
#!/bin/bash
# openvpn-stats.sh

STATUS_FILE="/var/log/openvpn/openvpn-status.log"

echo "=== OpenVPN Server Statistics ==="
echo "Total Clients Connected: $(grep -c "^CLIENT_LIST" "$STATUS_FILE")"
echo ""
echo "Connected Clients:"
grep "^CLIENT_LIST" "$STATUS_FILE" | awk -F',' '{printf "%-20s %-15s %-20s %s\n", $2, $3, $4, $5}'
echo ""
echo "Routing Table:"
grep "^ROUTING_TABLE" "$STATUS_FILE" | awk -F',' '{printf "%-15s %-20s %-20s\n", $2, $3, $4}'
```

### Alerting System

**Email alerts on connection:**
```bash
sudo nano /etc/openvpn/scripts/client-connect.sh
```

```bash
#!/bin/bash
# client-connect.sh

CLIENT="$common_name"
IP="$trusted_ip"
VPN_IP="$ifconfig_pool_remote_ip"

# Send email alert
echo "Client $CLIENT connected from $IP (VPN IP: $VPN_IP)" | mail -s "VPN Connection Alert" admin@example.com

# Log to syslog
logger -t openvpn "Client $CLIENT connected from $IP"

exit 0
```

---

## Platform-Specific Clients

### Linux Desktop

```bash
# Install GUI client
sudo apt install network-manager-openvpn-gnome

# Import config
sudo nmcli connection import type openvpn file client.ovpn

# Or use command line
sudo openvpn --config client.ovpn
```

### Windows

1. Download OpenVPN GUI from https://openvpn.net/community-downloads/
2. Install OpenVPN
3. Copy `.ovpn` file to `C:\Program Files\OpenVPN\config\`
4. Run OpenVPN GUI as Administrator
5. Right-click system tray icon → Connect

### macOS

1. Download Tunnelblick from https://tunnelblick.net/
2. Install Tunnelblick
3. Double-click `.ovpn` file to import
4. Click Tunnelblick icon → Connect

### Android

1. Install "OpenVPN for Android" from Play Store
2. Open app → + → Import
3. Select `.ovpn` file
4. Tap to connect

### iOS

1. Install "OpenVPN Connect" from App Store
2. Transfer `.ovpn` file via:
   - iTunes File Sharing
   - Email (open attachment in OpenVPN Connect)
   - iCloud/Dropbox
3. Import profile
4. Connect

### Router (DD-WRT/OpenWrt)

**DD-WRT:**
1. Services → VPN → OpenVPN Client
2. Enable OpenVPN Client
3. Paste `.ovpn` contents into Additional Config
4. Apply settings

**OpenWrt:**
```bash
# Install OpenVPN
opkg update
opkg install openvpn-openssl luci-app-openvpn

# Copy config
scp client.ovpn root@router:/etc/openvpn/

# Start VPN
/etc/init.d/openvpn start
/etc/init.d/openvpn enable
```

---

## Practical Examples

### Example 1: Home Server Remote Access (Raspberry Pi)

**Raspberry Pi Server Configuration:**

```bash
# Install on Raspberry Pi
sudo apt update
sudo apt install openvpn

# Run quick setup script
wget https://git.io/vpn -O openvpn-install.sh
chmod +x openvpn-install.sh
sudo ./openvpn-install.sh

# Configuration choices:
# - IP: your-dynamic-dns.itekk.in
# - Protocol: UDP
# - Port: 1194
# - DNS: 8.8.8.8
# - Client name: phone1

# Forward port 1194 on router to Raspberry Pi IP

# Start server
sudo systemctl start openvpn-server@server
sudo systemctl enable openvpn-server@server
```

**Access from anywhere:**
```bash
# On laptop/phone, use generated client1.ovpn
# Server address in config: vpn.itekk.in:1194
```

### Example 2: Split Tunnel for Work VPN

**Client config for accessing work network only:**

```bash
# Don't redirect all traffic
# route-nopull  # Ignore server's pushed routes

# Add only work network routes
route 10.0.0.0 255.0.0.0
route 192.168.50.0 255.255.255.0

# Keep local DNS
# pull-filter ignore "dhcp-option DNS"
```

### Example 3: Multi-User Home VPN

**Different configurations for family members:**

```bash
# Create certificates
cd ~/openvpn-ca
./easyrsa gen-req dad nopass && ./easyrsa sign-req client dad
./easyrsa gen-req mom nopass && ./easyrsa sign-req client mom
./easyrsa gen-req kid nopass && ./easyrsa sign-req client kid

# Create client-specific configs
sudo mkdir -p /etc/openvpn/ccd

# Dad - full access
sudo nano /etc/openvpn/ccd/dad
ifconfig-push 10.8.0.10 255.255.255.0

# Mom - full access
sudo nano /etc/openvpn/ccd/mom
ifconfig-push 10.8.0.11 255.255.255.0

# Kid - limited access (no internet, LAN only)
sudo nano /etc/openvpn/ccd/kid
ifconfig-push 10.8.0.12 255.255.255.0
push "route 192.168.1.0 255.255.255.0"
push "route 10.8.0.0 255.255.255.0"
# Block internet
push "route 0.0.0.0 0.0.0.0 net_gateway"
```

### Example 4: Port 443 VPN (Firewall Bypass)

**Server config to use HTTPS port:**

```bash
# Change to TCP port 443 (looks like HTTPS)
port 443
proto tcp

# Everything else remains the same
```

**Benefits:**
- Works through restrictive firewalls
- Bypasses port blocking
- Appears as regular HTTPS traffic

### Example 5: Client-to-Client Communication

**Enable clients to communicate:**

```bash
# Server config
client-to-client

# Push VPN subnet to all clients
push "route 10.8.0.0 255.255.255.0"
```

**Use cases:**
- File sharing between VPN clients
- Local multiplayer gaming
- Peer-to-peer applications

### Example 6: Tunnel All Traffic Through VPN

**Force all internet through VPN:**

```bash
# Server config
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DNS 8.8.4.4"

# Block DNS leaks (Windows)
push "block-outside-dns"
```

### Example 7: VPN Chaining (VPN through VPN)

**Connect VPN → VPN for extra security:**

```bash
# First VPN connection
sudo openvpn --config vpn1.ovpn --daemon

# Wait for connection
sleep 5

# Second VPN through first
sudo openvpn --config vpn2.ovpn --route-nopull --route-gateway 10.8.0.1
```

### Example 8: Automated Connection Monitoring

```bash
#!/bin/bash
# vpn-monitor.sh - Restart VPN if connection drops

VPN_CONFIG="/etc/openvpn/client/work.conf"
CHECK_HOST="10.8.0.1"

while true; do
    if ! ping -c 1 -W 5 "$CHECK_HOST" > /dev/null 2>&1; then
        echo "$(date): VPN connection lost, reconnecting..." >> /var/log/vpn-monitor.log
        sudo systemctl restart openvpn-client@work
    fi
    sleep 60
done
```

**Run as systemd service:**
```bash
sudo nano /etc/systemd/system/vpn-monitor.service
```

```ini
[Unit]
Description=VPN Connection Monitor
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/vpn-monitor.sh
Restart=always

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl enable vpn-monitor
sudo systemctl start vpn-monitor
```

---

## Performance Optimization

### Server Optimization

```bash
# Increase file descriptors
sudo nano /etc/security/limits.conf
* soft nofile 100000
* hard nofile 100000

# Kernel tuning
sudo nano /etc/sysctl.conf
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.core.netdev_max_backlog = 5000

sudo sysctl -p
```

### Client Optimization

```bash
# Fast cipher
cipher AES-128-GCM

# Larger buffers
sndbuf 524288
rcvbuf 524288

# Fast reconnection
fast-io

# Reduce handshake frequency
reneg-sec 0
```

---

## Backup and Disaster Recovery

### Backup Script

```bash
#!/bin/bash
# openvpn-backup.sh

BACKUP_DIR="/backup/openvpn"
DATE=$(date +%Y%m%d-%H%M%S)

mkdir -p "$BACKUP_DIR"

# Backup PKI
tar -czf "$BACKUP_DIR/pki-$DATE.tar.gz" ~/openvpn-ca/pki/

# Backup server config
tar -czf "$BACKUP_DIR/server-$DATE.tar.gz" /etc/openvpn/server/

# Backup logs (last 7 days)
tar -czf "$BACKUP_DIR/logs-$DATE.tar.gz" /var/log/openvpn/

# Keep only last 30 backups
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +30 -delete

echo "Backup completed: $DATE"
```

### Restore Process

```bash
# Restore PKI
tar -xzf pki-20240101.tar.gz -C ~/openvpn-ca/

# Restore server config
sudo tar -xzf server-20240101.tar.gz -C /etc/openvpn/

# Restart server
sudo systemctl restart openvpn-server@server
```

---

## Security Checklist

- [ ] Use strong encryption (AES-256-GCM, SHA512)
- [ ] Enable TLS-Crypt or TLS-Auth
- [ ] Use certificate-based authentication
- [ ] Run with least privileges (nobody:nogroup)
- [ ] Enable firewall and allow only necessary ports
- [ ] Use strong passwords for certificate protection
- [ ] Regularly update OpenVPN and system
- [ ] Monitor logs for suspicious activity
- [ ] Implement fail2ban for brute force protection
- [ ] Use CRL for certificate revocation
- [ ] Backup certificates and keys securely
- [ ] Test DR procedures regularly
- [ ] Document all configurations
- [ ] Implement 2FA if possible
- [ ] Use dedicated VPN server (not multi-purpose)

---

## Common Commands Reference

```bash
# Server Management
sudo systemctl start openvpn-server@server
sudo systemctl stop openvpn-server@server
sudo systemctl restart openvpn-server@server
sudo systemctl status openvpn-server@server
sudo systemctl enable openvpn-server@server

# Client Management
sudo systemctl start openvpn-client@config
sudo systemctl stop openvpn-client@config
sudo openvpn --config client.ovpn

# Certificate Management
./easyrsa gen-req <name> nopass
./easyrsa sign-req client <name>
./easyrsa revoke <name>
./easyrsa gen-crl

# Monitoring
sudo tail -f /var/log/openvpn/openvpn.log
sudo cat /var/log/openvpn/openvpn-status.log
ip addr show tun0
ip route show

# Testing
ping 10.8.0.1
curl ifconfig.me
nslookup google.com
traceroute 8.8.8.8
```

---

## Legal Disclaimer

**Important**: VPN technology should only be used for legitimate purposes:

✓ **Legitimate Uses:**
- Secure remote access to your own networks
- Protecting privacy on public WiFi
- Authorized remote work access
- Testing in lab environments with permission

✗ **Prohibited Uses:**
- Bypassing legal restrictions
- Hiding illegal activities
- Unauthorized access to networks
- Violating terms of service
- Copyright infringement
- Evading network monitoring in corporate environments without authorization

**Always:**
- Obtain proper authorization before setting up VPNs
- Comply with local laws and regulations
- Respect network policies
- Use VPN technology ethically and responsibly

---

## Additional Resources

### Official Documentation
- **OpenVPN Website**: https://openvpn.net/
- **Community Wiki**: https://community.openvpn.net/
- **Official Documentation**: https://openvpn.net/community-resources/
- **GitHub Repository**: https://github.com/OpenVPN/openvpn

### Community Resources
- **OpenVPN Forum**: https://forums.openvpn.net/
- **Reddit**: r/OpenVPN
- **IRC**: #openvpn on Freenode

### Related Tools
- **WireGuard**: Modern VPN alternative
- **SoftEther VPN**: Multi-protocol VPN software
- **OpenConnect**: Compatible with Cisco AnyConnect
- **StrongSwan**: IPsec VPN solution

### Learning Resources
- OpenVPN HOWTO documentation
- Ubuntu Server Guide
- DigitalOcean tutorials
- Linode guides
- YouTube tutorials

### Books
- "Mastering OpenVPN" by Eric Crist
- "OpenVPN 2 Cookbook" by Jan Just Keijser
- "Linux Network Administrator's Guide"

---

## Quick Start Cheat Sheet

### Server Setup (3 Commands)
```bash
wget https://git.io/vpn -O openvpn-install.sh
chmod +x openvpn-install.sh
sudo ./openvpn-install.sh
```

### Client Connection
```bash
sudo openvpn --config client.ovpn
```

### Check Connection
```bash
curl ifconfig.me
ping 10.8.0.1
```

---

**Last Updated**: December 2024  
**Version**: 2.6.x compatible  
**Author**: Network Security Documentation  
**License**: Free to use and modify

---

*Remember: A VPN is only as secure as its configuration. Take time to understand each setting and implement appropriate security measures for your use case.*
