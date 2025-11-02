# Smart TV Bandwidth Limiter for Ubuntu Linux

A collection of scripts and tools to limit bandwidth for specific devices (Smart TVs) on your home network when your router lacks QoS functionality.

## 📋 Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Solutions Included](#solutions-included)
- [Script Documentation](#script-documentation)
- [Configuration](#configuration)
- [Monitoring](#monitoring)
- [Troubleshooting](#troubleshooting)
- [FAQ](#faq)
- [Legal Notice](#legal-notice)

---

## 🎯 Overview

This package provides multiple solutions to limit network bandwidth for specific devices (particularly Smart TVs) on your LAN, ensuring adequate bandwidth remains available for work computers and laptops.

### What's Included

- **6 Shell Scripts** - Ready-to-use bandwidth limiting solutions
- **Multiple Approaches** - IP-based, MAC-based, and interface-based limiting
- **Monitoring Tools** - Scripts to monitor bandwidth usage
- **Easy Cleanup** - Remove all configurations with one command
- **Comprehensive Documentation** - This README with detailed instructions

---

## 🔧 Prerequisites

### Hardware Requirements

**Option 1: Existing Ubuntu Machine**
- Ubuntu Linux 18.04+ (Desktop or Server)
- Two network interfaces (physical or virtual)
- Machine positioned between router and devices to limit

**Option 2: Raspberry Pi (Recommended for dedicated solution)**
- Raspberry Pi 3B+ or newer
- Ubuntu Server or Raspbian OS
- USB to Ethernet adapter (for second interface) or use WiFi + Ethernet

### Software Requirements

```bash
# Install required packages
sudo apt update
sudo apt install -y \
    iproute2 \
    iptables \
    iptables-persistent \
    net-tools \
    tcpdump \
    iftop \
    nethogs
```

### Network Setup

Your network should be configured as follows:

```
Internet → Router → Linux Gateway → Switch → Devices
                         ↓
                    Limited Devices
```

---

## 🚀 Quick Start

### Step 1: Identify Your Smart TVs

```bash
# Scan your network
sudo nmap -sn 192.168.1.0/24

# Or list DHCP leases
cat /var/lib/dhcp/dhclient.leases
```

### Step 2: Choose Your Script

**For IP-based limiting (easiest):**
```bash
chmod +x setup_traffic_shaping.sh
sudo ./setup_traffic_shaping.sh
```

**For MAC-based limiting (more reliable):**
```bash
chmod +x limit_by_mac.sh
sudo ./limit_by_mac.sh
```

**For Raspberry Pi:**
```bash
chmod +x raspberry_pi_setup.sh
sudo ./raspberry_pi_setup.sh
```

### Step 3: Monitor Results

```bash
chmod +x monitor_traffic.sh
sudo ./monitor_traffic.sh
```

### Step 4: Remove Limits (if needed)

```bash
chmod +x remove_limits.sh
sudo ./remove_limits.sh
```

---

## 📦 Solutions Included

### Solution 1: IP-Based Traffic Shaping (setup_traffic_shaping.sh)

**Best for:** Quick setup, static IP assignments
**Pros:** Easy to configure, straightforward
**Cons:** Requires static IPs for devices

**How it works:**
- Uses Linux Traffic Control (tc) with HTB (Hierarchical Token Bucket)
- Creates separate classes for limited and unlimited devices
- Filters traffic by destination IP address

### Solution 2: MAC-Based Traffic Shaping (limit_by_mac.sh)

**Best for:** Devices with dynamic IPs
**Pros:** More reliable, survives DHCP changes
**Cons:** Slightly more complex setup

**How it works:**
- Uses iptables to mark packets by MAC address
- Uses tc to apply bandwidth limits to marked packets
- Works regardless of IP address changes

### Solution 3: Interface-Based Limiting (limit_by_interface.sh)

**Best for:** Separate physical network for Smart TVs
**Pros:** Simple, affects all traffic on interface
**Cons:** Requires separate network interface

**How it works:**
- Applies bandwidth limit to entire network interface
- All devices on that interface share the bandwidth limit

### Solution 4: Raspberry Pi Gateway (raspberry_pi_setup.sh)

**Best for:** Dedicated hardware solution
**Pros:** Doesn't use main computer resources, always-on
**Cons:** Requires Raspberry Pi hardware

**How it works:**
- Configures Raspberry Pi as network gateway
- Routes Smart TV traffic through the Pi
- Applies bandwidth limits on the Pi

---

## 📖 Script Documentation

### setup_traffic_shaping.sh

Main traffic shaping script using IP-based filtering.

**Configuration variables:**
```bash
ROUTER_INTERFACE="eth0"      # Interface to router
LAN_INTERFACE="eth1"         # Interface to LAN
SMART_TV_IPS=(...)          # Array of Smart TV IPs
BANDWIDTH_LIMIT="5mbit"      # Limit per device
```

**Usage:**
```bash
sudo ./setup_traffic_shaping.sh
```

**What it does:**
1. Enables IP forwarding
2. Creates HTB qdisc on LAN interface
3. Creates bandwidth-limited class for Smart TVs
4. Creates unlimited class for other devices
5. Sets up iptables NAT/masquerading

---

### limit_by_mac.sh

MAC address-based traffic limiting (more reliable).

**Configuration variables:**
```bash
INTERFACE="eth0"
declare -A DEVICES=(
    ["aa:bb:cc:dd:ee:ff"]="SmartTV1"
    ["11:22:33:44:55:66"]="SmartTV2"
)
BANDWIDTH="5mbit"
```

**Usage:**
```bash
sudo ./limit_by_mac.sh
```

**What it does:**
1. Creates tc classes for each MAC address
2. Uses iptables mangle table to mark packets
3. Filters marked packets to limited classes
4. Works with any IP address

**Find MAC addresses:**
```bash
# Scan network for MAC addresses
sudo nmap -sn 192.168.1.0/24 | grep "MAC Address"

# Or use arp
arp -a
```

---

### limit_by_interface.sh

Simple per-interface bandwidth limiting.

**Configuration variables:**
```bash
LIMITED_INTERFACE="eth1"     # Interface for Smart TVs
BANDWIDTH_LIMIT="20mbit"     # Total for all devices
```

**Usage:**
```bash
sudo ./limit_by_interface.sh
```

**When to use:**
- You have Smart TVs on a separate network interface
- You want to limit total bandwidth for that interface
- Simplest solution if hardware allows

---

### raspberry_pi_setup.sh

Complete setup script for Raspberry Pi as gateway.

**Usage:**
```bash
sudo ./raspberry_pi_setup.sh
```

**What it does:**
1. Configures network interfaces
2. Enables IP forwarding
3. Sets up traffic shaping
4. Configures as system service (auto-start on boot)
5. Creates monitoring dashboard

**Hardware setup:**
```
Router (192.168.1.1)
  ↓
Raspberry Pi eth0 (192.168.1.2)
  ↓
Raspberry Pi eth1 (192.168.2.1) ← New subnet for Smart TVs
  ↓
Smart TVs (192.168.2.x)
```

---

### monitor_traffic.sh

Real-time traffic monitoring and statistics.

**Usage:**
```bash
sudo ./monitor_traffic.sh
```

**Features:**
- Shows current bandwidth usage per device
- Displays tc statistics
- Shows top bandwidth consumers
- Real-time updates every 2 seconds

**Example output:**
```
=== Traffic Control Statistics ===
class htb 1:10 rate 5000Kbit ceil 10000Kbit
 Sent 45623456 bytes 12345 pkt
 rate 4.8Mbit

=== Top Bandwidth Consumers ===
192.168.1.100    4.8 Mbps
192.168.1.101    2.3 Mbps
```

---

### remove_limits.sh

Complete cleanup script to remove all bandwidth limiting.

**Usage:**
```bash
sudo ./remove_limits.sh
```

**What it does:**
1. Removes all tc qdiscs and classes
2. Clears iptables rules
3. Disables IP forwarding (optional)
4. Restores normal network operation

**Safe to run multiple times** - will show warnings but not cause issues.

---

## ⚙️ Configuration

### Common Configuration Tasks

#### 1. Change Bandwidth Limits

Edit the script and modify:
```bash
BANDWIDTH_LIMIT="5mbit"    # Change to desired speed
# Options: 1mbit, 5mbit, 10mbit, 100kbit, etc.
```

#### 2. Add More Devices

**For IP-based:**
```bash
SMART_TV_IPS=(
    "192.168.1.100"
    "192.168.1.101"
    "192.168.1.102"
    "192.168.1.103"    # Add new IP here
)
```

**For MAC-based:**
```bash
declare -A DEVICES=(
    ["aa:bb:cc:dd:ee:ff"]="SmartTV1"
    ["11:22:33:44:55:66"]="SmartTV2"
    ["12:34:56:78:90:ab"]="SmartTV3"    # Add new MAC here
)
```

#### 3. Set Static IPs on Router

For IP-based limiting to work reliably:
1. Access router admin panel (usually 192.168.1.1)
2. Find DHCP settings
3. Add static/reserved IP for each Smart TV MAC address
4. Restart Smart TVs or renew DHCP lease

#### 4. Make Scripts Start on Boot

```bash
# Create systemd service
sudo nano /etc/systemd/system/bandwidth-limiter.service
```

Add:
```ini
[Unit]
Description=Bandwidth Limiter for Smart TVs
After=network.target

[Service]
Type=oneshot
ExecStart=/path/to/setup_traffic_shaping.sh
RemainAfterExit=yes
ExecStop=/path/to/remove_limits.sh

[Install]
WantedBy=multi-user.target
```

Enable:
```bash
sudo systemctl daemon-reload
sudo systemctl enable bandwidth-limiter.service
sudo systemctl start bandwidth-limiter.service
```

---

## 📊 Monitoring

### Real-Time Traffic Monitoring

**Using included script:**
```bash
sudo ./monitor_traffic.sh
```

**Manual monitoring commands:**

```bash
# Watch tc statistics
watch -n 1 'tc -s class show dev eth0'

# Monitor specific IP
sudo iftop -i eth0 -f "host 192.168.1.100"

# See which processes use bandwidth
sudo nethogs eth0

# Packet capture for analysis
sudo tcpdump -i eth0 -n host 192.168.1.100
```

### Check If Limits Are Working

```bash
# View tc configuration
tc -s qdisc show dev eth0
tc -s class show dev eth0
tc filter show dev eth0

# Check iptables rules
sudo iptables -t nat -L -v -n
sudo iptables -t mangle -L -v -n

# Verify IP forwarding
cat /proc/sys/net/ipv4/ip_forward
# Should output: 1
```

### Bandwidth Testing

From Smart TV or limited device:
1. Open browser and go to https://fast.com
2. Run speed test
3. Should see speeds limited to configured value

From unlimited device:
1. Should see full speed available

---

## 🔧 Troubleshooting

### Problem: Limits Not Applied

**Check 1: Verify tc is configured**
```bash
tc -s class show dev eth0
# Should show classes with your bandwidth limits
```

**Check 2: Verify IP forwarding**
```bash
cat /proc/sys/net/ipv4/ip_forward
# Should be 1

# If not:
sudo sysctl -w net.ipv4.ip_forward=1
```

**Check 3: Verify iptables rules**
```bash
sudo iptables -t nat -L -v -n
# Should show MASQUERADE rule

# If not, run:
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
```

**Check 4: Correct interface names**
```bash
ip link show
# Verify interface names match script configuration
```

---

### Problem: No Internet on Limited Devices

**Check 1: IP forwarding enabled**
```bash
sudo sysctl -w net.ipv4.ip_forward=1
```

**Check 2: iptables FORWARD rules**
```bash
sudo iptables -P FORWARD ACCEPT
sudo iptables -A FORWARD -i eth1 -o eth0 -j ACCEPT
sudo iptables -A FORWARD -i eth0 -o eth1 -m state --state RELATED,ESTABLISHED -j ACCEPT
```

**Check 3: NAT configured**
```bash
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
```

**Check 4: Device gateway setting**
- Smart TV network settings should point to Linux gateway IP
- Not directly to router

---

### Problem: All Devices Slow

**Check 1: Total bandwidth allocation**
```bash
tc class show dev eth0
# Ensure root class has sufficient bandwidth
```

**Check 2: Default class**
```bash
# Ensure unlimited devices use high-bandwidth class
tc qdisc show dev eth0 | grep "default"
```

**Fix:**
```bash
# Recreate with higher limits
sudo ./remove_limits.sh
# Edit script to increase limits
sudo ./setup_traffic_shaping.sh
```

---

### Problem: Script Fails to Run

**Check 1: Permissions**
```bash
chmod +x *.sh
```

**Check 2: Running as root**
```bash
sudo ./setup_traffic_shaping.sh
```

**Check 3: Dependencies installed**
```bash
sudo apt install iproute2 iptables net-tools
```

**Check 4: Script syntax errors**
```bash
bash -n setup_traffic_shaping.sh
# Should not show any errors
```

---

### Problem: Raspberry Pi Not Routing

**Check 1: Both interfaces up**
```bash
ip link show
# Both eth0 and eth1 should be UP
```

**Check 2: IP addresses assigned**
```bash
ip addr show
# Each interface should have IP
```

**Check 3: Default route**
```bash
ip route show
# Should show default via router IP
```

**Fix routing:**
```bash
sudo ip route add default via 192.168.1.1 dev eth0
```

---

## ❓ FAQ

### Q: Which script should I use?

**A:** Start with `setup_traffic_shaping.sh` (IP-based) if:
- You can assign static IPs to your Smart TVs
- You want the simplest solution
- You're new to Linux networking

Use `limit_by_mac.sh` if:
- Your Smart TVs get dynamic IPs
- You want a more robust solution
- You're comfortable with slightly more complexity

Use `raspberry_pi_setup.sh` if:
- You have a Raspberry Pi to dedicate
- You want an always-on solution
- You don't want to use your main computer

---

### Q: How much bandwidth should I limit to?

**A:** Typical recommendations:
- **SD streaming (480p)**: 3-5 Mbps per TV
- **HD streaming (720p)**: 5-8 Mbps per TV
- **Full HD (1080p)**: 8-12 Mbps per TV
- **4K streaming**: 25+ Mbps per TV

For multiple TVs, set limit per TV based on highest expected use.

Example: If you have 2 Smart TVs and want to allow HD streaming:
```bash
BANDWIDTH_LIMIT="10mbit"  # Per TV
```

---

### Q: Will this work with WiFi devices?

**A:** Yes, but setup differs:
- For WiFi Smart TVs connected to same router, use IP or MAC-based limiting
- Traffic shaping applies regardless of connection type (wired/wireless)
- Ensure your Linux gateway is in the path of WiFi traffic

---

### Q: Can I limit bandwidth for phones/tablets?

**A:** Absolutely! Just add their IPs or MAC addresses:

```bash
SMART_TV_IPS=(
    "192.168.1.100"    # Smart TV
    "192.168.1.101"    # Smart TV
    "192.168.1.150"    # Tablet
    "192.168.1.151"    # Phone
)
```

---

### Q: Does this slow down my computer?

**A:** Minimal impact:
- tc uses very little CPU (< 1%)
- RAM usage is negligible (< 10 MB)
- No noticeable performance impact on modern hardware
- Raspberry Pi handles this easily

---

### Q: Can I have different limits for different devices?

**A:** Yes! Modify the script to create multiple classes:

```bash
# TV1: 5 Mbps
tc class add dev eth0 parent 1:1 classid 1:10 htb rate 5mbit
tc filter add dev eth0 protocol ip parent 1:0 prio 1 u32 match ip dst 192.168.1.100 flowid 1:10

# TV2: 10 Mbps
tc class add dev eth0 parent 1:1 classid 1:20 htb rate 10mbit
tc filter add dev eth0 protocol ip parent 1:0 prio 1 u32 match ip dst 192.168.1.101 flowid 1:20
```

---

### Q: How do I remove all limits?

**A:** Simple:
```bash
sudo ./remove_limits.sh
```

This completely removes all bandwidth limiting and restores normal operation.

---

### Q: Will this survive a reboot?

**A:** Not by default. To make persistent:

1. Save iptables rules:
```bash
sudo iptables-save > /etc/iptables/rules.v4
```

2. Create systemd service (see Configuration section)

3. Or add to rc.local:
```bash
sudo nano /etc/rc.local
# Add before "exit 0":
/path/to/setup_traffic_shaping.sh
```

---

### Q: Can I use this on Windows or Mac?

**A:** These scripts are for Linux only. However:
- **Windows**: Use WSL2 (Windows Subsystem for Linux) with limitations
- **Mac**: macOS has `pfctl` for traffic shaping (different syntax)
- **Both**: Consider running Ubuntu in VirtualBox as gateway

---

### Q: Is this legal?

**A:** Yes, on your own network:
- ✅ You own the network and devices
- ✅ You're managing your own bandwidth
- ✅ No external networks affected

Not legal if:
- ❌ You're on a shared network without permission
- ❌ You're limiting others' devices without consent
- ❌ You're bypassing ISP or organization policies

---

### Q: Why is my Smart TV still buffering?

**A:** Check:
1. Total bandwidth limit isn't too low
2. Multiple devices not exceeding total available bandwidth
3. ISP connection is stable (check with speed test)
4. Smart TV software updated
5. Streaming quality set appropriately in app

---

### Q: Can I prioritize certain traffic types?

**A:** Yes! Advanced configuration example:

```bash
# Prioritize gaming traffic
tc filter add dev eth0 protocol ip parent 1:0 prio 1 u32 \
    match ip dport 3074 0xffff flowid 1:30  # Xbox Live

# Deprioritize torrents
tc filter add dev eth0 protocol ip parent 1:0 prio 2 u32 \
    match ip dport 6881 0xffff flowid 1:10  # BitTorrent
```

---

## 📚 Additional Resources

### Learn More About Traffic Control

- [Linux Advanced Routing & Traffic Control HOWTO](https://lartc.org/)
- [tc man page](https://man7.org/linux/man-pages/man8/tc.8.html)
- [HTB (Hierarchical Token Bucket) guide](https://luxik.cdi.cz/~devik/qos/htb/)

### Network Monitoring Tools

- **iftop**: Real-time bandwidth monitoring
- **nethogs**: Per-process network usage
- **bmon**: Bandwidth monitor
- **vnstat**: Network statistics logger

Install all:
```bash
sudo apt install iftop nethogs bmon vnstat
```

### Alternative Solutions

- **OpenWrt/DD-WRT**: Custom router firmware with QoS
- **pfSense**: Full-featured firewall/router OS
- **Untangle**: Network gateway with traffic shaping
- **Ubiquiti EdgeRouter**: Commercial solution with excellent QoS

---

## ⚠️ Legal Notice

### Terms of Use

This software is provided "AS IS" without warranty of any kind. Use at your own risk.

### Acceptable Use

✅ **Permitted:**
- Use on networks you own or manage
- Personal home network management
- Authorized network administration
- Educational purposes in controlled environments

❌ **Prohibited:**
- Use on networks without authorization
- Interference with others' network services
- Violation of ISP terms of service
- Any illegal network manipulation

### Liability

- Authors are not responsible for network disruptions
- Users are responsible for proper configuration
- Test in non-production environments first
- Backup configurations before making changes

### Privacy

These scripts:
- Do NOT collect or transmit personal data
- Do NOT log browsing history
- Do NOT decrypt HTTPS traffic
- Only manage bandwidth allocation

---

## 🤝 Contributing

Found a bug? Have an improvement? Contributions welcome!

### Reporting Issues

Include:
- Ubuntu version (`lsb_release -a`)
- Script name and version
- Error messages
- Network configuration
- Steps to reproduce

### Submitting Improvements

1. Test thoroughly on your network
2. Comment code clearly
3. Update README if needed
4. Ensure backwards compatibility

---

## 📄 Version History

- **v1.0.0** (2025-11-02): Initial release
  - IP-based traffic shaping
  - MAC-based traffic shaping
  - Interface-based limiting
  - Raspberry Pi setup
  - Monitoring tools
  - Cleanup scripts

---

## 📞 Support

### Quick Help

- Check [Troubleshooting](#troubleshooting) section
- Review [FAQ](#faq)
- Run diagnostic: `sudo ./monitor_traffic.sh`

### Need More Help?

- Ubuntu Forums: https://ubuntuforums.org/
- Ask Ubuntu: https://askubuntu.com/
- Linux Networking: r/linuxnetworking

---

## 🎓 Credits

Created with ❤️ for the Ubuntu community

Based on:
- Linux Traffic Control (tc) documentation
- iptables/netfilter framework
- Community best practices

---

## 📝 License

This project is free and open source.

You are free to:
- Use for personal or commercial purposes
- Modify and adapt for your needs
- Share with others

Please:
- Give credit where appropriate
- Share improvements with the community
- Use responsibly and ethically

---

**Remember**: With great bandwidth comes great responsibility! 🚀

Happy bandwidth limiting! 🎉
