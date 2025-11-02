#!/bin/bash
#
# WiFi Access Point with Bandwidth Limiting for Smart TVs
# Version: 1.0.0
# Description: Creates a separate WiFi network for Smart TVs with built-in bandwidth limits
#
# Usage: sudo ./wifi_ap_limiter.sh
#

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check root
if [[ $EUID -ne 0 ]]; then
   print_error "This script must be run as root (use sudo)"
   exit 1
fi

echo ""
echo "================================================"
echo "  WiFi Access Point + Bandwidth Limiter Setup"
echo "================================================"
echo ""

# ============================================================================
# CONFIGURATION SECTION - MODIFY THESE VALUES
# ============================================================================

# WiFi Configuration
WIFI_INTERFACE="wlan0"          # Your WiFi interface
ETHERNET_INTERFACE="eth0"       # Your ethernet interface (to internet)

SSID="SmartTV_Limited"          # WiFi network name
PASSWORD="smarttv2024"          # WiFi password (min 8 chars)
CHANNEL="6"                     # WiFi channel (1-11)

# IP Configuration for WiFi network
AP_IP="10.0.0.1"
AP_NETMASK="255.255.255.0"
DHCP_START="10.0.0.10"
DHCP_END="10.0.0.50"

# Bandwidth Limits (applied to entire WiFi network)
BANDWIDTH_LIMIT="20mbit"        # Total for all Smart TVs
BANDWIDTH_CEILING="25mbit"

# ============================================================================
# END CONFIGURATION SECTION
# ============================================================================

print_info "Configuration:"
echo "  WiFi Interface: $WIFI_INTERFACE"
echo "  Ethernet Interface: $ETHERNET_INTERFACE"
echo "  WiFi SSID: $SSID"
echo "  WiFi Password: $PASSWORD"
echo "  Access Point IP: $AP_IP"
echo "  Bandwidth Limit: $BANDWIDTH_LIMIT"
echo ""

# Check if interfaces exist
if ! ip link show "$WIFI_INTERFACE" &> /dev/null; then
    print_error "WiFi interface $WIFI_INTERFACE not found!"
    print_info "Available interfaces:"
    ip link show
    exit 1
fi

if ! ip link show "$ETHERNET_INTERFACE" &> /dev/null; then
    print_error "Ethernet interface $ETHERNET_INTERFACE not found!"
    exit 1
fi

print_success "Interfaces verified"
echo ""

# Install required packages
print_info "Installing required packages..."
apt update
apt install -y hostapd dnsmasq iptables
print_success "Packages installed"
echo ""

# Stop services
print_info "Stopping conflicting services..."
systemctl stop hostapd 2>/dev/null || true
systemctl stop dnsmasq 2>/dev/null || true
systemctl stop wpa_supplicant 2>/dev/null || true
print_success "Services stopped"
echo ""

# Configure WiFi interface
print_info "Configuring WiFi interface..."
ip link set $WIFI_INTERFACE down
ip addr flush dev $WIFI_INTERFACE
ip addr add ${AP_IP}/24 dev $WIFI_INTERFACE
ip link set $WIFI_INTERFACE up
print_success "WiFi interface configured: $AP_IP"
echo ""

# Configure hostapd (WiFi Access Point)
print_info "Configuring hostapd..."
cat > /etc/hostapd/hostapd.conf << EOF
# WiFi interface
interface=$WIFI_INTERFACE

# Driver
driver=nl80211

# WiFi configuration
ssid=$SSID
hw_mode=g
channel=$CHANNEL
ieee80211n=1
wmm_enabled=1

# Security
auth_algs=1
wpa=2
wpa_key_mgmt=WPA-PSK
wpa_passphrase=$PASSWORD
rsn_pairwise=CCMP
EOF

# Set hostapd config path
if [ -f /etc/default/hostapd ]; then
    sed -i 's|#DAEMON_CONF=""|DAEMON_CONF="/etc/hostapd/hostapd.conf"|' /etc/default/hostapd
fi

print_success "hostapd configured"
echo ""

# Configure dnsmasq (DHCP + DNS)
print_info "Configuring DHCP server..."
mv /etc/dnsmasq.conf /etc/dnsmasq.conf.backup 2>/dev/null || true

cat > /etc/dnsmasq.conf << EOF
# Interface to listen on
interface=$WIFI_INTERFACE

# DHCP range
dhcp-range=$DHCP_START,$DHCP_END,12h

# Gateway
dhcp-option=3,$AP_IP

# DNS servers
dhcp-option=6,8.8.8.8,8.8.4.4
server=8.8.8.8
server=8.8.4.4

# Log
log-queries
log-dhcp
EOF

print_success "DHCP server configured"
echo ""

# Enable IP forwarding
print_info "Enabling IP forwarding..."
sysctl -w net.ipv4.ip_forward=1 > /dev/null
if ! grep -q "net.ipv4.ip_forward=1" /etc/sysctl.conf; then
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
fi
print_success "IP forwarding enabled"
echo ""

# Configure iptables for NAT
print_info "Configuring NAT..."
iptables -t nat -F
iptables -t nat -A POSTROUTING -o $ETHERNET_INTERFACE -j MASQUERADE
iptables -A FORWARD -i $WIFI_INTERFACE -o $ETHERNET_INTERFACE -j ACCEPT
iptables -A FORWARD -i $ETHERNET_INTERFACE -o $WIFI_INTERFACE -m state --state RELATED,ESTABLISHED -j ACCEPT

# Save iptables
if command -v netfilter-persistent &> /dev/null; then
    netfilter-persistent save
fi
print_success "NAT configured"
echo ""

# Apply bandwidth limiting
print_info "Applying bandwidth limits..."

# Clear existing rules
tc qdisc del dev $WIFI_INTERFACE root 2>/dev/null || true

# Apply TBF (Token Bucket Filter) for simplicity
tc qdisc add dev $WIFI_INTERFACE root tbf \
    rate $BANDWIDTH_LIMIT \
    burst 32kbit \
    latency 400ms

print_success "Bandwidth limit applied: $BANDWIDTH_LIMIT"
echo ""

# Start services
print_info "Starting services..."
systemctl unmask hostapd
systemctl enable hostapd
systemctl start hostapd

systemctl enable dnsmasq
systemctl start dnsmasq

print_success "Services started"
echo ""

# Create startup script
print_info "Creating startup script..."
cat > /usr/local/bin/smarttv-ap-start.sh << 'STARTUP'
#!/bin/bash
# Start Smart TV WiFi AP

WIFI_INTERFACE="WIFI_IFACE"
ETHERNET_INTERFACE="ETH_IFACE"
AP_IP="AP_IP_ADDR"
BANDWIDTH="BW_LIMIT"

# Configure interface
ip addr add ${AP_IP}/24 dev $WIFI_INTERFACE
ip link set $WIFI_INTERFACE up

# Enable forwarding
sysctl -w net.ipv4.ip_forward=1

# NAT
iptables -t nat -A POSTROUTING -o $ETHERNET_INTERFACE -j MASQUERADE

# Bandwidth limit
tc qdisc del dev $WIFI_INTERFACE root 2>/dev/null || true
tc qdisc add dev $WIFI_INTERFACE root tbf rate $BANDWIDTH burst 32kbit latency 400ms

# Start services
systemctl start hostapd
systemctl start dnsmasq
STARTUP

# Substitute variables
sed -i "s/WIFI_IFACE/$WIFI_INTERFACE/g" /usr/local/bin/smarttv-ap-start.sh
sed -i "s/ETH_IFACE/$ETHERNET_INTERFACE/g" /usr/local/bin/smarttv-ap-start.sh
sed -i "s/AP_IP_ADDR/$AP_IP/g" /usr/local/bin/smarttv-ap-start.sh
sed -i "s/BW_LIMIT/$BANDWIDTH_LIMIT/g" /usr/local/bin/smarttv-ap-start.sh

chmod +x /usr/local/bin/smarttv-ap-start.sh
print_success "Startup script created"
echo ""

# Verify setup
print_info "Verifying setup..."
sleep 3

if systemctl is-active --quiet hostapd; then
    print_success "hostapd is running"
else
    print_error "hostapd failed to start"
    journalctl -u hostapd -n 20
fi

if systemctl is-active --quiet dnsmasq; then
    print_success "dnsmasq is running"
else
    print_error "dnsmasq failed to start"
fi

echo ""
print_success "================================================"
print_success "  WiFi Access Point Setup Complete!"
print_success "================================================"
echo ""
echo "WiFi Network Details:"
echo "  • SSID: $SSID"
echo "  • Password: $PASSWORD"
echo "  • Channel: $CHANNEL"
echo ""
echo "Network Configuration:"
echo "  • Access Point IP: $AP_IP"
echo "  • DHCP Range: $DHCP_START - $DHCP_END"
echo "  • Bandwidth Limit: $BANDWIDTH_LIMIT"
echo ""
echo "Next Steps:"
echo "  1. Connect your Smart TVs to WiFi: $SSID"
echo "  2. Use password: $PASSWORD"
echo "  3. Smart TVs will automatically get limited bandwidth"
echo "  4. Your computers stay on your main WiFi (unlimited)"
echo ""
echo "Monitoring:"
echo "  • Check DHCP leases: cat /var/lib/misc/dnsmasq.leases"
echo "  • View bandwidth: tc -s qdisc show dev $WIFI_INTERFACE"
echo "  • AP status: systemctl status hostapd"
echo ""
echo "Management:"
echo "  • Stop AP: sudo systemctl stop hostapd dnsmasq"
echo "  • Start AP: sudo systemctl start hostapd dnsmasq"
echo "  • Remove limits: sudo tc qdisc del dev $WIFI_INTERFACE root"
echo ""
print_info "WiFi Access Point is now broadcasting!"
print_warning "Connect your Smart TVs to: $SSID"
