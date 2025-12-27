# OpenVPN Complete Setup Scripts

Automated scripts for setting up OpenVPN server on Ubuntu Linux with proper security and DDNS support.

## Overview

This collection of scripts automates the complete OpenVPN server installation process, from cleanup to creating your first client. Each script handles one specific step and must be run in order.

## Requirements

- Ubuntu 22.04 LTS or 24.04 LTS
- Root/sudo access
- Internet connection
- Basic knowledge of networking

## Features

- ✅ Complete cleanup of old installations
- ✅ Automated package installation
- ✅ CA with password protection (secure)
- ✅ Passwordless client certificates (convenient)
- ✅ DDNS support (use domain instead of IP)
- ✅ Proper firewall configuration
- ✅ Network security hardening
- ✅ Automatic client generation script

## Quick Start

### 1. Download Scripts

```bash
# Navigate to the scripts directory
cd openvpn-setup

# Make all scripts executable
chmod +x *.sh
```

### 2. Run Scripts in Order

**Important:** Pay attention to which scripts need sudo and which don't!

```bash
# Step 1: Cleanup (requires sudo)
sudo ./01-cleanup.sh

# Step 2: Install packages (requires sudo)
sudo ./02-install-packages.sh

# Step 3: Setup Easy-RSA (regular user - NO sudo)
./03-setup-easyrsa.sh

# Step 4: Build CA (regular user - NO sudo)
./04-build-ca.sh
# ⚠️  SAVE THE CA PASSWORD SECURELY!

# Step 5: Generate server certificates (regular user - NO sudo)
./05-generate-server-cert.sh
# ⚠️  This takes 5-30 minutes for DH generation

# Step 6: Copy server files (requires sudo)
sudo ./06-copy-server-files.sh

# Step 7: Configure server (requires sudo)
sudo ./07-configure-server.sh

# Step 8: Configure network (requires sudo)
sudo ./08-configure-network.sh

# Step 9: Start server (requires sudo)
sudo ./09-start-server.sh

# Step 10: Create first client (regular user - NO sudo)
./10-create-client.sh
```

### 3. Configure Router

After running the scripts, configure your router:

1. Login to your router admin panel
2. Go to Port Forwarding / Virtual Server
3. Forward UDP port 1194 to your Ubuntu server's local IP
4. Save settings

### 4. Connect from Client

Transfer the `.ovpn` file to your device and connect:

```bash
# Linux
sudo openvpn --config client.ovpn

# Ubuntu Desktop
sudo nmcli connection import type openvpn file client.ovpn
```

## Script Details

### 01-cleanup.sh (sudo required)

Removes all previous OpenVPN installations and configurations.

**What it does:**
- Stops OpenVPN services
- Removes server/client configs
- Deletes Easy-RSA directory
- Cleans logs
- Removes old helper scripts

**When to run:**
- First time setup
- Starting fresh after failed installation
- Removing old configuration

### 02-install-packages.sh (sudo required)

Installs OpenVPN and required dependencies.

**What it installs:**
- OpenVPN server and client
- Easy-RSA for certificate management
- Network utilities
- Firewall tools

### 03-setup-easyrsa.sh (regular user)

Sets up Easy-RSA and configures organization details.

**What it does:**
- Creates Easy-RSA directory structure
- Configures variables (country, organization, etc.)
- Initializes PKI

**Interactive prompts:**
- Country (default: IN)
- Province (default: Tamil Nadu)
- City (default: Chennai)
- Organization (default: HomeVPN)
- Email (default: admin@nerunja.mywire.org)

### 04-build-ca.sh (regular user)

Builds the Certificate Authority with password protection.

**What it does:**
- Creates CA certificate
- Protects CA private key with password

**⚠️  CRITICAL:**
- You will set a CA password
- This password is needed when creating new clients
- SAVE THIS PASSWORD SECURELY!
- Cannot be recovered if lost

### 05-generate-server-cert.sh (regular user)

Generates all server certificates and keys.

**What it does:**
- Creates server certificate
- Signs server certificate (needs CA password)
- Generates DH parameters (takes time!)
- Creates TLS authentication key

**Time required:**
- 5-30 minutes for DH generation
- CPU-intensive process

### 06-copy-server-files.sh (sudo required)

Copies certificates to OpenVPN directory with proper permissions.

**What it does:**
- Creates OpenVPN directories
- Copies all certificate files
- Sets proper file permissions (600 for keys)
- Sets ownership to root

### 07-configure-server.sh (sudo required)

Creates OpenVPN server configuration file.

**Interactive prompts:**
- VPN port (default: 1194)
- Protocol (default: udp)
- DNS servers (default: 8.8.8.8, 8.8.4.4)
- Maximum clients (default: 10)

**Configuration created:**
- VPN subnet: 10.8.0.0/24
- Server IP: 10.8.0.1
- Encryption: AES-256-GCM
- Compression: LZ4

### 08-configure-network.sh (sudo required)

Configures IP forwarding and firewall.

**What it does:**
- Enables IP forwarding
- Configures NAT/masquerading
- Sets up UFW firewall rules
- Allows OpenVPN port
- Maintains SSH access

**Interactive prompts:**
- Network interface (auto-detected)

### 09-start-server.sh (sudo required)

Starts OpenVPN server and enables auto-start.

**What it does:**
- Starts OpenVPN service
- Enables auto-start on boot
- Verifies server is running
- Checks TUN interface
- Displays status and logs

### 10-create-client.sh (regular user)

Creates first VPN client configuration.

**Interactive prompts:**
- Client name (e.g., laptop, phone)
- Server address (DDNS domain or IP)

**What it creates:**
- Client certificate (needs CA password)
- Client .ovpn configuration file
- Helper script for future clients

**Output:**
- `~/client-configs/client-name.ovpn`
- `~/add-client.sh` (helper for more clients)

## After Setup

### Verify Server is Running

```bash
# Check service status
sudo systemctl status openvpn-server@server

# View logs
sudo journalctl -u openvpn-server@server -f

# Check TUN interface
ip addr show tun0

# Check listening port
sudo ss -tulpn | grep 1194
```

### Test Connection

```bash
# Check your public IP before connecting
curl ifconfig.me

# Connect to VPN
sudo openvpn --config client.ovpn

# In another terminal, check IP again (should show server's IP)
curl ifconfig.me

# Ping VPN server
ping 10.8.0.1
```

### Create More Clients

```bash
# Option 1: Run the main script again
./10-create-client.sh

# Option 2: Use the helper script (created by step 10)
./add-client.sh phone
./add-client.sh tablet
./add-client.sh work-laptop
```

### Revoke a Client

```bash
cd ~/openvpn-ca

# Revoke certificate
./easyrsa revoke client-name

# Generate CRL
./easyrsa gen-crl

# Copy to server
sudo cp pki/crl.pem /etc/openvpn/server/

# Add to server config (if not already present)
sudo nano /etc/openvpn/server/server.conf
# Add: crl-verify crl.pem

# Restart server
sudo systemctl restart openvpn-server@server
```

## Directory Structure

After setup, you'll have:

```
~/openvpn-ca/              # Certificate Authority
├── pki/
│   ├── ca.crt            # CA certificate
│   ├── issued/           # Signed certificates
│   ├── private/          # Private keys
│   └── dh.pem           # DH parameters
├── ta.key               # TLS auth key
└── vars                 # Configuration variables

~/client-configs/          # Client configurations
├── client1.ovpn          # Ready-to-use client files
├── client2.ovpn
└── keys/                 # Certificate copies

/etc/openvpn/server/       # Server files
├── server.conf           # Server configuration
├── ca.crt
├── server.crt
├── server.key
├── dh.pem
└── ta.key

/var/log/openvpn/          # Logs
├── openvpn.log           # Server log
└── openvpn-status.log    # Connection status
```

## Troubleshooting

### Server Won't Start

```bash
# Check detailed logs
sudo journalctl -u openvpn-server@server -n 100 --no-pager

# Test configuration
sudo openvpn --config /etc/openvpn/server/server.conf

# Check file permissions
ls -la /etc/openvpn/server/

# Verify IP forwarding
cat /proc/sys/net/ipv4/ip_forward  # Should return 1
```

### Client Can't Connect

```bash
# Server side:
# Check if server is running
sudo systemctl status openvpn-server@server

# Check firewall
sudo ufw status

# Check port is listening
sudo ss -tulpn | grep 1194

# Client side:
# Verify server address
grep "remote" client.ovpn

# Test connectivity
ping server-ip
telnet server-ip 1194  # Should connect
```

### No Internet Through VPN

```bash
# Check IP forwarding
cat /proc/sys/net/ipv4/ip_forward  # Should be 1

# Check NAT rules
sudo iptables -t nat -L POSTROUTING

# Manually add if missing
sudo iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE
```

### Certificate Issues

```bash
# Verify certificate matches key
cd ~/openvpn-ca
openssl x509 -noout -modulus -in pki/issued/client.crt | openssl md5
openssl rsa -noout -modulus -in pki/private/client.key | openssl md5
# These should match

# Check certificate expiration
openssl x509 -in pki/issued/client.crt -noout -dates
```

## Security Best Practices

1. **Save CA Password Securely**
   - Use a password manager
   - Never write it down unprotected
   - This password cannot be recovered

2. **One Certificate Per Device**
   - Create separate cert for each device
   - Easier to revoke if device is lost
   - Better audit trail

3. **Secure File Transfer**
   - Never email .ovpn files
   - Use SCP, encrypted USB, or secure messaging
   - Delete after transfer

4. **Enable Device Encryption**
   - Encrypt laptop/desktop
   - Enable phone/tablet encryption
   - Protects .ovpn files at rest

5. **Regular Backups**
   ```bash
   # Backup CA
   tar -czf openvpn-ca-backup-$(date +%Y%m%d).tar.gz ~/openvpn-ca
   
   # Backup server config
   sudo tar -czf openvpn-server-backup-$(date +%Y%m%d).tar.gz /etc/openvpn/server
   ```

6. **Monitor Connections**
   ```bash
   # Check connected clients
   sudo cat /var/log/openvpn/openvpn-status.log | grep CLIENT_LIST
   
   # Watch logs
   sudo tail -f /var/log/openvpn/openvpn.log
   ```

## Useful Commands

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
```

### Client Management

```bash
# Create new client
./add-client.sh clientname

# List all certificates
ls ~/openvpn-ca/pki/issued/

# Revoke client
cd ~/openvpn-ca
./easyrsa revoke clientname
./easyrsa gen-crl
sudo cp pki/crl.pem /etc/openvpn/server/
sudo systemctl restart openvpn-server@server
```

### Monitoring

```bash
# Connected clients
sudo cat /var/log/openvpn/openvpn-status.log

# Real-time logs
sudo tail -f /var/log/openvpn/openvpn.log

# Check TUN interface
ip addr show tun0

# Network statistics
sudo vnstat -i tun0
```

## Additional Resources

- OpenVPN Documentation: https://openvpn.net/community-resources/
- Ubuntu Server Guide: https://ubuntu.com/server/docs
- Easy-RSA Documentation: https://easy-rsa.readthedocs.io/

## Support

If you encounter issues:

1. Check the troubleshooting section above
2. Review the logs: `sudo journalctl -u openvpn-server@server`
3. Verify each step was completed successfully
4. Ensure router port forwarding is configured

## License

These scripts are provided as-is for educational and personal use.

## Security Notice

- Only use on networks you own
- Never scan or test unauthorized networks
- Respect privacy and security laws
- Keep software updated regularly

---

**Last Updated:** December 27, 2024  
**Compatible With:** Ubuntu 22.04 LTS, 24.04 LTS  
**OpenVPN Version:** 2.6.x
