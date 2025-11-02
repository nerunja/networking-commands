#!/bin/bash
#
# Smart TV Bandwidth Limiter - IP-Based Traffic Shaping
# Version: 1.0.0
# Description: Limits bandwidth for specific devices by IP address
#
# Usage: sudo ./setup_traffic_shaping.sh
#

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   print_error "This script must be run as root (use sudo)"
   exit 1
fi

print_info "Starting Smart TV Bandwidth Limiter Setup..."
echo ""

# ============================================================================
# CONFIGURATION SECTION - MODIFY THESE VALUES
# ============================================================================

# Network interfaces
ROUTER_INTERFACE="eth0"      # Interface connected to router (upstream)
LAN_INTERFACE="eth1"         # Interface connected to LAN (downstream)

# Smart TV IP addresses to limit
# Add or remove IP addresses as needed
SMART_TV_IPS=(
    "192.168.1.100"
    "192.168.1.101"
    "192.168.1.102"
)

# Bandwidth limit per Smart TV
# Options: Xkbit (kilobits), Xmbit (megabits), Xgbit (gigabits)
# Examples: 1mbit, 5mbit, 10mbit, 500kbit
BANDWIDTH_LIMIT="5mbit"

# Maximum burst limit (ceiling) - allows temporary speed bursts
BANDWIDTH_CEILING="10mbit"

# Total available bandwidth for all devices
TOTAL_BANDWIDTH="100mbit"

# ============================================================================
# END CONFIGURATION SECTION
# ============================================================================

print_info "Configuration:"
echo "  Router Interface: $ROUTER_INTERFACE"
echo "  LAN Interface: $LAN_INTERFACE"
echo "  Bandwidth Limit per TV: $BANDWIDTH_LIMIT"
echo "  Bandwidth Ceiling per TV: $BANDWIDTH_CEILING"
echo "  Smart TVs to limit:"
for ip in "${SMART_TV_IPS[@]}"; do
    echo "    - $ip"
done
echo ""

# Verify interfaces exist
print_info "Verifying network interfaces..."
for interface in "$ROUTER_INTERFACE" "$LAN_INTERFACE"; do
    if ! ip link show "$interface" &> /dev/null; then
        print_error "Interface $interface not found!"
        print_info "Available interfaces:"
        ip link show | grep -E "^[0-9]+:" | awk '{print $2}' | tr -d ':'
        exit 1
    fi
    print_success "Interface $interface found"
done
echo ""

# Enable IP forwarding
print_info "Enabling IP forwarding..."
sysctl -w net.ipv4.ip_forward=1 > /dev/null
if ! grep -q "net.ipv4.ip_forward=1" /etc/sysctl.conf; then
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
    print_success "IP forwarding enabled permanently"
else
    print_success "IP forwarding already enabled"
fi
echo ""

# Clear existing traffic control rules
print_info "Clearing existing traffic control rules..."
tc qdisc del dev $LAN_INTERFACE root 2>/dev/null || true
print_success "Existing rules cleared"
echo ""

# Setup HTB (Hierarchical Token Bucket) qdisc
print_info "Setting up traffic control hierarchy..."

# Create root qdisc with default class 30 (unlimited)
tc qdisc add dev $LAN_INTERFACE root handle 1: htb default 30
print_success "Root qdisc created"

# Create root class with total bandwidth
tc class add dev $LAN_INTERFACE parent 1: classid 1:1 htb rate $TOTAL_BANDWIDTH
print_success "Root class created with total bandwidth: $TOTAL_BANDWIDTH"

# Create limited class for Smart TVs (class 1:10)
tc class add dev $LAN_INTERFACE parent 1:1 classid 1:10 htb \
    rate $BANDWIDTH_LIMIT ceil $BANDWIDTH_CEILING prio 2
print_success "Limited class created (ID: 1:10) - Rate: $BANDWIDTH_LIMIT, Ceil: $BANDWIDTH_CEILING"

# Create unlimited class for other devices (class 1:30)
UNLIMITED_BANDWIDTH="90mbit"
tc class add dev $LAN_INTERFACE parent 1:1 classid 1:30 htb \
    rate $UNLIMITED_BANDWIDTH ceil $TOTAL_BANDWIDTH prio 1
print_success "Unlimited class created (ID: 1:30) - Rate: $UNLIMITED_BANDWIDTH"

echo ""

# Add filters for each Smart TV
print_info "Adding filters for Smart TVs..."
filter_counter=1
for ip in "${SMART_TV_IPS[@]}"; do
    tc filter add dev $LAN_INTERFACE protocol ip parent 1:0 prio 1 u32 \
        match ip dst $ip flowid 1:10
    print_success "Filter added for Smart TV: $ip → Limited class"
    ((filter_counter++))
done
echo ""

# Setup iptables for NAT/Masquerading
print_info "Configuring iptables NAT..."

# Clear existing NAT rules
iptables -t nat -F 2>/dev/null || true

# Enable masquerading for outgoing traffic
iptables -t nat -A POSTROUTING -o $ROUTER_INTERFACE -j MASQUERADE
print_success "NAT masquerading enabled"

# Allow forwarding
iptables -A FORWARD -i $LAN_INTERFACE -o $ROUTER_INTERFACE -j ACCEPT
iptables -A FORWARD -i $ROUTER_INTERFACE -o $LAN_INTERFACE \
    -m state --state RELATED,ESTABLISHED -j ACCEPT
print_success "Packet forwarding rules added"

echo ""

# Save iptables rules
print_info "Saving iptables rules..."
if command -v netfilter-persistent &> /dev/null; then
    netfilter-persistent save
    print_success "iptables rules saved with netfilter-persistent"
elif command -v iptables-save &> /dev/null; then
    iptables-save > /etc/iptables/rules.v4 2>/dev/null || \
    iptables-save > /etc/iptables.rules 2>/dev/null || \
    print_warning "Could not save iptables rules automatically"
fi
echo ""

# Display configuration summary
print_success "=== Traffic Shaping Configuration Complete ==="
echo ""
echo "Summary:"
echo "  ✓ IP forwarding enabled"
echo "  ✓ Traffic control hierarchy created"
echo "  ✓ ${#SMART_TV_IPS[@]} Smart TV(s) limited to $BANDWIDTH_LIMIT each"
echo "  ✓ Other devices have up to $TOTAL_BANDWIDTH available"
echo "  ✓ NAT/Masquerading configured"
echo ""

# Show current configuration
print_info "Current Traffic Control Configuration:"
echo ""
tc -s qdisc show dev $LAN_INTERFACE
echo ""
tc -s class show dev $LAN_INTERFACE
echo ""

# Provide next steps
print_success "=== Setup Complete ==="
echo ""
echo "Next steps:"
echo "  1. Verify Smart TVs are using this device as gateway"
echo "  2. Test bandwidth on Smart TVs (visit fast.com)"
echo "  3. Monitor traffic: sudo ./monitor_traffic.sh"
echo "  4. Remove limits: sudo ./remove_limits.sh"
echo ""
echo "To make this persistent across reboots:"
echo "  sudo systemctl enable bandwidth-limiter.service"
echo ""
print_info "Bandwidth limiting is now active!"
