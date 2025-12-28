# OpenVPN Server - Quick Start Guide

Complete guide to set up and run your OpenVPN server from scratch.

---

## 📋 Prerequisites

- Ubuntu 24.04 (Noble) or compatible Linux distribution
- Root/sudo access
- Internet connection
- (Optional) Domain name or DDNS for remote access

---

## 🚀 Installation Steps

### Step 1: Clean Start (Optional)

If you have an existing OpenVPN installation and want to start fresh:

```bash
sudo ./01-cleanup.sh
```

**What it does:**
- Stops all OpenVPN services
- Removes old configurations
- Cleans up certificates and keys
- Prepares system for fresh installation

---

### Step 2: Install Packages

```bash
sudo ./02-install-packages.sh
```

**What it installs:**
- OpenVPN server and client
- Easy-RSA (certificate management)
- Network utilities (net-tools, iptables)
- Firewall tools

**Note:** If you see repository warnings, you can safely continue if OpenVPN installs successfully.

---

### Step 3: Set Up Easy-RSA

```bash
./03-setup-easyrsa.sh
```

⚠️ **Important:** Run WITHOUT sudo!

**You'll be asked for:**
- Country (2 letter code) - e.g., `IN`
- Province/State - e.g., `Tamil Nadu`
- City - e.g., `Chennai`
- Organization - e.g., `HomeVPN`
- Email - e.g., `admin@yourdomain.org`
- Organizational Unit - e.g., `IT`

**Defaults are provided** - just press Enter to accept them.

---

### Step 4: Build Certificate Authority (CA)

```bash
./04-build-ca.sh
```

⚠️ **Critical Step:**

You'll be asked to create a **CA password**. This password is required every time you:
- Add new VPN clients
- Sign certificates
- Revoke certificates

**Password Requirements:**
- At least 16 characters
- Mix of uppercase, lowercase, numbers, symbols
- Store in a password manager
- **There is NO way to recover this password if lost!**

**Recommended:** Use a password manager to generate and store a strong password like: `Xk9$mP2@vL5#qR8&wN4!`

---

### Step 5: Generate Server Certificates

```bash
./05-generate-server-cert.sh
```

**This script generates:**
1. Server certificate and private key
2. Diffie-Hellman parameters (takes 5-30 minutes!)
3. TLS authentication key

⏱️ **Wait Time:** The DH parameter generation is CPU-intensive and will take time. This is normal!

You'll need your **CA password** from Step 4.

---

### Step 6: Copy Server Files

```bash
sudo ./06-copy-server-files.sh
```

**What it does:**
- Copies certificates to `/etc/openvpn/server/`
- Sets proper file permissions (600 for private keys)
- Sets ownership to root

---

### Step 7: Configure Server

```bash
sudo ./07-configure-server.sh
```

**You'll configure:**

1. **VPN Port:** Default `1194` (press Enter)
2. **Protocol:** `udp` or `tcp` (udp recommended)
3. **DNS Servers:** Choose from:
   - **Option 1:** Google DNS (8.8.8.8) - Fast, widely used
   - **Option 2:** Cloudflare (1.1.1.1) - **Privacy-focused (Default)**
   - **Option 3:** Quad9 (9.9.9.9) - Security-focused, blocks malware
   - **Option 4:** Custom DNS
4. **Maximum Clients:** Default `10`

**Security Features:**
- ✅ AES-256-GCM encryption
- ✅ SHA256 authentication
- ✅ TLS 1.3 support
- ✅ LZ4 compression
- ✅ Runs as unprivileged user (nobody)

---

### Step 8: Configure Network & Firewall

```bash
sudo ./08-configure-network.sh
```

**You'll be asked:**
- Confirm detected network interface (usually `eth0`, `wlp*`, or `enp*`)

**What it configures:**
- IP forwarding enabled
- NAT (Network Address Translation)
- UFW firewall rules
- Port 1194/udp allowed
- SSH access maintained

⚠️ **Important:** After this step, you'll see instructions to configure **router port forwarding**:

```
External Port: 1194 (udp)
Internal IP: [Your server's local IP]
Internal Port: 1194
```

You must configure this on your router to allow external VPN connections!

---

### Step 9: Start OpenVPN Server

```bash
sudo ./09-start-server.sh
```

**What it does:**
- Starts OpenVPN server service
- Enables auto-start on boot
- Verifies server is running
- Creates TUN interface (tun0)
- Shows server status and logs

**Verification Checks:**
- ✅ Service status: Active
- ✅ Server initialization: Complete
- ✅ TUN interface: Created (10.8.0.1)
- ✅ Port: Listening on 1194

**Useful Commands:**
```bash
# View server status
sudo systemctl status openvpn-server@server

# View live logs
sudo journalctl -u openvpn-server@server -f

# Restart server
sudo systemctl restart openvpn-server@server

# Stop server
sudo systemctl stop openvpn-server@server
```

---

### Step 10: Create VPN Client

```bash
./10-create-client.sh
```

**You'll be asked for:**
1. **Client name:** e.g., `my-laptop`, `work-phone`, `tablet`
2. **Server address:** Your public IP or DDNS domain (e.g., `home.mywire.org`)

You'll need your **CA password** again.

**Output:**
- Client configuration file: `~/client-configs/[client-name].ovpn`
- This file contains **everything** needed to connect (certificates embedded)

⚠️ **Security Warning:**
The `.ovpn` file is sensitive! Transfer it securely:
- ✅ USB drive (physical transfer)
- ✅ SCP: `scp ~/client-configs/client.ovpn user@device:~/`
- ✅ Password-protected zip
- ✅ Encrypted messaging (Signal, WhatsApp)

**Never:**
- ✗ Email unencrypted
- ✗ Public cloud storage
- ✗ Unencrypted messaging

---

## 🧪 Testing Your VPN

### Local Testing (Same Machine)

Test the connection on the same machine as the server:

```bash
cd ~/client-configs
sudo ./test-vpn-local.sh
```

This connects to `127.0.0.1:1194` for local testing.

**In another terminal, verify:**
```bash
# Check VPN interface
ip addr show tun1

# Ping VPN server
ping -c 3 10.8.0.1

# Check routes
ip route | grep tun1
```

Press `Ctrl+C` to disconnect.

---

### Remote Testing (Different Device)

1. **Transfer the `.ovpn` file** to your device securely
2. **Import and connect:**

**Linux:**
```bash
sudo openvpn --config client.ovpn
```

**Ubuntu Desktop (GUI):**
```bash
sudo nmcli connection import type openvpn file client.ovpn
nmcli connection up client
```

**Windows:**
1. Install OpenVPN GUI from https://openvpn.net/community-downloads/
2. Copy `.ovpn` to: `C:\Program Files\OpenVPN\config\`
3. Right-click OpenVPN GUI → Connect

**Android:**
1. Install "OpenVPN for Android" from Play Store
2. Import `.ovpn` file
3. Connect

**iOS:**
1. Install "OpenVPN Connect" from App Store
2. Import `.ovpn` file
3. Connect

---

### Verify VPN Connection

After connecting, verify your VPN is working:

```bash
# 1. Check VPN interface (should show tun0 or tun1)
ip addr show tun0

# 2. Ping VPN server
ping 10.8.0.1

# 3. Check your public IP (should show server's IP)
curl ifconfig.me

# 4. Test DNS
nslookup google.com
```

---

## 🔧 Common Operations

### Add More VPN Clients

**Option 1:** Run the script again
```bash
./10-create-client.sh
```

**Option 2:** Use the helper script (created automatically)
```bash
cd ~/ws/github/nerunja/networking-commands/OpenVPN/scripts
./add-client.sh phone
./add-client.sh tablet
```

Each client gets a unique certificate and can connect simultaneously (up to max clients configured).

---

### Check Server Status

```bash
# Quick status check
sudo systemctl status openvpn-server@server

# View active connections
sudo cat /var/log/openvpn/openvpn-status.log

# View detailed logs
sudo tail -f /var/log/openvpn/openvpn.log

# Or use journalctl
sudo journalctl -u openvpn-server@server -f
```

---

### Restart Server

```bash
sudo systemctl restart openvpn-server@server
```

---

### Stop Server

```bash
sudo systemctl stop openvpn-server@server
```

---

### Start Server (if stopped)

```bash
sudo systemctl start openvpn-server@server
```

---

## 📁 Important Files & Directories

### Server Files
```
/etc/openvpn/server/
├── server.conf          # Main server configuration
├── ca.crt              # Certificate Authority certificate
├── server.crt          # Server certificate
├── server.key          # Server private key (protected)
├── dh.pem              # Diffie-Hellman parameters
└── ta.key              # TLS authentication key

/var/log/openvpn/
├── openvpn.log         # Server logs
├── openvpn-status.log  # Current connections
└── ipp.txt             # Client IP persistence
```

### Client Files
```
~/client-configs/
├── [client-name].ovpn  # Client configuration files
└── test-vpn-local.sh   # Local testing script

~/openvpn-ca/           # Certificate Authority
├── pki/
│   ├── ca.crt          # CA certificate
│   ├── private/ca.key  # CA private key (password protected)
│   ├── issued/         # Signed certificates
│   └── private/        # Private keys
└── vars                # Easy-RSA configuration
```

---

## 🔒 Security Best Practices

### 1. **Protect Your CA Password**
- Store in a password manager
- Never share or write down
- Use strong password (16+ characters)

### 2. **Secure Client Files**
- Transfer `.ovpn` files securely
- Delete from server after transfer
- Don't store in public cloud unencrypted

### 3. **Regular Updates**
```bash
sudo apt update
sudo apt upgrade openvpn
```

### 4. **Monitor Connections**
```bash
# Check who's connected
sudo cat /var/log/openvpn/openvpn-status.log
```

### 5. **Firewall Configuration**
- Keep UFW enabled
- Only allow necessary ports
- Monitor firewall logs

---

## 🐛 Troubleshooting

### Server Won't Start

**Check logs:**
```bash
sudo journalctl -u openvpn-server@server -n 50
```

**Common issues:**
- Missing certificates: Re-run step 6
- Port already in use: Check with `sudo ss -tulpn | grep 1194`
- Firewall blocking: Check `sudo ufw status`

---

### Client Can't Connect

**Check:**
1. Server is running: `sudo systemctl status openvpn-server@server`
2. Router port forwarding configured correctly
3. Firewall allows port 1194/udp
4. Correct server address in client config
5. Client has correct certificates

**Debug client connection:**
```bash
sudo openvpn --config client.ovpn --verb 6
```

---

### Compression Warnings

If you see compression warnings, they're informational only. The connection still works. This is OpenVPN 2.6+ being strict about compression.

To eliminate the warning (optional), the server config already has `allow-compression yes`.

---

### Network Not Routing

**Check IP forwarding:**
```bash
cat /proc/sys/net/ipv4/ip_forward  # Should show "1"
```

**Check NAT rules:**
```bash
sudo iptables -t nat -L POSTROUTING -v
```

**Re-apply network config:**
```bash
sudo ./08-configure-network.sh
```

---

## 📊 VPN Network Information

- **VPN Subnet:** 10.8.0.0/24
- **Server IP:** 10.8.0.1
- **Client IP Range:** 10.8.0.2 - 10.8.0.254
- **DNS Servers:** Configured in step 7 (default: Cloudflare 1.1.1.1)
- **Encryption:** AES-256-GCM
- **Protocol:** UDP (default) or TCP
- **Port:** 1194 (default)

---

## 🎯 Quick Reference

### Full Installation (Fresh System)
```bash
sudo ./01-cleanup.sh        # Optional, if reinstalling
sudo ./02-install-packages.sh
./03-setup-easyrsa.sh
./04-build-ca.sh            # Set CA password!
./05-generate-server-cert.sh
sudo ./06-copy-server-files.sh
sudo ./07-configure-server.sh
sudo ./08-configure-network.sh
sudo ./09-start-server.sh
./10-create-client.sh
```

### Add New Client
```bash
./10-create-client.sh
# OR
./add-client.sh client-name
```

### Test Connection
```bash
# Local test
sudo ~/client-configs/test-vpn-local.sh

# Remote test
sudo openvpn --config client.ovpn
```

### Server Management
```bash
# Status
sudo systemctl status openvpn-server@server

# Start/Stop/Restart
sudo systemctl start openvpn-server@server
sudo systemctl stop openvpn-server@server
sudo systemctl restart openvpn-server@server

# Logs
sudo journalctl -u openvpn-server@server -f
```

---

## 📞 Support

For issues or questions:
1. Check troubleshooting section above
2. Review logs: `sudo journalctl -u openvpn-server@server -n 100`
3. Verify all steps were completed in order
4. Check OpenVPN documentation: https://openvpn.net/community-resources/

---

## ✅ Setup Complete!

Your OpenVPN server is now ready to use. Remember to:

1. ✅ Configure router port forwarding
2. ✅ Keep your CA password safe
3. ✅ Transfer client configs securely
4. ✅ Test connections before relying on them
5. ✅ Monitor server logs regularly
6. ✅ Keep OpenVPN updated

Enjoy your secure VPN connection! 🔒
