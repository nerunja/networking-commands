# OpenVPN Security Guide - Protecting Your VPN Access

## Table of Contents
1. [Security Risk Assessment](#security-risk-assessment)
2. [Understanding the Risk](#understanding-the-risk)
3. [Security Options Overview](#security-options-overview)
4. [Option 1: Password-Protected Certificates](#option-1-password-protected-certificates)
5. [Option 2: Username/Password Authentication](#option-2-usernamepassword-authentication)
6. [Option 3: Two-Factor Authentication](#option-3-two-factor-authentication)
7. [Option 4: Hybrid Approach (Recommended)](#option-4-hybrid-approach-recommended)
8. [Security Best Practices](#security-best-practices)
9. [Certificate Management](#certificate-management)
10. [Monitoring and Alerts](#monitoring-and-alerts)
11. [Emergency Procedures](#emergency-procedures)
12. [Security Comparison Matrix](#security-comparison-matrix)

---

## Security Risk Assessment

### The Critical Question

**"If someone gets my client.ovpn file, can they access my VPN?"**

**Answer: YES** ⚠️

### What's in a client.ovpn File?

```bash
# View what's inside
cat client1.ovpn

# Contains:
# 1. CA Certificate (public)
# 2. Client Certificate (public)
# 3. Client Private Key (PRIVATE - this is the security risk!)
# 4. TLS Authentication Key (shared secret)
# 5. Server address and connection details
```

**The client.ovpn file contains EVERYTHING needed to connect to your VPN.**

### Real-World Analogy

Think of your VPN like a house:

| Security Level | House Analogy | VPN Reality |
|----------------|---------------|-------------|
| **Passwordless Certificate** | Physical key hidden in lockbox | .ovpn file on device |
| **Password-Protected Certificate** | Key in lockbox with combination | .ovpn file + password to unlock |
| **Username/Password Auth** | Key + alarm code | .ovpn file + login credentials |
| **Two-Factor Auth** | Key + alarm code + fingerprint | .ovpn file + password + OTP |

---

## Understanding the Risk

### Threat Scenarios

#### Scenario 1: Lost/Stolen Phone
```
Risk Level: HIGH
Impact: Immediate VPN access
Mitigation: Device encryption + certificate revocation
```

#### Scenario 2: Compromised Email/Cloud
```
Risk Level: MEDIUM-HIGH
Impact: If .ovpn file was sent via email or cloud storage
Mitigation: Never send .ovpn via insecure channels
```

#### Scenario 3: Malware on Device
```
Risk Level: HIGH
Impact: Can extract .ovpn file from device
Mitigation: Antivirus, device hardening, password protection
```

#### Scenario 4: Insider Threat
```
Risk Level: MEDIUM
Impact: Family member or guest accesses your device
Mitigation: Per-device certificates, quick revocation
```

### What an Attacker Can Do

**With just your client.ovpn file:**
- ✅ Connect to your VPN
- ✅ Access your home network
- ✅ Use your internet connection (your IP address)
- ✅ Access any services on your home network
- ✅ Potentially intercept traffic if they MITM

**What they CANNOT do (with proper setup):**
- ❌ Create new VPN accounts (they need CA password)
- ❌ Access other client certificates
- ❌ Modify server configuration

---

## Security Options Overview

### Quick Comparison

| Option | Security | Convenience | Setup Complexity | Use Case |
|--------|----------|-------------|------------------|----------|
| **Certificate Only** | ⭐⭐ | ⭐⭐⭐⭐⭐ | Easy | Trusted devices only |
| **Password-Protected Cert** | ⭐⭐⭐ | ⭐⭐⭐ | Easy | Personal use |
| **Username/Password** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | Medium | Recommended for most |
| **Two-Factor (2FA)** | ⭐⭐⭐⭐⭐ | ⭐⭐ | Complex | High security needs |

---

## Option 1: Password-Protected Certificates

### Overview

Add a password to the client's private key. User must enter password every time they connect.

**Security Model:**
- Something you have: .ovpn file
- Something you know: Private key password

### Implementation

#### Generate Password-Protected Client Certificate

```bash
# Navigate to Easy-RSA directory
cd ~/openvpn-ca

# Generate client certificate WITH password
./easyrsa gen-req client1

# Prompts:
# Enter PEM pass phrase: [ENTER STRONG PASSWORD]
# Verifying - Enter PEM pass phrase: [ENTER SAME PASSWORD]
# Common Name [client1]: [press Enter]

# Sign the certificate (requires CA password)
./easyrsa sign-req client client1

# Type 'yes' to confirm
# Enter CA password when prompted
```

#### Create Client Configuration

```bash
# Create client config (same process as before)
mkdir -p ~/client-configs/keys

cp pki/ca.crt ~/client-configs/keys/
cp pki/issued/client1.crt ~/client-configs/keys/
cp pki/private/client1.key ~/client-configs/keys/  # This key is encrypted
cp ta.key ~/client-configs/keys/

# Create .ovpn file (same as before)
cat > ~/client-configs/client1.ovpn << 'EOF'
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
```

#### Client Experience

```bash
# When connecting, user will see:
sudo openvpn --config client1.ovpn

# Output:
# Enter Private Key Password: ********

# Every connection requires this password
```

### Pros and Cons

**Advantages:**
- ✅ Simple to implement
- ✅ No server changes needed
- ✅ Stolen .ovpn file requires password
- ✅ Works on all platforms

**Disadvantages:**
- ❌ Password must be entered every connection
- ❌ Can't save password (defeats purpose)
- ❌ Annoying for frequent reconnections
- ❌ Easy to write password down (security risk)

### Best For:
- Infrequent VPN use
- High-security requirements
- Single-user scenarios
- When server modification not possible

---

## Option 2: Username/Password Authentication

### Overview

Require username and password IN ADDITION to valid certificate. Even with stolen .ovpn file, attacker needs credentials.

**Security Model:**
- Something you have: .ovpn file (certificate)
- Something you know: Username + Password

### Implementation

#### Step 1: Install PAM Authentication Plugin

```bash
# Install OpenVPN PAM plugin
sudo apt update
sudo apt install openvpn-auth-pam

# Verify installation
dpkg -L openvpn-auth-pam | grep openvpn-plugin-auth-pam.so

# Should show path like:
# /usr/lib/x86_64-linux-gnu/openvpn/plugins/openvpn-plugin-auth-pam.so
```

#### Step 2: Configure Server

```bash
# Edit server configuration
sudo nano /etc/openvpn/server/server.conf
```

**Add these lines:**

```bash
# Username/Password Authentication
plugin /usr/lib/x86_64-linux-gnu/openvpn/plugins/openvpn-plugin-auth-pam.so login

# Optional: Require certificate verification too
verify-client-cert require

# Optional: Use username as common name (for logging)
username-as-common-name

# Optional: Don't cache passwords in memory
auth-nocache
```

**Save and restart server:**

```bash
sudo systemctl restart openvpn-server@server

# Check logs for errors
sudo journalctl -u openvpn-server@server -n 20
```

#### Step 3: Create VPN Users

```bash
# Create dedicated VPN user
sudo adduser vpnuser1

# Prompts:
# Enter new UNIX password: [CREATE STRONG PASSWORD]
# Retype new UNIX password: [SAME PASSWORD]
# Full Name []: VPN User 1
# Room Number []: [press Enter]
# Work Phone []: [press Enter]
# Home Phone []: [press Enter]
# Other []: [press Enter]
# Is the information correct? [Y/n]: Y

# Create additional users
sudo adduser vpnuser2
sudo adduser family-member

# List VPN users
cat /etc/passwd | grep vpnuser
```

#### Step 4: Configure Client

```bash
# Edit client configuration
nano ~/client-configs/client1.ovpn
```

**Add this line:**

```bash
auth-user-pass
```

**Or specify credentials file (less secure but convenient):**

```bash
auth-user-pass /home/user/vpn-credentials.txt
```

**If using credentials file:**

```bash
# Create credentials file
cat > ~/vpn-credentials.txt << EOF
vpnuser1
YourStrongPassword123
EOF

# Secure the file
chmod 600 ~/vpn-credentials.txt

# Update .ovpn file path (full path required)
auth-user-pass /home/username/vpn-credentials.txt
```

#### Complete Client Configuration Example

```bash
cat > ~/client-configs/client1.ovpn << 'EOF'
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

# Username/Password Authentication
auth-user-pass

# Optional: Credentials file (less secure but convenient)
# auth-user-pass /home/username/vpn-credentials.txt
EOF

# Add inline certificates (same as before)
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
```

#### Step 5: Test Connection

```bash
# Client will be prompted for credentials
sudo openvpn --config client1.ovpn

# Output:
# Enter Auth Username: vpnuser1
# Enter Auth Password: ********

# Connection proceeds if credentials are correct
```

### Advanced PAM Configuration

#### Create VPN-Specific Group

```bash
# Create VPN group
sudo groupadd vpnusers

# Add users to group
sudo usermod -aG vpnusers vpnuser1
sudo usermod -aG vpnusers vpnuser2

# Verify group membership
groups vpnuser1
```

#### Restrict VPN Access to Specific Group

```bash
# Create PAM configuration for OpenVPN
sudo nano /etc/pam.d/openvpn
```

**Add:**

```bash
# OpenVPN PAM Configuration
# Only allow members of vpnusers group

# Account validation
account required pam_unix.so
account required pam_permit.so

# Authentication
auth required pam_unix.so
auth required pam_succeed_if.so user ingroup vpnusers

# Session
session required pam_unix.so
```

**Test configuration:**

```bash
# Update server.conf to use custom PAM config
sudo nano /etc/openvpn/server/server.conf
```

**Change plugin line to:**

```bash
plugin /usr/lib/x86_64-linux-gnu/openvpn/plugins/openvpn-plugin-auth-pam.so openvpn
```

**Restart server:**

```bash
sudo systemctl restart openvpn-server@server
```

### Pros and Cons

**Advantages:**
- ✅ Stolen .ovpn file is useless without credentials
- ✅ Can use same credentials across all your devices
- ✅ Password can be saved in VPN client (convenient)
- ✅ Easy to change password without regenerating certificates
- ✅ Can have different users with different permissions
- ✅ Good balance of security and convenience

**Disadvantages:**
- ❌ Requires server-side configuration
- ❌ Credentials stored on client (if using auth-user-pass file)
- ❌ All users authenticate against same Linux users
- ❌ No audit trail per certificate

### Best For:
- Home VPN with multiple family members
- When you want to share VPN with trusted people
- Balancing security and convenience
- **RECOMMENDED FOR MOST HOME USERS**

---

## Option 3: Two-Factor Authentication

### Overview

Require OTP (One-Time Password) code in addition to username/password and certificate.

**Security Model:**
- Something you have: .ovpn file + phone/authenticator
- Something you know: Username + Password + OTP code

### Implementation

#### Step 1: Install Google Authenticator PAM

```bash
# Install Google Authenticator
sudo apt update
sudo apt install libpam-google-authenticator

# Verify installation
which google-authenticator
```

#### Step 2: Configure Each VPN User

```bash
# Switch to VPN user
sudo su - vpnuser1

# Run Google Authenticator setup
google-authenticator

# Prompts and recommended answers:

# Do you want authentication tokens to be time-based (y/n) y
# [QR CODE DISPLAYED]
# [Scan with Google Authenticator app on phone]

# Your new secret key is: XXXXXXXXXXXXXXXXXXXX
# [SAVE THIS SECURELY]

# Your verification code is: 123456
# Your emergency scratch codes are:
#   12345678
#   87654321
#   [SAVE THESE SECURELY]

# Do you want me to update your "~/.google_authenticator" file? (y/n) y

# Do you want to disallow multiple uses of the same authentication token? (y/n) y

# By default, tokens are good for 30 seconds. (y/n) n

# Do you want to enable rate-limiting? (y/n) y

# Exit back to your user
exit
```

#### Step 3: Configure PAM for 2FA

```bash
# Create OpenVPN PAM configuration
sudo nano /etc/pam.d/openvpn
```

**Add:**

```bash
# OpenVPN 2FA PAM Configuration

# First authenticate with username/password
auth required pam_unix.so

# Then require Google Authenticator OTP
auth required pam_google_authenticator.so

# Account and session
account required pam_unix.so
session required pam_unix.so
```

#### Step 4: Configure Server

```bash
# Edit server configuration
sudo nano /etc/openvpn/server/server.conf
```

**Ensure these lines exist:**

```bash
# PAM authentication with custom config
plugin /usr/lib/x86_64-linux-gnu/openvpn/plugins/openvpn-plugin-auth-pam.so openvpn

# Verify client certificate
verify-client-cert require

# Don't cache credentials
auth-nocache
```

**Restart server:**

```bash
sudo systemctl restart openvpn-server@server
```

#### Step 5: Configure Client

```bash
# Edit client configuration
nano ~/client-configs/client1.ovpn
```

**Add:**

```bash
# Enable username/password authentication
auth-user-pass

# Static challenge for OTP
# (Some clients need this for 2FA prompting)
static-challenge "Enter OTP Code" 1
```

#### Step 6: Client Connection

```bash
# Connect to VPN
sudo openvpn --config client1.ovpn

# Prompts:
# Enter Auth Username: vpnuser1
# Enter Auth Password: YourPassword123456  (where 123456 is OTP code)
#                      ^^^^^^^^^^^^^^^^-------- Your password
#                                      ^^^^^^-- 6-digit OTP

# OR if using static-challenge:
# Enter Auth Username: vpnuser1
# Enter Auth Password: YourPassword
# Enter OTP Code: 123456
```

### Alternative: TOTP with Separate Prompt

**For better UX, configure to prompt separately:**

```bash
# Install additional PAM module
sudo apt install libpam-oath

# Configure to use OATH tokens
# (More complex setup - consult documentation)
```

### Pros and Cons

**Advantages:**
- ✅ Highest security level
- ✅ Stolen .ovpn + password still not enough
- ✅ OTP changes every 30 seconds
- ✅ Emergency backup codes available
- ✅ Can use hardware tokens (YubiKey, etc.)

**Disadvantages:**
- ❌ Complex setup
- ❌ Requires phone/authenticator app
- ❌ Can't connect if phone is lost (use emergency codes)
- ❌ More friction for every connection
- ❌ User frustration with frequent connections

### Best For:
- Critical infrastructure
- Business VPN access
- Compliance requirements (SOC2, HIPAA, etc.)
- High-value targets
- NOT recommended for typical home use

---

## Option 4: Hybrid Approach (Recommended)

### Overview

**Best balance of security and convenience:**
- Passwordless certificates (easy to use)
- Username/Password authentication (security layer)
- One certificate per device (granular control)

**Security Model:**
- Something you have: .ovpn file (tied to specific device)
- Something you know: Username + Password (can be same for all your devices)

### Why This Works

1. **Stolen .ovpn file:** Useless without your username/password
2. **Compromised password:** Attacker still needs device-specific certificate
3. **Lost device:** Revoke that device's certificate only
4. **Convenience:** Password can be saved in VPN clients

### Implementation

#### Step 1: Server Setup (One Time)

```bash
# Install PAM plugin
sudo apt install openvpn-auth-pam

# Edit server config
sudo nano /etc/openvpn/server/server.conf
```

**Add:**

```bash
# Username/Password Authentication
plugin /usr/lib/x86_64-linux-gnu/openvpn/plugins/openvpn-plugin-auth-pam.so login

# Require valid certificate
verify-client-cert require

# Use username for logging
username-as-common-name

# Don't cache passwords
auth-nocache
```

**Restart server:**

```bash
sudo systemctl restart openvpn-server@server
```

#### Step 2: Create Your VPN Account

```bash
# Create your personal VPN account
sudo adduser nerunja

# Enter your VPN password (use strong password)
# This password will be used for ALL your devices
```

#### Step 3: Generate Certificates Per Device

```bash
# Create automated script
nano ~/add-secure-client.sh
```

**Script content:**

```bash
#!/bin/bash
# add-secure-client.sh - Hybrid security approach

CLIENT_NAME=$1

if [ -z "$CLIENT_NAME" ]; then
    echo "Usage: ./add-secure-client.sh <device-name>"
    echo ""
    echo "Examples:"
    echo "  ./add-secure-client.sh nerunja-laptop"
    echo "  ./add-secure-client.sh nerunja-phone"
    echo "  ./add-secure-client.sh nerunja-tablet"
    exit 1
fi

cd ~/openvpn-ca || exit 1

echo "========================================="
echo "Creating VPN Client: $CLIENT_NAME"
echo "Security: Certificate + Username/Password"
echo "========================================="
echo ""

# Generate passwordless certificate (certificate per device)
echo "Step 1: Generating device certificate..."
./easyrsa gen-req "$CLIENT_NAME" nopass

echo ""
echo "Step 2: Signing certificate (requires CA password)..."
./easyrsa sign-req client "$CLIENT_NAME"

# Create client config
mkdir -p ~/client-configs/keys

cp pki/ca.crt ~/client-configs/keys/
cp "pki/issued/$CLIENT_NAME.crt" ~/client-configs/keys/
cp "pki/private/$CLIENT_NAME.key" ~/client-configs/keys/
cp ta.key ~/client-configs/keys/

echo ""
echo "Step 3: Creating client configuration..."

cat > ~/client-configs/$CLIENT_NAME.ovpn << 'EOF'
# OpenVPN Client Configuration
# Device-specific certificate + Username/Password authentication

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

# Username/Password Authentication
# You'll be prompted to enter credentials when connecting
# Username: nerunja (your VPN account)
# Password: [your VPN password]
auth-user-pass

# Optional: Save credentials (less secure but convenient)
# Uncomment and update path:
# auth-user-pass /home/username/vpn-credentials.txt
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
echo "Client configuration: ~/client-configs/$CLIENT_NAME.ovpn"
echo ""
echo "Security Features:"
echo "  ✓ Device-specific certificate ($CLIENT_NAME)"
echo "  ✓ Username/Password required (nerunja/[password])"
echo "  ✓ Stolen .ovpn file alone is useless"
echo ""
echo "When connecting:"
echo "  Username: nerunja"
echo "  Password: [your VPN password]"
echo ""
echo "Transfer this file securely to your device."
echo "========================================="
```

**Make executable:**

```bash
chmod +x ~/add-secure-client.sh
```

#### Step 4: Create Clients for Each Device

```bash
# Create certificate for each device
~/add-secure-client.sh nerunja-laptop
~/add-secure-client.sh nerunja-phone
~/add-secure-client.sh nerunja-tablet

# You'll need CA password for each
# Username/password will be: nerunja/[your VPN password]
```

#### Step 5: Client Connection

```bash
# On any device, connect with:
sudo openvpn --config nerunja-laptop.ovpn

# Prompts:
# Enter Auth Username: nerunja
# Enter Auth Password: [your VPN password]

# Same credentials work for all YOUR devices
# But each device has its own certificate
```

### Optional: Save Credentials (Per Device)

**On trusted devices, save credentials for convenience:**

```bash
# Create credentials file
cat > ~/vpn-creds.txt << EOF
nerunja
YourVPNPassword123
EOF

chmod 600 ~/vpn-creds.txt

# Edit .ovpn file
nano nerunja-laptop.ovpn
```

**Update auth-user-pass line:**

```bash
# Change from:
auth-user-pass

# To:
auth-user-pass /home/username/vpn-creds.txt
```

**Now connection is automatic (but still secure):**

```bash
# No prompts - uses saved credentials
sudo openvpn --config nerunja-laptop.ovpn
```

### Managing Family Members

```bash
# Create separate accounts for family
sudo adduser family-member1
sudo adduser family-member2

# Create their devices
~/add-secure-client.sh family1-phone
~/add-secure-client.sh family2-laptop

# Each family member uses their own username/password
# But you control who has access via Linux user accounts
```

### Pros and Cons

**Advantages:**
- ✅ Excellent security/convenience balance
- ✅ Stolen .ovpn requires your password
- ✅ Lost device = revoke that certificate only
- ✅ Same password for all YOUR devices (convenient)
- ✅ Can save password on trusted devices
- ✅ Granular control (one cert per device)
- ✅ Easy to change password (no cert regeneration)
- ✅ Can have different users (family members)

**Disadvantages:**
- ❌ Requires server configuration
- ❌ Slightly more complex than certificate-only
- ❌ If password compromised AND .ovpn stolen = vulnerable

### Best For:
- **RECOMMENDED FOR HOME USE**
- Multiple devices (laptop, phone, tablet)
- Family VPN access
- Good security without annoyance
- Most flexible approach

---

## Security Best Practices

### 1. One Certificate Per Device

**Always create separate certificates:**

```bash
# DON'T DO THIS:
# One certificate for all devices

# DO THIS:
~/add-secure-client.sh nerunja-laptop
~/add-secure-client.sh nerunja-phone
~/add-secure-client.sh nerunja-ipad
~/add-secure-client.sh nerunja-work-laptop
```

**Benefits:**
- Revoke lost/stolen device without affecting others
- Track which device is connecting
- Identify suspicious connections
- Separate work/personal access

### 2. Secure File Transfer

**NEVER:**
- ❌ Email .ovpn files unencrypted
- ❌ Upload to public cloud storage
- ❌ Send via SMS/unencrypted messaging
- ❌ Post in Slack/Discord/public forums

**ALWAYS:**
- ✅ Physical transfer (USB drive)
- ✅ Encrypted transfer (SCP/SFTP)
- ✅ Password-protected zip file
- ✅ Encrypted messaging (Signal, WhatsApp)
- ✅ Temporary file sharing with expiration

**Secure transfer examples:**

```bash
# Method 1: SCP (Secure Copy)
scp ~/client-configs/nerunja-laptop.ovpn user@laptop:~/

# Method 2: Password-protected ZIP
zip --encrypt nerunja-laptop.zip ~/client-configs/nerunja-laptop.ovpn
# Enter encryption password when prompted

# Method 3: GPG encryption
gpg -c ~/client-configs/nerunja-laptop.ovpn
# Creates nerunja-laptop.ovpn.gpg

# Method 4: Temporary file sharing
# Upload to https://send.vis.ee/ (E2E encrypted)
# Or https://privnote.com/ (self-destructing)
```

### 3. Device Encryption

**Encrypt all devices with VPN access:**

**Laptop (Linux):**
```bash
# Use LUKS full disk encryption during installation
# Or encrypt home directory
ecryptfs-migrate-home -u username
```

**Phone/Tablet:**
- iOS: Settings → Face ID & Passcode → Enable
- Android: Settings → Security → Encrypt phone

**Benefits:**
- Stolen device = can't access .ovpn file
- Protects saved passwords
- Required for truly secure setup

### 4. Strong Passwords

**VPN account passwords should be:**
- At least 16 characters
- Mix of upper/lower/numbers/symbols
- Unique (not used elsewhere)
- Stored in password manager

**Generate strong passwords:**

```bash
# Generate 20-character random password
openssl rand -base64 20

# Or use password manager
# 1Password, Bitwarden, KeePassXC, etc.
```

### 5. Regular Certificate Rotation

**Set up certificate expiration reminder:**

```bash
# Check certificate expiration
cd ~/openvpn-ca
openssl x509 -in pki/issued/nerunja-laptop.crt -noout -dates

# Create reminder script
cat > ~/check-cert-expiry.sh << 'EOF'
#!/bin/bash
cd ~/openvpn-ca

echo "Certificate Expiration Status:"
echo "==============================="

for cert in pki/issued/*.crt; do
    name=$(basename "$cert" .crt)
    expiry=$(openssl x509 -in "$cert" -noout -enddate | cut -d= -f2)
    expiry_epoch=$(date -d "$expiry" +%s)
    now_epoch=$(date +%s)
    days_left=$(( ($expiry_epoch - $now_epoch) / 86400 ))
    
    if [ $days_left -lt 30 ]; then
        echo "⚠️  $name: $days_left days (URGENT)"
    elif [ $days_left -lt 90 ]; then
        echo "⚠️  $name: $days_left days"
    else
        echo "✓ $name: $days_left days"
    fi
done
EOF

chmod +x ~/check-cert-expiry.sh

# Run monthly
crontab -e
# Add: 0 0 1 * * ~/check-cert-expiry.sh | mail -s "VPN Certificate Status" your@email.com
```

### 6. Monitor Access Logs

**Set up log monitoring:**

```bash
# Create log monitoring script
cat > ~/monitor-vpn.sh << 'EOF'
#!/bin/bash

LOG_FILE="/var/log/openvpn/openvpn.log"
STATUS_FILE="/var/log/openvpn/openvpn-status.log"

echo "=== Currently Connected Clients ==="
sudo cat "$STATUS_FILE" | grep "CLIENT_LIST" | awk -F',' '{printf "%-20s %-15s %-20s\n", $2, $3, $4}'

echo ""
echo "=== Recent Connections (Last 10) ==="
sudo grep "MULTI: Learn:" "$LOG_FILE" | tail -10 | awk '{print $1, $2, $10, $11}'

echo ""
echo "=== Failed Authentication Attempts ==="
sudo grep -i "auth.*fail\|authentication.*fail\|bad.*password" "$LOG_FILE" | tail -5
EOF

chmod +x ~/monitor-vpn.sh

# Run to check status
~/monitor-vpn.sh
```

### 7. Geographic Access Control (Optional)

**Block connections from unexpected countries:**

```bash
# Install GeoIP
sudo apt install geoip-bin geoip-database

# Create connection script
sudo nano /etc/openvpn/scripts/check-country.sh
```

**Script content:**

```bash
#!/bin/bash
# Check client's country

CLIENT_IP="$trusted_ip"
ALLOWED_COUNTRIES="IN US GB"  # India, USA, UK

COUNTRY=$(geoiplookup "$CLIENT_IP" | cut -d: -f2 | cut -d, -f1 | xargs)

for allowed in $ALLOWED_COUNTRIES; do
    if [ "$COUNTRY" = "$allowed" ]; then
        exit 0  # Allow
    fi
done

logger -t openvpn "Blocked connection from $COUNTRY ($CLIENT_IP)"
exit 1  # Deny
```

**Make executable:**

```bash
sudo chmod +x /etc/openvpn/scripts/check-country.sh
```

**Add to server.conf:**

```bash
script-security 2
client-connect /etc/openvpn/scripts/check-country.sh
```

---

## Certificate Management

### Listing All Certificates

```bash
# View all issued certificates
cd ~/openvpn-ca
ls -lh pki/issued/

# Check certificate details
./easyrsa show-cert nerunja-laptop

# List with expiration dates
for cert in pki/issued/*.crt; do
    name=$(basename "$cert" .crt)
    expiry=$(openssl x509 -in "$cert" -noout -enddate)
    echo "$name: $expiry"
done
```

### Revoking Certificates

**When to revoke:**
- Device lost or stolen
- Device no longer in use
- Security breach suspected
- Employee/family member leaves

**How to revoke:**

```bash
cd ~/openvpn-ca

# Revoke certificate
./easyrsa revoke nerunja-phone

# Prompts:
# Type the word 'yes' to continue: yes
# Enter CA password

# Generate CRL (Certificate Revocation List)
./easyrsa gen-crl

# Copy CRL to server
sudo cp pki/crl.pem /etc/openvpn/server/

# Add to server.conf (if not already present)
sudo nano /etc/openvpn/server/server.conf
# Add: crl-verify crl.pem

# Restart server
sudo systemctl restart openvpn-server@server

# Verify revocation
openssl crl -in pki/crl.pem -noout -text | grep nerunja-phone
```

### Emergency Revocation Script

```bash
# Create quick revoke script
cat > ~/revoke-vpn-client.sh << 'EOF'
#!/bin/bash
CLIENT_NAME=$1

if [ -z "$CLIENT_NAME" ]; then
    echo "Usage: ./revoke-vpn-client.sh <client-name>"
    exit 1
fi

cd ~/openvpn-ca || exit 1

echo "⚠️  REVOKING VPN ACCESS FOR: $CLIENT_NAME"
echo ""

# Revoke certificate
./easyrsa revoke "$CLIENT_NAME"

# Generate CRL
./easyrsa gen-crl

# Copy to server
sudo cp pki/crl.pem /etc/openvpn/server/

# Restart server
sudo systemctl restart openvpn-server@server

echo ""
echo "✓ Certificate revoked: $CLIENT_NAME"
echo "✓ Server restarted"
echo "✓ Client can no longer connect"
EOF

chmod +x ~/revoke-vpn-client.sh

# Usage:
# ~/revoke-vpn-client.sh nerunja-lost-phone
```

### Renewing Certificates

```bash
# Generate new certificate with same name
cd ~/openvpn-ca

# Revoke old certificate
./easyrsa revoke nerunja-laptop

# Generate new request
./easyrsa gen-req nerunja-laptop nopass

# Sign new certificate
./easyrsa sign-req client nerunja-laptop

# Update CRL
./easyrsa gen-crl
sudo cp pki/crl.pem /etc/openvpn/server/

# Recreate .ovpn file with new certificate
~/add-secure-client.sh nerunja-laptop

# Transfer new .ovpn to device
```

---

## Monitoring and Alerts

### Real-Time Connection Monitoring

```bash
# Watch connections in real-time
sudo tail -f /var/log/openvpn/openvpn.log | grep --line-buffered "MULTI\|Auth"

# In separate terminal, watch status
watch -n 5 'sudo cat /var/log/openvpn/openvpn-status.log | grep CLIENT_LIST'
```

### Email Alerts on Connection

```bash
# Install mail utilities
sudo apt install mailutils

# Create connection alert script
sudo nano /etc/openvpn/scripts/client-connect-alert.sh
```

**Script content:**

```bash
#!/bin/bash
# Alert on new VPN connection

CLIENT="$common_name"
IP="$trusted_ip"
VPN_IP="$ifconfig_pool_remote_ip"
TIME=$(date)

# Email details
TO="your-email@gmail.com"
SUBJECT="VPN Connection Alert: $CLIENT"

BODY="New VPN Connection:
Device: $CLIENT
Source IP: $IP
VPN IP: $VPN_IP
Time: $TIME
"

echo "$BODY" | mail -s "$SUBJECT" "$TO"

# Log to syslog
logger -t openvpn-alert "Connection: $CLIENT from $IP"

exit 0
```

**Make executable:**

```bash
sudo chmod +x /etc/openvpn/scripts/client-connect-alert.sh
```

**Add to server.conf:**

```bash
script-security 2
client-connect /etc/openvpn/scripts/client-connect-alert.sh
```

### Failed Authentication Alerts

```bash
# Monitor for failed auth attempts
cat > ~/check-failed-auth.sh << 'EOF'
#!/bin/bash

LOG_FILE="/var/log/openvpn/openvpn.log"
ALERT_THRESHOLD=3

# Count recent failures (last hour)
FAILURES=$(sudo grep -c "TLS Auth Error\|AUTH_FAILED" "$LOG_FILE")

if [ $FAILURES -ge $ALERT_THRESHOLD ]; then
    echo "⚠️  WARNING: $FAILURES failed authentication attempts detected!"
    echo "Recent failures:"
    sudo grep "TLS Auth Error\|AUTH_FAILED" "$LOG_FILE" | tail -10
    
    # Send email alert
    echo "Multiple VPN authentication failures detected. Check logs." | \
        mail -s "VPN Security Alert" your-email@gmail.com
fi
EOF

chmod +x ~/check-failed-auth.sh

# Run via cron every hour
crontab -e
# Add: 0 * * * * ~/check-failed-auth.sh
```

### Connection Dashboard

```bash
# Create simple dashboard
cat > ~/vpn-dashboard.sh << 'EOF'
#!/bin/bash

clear
echo "╔════════════════════════════════════════════════════════════╗"
echo "║            OpenVPN Server Dashboard                        ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Server status
echo "Server Status:"
systemctl is-active openvpn-server@server && echo "  ✓ Running" || echo "  ✗ Stopped"
echo ""

# Connected clients
echo "Connected Clients:"
CLIENTS=$(sudo cat /var/log/openvpn/openvpn-status.log | grep -c "CLIENT_LIST")
echo "  Total: $CLIENTS"
echo ""
sudo cat /var/log/openvpn/openvpn-status.log | grep "CLIENT_LIST" | \
    awk -F',' '{printf "  %-20s %-15s %s\n", $2, $3, $4}' | head -10
echo ""

# Network stats
echo "Network Interface:"
ip addr show tun0 2>/dev/null | grep "inet " | awk '{print "  VPN IP: " $2}' || echo "  ✗ Not running"
echo ""

# Recent activity
echo "Recent Activity (Last 5 connections):"
sudo grep "MULTI: Learn:" /var/log/openvpn/openvpn.log | tail -5 | \
    awk '{print "  " $1, $2, $10}'
echo ""

# Certificate expiration warnings
echo "Certificate Status:"
cd ~/openvpn-ca
for cert in pki/issued/*.crt; do
    name=$(basename "$cert" .crt)
    expiry_date=$(openssl x509 -in "$cert" -noout -enddate | cut -d= -f2)
    expiry_epoch=$(date -d "$expiry_date" +%s)
    now_epoch=$(date +%s)
    days_left=$(( ($expiry_epoch - $now_epoch) / 86400 ))
    
    if [ $days_left -lt 30 ]; then
        echo "  ⚠️  $name: $days_left days left (URGENT)"
    fi
done | head -5
echo ""

echo "Last updated: $(date)"
EOF

chmod +x ~/vpn-dashboard.sh

# Run dashboard
~/vpn-dashboard.sh
```

---

## Emergency Procedures

### Lost/Stolen Device

**Immediate actions (within 5 minutes):**

```bash
# 1. Revoke certificate immediately
~/revoke-vpn-client.sh device-name

# 2. Change VPN password (if using username/password)
sudo passwd vpnuser

# 3. Check recent connections
sudo grep "device-name" /var/log/openvpn/openvpn.log | tail -20

# 4. Block device's last known IP (if needed)
sudo ufw deny from LAST_KNOWN_IP
```

### Suspected Breach

**If you suspect unauthorized access:**

```bash
# 1. Check currently connected clients
sudo cat /var/log/openvpn/openvpn-status.log

# 2. Revoke all certificates
cd ~/openvpn-ca
for cert in pki/issued/*.crt; do
    name=$(basename "$cert" .crt)
    if [ "$name" != "server" ]; then
        ./easyrsa revoke "$name"
    fi
done

# 3. Generate new CRL
./easyrsa gen-crl
sudo cp pki/crl.pem /etc/openvpn/server/

# 4. Restart server
sudo systemctl restart openvpn-server@server

# 5. Create new certificates for legitimate devices
~/add-secure-client.sh new-laptop
~/add-secure-client.sh new-phone

# 6. Review logs for suspicious activity
sudo grep -i "auth.*fail\|suspicious\|error" /var/log/openvpn/openvpn.log
```

### Password Compromise

**If VPN password is compromised:**

```bash
# 1. Change password immediately
sudo passwd nerunja

# 2. Force disconnect all clients
sudo systemctl restart openvpn-server@server

# 3. Notify all legitimate users of new password

# 4. Review connection logs
sudo grep "nerunja" /var/log/openvpn/openvpn.log | tail -50

# 5. Consider enabling 2FA if not already enabled
```

### Complete Server Compromise

**Nuclear option - start from scratch:**

```bash
# 1. Stop server
sudo systemctl stop openvpn-server@server

# 2. Backup current setup (for forensics)
sudo tar -czf /tmp/openvpn-breach-backup-$(date +%Y%m%d).tar.gz \
    /etc/openvpn ~/openvpn-ca

# 3. Remove all configurations
sudo rm -rf /etc/openvpn/server/*
sudo rm -rf ~/openvpn-ca

# 4. Follow fresh installation guide from beginning

# 5. Audit network and system for other compromises
sudo apt install rkhunter chkrootkit
sudo rkhunter --check
sudo chkrootkit
```

---

## Security Comparison Matrix

### Feature Comparison

| Feature | Cert Only | Cert + Password | Username/Pass | 2FA |
|---------|-----------|-----------------|---------------|-----|
| **Stolen .ovpn Security** | ❌ None | ✅ Good | ✅ Good | ✅ Excellent |
| **Setup Complexity** | ⭐ Easy | ⭐ Easy | ⭐⭐ Medium | ⭐⭐⭐ Hard |
| **User Convenience** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐ |
| **Password Management** | None | Per-device | Shared/per-user | Shared + OTP |
| **Revocation Speed** | Instant | Instant | Instant | Instant |
| **Multi-User Support** | ❌ No | ❌ No | ✅ Yes | ✅ Yes |
| **Password Changes** | N/A | Regenerate cert | Easy | Easy |
| **Mobile Friendly** | ✅ Yes | ⚠️ OK | ✅ Yes | ⚠️ OK |
| **Audit Trail** | ✅ Yes | ✅ Yes | ✅✅ Better | ✅✅ Better |
| **Recommended For** | Testing only | Personal only | Home/family | Business |

### Attack Scenarios

| Attack Vector | Cert Only | Cert + Pass | User/Pass | 2FA |
|---------------|-----------|-------------|-----------|-----|
| **Stolen laptop (encrypted)** | ✅ Protected | ✅ Protected | ✅ Protected | ✅ Protected |
| **Stolen laptop (unencrypted)** | ❌ Compromised | ✅ Protected | ✅ Protected | ✅ Protected |
| **Email interception** | ❌ Compromised | ✅ Protected | ✅ Protected | ✅ Protected |
| **Malware on device** | ❌ Compromised | ⚠️ May be compromised | ⚠️ May be compromised | ✅ Protected |
| **Password compromise** | N/A | N/A | ❌ Compromised | ✅ Protected |
| **Insider threat** | ❌ Compromised | ✅ Protected | ✅ Protected | ✅ Protected |

### Convenience Score

| Scenario | Cert Only | Cert + Pass | User/Pass | 2FA |
|----------|-----------|-------------|-----------|-----|
| **First connection** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐ |
| **Daily reconnections** | ⭐⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐ |
| **Multiple devices** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| **Family sharing** | ❌ | ❌ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Lost password** | N/A | ❌ Locked out | ✅ Reset easily | ⚠️ Need backup codes |

---

## Final Recommendations

### For Home Use (Recommended: Option 4)

**Setup:**
- Passwordless certificates (one per device)
- Username/Password authentication
- Device encryption mandatory

**Why:**
- Excellent security/convenience balance
- Easy to manage multiple devices
- Simple to share with family
- Can save password on trusted devices

**Implementation:**
```bash
# Use the hybrid approach script
~/add-secure-client.sh nerunja-laptop
~/add-secure-client.sh nerunja-phone
~/add-secure-client.sh wife-tablet
```

### For Personal Use Only (Option 1 or 2)

**If only you use the VPN:**
- Option 1: Password-protected certificates
- Option 2: Username/Password authentication

**Why:**
- Simpler setup
- No need for multi-user support

### For High Security Needs (Option 3)

**When to use 2FA:**
- Business/work VPN
- Compliance requirements
- High-value targets
- Critical infrastructure

**Why:**
- Maximum security
- Worth the inconvenience for critical systems

### Quick Decision Guide

**Choose based on:**

1. **How many people use it?**
   - Just you → Option 1 or 2
   - Family/multiple users → Option 4
   - Business → Option 3

2. **How often do you connect?**
   - Rarely → Option 1 (password per connection is OK)
   - Frequently → Option 4 (save credentials)
   - Always on → Option 4

3. **What's your risk tolerance?**
   - Low (home use) → Option 4
   - Medium → Option 2 or 4
   - High (business) → Option 3

4. **Device security:**
   - Encrypted devices → Option 2 or 4
   - Unencrypted → Option 1 or 3
   - Public/shared → Option 3

---

## Summary

### Key Takeaways

1. **Passwordless certificates are convenient but risky** - stolen .ovpn = full access
2. **Username/Password authentication adds crucial security layer** - stolen .ovpn needs credentials
3. **One certificate per device is essential** - enables granular revocation
4. **Device encryption is non-negotiable** - protects .ovpn files at rest
5. **Hybrid approach (Option 4) is best for most home users** - security + convenience

### Security Checklist

- [ ] Use one certificate per device
- [ ] Enable username/password authentication
- [ ] Encrypt all devices with VPN access
- [ ] Transfer .ovpn files securely
- [ ] Use strong, unique VPN passwords
- [ ] Set up certificate expiration monitoring
- [ ] Configure connection alerts
- [ ] Test emergency revocation procedure
- [ ] Document recovery procedures
- [ ] Regular security audits

### What's Next?

1. **Choose your security model** based on needs
2. **Implement server-side authentication** if using Option 2, 3, or 4
3. **Generate device-specific certificates** for all devices
4. **Set up monitoring and alerts**
5. **Test emergency procedures**
6. **Document everything**
7. **Train users** (family members) on security practices

---

**Remember:** Security is about layers. No single measure is perfect, but combining:
- Device-specific certificates
- Username/Password authentication
- Device encryption
- Secure file transfer
- Quick revocation capability

...creates a robust security posture suitable for home use while maintaining good user experience.

---

**Last Updated:** December 27, 2024  
**Version:** 1.0  
**Compatible With:** OpenVPN 2.6.x, Ubuntu 22.04/24.04 LTS  

---

*Security is not a product, but a process. Regularly review and update your VPN security practices.*
