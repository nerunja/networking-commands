# Connecting to OpenVPN Server from Android

Complete guide to set up and connect your Android phone to your OpenVPN server.

---

## 📱 Step 1: Install OpenVPN Client App

### Recommended App: OpenVPN for Android

1. Open **Google Play Store**
2. Search for: **"OpenVPN for Android"**
3. Install the app by **Arne Schwabe**
   - App ID: `de.blinkt.openvpn`
   - Developer: Arne Schwabe
   - Free and open-source
   - 10M+ downloads

**Alternative:** "OpenVPN Connect" (official app by OpenVPN Inc.)

---

## 📲 Step 2: Create a Dedicated Mobile Client (Recommended)

It's best practice to create a separate VPN profile specifically for your phone:

```bash
# On your OpenVPN server
cd ~/ws/github/nerunja/networking-commands/OpenVPN/scripts
./10-create-client.sh
```

**When prompted, enter:**
- **Client name:** `android-phone` or `nerunja-phone`
- **Server address:** `<your-name>.mywire.org` (your DDNS domain)
- **CA password:** (the password you set during setup)

**Output file:** `~/client-configs/android-phone.ovpn`

---

## 📤 Step 3: Transfer .ovpn File to Your Phone

Choose one of these secure methods:

### Option A: USB Cable (Most Secure) ✅ Recommended

1. Connect your Android phone to your computer via USB
2. Enable **File Transfer** mode on your phone
3. Copy the file to your phone:
   ```bash
   # The file will be at:
   ~/client-configs/android-phone.ovpn

   # Copy to your phone's Downloads folder
   # (using file manager or drag-and-drop)
   ```

### Option B: Simple HTTP Server (Local Network Only)

```bash
# On your server
cd ~/client-configs
python3 -m http.server 8000

# On your phone's browser, navigate to:
# http://YOUR_SERVER_IP:8000
# Example: http://192.168.1.55:8000

# Download android-phone.ovpn
# Press Ctrl+C on server to stop when done
```

### Option C: Using ADB (Android Debug Bridge)

```bash
# First, enable USB debugging on your phone
# Settings → About Phone → Tap "Build Number" 7 times
# Settings → Developer Options → Enable USB Debugging

# Transfer file
adb push ~/client-configs/android-phone.ovpn /sdcard/Download/
```

### Option D: Encrypted Messaging ✅ Secure

1. Send the `.ovpn` file to yourself via:
   - **Signal** (most secure)
   - **WhatsApp**
   - **Telegram**
2. Download on your phone
3. **Delete the message** after downloading

### Option E: QR Code (If Available)

If your `10-create-client.sh` script supports QR codes:
```bash
# Install qrencode first
sudo apt install qrencode

# Generate QR code
qrencode -t ANSIUTF8 < ~/client-configs/android-phone.ovpn

# Scan with OpenVPN app
```

---

## 📥 Step 4: Import Configuration into OpenVPN App

1. **Open** the "OpenVPN for Android" app
2. Tap the **"+"** icon (top-right or bottom-right)
3. Select **"Import"** or **"Import Profile from SD card"**
4. **Navigate** to where you saved the file:
   - Usually: **Internal Storage → Download**
   - File name: `android-phone.ovpn`
5. **Tap** the file to import
6. The app will show a **profile preview** screen
   - You'll see server address, port, protocol
   - Certificate information
7. **Optional:** Give it a friendly name (e.g., "Home VPN")
8. Tap **"Add"** or **"OK"** to save

**Import successful if you see:**
- ✅ Profile appears in the main list
- ✅ Server address is correct
- ✅ No error messages

---

## 🔌 Step 5: Connect to Your VPN

### First-Time Connection:

1. **Tap** on your VPN profile name (e.g., "android-phone")
2. **Tap** the **Connect** button or toggle switch
3. **Android VPN Permission** dialog appears:
   - Shows: "OpenVPN for Android wants to set up a VPN connection"
   - Tap **"OK"** to grant permission
   - This is **required** for VPN to work
4. Connection status will show:
   - "Connecting..."
   - "Connected" (with green checkmark)
5. **VPN icon** (🔑) appears in status bar
6. **Notification** shows connection details

### What to Expect:
- **Connection time:** 2-5 seconds (first time may be longer)
- **Battery:** Minimal impact
- **Data usage:** Slightly increased due to encryption overhead

---

## ✅ Step 6: Verify Connection is Working

### Test 1: Check VPN Status in App
- Status shows: **"Connected"**
- Timer shows connection duration
- Data transfer stats visible (bytes in/out)

### Test 2: Check Your Public IP Address

**Method A: Using Browser**
1. Open **Chrome** or any browser
2. Go to: **https://ifconfig.me**
3. You should see your **VPN server's public IP**
4. Compare with your phone's normal IP (disconnect VPN to check)

**Method B: Using "What's My IP" Sites**
- https://whatismyip.com
- https://ipinfo.io
- Should show server location, not your phone's location

### Test 3: DNS Check
1. Go to: **https://www.dnsleaktest.com**
2. Click **"Standard Test"**
3. Should show your configured DNS servers:
   - Google DNS: 8.8.8.8, 8.8.4.4
   - Cloudflare: 1.1.1.1, 1.0.0.1
   - Quad9: 9.9.9.9
   - (Whatever you configured in step 7 of server setup)

### Test 4: Ping Test (Advanced)

If you have a terminal app like **Termux**:
```bash
# Install Termux from F-Droid or Play Store
# In Termux, run:
ping -c 4 10.8.0.1

# Should show replies from VPN server
```

---

## ⚙️ App Configuration & Settings

### Recommended Settings in OpenVPN App:

**Open app settings** (three dots menu → Settings):

#### 1. Connection Settings
- **Connect on boot:** `Enabled` (auto-connect when phone starts)
- **Seamless tunnel:** `Enabled` (reconnect on network change)
- **Connection timeout:** `30 seconds` (default)

#### 2. Battery Optimization
**Important:** Disable battery optimization for VPN app
1. Go to phone's **Settings → Apps → OpenVPN for Android**
2. **Battery → Unrestricted** (allows background running)
3. This prevents Android from killing VPN connection

#### 3. VPN Settings (per profile)
Tap profile → Edit (pencil icon):
- **Allowed Apps** (optional): Select which apps use VPN
- **VPN Protocol:** UDP (faster) or TCP (more reliable)
- **Custom DNS:** Override server-pushed DNS if needed

#### 4. Split Tunneling (Advanced)
**Exclude apps from VPN:**
- Settings → VPN profile → Allowed/Disallowed Apps
- Useful for: Banking apps, local network apps
- Default: All apps use VPN

---

## 🔒 Security Best Practices

### 1. Protect Your .ovpn File
- **Delete** from Downloads folder after import
- Configuration is stored securely in app
- Don't share the file with anyone

### 2. Monitor Connection Status
- Check VPN icon in status bar regularly
- If icon disappears, you're **not protected**
- Enable notifications for connection/disconnection

### 3. Use Strong Device Security
- Set up PIN/Password/Fingerprint lock
- Enable **Find My Device**
- Keep Android OS updated

### 4. Regular Updates
- Update OpenVPN app when available
- Check for server configuration updates

### 5. Create Separate Profiles
- One profile per device
- Easy to revoke if phone is lost
- Better tracking in server logs

---

## 🐛 Troubleshooting

### Problem: Can't Import .ovpn File

**Solutions:**
1. **Check file location:**
   - Must be on phone storage (not Google Drive)
   - Try moving to Downloads folder
2. **File permissions:**
   - Make sure file is readable
3. **Corrupted download:**
   - Re-download or re-transfer file
4. **Wrong app:**
   - Make sure using "OpenVPN for Android" not "OpenVPN Connect"

---

### Problem: Can't Connect - "Connection Timeout"

**Check these in order:**

#### A. Server Status
On your server, check if VPN is running:
```bash
sudo systemctl status openvpn-server@server
```
If not running:
```bash
sudo systemctl start openvpn-server@server
```

#### B. Router Port Forwarding
**Critical:** Your router must forward port 1194 UDP

1. Log into your router (usually http://192.168.1.1)
2. Find **Port Forwarding** section
3. Verify rule exists:
   - **External Port:** 1194
   - **Protocol:** UDP
   - **Internal IP:** Your server's IP (e.g., 192.168.1.55)
   - **Internal Port:** 1194
4. **Save** and **reboot router** if needed

#### C. DDNS Domain Working?
Test your DDNS domain:
```bash
# On server or any computer
nslookup nerunja.mywire.org

# Should return your public IP
```

If not working, update DDNS:
- Check your DDNS provider settings
- Make sure auto-update is enabled

#### D. Network Type
- **Try mobile data (4G/5G)** instead of WiFi
- Some WiFi networks block VPN
- If works on mobile but not WiFi → WiFi router issue

#### E. Firewall on Server
```bash
# On server
sudo ufw status

# Should show:
# 1194/udp    ALLOW    Anywhere
```

If not:
```bash
sudo ufw allow 1194/udp
sudo ufw reload
```

---

### Problem: Connects But No Internet

**Possible causes:**

#### 1. DNS Issue
**Solution:** Override DNS in app
- Edit profile → DNS → Override DNS
- Set to: `8.8.8.8` and `8.8.4.4`

#### 2. Server Routing Issue
On server, check IP forwarding:
```bash
cat /proc/sys/net/ipv4/ip_forward
# Should show: 1
```

If shows 0:
```bash
sudo sysctl -w net.ipv4.ip_forward=1
# Make permanent:
sudo ./08-configure-network.sh
```

#### 3. NAT Not Working
On server:
```bash
sudo iptables -t nat -L POSTROUTING -v
# Should show MASQUERADE rule
```

If missing:
```bash
sudo ./08-configure-network.sh
```

---

### Problem: Frequent Disconnections

**Solutions:**

#### 1. Switch to TCP Protocol
- UDP is faster but less stable on mobile networks
- Edit profile → Protocol → Change to **TCP**
- Note: Server must support TCP (may need reconfiguration)

#### 2. Adjust Keepalive
- Default: ping every 10 seconds
- Edit profile → Advanced → Keepalive
- Increase to: `keepalive 20 120`

#### 3. Disable Battery Optimization
- Settings → Apps → OpenVPN for Android
- Battery → Unrestricted

#### 4. Network Change Behavior
- Enable "Seamless Tunnel" in app settings
- Reconnects automatically when switching WiFi/Mobile

---

### Problem: "Authentication Failed"

**Causes:**
- Wrong certificates
- Server configuration changed
- Certificate expired

**Solutions:**
1. **Re-import configuration:**
   - Delete current profile
   - Re-transfer and import .ovpn file
2. **Create new client:**
   ```bash
   ./10-create-client.sh
   # Use different name: android-phone-2
   ```
3. **Check server logs:**
   ```bash
   sudo journalctl -u openvpn-server@server -f
   # Look for authentication errors
   ```

---

### Problem: "TLS Handshake Failed"

**Usually indicates:**
- Certificate/key mismatch
- Incompatible TLS version
- Firewall blocking connection

**Solutions:**
1. **Check server time:**
   ```bash
   date
   # Must be correct for certificate validation
   ```
2. **Regenerate client:**
   ```bash
   ./10-create-client.sh
   ```
3. **Check TLS settings:**
   - Make sure client and server TLS versions match

---

## 📊 Understanding Connection Details

When connected, tap on the profile to see details:

### Connection Stats:
- **Duration:** How long connected
- **Bytes In/Out:** Data transferred
- **Server:** VPN server address
- **Assigned IP:** Your VPN IP (e.g., 10.8.0.6)
- **Gateway:** VPN gateway (10.8.0.1)

### Network Info:
- **Local IP:** Your device's IP before VPN
- **Public IP:** IP address visible to internet (server's IP)
- **DNS Servers:** DNS being used
- **Routes:** Routing table

---

## 🎯 Quick Reference

### Connection Checklist
- ✅ OpenVPN app installed
- ✅ .ovpn file imported
- ✅ VPN permission granted
- ✅ Router port forwarding configured
- ✅ Server running and accessible
- ✅ DDNS domain resolving correctly

### Connect/Disconnect
```
Connect:    Tap profile → Toggle ON
Disconnect: Tap profile → Toggle OFF
Status:     Check VPN icon in status bar
```

### Testing Connection
```
IP Check:  ifconfig.me
DNS Check: dnsleaktest.com
Ping:      ping 10.8.0.1 (in Termux)
```

### When to Use VPN
- ✅ Public WiFi (coffee shops, airports)
- ✅ Hotel WiFi
- ✅ Accessing home network remotely
- ✅ Privacy on mobile networks
- ✅ Bypass geo-restrictions

### When You Might NOT Use VPN
- 🏠 At home (already on same network)
- 💰 Banking apps (some detect VPN)
- 📺 Local streaming services
- 🎮 Gaming (adds latency)

---

## 🔐 Advanced Features

### Auto-Connect Rules

Set VPN to connect automatically based on network:

1. **Edit Profile** → Advanced → Connection Rules
2. Configure:
   - **Unknown WiFi:** Auto-connect
   - **Known WiFi (home):** Don't connect
   - **Mobile Data:** Auto-connect

### Per-App VPN (Split Tunneling)

Choose which apps use VPN:

1. **Edit Profile** → Allowed Apps
2. **Mode:**
   - **Allow only these apps:** Whitelist mode
   - **Don't allow these apps:** Blacklist mode
3. **Select apps:**
   - Check apps that should/shouldn't use VPN

**Example use cases:**
- Exclude banking apps (they block VPN)
- Exclude local network apps
- Include only browsers and email

---

## 📱 Multiple Device Setup

### Recommended Naming Convention:
```
android-phone      (your main phone)
android-tablet     (your tablet)
android-work       (work phone)
partner-phone      (partner's phone)
```

### Create Multiple Clients:
```bash
# On server
./10-create-client.sh  # Create first client
./10-create-client.sh  # Run again for second client
./10-create-client.sh  # Run again for third client

# Each gets unique certificates
# All can connect simultaneously (up to max_clients limit)
```

---

## 📈 Monitoring Your Connection

### On Your Phone:

**OpenVPN App:**
- Real-time data transfer stats
- Connection duration
- Log viewer (tap profile → Log)

**Network Settings:**
- Settings → Network → VPN
- Shows active VPN connection

### On Your Server:

**View Connected Clients:**
```bash
sudo cat /var/log/openvpn/openvpn-status.log
```

**Live Logs:**
```bash
sudo journalctl -u openvpn-server@server -f
```

**Connection History:**
```bash
sudo grep "Peer Connection Initiated" /var/log/openvpn/openvpn.log
```

---

## 🆘 Getting Help

### In-App Logs
1. Tap VPN profile
2. Tap **"Log"** tab
3. Look for errors in red
4. Share logs if seeking help

### Useful Diagnostics
```bash
# On server - check if client is connected
sudo tail -f /var/log/openvpn/openvpn.log

# Check firewall
sudo ufw status verbose

# Test server is listening
sudo ss -tulpn | grep 1194
```

---

## ✅ Success Checklist

After setup, verify:
- [ ] App installed and configured
- [ ] Profile imported successfully
- [ ] Can connect without errors
- [ ] VPN icon appears in status bar
- [ ] Public IP shows server's IP
- [ ] Internet works while connected
- [ ] DNS is working (can browse websites)
- [ ] Connection survives network switches
- [ ] Auto-reconnect working (if enabled)
- [ ] Battery optimization disabled for app

---

## 🎉 You're All Set!

Your Android phone is now configured to securely connect to your home VPN server!

**Remember:**
- Keep your .ovpn file secure (delete after import)
- Monitor battery usage
- Check connection status regularly
- Update the app when prompted
- Create separate profiles for each device

**For other devices:**
- See [QUICKSTART.md](QUICKSTART.md) for general setup
- Windows/Mac/iOS instructions available

---

**Last Updated:** December 28, 2025
**Compatible with:** OpenVPN for Android v0.7.x and newer
**Server Version:** OpenVPN 2.6.x
