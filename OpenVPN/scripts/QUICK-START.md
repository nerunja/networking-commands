# OpenVPN Setup - Quick Reference

## Installation Order

Run these scripts in exact order:

```bash
# 1. CLEANUP (sudo required)
sudo ./01-cleanup.sh

# 2. INSTALL (sudo required)
sudo ./02-install-packages.sh

# 3. SETUP EASYRSA (regular user - NO sudo)
./03-setup-easyrsa.sh

# 4. BUILD CA (regular user - NO sudo)
./04-build-ca.sh
# ⚠️  SAVE THE CA PASSWORD!

# 5. GENERATE CERTS (regular user - NO sudo)
./05-generate-server-cert.sh
# ⏱️  Takes 5-30 minutes

# 6. COPY FILES (sudo required)
sudo ./06-copy-server-files.sh

# 7. CONFIGURE SERVER (sudo required)
sudo ./07-configure-server.sh

# 8. CONFIGURE NETWORK (sudo required)
sudo ./08-configure-network.sh

# 9. START SERVER (sudo required)
sudo ./09-start-server.sh

# 10. CREATE CLIENT (regular user - NO sudo)
./10-create-client.sh
```

## First Time Setup

```bash
# Download/extract scripts to directory
cd openvpn-setup

# Make executable (do this first!)
chmod +x *.sh

# Run in order (see above)
sudo ./01-cleanup.sh
# ... continue with rest
```

## Important Notes

### Sudo vs Regular User

**WITH sudo (run as root):**
- 01-cleanup.sh
- 02-install-packages.sh
- 06-copy-server-files.sh
- 07-configure-server.sh
- 08-configure-network.sh
- 09-start-server.sh

**WITHOUT sudo (run as regular user):**
- 03-setup-easyrsa.sh
- 04-build-ca.sh
- 05-generate-server-cert.sh
- 10-create-client.sh

### CA Password

- Set in step 4 (04-build-ca.sh)
- Needed when creating new clients
- Cannot be recovered if lost
- Save in password manager!

### Time Requirements

- Steps 1-4: ~5 minutes
- Step 5: **5-30 minutes** (DH generation)
- Steps 6-10: ~10 minutes
- **Total: 20-45 minutes**

## After Setup

### Verify Server

```bash
# Check status
sudo systemctl status openvpn-server@server

# View logs
sudo journalctl -u openvpn-server@server -f

# Check interface
ip addr show tun0

# Check port
sudo ss -tulpn | grep 1194
```

### Router Configuration

**Required:** Forward port 1194 (UDP) to your server

1. Router admin panel (usually 192.168.1.1)
2. Port Forwarding / Virtual Server
3. External: 1194 UDP → Internal: [server-ip]:1194
4. Save and apply

### Connect from Client

**Linux:**
```bash
sudo openvpn --config client.ovpn
```

**Ubuntu Desktop:**
```bash
sudo nmcli connection import type openvpn file client.ovpn
# Then: Network Manager → VPN → Connect
```

**Windows:**
1. Install OpenVPN GUI
2. Copy .ovpn to `C:\Program Files\OpenVPN\config\`
3. Right-click → Connect

**Android/iOS:**
1. Install OpenVPN app
2. Import .ovpn file
3. Connect

### Add More Clients

```bash
# Use helper script (created by step 10)
./add-client.sh laptop
./add-client.sh phone
./add-client.sh tablet

# Needs CA password each time
```

### Revoke Client

```bash
cd ~/openvpn-ca
./easyrsa revoke clientname
./easyrsa gen-crl
sudo cp pki/crl.pem /etc/openvpn/server/

# Add to server.conf (if not present):
# crl-verify crl.pem

sudo systemctl restart openvpn-server@server
```

## Common Commands

### Server Management

```bash
# Status
sudo systemctl status openvpn-server@server

# Start
sudo systemctl start openvpn-server@server

# Stop
sudo systemctl stop openvpn-server@server

# Restart
sudo systemctl restart openvpn-server@server

# Logs
sudo journalctl -u openvpn-server@server -f
sudo tail -f /var/log/openvpn/openvpn.log
```

### Monitoring

```bash
# Connected clients
sudo cat /var/log/openvpn/openvpn-status.log | grep CLIENT_LIST

# Server details
sudo cat /var/log/openvpn/openvpn-status.log

# Network stats
ip -s link show tun0
```

### Testing

```bash
# From client:

# Check VPN interface
ip addr show tun0

# Ping server
ping 10.8.0.1

# Check public IP
curl ifconfig.me

# Test DNS
nslookup google.com
```

## Troubleshooting

### Server Won't Start

```bash
# Check logs
sudo journalctl -u openvpn-server@server -n 50

# Test config
sudo openvpn --config /etc/openvpn/server/server.conf

# Check files
ls -la /etc/openvpn/server/
```

### Client Can't Connect

```bash
# Server checks:
sudo systemctl status openvpn-server@server
sudo ufw status | grep 1194
sudo ss -tulpn | grep 1194

# Client checks:
ping server-ip
telnet server-ip 1194
```

### No Internet Through VPN

```bash
# Check IP forwarding
cat /proc/sys/net/ipv4/ip_forward  # Should be 1

# Check NAT
sudo iptables -t nat -L POSTROUTING

# Fix if needed
sudo iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE
```

## File Locations

```bash
~/openvpn-ca/              # CA and certificates
~/client-configs/          # Client .ovpn files
/etc/openvpn/server/       # Server config and certs
/var/log/openvpn/          # Logs
```

## Security Checklist

- [ ] CA password saved securely
- [ ] Router port forwarding configured
- [ ] One certificate per device
- [ ] .ovpn files transferred securely
- [ ] Devices encrypted
- [ ] Backup created
- [ ] Firewall enabled
- [ ] Server auto-start enabled

## Quick Backup

```bash
# Backup CA (important!)
tar -czf openvpn-ca-backup-$(date +%Y%m%d).tar.gz ~/openvpn-ca

# Backup server config
sudo tar -czf openvpn-server-backup-$(date +%Y%m%d).tar.gz /etc/openvpn/server

# Copy to safe location
cp *.tar.gz /path/to/backup/
```

## Getting Help

1. Check README.md for detailed info
2. Review logs: `sudo journalctl -u openvpn-server@server`
3. Test each step individually
4. Verify prerequisites are met

---

**Remember:** Run scripts in order, pay attention to sudo requirements, save CA password!
