# Quick Start Guide for Existing WiFi Setup

## Your Current Situation

You have:
- ✅ WiFi router with DHCP
- ✅ All devices connect directly to WiFi
- ✅ Ubuntu Linux machine on the same network

**The scripts won't work as-is** because traffic doesn't flow through your Linux machine.

---

## Solution Options (Choose One)

### 🌟 Option 1: Manual Gateway Configuration (Recommended)

**What:** Change Smart TV settings to use your Linux machine as gateway

**Pros:**
- ✅ Simple and reliable
- ✅ No additional hardware needed
- ✅ Works with all the provided scripts

**Cons:**
- ❌ Must configure each Smart TV manually
- ❌ Need to know your Linux machine's IP

**Steps:**

1. **Find your Linux machine's IP:**
```bash
ip addr show | grep "inet " | grep -v 127.0.0.1
# Example output: 192.168.1.50
```

2. **Enable your Linux machine as a gateway:**
```bash
# Enable IP forwarding
sudo sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf

# Enable NAT
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo iptables -A FORWARD -j ACCEPT

# Save rules
sudo netfilter-persistent save
```

3. **Configure each Smart TV:**
   - Go to: Settings → Network → Network Settings
   - Change from "Automatic (DHCP)" to "Manual" or "Static"
   - Enter:
     - **IP Address:** 192.168.1.100 (choose unused IP)
     - **Subnet Mask:** 255.255.255.0
     - **Gateway:** 192.168.1.50 (YOUR Linux machine IP)
     - **DNS 1:** 8.8.8.8
     - **DNS 2:** 8.8.4.4

4. **Apply bandwidth limits:**
```bash
sudo ./limit_by_mac.sh
# or
sudo ./setup_traffic_shaping.sh
```

5. **Test:** Visit fast.com on Smart TV - should see limited speed

---

### 🔧 Option 2: Create Separate Smart TV WiFi Network

**What:** Turn your Linux machine into a WiFi access point for Smart TVs

**Pros:**
- ✅ Automatic - no per-device configuration
- ✅ Clean separation
- ✅ Easy to manage

**Cons:**
- ❌ Requires WiFi adapter on Linux machine
- ❌ Smart TVs must manually connect to new network once

**Steps:**

1. **Check if you have WiFi interface:**
```bash
ip link show | grep wlan
# Should show: wlan0 or similar
```

2. **Run the WiFi AP script:**
```bash
sudo ./wifi_ap_limiter.sh
```

3. **Connect Smart TVs to the new WiFi:**
   - Network name (SSID): **SmartTV_Limited**
   - Password: **smarttv2024**

4. **Done!** Bandwidth is automatically limited

5. **Keep your computers on the original WiFi** (unlimited speed)

---

### ⚠️ Option 3: Transparent Interception (Advanced)

**What:** Use ARP spoofing to intercept traffic without configuration changes

**Pros:**
- ✅ No device configuration needed
- ✅ Works immediately

**Cons:**
- ❌ More complex
- ❌ Can disrupt network if misconfigured
- ❌ Requires bettercap

**Steps:**

1. **Install bettercap:**
```bash
sudo apt install bettercap
```

2. **Find Smart TV IPs:**
```bash
sudo nmap -sn 192.168.1.0/24
# Look for Smart TV MAC addresses
```

3. **Create interception caplet:**
```bash
cat > intercept-smarttv.cap << 'EOF'
# Enable forwarding
set net.forwarding true

# Set Smart TV IPs (CHANGE THESE!)
set arp.spoof.targets 192.168.1.100,192.168.1.101

# Start ARP spoofing
net.probe on
arp.spoof on

# Keep running
sleep 999999
EOF
```

4. **Start bettercap (Terminal 1):**
```bash
sudo bettercap -caplet intercept-smarttv.cap
```

5. **Apply bandwidth limits (Terminal 2):**
```bash
sudo ./limit_by_mac.sh
```

**Warning:** Only use on your own network. Stop with Ctrl+C.

---

### 🏠 Option 4: Router-Level Solution

**What:** Replace or flash router firmware

**Pros:**
- ✅ Works for entire network
- ✅ Doesn't require Linux machine running 24/7
- ✅ Professional solution

**Cons:**
- ❌ May require new router ($30-100)
- ❌ Or flashing firmware (moderate risk)

**Options:**

**A. Buy QoS-capable router:**
- TP-Link Archer C7/C9
- Asus RT-AC68U
- Netgear R7000

**B. Flash with OpenWrt/DD-WRT:**
1. Check if your router supports: https://openwrt.org/toh/start
2. Follow flash instructions (router-specific)
3. Install luci-app-sqm for QoS
4. Configure bandwidth limits per device

---

## Comparison Table

| Solution | Difficulty | Effectiveness | Cost | Always-On |
|----------|-----------|---------------|------|-----------|
| Manual Gateway | Easy | ⭐⭐⭐⭐⭐ | Free | Linux must run |
| WiFi AP | Easy | ⭐⭐⭐⭐⭐ | Free* | Linux must run |
| Transparent Proxy | Hard | ⭐⭐⭐⭐ | Free | Linux must run |
| Router Upgrade | Medium | ⭐⭐⭐⭐⭐ | $30-100 | ✅ Yes |

*Requires WiFi adapter if not built-in

---

## My Recommendation for You

**If you have a WiFi adapter on your Linux machine:**
→ **Use Option 2** (WiFi AP) - cleanest solution

**If Linux machine only has Ethernet:**
→ **Use Option 1** (Manual Gateway) - simplest that works

**If you want "set and forget":**
→ **Use Option 4** (Router upgrade) - best long-term

---

## Testing Your Setup

After configuring, verify it works:

1. **Check if Smart TV is using Linux machine as gateway:**
```bash
# On Linux machine
sudo tcpdump -i eth0 -n host [SMART_TV_IP]
# Should see traffic when Smart TV does anything
```

2. **Test bandwidth limit:**
   - On Smart TV: Visit https://fast.com
   - Should show limited speed (e.g., 5 Mbps if that's your limit)

3. **Test from regular computer:**
   - Should show full speed (not limited)

---

## Need Help?

**Problem:** "Smart TV has no internet after gateway change"
- Check: `sudo iptables -t nat -L` (should show MASQUERADE)
- Check: `cat /proc/sys/net/ipv4/ip_forward` (should be 1)
- Run: `sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE`

**Problem:** "Can't apply bandwidth limits"
- Traffic must flow through Linux machine first
- Verify with: `sudo tcpdump -i eth0`
- If no Smart TV traffic visible, gateway isn't set correctly

**Problem:** "WiFi AP not broadcasting"
- Check: `sudo systemctl status hostapd`
- Check: `ip addr show wlan0` (should have IP)
- Try: `sudo systemctl restart hostapd`

---

## Quick Command Reference

```bash
# Enable Linux machine as gateway
sudo sysctl -w net.ipv4.ip_forward=1
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# Check if traffic is flowing
sudo tcpdump -i eth0 -n host 192.168.1.100

# Apply bandwidth limits
sudo ./limit_by_mac.sh

# Monitor bandwidth
sudo ./monitor_traffic.sh

# Remove limits
sudo ./remove_limits.sh
```

---

**Bottom Line:** Your scripts need traffic to flow through your Linux machine. Choose the option above that best fits your technical comfort level and hardware!
