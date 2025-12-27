# VPN Connection Verification Guide for Ubuntu Linux

## Table of Contents
1. [Overview](#overview)
2. [Before VPN Connection](#before-vpn-connection)
3. [After VPN Connection](#after-vpn-connection)
4. [Key Differences Explained](#key-differences-explained)
5. [Verification Commands](#verification-commands)
6. [Interface Verification](#interface-verification)
7. [DNS Leak Testing](#dns-leak-testing)
8. [IPv6 Leak Testing](#ipv6-leak-testing)
9. [Routing Table Verification](#routing-table-verification)
10. [Kill Switch Testing](#kill-switch-testing)
11. [Troubleshooting](#troubleshooting)
12. [Security Best Practices](#security-best-practices)

---

## Overview

This guide explains how to verify that your VPN connection is working correctly and that your real IP address is properly masked. Understanding these verification steps is crucial for maintaining privacy and security.

### What Changes When Connected to VPN?

1. **Public IP Address**: Changes from your ISP IP to VPN server IP
2. **Geographic Location**: Appears to be at VPN server location
3. **Network Interface**: New tunnel interface (tun0/tap0) created
4. **Routing Table**: Traffic routed through VPN tunnel
5. **DNS Servers**: May change to VPN provider's DNS
6. **ISP Visibility**: Your ISP only sees encrypted VPN traffic

---

## Before VPN Connection

### Check Your Real Public IP

```bash
# Method 1: Simple IP check
curl ifconfig.me
# Output: 203.0.113.45 (Your real ISP-assigned IP)

# Method 2: Detailed information
curl ipinfo.io
```

**Expected Output (Before VPN):**
```json
{
  "ip": "203.0.113.45",
  "hostname": "broadband.yourISP.com",
  "city": "Chennai",
  "region": "Tamil Nadu",
  "country": "IN",
  "loc": "13.0827,80.2707",
  "org": "AS12345 Your Internet Provider",
  "postal": "600001",
  "timezone": "Asia/Kolkata"
}
```

### Check VPN Interface Status

```bash
# Try to view VPN interface (should not exist yet)
ip addr show tun0
```

**Expected Output (Before VPN):**
```
Device "tun0" does not exist.
```

### Alternative Methods

```bash
# Using different IP check services
curl icanhazip.com
curl ipecho.net/plain
curl whatismyip.akamai.com
curl checkip.amazonaws.com

# Detailed check with headers
curl -s https://ipinfo.io | jq '.'
```

---

## After VPN Connection

### Connect to VPN First

```bash
# Example: OpenVPN connection
sudo openvpn --config /path/to/config.ovpn

# Example: WireGuard connection
sudo wg-quick up wg0

# Example: Using NetworkManager
nmcli connection up vpn-connection-name
```

### Verify IP Address Changed

```bash
# Check your new public IP (should be VPN server's IP)
curl ifconfig.me
# Output: 198.51.100.78 (VPN server's IP - different from before)

# Detailed information
curl ipinfo.io
```

**Expected Output (After VPN):**
```json
{
  "ip": "198.51.100.78",
  "hostname": "vpn-server-us.provider.com",
  "city": "New York",
  "region": "New York",
  "country": "US",
  "loc": "40.7128,-74.0060",
  "org": "AS54321 VPN Provider Inc",
  "postal": "10001",
  "timezone": "America/New_York"
}
```

### Verify VPN Interface Exists

```bash
# Check VPN tunnel interface (should now exist)
ip addr show tun0
```

**Expected Output (After VPN):**
```
3: tun0: <POINTOPOINT,MULTICAST,NOARP,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UNKNOWN group default qlen 500
    link/none 
    inet 10.8.0.2/24 scope global tun0
       valid_lft forever preferred_lft forever
    inet6 fe80::a1b2:c3d4:e5f6:7890/64 scope link stable-privacy 
       valid_lft forever preferred_lft forever
```

**Key Points:**
- **State**: Should be `UP` and `LOWER_UP`
- **Private IP**: Usually in ranges like 10.x.x.x or 172.16.x.x
- **Interface Type**: `POINTOPOINT` (tunnel interface)

---

## Key Differences Explained

### Comparison Table

| Aspect | Before VPN | After VPN | Why It Matters |
|--------|-----------|-----------|----------------|
| **Public IP** | 203.0.113.45 (Your ISP) | 198.51.100.78 (VPN Server) | Websites see VPN IP, not yours |
| **Location** | Chennai, India | New York, USA | Geo-restrictions bypassed |
| **ISP/Org** | Your Internet Provider | VPN Provider Inc | ISP sees only VPN provider |
| **Hostname** | broadband.yourISP.com | vpn-server-us.provider.com | Identifies connection type |
| **tun0 interface** | Does not exist | Active (10.8.0.2/24) | Confirms tunnel is established |
| **DNS Server** | ISP DNS (e.g., 8.8.8.8) | VPN DNS (e.g., 10.8.0.1) | Prevents DNS leaks |
| **Routing** | Direct to ISP gateway | Through VPN tunnel | All traffic encrypted |

### What Each Field Means

**IP Address:**
- **Before**: Your real IP that websites/services log
- **After**: VPN server's IP - your real IP is hidden

**City/Region/Country:**
- **Before**: Your actual physical location
- **After**: VPN server's location (can be anywhere)
- **Use Case**: Access geo-blocked content, bypass censorship

**Organization (org):**
- **Before**: Your ISP (e.g., "Airtel", "BSNL")
- **After**: VPN provider (e.g., "NordVPN", "ProtonVPN")
- **Privacy Benefit**: ISP can't track your browsing

**Hostname:**
- **Before**: ISP's hostname pattern
- **After**: VPN provider's hostname
- **Technical Indicator**: Confirms you're on VPN infrastructure

---

## Verification Commands

### Comprehensive Verification Script

```bash
#!/bin/bash
# VPN Verification Script

echo "=== VPN CONNECTION VERIFICATION ==="
echo ""

# 1. Public IP Check
echo "1. Public IP Address:"
PUBLIC_IP=$(curl -s ifconfig.me)
echo "   $PUBLIC_IP"
echo ""

# 2. Detailed IP Information
echo "2. IP Geolocation:"
curl -s ipinfo.io | jq '.'
echo ""

# 3. VPN Interface Check
echo "3. VPN Interface Status:"
if ip addr show tun0 &>/dev/null; then
    echo "   ✓ tun0 interface is UP"
    ip addr show tun0 | grep "inet "
elif ip addr show tap0 &>/dev/null; then
    echo "   ✓ tap0 interface is UP"
    ip addr show tap0 | grep "inet "
else
    echo "   ✗ No VPN interface found"
fi
echo ""

# 4. Default Gateway
echo "4. Default Gateway:"
ip route | grep default
echo ""

# 5. DNS Servers
echo "5. DNS Servers:"
cat /etc/resolv.conf | grep nameserver
echo ""

# 6. Active Connections
echo "6. VPN Connection Status:"
nmcli connection show --active | grep vpn
echo ""

echo "=== VERIFICATION COMPLETE ==="
```

### Save and Run the Script

```bash
# Save the script
cat > vpn-check.sh << 'EOF'
[paste script above]
EOF

# Make executable
chmod +x vpn-check.sh

# Run it
./vpn-check.sh
```

### Quick One-Liners

```bash
# Quick IP comparison (run before and after VPN)
echo "Public IP: $(curl -s ifconfig.me) | Location: $(curl -s ipinfo.io/city)"

# Check if VPN is active
ip addr show tun0 &>/dev/null && echo "VPN Active" || echo "VPN Inactive"

# Monitor IP changes in real-time
watch -n 5 'curl -s ifconfig.me'
```

---

## Interface Verification

### Check All Network Interfaces

```bash
# List all interfaces
ip addr show

# Check specific VPN interfaces
ip addr show tun0     # OpenVPN typically uses tun0
ip addr show tap0     # Some VPNs use tap0
ip addr show wg0      # WireGuard uses wg0
ip addr show ppp0     # PPTP/L2TP uses ppp0
```

### Interface Status Indicators

```bash
# Detailed interface information
ip -s link show tun0

# Statistics
ip -s -s link show tun0

# Interface flags meaning:
# UP           - Interface is enabled
# LOWER_UP     - Physical layer is up
# POINTOPOINT  - Point-to-point link (VPN tunnel)
# RUNNING      - Interface is operational
# MULTICAST    - Supports multicast
# NOARP        - No ARP protocol (not needed for tunnels)
```

### Check Interface Metrics

```bash
# Traffic statistics
ifconfig tun0
# OR
cat /sys/class/net/tun0/statistics/rx_bytes
cat /sys/class/net/tun0/statistics/tx_bytes

# Real-time monitoring
iftop -i tun0
# OR
nethogs tun0
```

---

## DNS Leak Testing

### What is a DNS Leak?

Even with VPN connected, if DNS queries go to your ISP's DNS servers instead of VPN's DNS, your browsing can be tracked.

### Check Current DNS Servers

```bash
# Method 1: Check resolv.conf
cat /etc/resolv.conf

# Expected (with VPN):
# nameserver 10.8.0.1        # VPN's DNS
# nameserver 10.8.0.2        # VPN's backup DNS

# Bad (DNS leak):
# nameserver 192.168.1.1     # Your router
# nameserver 8.8.8.8         # Google DNS (ISP can see)
```

### Advanced DNS Leak Testing

```bash
# Check which DNS server is actually being used
dig +short myip.opendns.com @resolver1.opendns.com

# Test DNS leak with multiple queries
for i in {1..5}; do
    dig +short whoami.akamai.net
done
# All results should show VPN IP, not your real IP

# Check systemd-resolved (if using)
systemd-resolve --status

# Check NetworkManager DNS
nmcli dev show | grep DNS
```

### Online DNS Leak Tests

```bash
# Browser-based tests (use curl to check)
curl -s https://dnsleaktest.com/ | grep -i "dns leak"

# Using specialized DNS leak test
curl -s https://dns.google/resolve?name=example.com

# Check which DNS resolver is used
nslookup -type=TXT whoami.akamai.net
```

### Fix DNS Leaks

```bash
# Method 1: Force VPN DNS in NetworkManager
nmcli connection modify vpn-name ipv4.dns "10.8.0.1,10.8.0.2"
nmcli connection modify vpn-name ipv4.ignore-auto-dns yes

# Method 2: Manually set DNS
sudo nano /etc/resolv.conf
# Add:
# nameserver 10.8.0.1
# nameserver 10.8.0.2

# Prevent overwriting
sudo chattr +i /etc/resolv.conf

# Method 3: Use OpenVPN's DNS push
# In .ovpn file, ensure:
# dhcp-option DNS 10.8.0.1

# Method 4: Use resolvconf
sudo apt install openresolv
# OpenVPN will automatically update DNS
```

---

## IPv6 Leak Testing

### Why IPv6 Leaks Matter

Many VPNs only tunnel IPv4 traffic. If your ISP supports IPv6, your real IPv6 address might leak even when VPN is active.

### Check for IPv6 Leaks

```bash
# Check your IPv6 address
curl -6 ifconfig.me

# Expected (secure):
# - Times out (no IPv6 connectivity)
# - Shows VPN's IPv6 address

# Bad (IPv6 leak):
# - Shows your real IPv6 address from ISP

# Alternative IPv6 check
curl -6 icanhazip.com
curl -6 ident.me
```

### Detailed IPv6 Analysis

```bash
# List IPv6 addresses
ip -6 addr show

# Check IPv6 routing
ip -6 route

# Test IPv6 connectivity
ping6 -c 3 google.com

# Check if IPv6 is working through VPN
traceroute6 google.com
```

### Fix IPv6 Leaks

```bash
# Method 1: Disable IPv6 completely (most secure)
sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1
sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1

# Make permanent
echo "net.ipv6.conf.all.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf

# Method 2: Block IPv6 in firewall
sudo ip6tables -P INPUT DROP
sudo ip6tables -P FORWARD DROP
sudo ip6tables -P OUTPUT DROP

# Method 3: Use VPN with IPv6 support
# Ensure your VPN provider supports IPv6
# Check VPN config for IPv6 settings
```

---

## Routing Table Verification

### Check Routing Table Before VPN

```bash
# View routing table
ip route show

# Example output (before VPN):
# default via 192.168.1.1 dev eth0 proto dhcp metric 100
# 192.168.1.0/24 dev eth0 proto kernel scope link src 192.168.1.100
```

### Check Routing Table After VPN

```bash
# View routing table after connecting
ip route show

# Example output (after VPN):
# default via 10.8.0.1 dev tun0 proto static metric 50
# 0.0.0.0/1 via 10.8.0.1 dev tun0
# 128.0.0.0/1 via 10.8.0.1 dev tun0
# 10.8.0.0/24 dev tun0 proto kernel scope link src 10.8.0.2
# 192.168.1.0/24 dev eth0 proto kernel scope link src 192.168.1.100
# [VPN_SERVER_IP] via 192.168.1.1 dev eth0
```

**Key Points:**
- Default route should go through `tun0` (or VPN interface)
- Lower metric = higher priority (VPN should have lower metric)
- VPN server IP should route through physical interface (eth0/wlan0)
- All other traffic routes through VPN

### Trace Route to Verify Path

```bash
# Before VPN - direct route
traceroute google.com
# Shows: Your ISP's routers

# After VPN - tunneled route
traceroute google.com
# Shows: VPN provider's network, then internet

# Detailed traceroute
mtr google.com
```

### Check Routing Table Details

```bash
# Show all routes with details
ip route show table all

# Show default route specifically
ip route get 8.8.8.8

# Expected (with VPN):
# 8.8.8.8 via 10.8.0.1 dev tun0 src 10.8.0.2 uid 1000

# Monitor route changes
ip monitor route
```

---

## Kill Switch Testing

A VPN kill switch prevents internet access if VPN disconnects, preventing IP leaks.

### Test Kill Switch Functionality

```bash
# 1. Connect to VPN and verify
curl ifconfig.me
# Note the VPN IP

# 2. Disconnect VPN suddenly
sudo killall openvpn
# OR
sudo wg-quick down wg0

# 3. Immediately test connectivity
curl ifconfig.me
# Expected: Connection should timeout or show error
# Bad: Shows your real IP (kill switch not working)

# 4. Check if any traffic is allowed
ping -c 3 8.8.8.8
# Expected: No response (kill switch active)
```

### Implement Kill Switch with iptables

```bash
#!/bin/bash
# VPN Kill Switch Script

# Variables
VPN_INTERFACE="tun0"
VPN_SERVER_IP="203.0.113.10"  # Your VPN server IP
LOCAL_NETWORK="192.168.1.0/24"

# Flush existing rules
sudo iptables -F
sudo iptables -X
sudo iptables -t nat -F
sudo iptables -t nat -X

# Default policy: DROP everything
sudo iptables -P INPUT DROP
sudo iptables -P FORWARD DROP
sudo iptables -P OUTPUT DROP

# Allow loopback
sudo iptables -A INPUT -i lo -j ACCEPT
sudo iptables -A OUTPUT -o lo -j ACCEPT

# Allow local network (optional)
sudo iptables -A INPUT -s $LOCAL_NETWORK -j ACCEPT
sudo iptables -A OUTPUT -d $LOCAL_NETWORK -j ACCEPT

# Allow connection to VPN server
sudo iptables -A OUTPUT -d $VPN_SERVER_IP -j ACCEPT
sudo iptables -A INPUT -s $VPN_SERVER_IP -j ACCEPT

# Allow VPN tunnel
sudo iptables -A INPUT -i $VPN_INTERFACE -j ACCEPT
sudo iptables -A OUTPUT -o $VPN_INTERFACE -j ACCEPT

# Allow established connections
sudo iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
sudo iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

echo "Kill switch enabled. Only VPN traffic allowed."
```

### Save and Restore Kill Switch Rules

```bash
# Save current rules
sudo iptables-save > /etc/iptables/vpn-killswitch.rules

# Restore rules on boot
sudo nano /etc/network/if-pre-up.d/iptables-restore
# Add:
# #!/bin/sh
# iptables-restore < /etc/iptables/vpn-killswitch.rules

# Make executable
sudo chmod +x /etc/network/if-pre-up.d/iptables-restore
```

### Alternative: UFW Kill Switch

```bash
# Reset UFW
sudo ufw --force reset

# Default deny all
sudo ufw default deny incoming
sudo ufw default deny outgoing

# Allow VPN server
sudo ufw allow out to [VPN_SERVER_IP] port [VPN_PORT]

# Allow VPN interface
sudo ufw allow out on tun0

# Allow local network (optional)
sudo ufw allow out to 192.168.1.0/24

# Enable UFW
sudo ufw enable
```

---

## Troubleshooting

### VPN Connected But Internet Not Working

```bash
# Check if VPN interface is up
ip addr show tun0

# Check routing
ip route show

# Test DNS resolution
nslookup google.com

# Check if IP forwarding is enabled (may need to be disabled)
cat /proc/sys/net/ipv4/ip_forward

# Restart network service
sudo systemctl restart NetworkManager
```

### IP Address Not Changing

```bash
# Verify VPN is actually connected
nmcli connection show --active

# Check if traffic is being routed through VPN
ip route get 8.8.8.8

# Check for route conflicts
ip route show | grep default

# Force DNS update
sudo systemctl restart systemd-resolved

# Clear DNS cache
sudo systemd-resolve --flush-caches
```

### DNS Not Working

```bash
# Check DNS configuration
cat /etc/resolv.conf

# Test DNS servers directly
dig @10.8.0.1 google.com
dig @8.8.8.8 google.com

# Check systemd-resolved status
systemd-resolve --status

# Restart DNS service
sudo systemctl restart systemd-resolved
```

### VPN Keeps Disconnecting

```bash
# Check VPN logs
sudo journalctl -u openvpn@client -f
# OR
sudo tail -f /var/log/syslog | grep vpn

# Check for MTU issues
ping -M do -s 1472 8.8.8.8
# If fails, try lower MTU:
sudo ip link set tun0 mtu 1400

# Test VPN server connectivity
ping [VPN_SERVER_IP]
traceroute [VPN_SERVER_IP]
```

### Interface Not Created

```bash
# Check if TUN/TAP module is loaded
lsmod | grep tun

# Load TUN module if needed
sudo modprobe tun

# Make permanent
echo "tun" | sudo tee -a /etc/modules

# Check permissions
ls -l /dev/net/tun
# Should be: crw-rw-rw-

# Fix permissions if needed
sudo chmod 666 /dev/net/tun
```

### IPv6 Leaking Despite VPN

```bash
# Confirm IPv6 leak
curl -6 ifconfig.me

# Disable IPv6 immediately
sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1

# Block IPv6 with firewall
sudo ip6tables -P OUTPUT DROP

# Check if disabled
ip -6 addr show
# Should show no addresses except ::1 (loopback)
```

---

## Security Best Practices

### Pre-Connection Checks

```bash
# 1. Verify VPN software integrity
dpkg -V openvpn
# OR
which openvpn | xargs md5sum

# 2. Check VPN configuration
cat /path/to/vpn.ovpn | grep -E "(cipher|auth|tls)"

# 3. Ensure kill switch is configured
sudo iptables -L -v -n

# 4. Verify DNS settings
cat /etc/resolv.conf
```

### During Connection

```bash
# Monitor connection in real-time
watch -n 1 'curl -s ifconfig.me'

# Check for leaks periodically
while true; do
    echo "$(date): $(curl -s ifconfig.me)"
    sleep 60
done

# Monitor VPN interface
watch -n 2 'ip -s link show tun0'
```

### Post-Connection Verification

```bash
# Complete verification checklist
echo "=== VPN Security Checklist ==="
echo "1. Public IP: $(curl -s ifconfig.me)"
echo "2. Location: $(curl -s ipinfo.io/city)"
echo "3. VPN Interface: $(ip addr show tun0 2>/dev/null | grep -q inet && echo "✓ Active" || echo "✗ Inactive")"
echo "4. DNS Servers: $(cat /etc/resolv.conf | grep nameserver)"
echo "5. IPv6: $(curl -6 -s --max-time 3 ifconfig.me 2>/dev/null || echo "✓ Disabled/Blocked")"
echo "6. Default Route: $(ip route | grep default)"
```

### Automated Monitoring Script

```bash
#!/bin/bash
# VPN Monitoring Script - Runs continuously

EXPECTED_VPN_IP="198.51.100.78"  # Your VPN IP
LOG_FILE="/var/log/vpn-monitor.log"

while true; do
    CURRENT_IP=$(curl -s --max-time 5 ifconfig.me)
    
    if [ "$CURRENT_IP" != "$EXPECTED_VPN_IP" ]; then
        echo "[$(date)] WARNING: IP changed to $CURRENT_IP" | tee -a $LOG_FILE
        # Optional: Take action
        # notify-send "VPN Leak Detected!"
        # killall firefox  # Close browser
    else
        echo "[$(date)] OK: VPN IP confirmed" >> $LOG_FILE
    fi
    
    sleep 300  # Check every 5 minutes
done
```

### Defense in Depth

```bash
# Layer 1: VPN Connection
# - Use reputable VPN provider
# - Enable kill switch
# - Use strong encryption (AES-256)

# Layer 2: Firewall
# - Block all non-VPN traffic
# - Disable IPv6 or tunnel it
# - Allow only VPN interface

# Layer 3: DNS Security
# - Use VPN's DNS only
# - Enable DNSSEC
# - Clear DNS cache after disconnection

# Layer 4: Application Level
# - Bind applications to VPN interface
# - Use SOCKS5 proxy over VPN
# - Disable WebRTC in browser

# Layer 5: Monitoring
# - Regular IP checks
# - DNS leak tests
# - Traffic analysis
```

### Bind Applications to VPN Interface

```bash
# Force application to use only VPN interface

# Method 1: Using firejail
sudo apt install firejail
firejail --net=tun0 firefox

# Method 2: Using network namespace
sudo ip netns add vpn_only
sudo ip link set tun0 netns vpn_only
sudo ip netns exec vpn_only firefox

# Method 3: Using proxychains with SOCKS proxy over VPN
sudo apt install proxychains
# Configure proxychains to use VPN's SOCKS proxy
proxychains firefox
```

---

## Quick Reference Commands

### Essential Checks

```bash
# Check public IP
curl ifconfig.me

# Check location
curl ipinfo.io/city

# Check VPN interface
ip addr show tun0

# Check routing
ip route | grep default

# Check DNS
cat /etc/resolv.conf | grep nameserver

# Full verification
curl -s ifconfig.me && ip addr show tun0 | grep inet && ip route | grep default
```

### Common VPN Commands

```bash
# Start VPN (OpenVPN)
sudo openvpn --config vpn.ovpn

# Start VPN (WireGuard)
sudo wg-quick up wg0

# Start VPN (NetworkManager)
nmcli connection up vpn-name

# Stop VPN
sudo killall openvpn
sudo wg-quick down wg0
nmcli connection down vpn-name

# Check VPN status
systemctl status openvpn@client
nmcli connection show --active
```

### One-Line Verifications

```bash
# Complete check
echo "IP: $(curl -s ifconfig.me) | VPN: $(ip addr show tun0 &>/dev/null && echo "Yes" || echo "No")"

# Location check
curl -s ipinfo.io | jq -r '"\(.ip) - \(.city), \(.country)"'

# DNS leak check
dig +short myip.opendns.com @resolver1.opendns.com

# IPv6 check
curl -6 -s --max-time 3 ifconfig.me 2>/dev/null || echo "IPv6 blocked ✓"
```

---

## Testing Scenarios

### Scenario 1: Basic VPN Test

```bash
# 1. Record your real IP
REAL_IP=$(curl -s ifconfig.me)
echo "Real IP: $REAL_IP"

# 2. Connect to VPN
sudo openvpn --config vpn.ovpn &

# 3. Wait for connection
sleep 10

# 4. Check new IP
VPN_IP=$(curl -s ifconfig.me)
echo "VPN IP: $VPN_IP"

# 5. Verify they're different
if [ "$REAL_IP" != "$VPN_IP" ]; then
    echo "✓ VPN is working"
else
    echo "✗ VPN failed"
fi
```

### Scenario 2: Kill Switch Test

```bash
# 1. Connect to VPN and verify
curl ifconfig.me > /tmp/vpn_ip.txt

# 2. Enable kill switch
sudo iptables -P OUTPUT DROP
sudo iptables -A OUTPUT -o tun0 -j ACCEPT

# 3. Kill VPN connection
sudo killall openvpn

# 4. Try to access internet
timeout 5 curl ifconfig.me
# Should timeout (kill switch working)
```

### Scenario 3: DNS Leak Test

```bash
# 1. Check DNS before VPN
dig google.com | grep SERVER

# 2. Connect to VPN
sudo openvpn --config vpn.ovpn &
sleep 10

# 3. Check DNS after VPN
dig google.com | grep SERVER
# Should show VPN DNS, not ISP DNS
```

---

## Additional Resources

### Useful Websites

- **IP Check**: https://ifconfig.me, https://ipinfo.io
- **DNS Leak Test**: https://dnsleaktest.com
- **IPv6 Leak Test**: https://test-ipv6.com
- **WebRTC Leak Test**: https://browserleaks.com/webrtc

### Tools to Install

```bash
# Essential tools
sudo apt install curl jq dig traceroute mtr

# Network analysis
sudo apt install wireshark tcpdump iptraf-ng

# VPN tools
sudo apt install openvpn wireguard network-manager-openvpn

# Firewall
sudo apt install ufw iptables-persistent
```

### Related Documentation

- OpenVPN Documentation: https://openvpn.net/community-resources/
- WireGuard Documentation: https://www.wireguard.com/quickstart/
- IPTables Tutorial: https://www.frozentux.net/iptables-tutorial/
- NetworkManager VPN: https://wiki.gnome.org/Projects/NetworkManager/VPN

---

## Legal and Ethical Considerations

### Legitimate Uses of VPN

1. **Privacy Protection**: Protect browsing from ISP tracking
2. **Security on Public WiFi**: Encrypt traffic on untrusted networks
3. **Remote Work**: Secure access to company resources
4. **Bypass Censorship**: Access blocked content in restrictive regions
5. **Geo-restrictions**: Access region-locked content you're entitled to

### Important Warnings

⚠️ **Using a VPN does NOT make you anonymous or untraceable**

⚠️ **VPNs do not protect against:**
- Malware and viruses
- Phishing attacks
- Browser fingerprinting
- Account-based tracking (cookies, login sessions)
- WebRTC leaks (disable in browser)

⚠️ **Legal Considerations:**
- VPN use is legal in most countries
- Using VPN for illegal activities is still illegal
- Some countries restrict or ban VPN use
- Always comply with terms of service

---

**Remember**: A VPN is one tool in a comprehensive security strategy. Verify your connection regularly and combine VPN use with other security best practices.
