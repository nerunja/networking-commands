#!/bin/bash
#
# Smart TV Bandwidth Limiter - MAC-Based Traffic Shaping
# Version: 1.0.0
# Description: Limits bandwidth for specific devices by MAC address (more reliable)
#
# Usage: sudo ./limit_by_mac.sh
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

print_info "Starting MAC-Based Bandwidth Limiter Setup..."
echo ""

# ============================================================================
# CONFIGURATION SECTION - MODIFY THESE VALUES
# ============================================================================

# Network interface to apply limits
INTERFACE="eth0"

# Device MAC addresses with descriptive names
# Format: ["MAC_ADDRESS"]="Description"
# To find MAC addresses: sudo nmap -sn 192.168.1.0/24 | grep "MAC Address"
#                    or: arp -a
declare -A DEVICES=(
    ["aa:bb:cc:dd:ee:ff"]="SmartTV_LivingRoom"
    ["11:22:33:44:55:66"]="SmartTV_Bedroom"
    ["12:34:56:78:90:ab"]="SmartTV_Kitchen"
)

# Bandwidth limit per device
BANDWIDTH="5mbit"

# Maximum burst (ceiling)
BANDWIDTH_CEIL="10mbit"

# Total available bandwidth
TOTAL_BANDWIDTH="100mbit"

# ============================================================================
# END CONFIGURATION SECTION
# ============================================================================

print_info "Configuration:"
echo "  Interface: $INTERFACE"
echo "  Bandwidth per device: $BANDWIDTH (ceil: $BANDWIDTH_CEIL)"
echo "  Devices to limit:"
for mac in "${!DEVICES[@]}"; do
    echo "    - ${DEVICES[$mac]} ($mac)"
done
echo ""

# Verify interface exists
if ! ip link show "$INTERFACE" &> /dev/null; then
    print_error "Interface $INTERFACE not found!"
    print_info "Available interfaces:"
    ip link show | grep -E "^[0-9]+:" | awk '{print $2}' | tr -d ':'
    exit 1
fi
print_success "Interface $INTERFACE verified"
echo ""

# Enable IP forwarding
print_info "Enabling IP forwarding..."
sysctl -w net.ipv4.ip_forward=1 > /dev/null
if ! grep -q "net.ipv4.ip_forward=1" /etc/sysctl.conf; then
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
fi
print_success "IP forwarding enabled"
echo ""

# Clear existing rules
print_info "Clearing existing traffic control rules..."
tc qdisc del dev $INTERFACE root 2>/dev/null || true
print_success "Cleared"

print_info "Clearing iptables mangle rules..."
iptables -t mangle -F 2>/dev/null || true
print_success "Cleared"
echo ""

# Setup HTB qdisc
print_info "Creating traffic control hierarchy..."
tc qdisc add dev $INTERFACE root handle 1: htb default 999
print_success "Root qdisc created"

# Create root class
tc class add dev $INTERFACE parent 1: classid 1:1 htb rate $TOTAL_BANDWIDTH
print_success "Root class created"

# Create unlimited class for unmarked traffic (class 999)
tc class add dev $INTERFACE parent 1:1 classid 1:999 htb \
    rate $TOTAL_BANDWIDTH ceil $TOTAL_BANDWIDTH prio 1
print_success "Unlimited class created for regular devices"
echo ""

# Create classes and filters for each MAC address
print_info "Setting up per-device bandwidth limits..."
counter=10
for mac in "${!DEVICES[@]}"; do
    device_name="${DEVICES[$mac]}"
    
    # Create class for this device
    tc class add dev $INTERFACE parent 1:1 classid 1:$counter htb \
        rate $BANDWIDTH ceil $BANDWIDTH_CEIL prio 2
    
    # Create filter using packet mark
    tc filter add dev $INTERFACE protocol ip parent 1:0 prio 1 \
        handle $counter fw flowid 1:$counter
    
    # Mark packets in iptables mangle table
    iptables -t mangle -A POSTROUTING -m mac --mac-source $mac \
        -j MARK --set-mark $counter
    iptables -t mangle -A PREROUTING -m mac --mac-source $mac \
        -j MARK --set-mark $counter
    
    print_success "Limited $device_name ($mac) to $BANDWIDTH"
    ((counter++))
done
echo ""

# Setup NAT if not already configured
print_info "Checking NAT configuration..."
if ! iptables -t nat -C POSTROUTING -o $INTERFACE -j MASQUERADE 2>/dev/null; then
    iptables -t nat -A POSTROUTING -o $INTERFACE -j MASQUERADE
    print_success "NAT masquerading enabled"
else
    print_success "NAT already configured"
fi
echo ""

# Save iptables rules
print_info "Saving iptables rules..."
if command -v netfilter-persistent &> /dev/null; then
    netfilter-persistent save
    print_success "Rules saved with netfilter-persistent"
elif command -v iptables-save &> /dev/null; then
    iptables-save > /etc/iptables/rules.v4 2>/dev/null || \
    iptables-save > /etc/iptables.rules 2>/dev/null || \
    print_warning "Could not save iptables rules automatically"
fi
echo ""

# Display current configuration
print_success "=== MAC-Based Bandwidth Limiting Active ==="
echo ""
echo "Summary:"
echo "  ✓ ${#DEVICES[@]} device(s) limited by MAC address"
echo "  ✓ Each device limited to $BANDWIDTH (ceiling: $BANDWIDTH_CEIL)"
echo "  ✓ Other devices have full $TOTAL_BANDWIDTH available"
echo "  ✓ Works with dynamic IP addresses"
echo ""

print_info "Current Traffic Control Configuration:"
echo ""
tc -s qdisc show dev $INTERFACE
echo ""
tc -s class show dev $INTERFACE
echo ""

print_info "Iptables Mangle Rules:"
iptables -t mangle -L -v -n --line-numbers
echo ""

# Provide next steps
print_success "=== Setup Complete ==="
echo ""
echo "Advantages of MAC-based limiting:"
echo "  • Works even if devices get new IP addresses"
echo "  • More reliable than IP-based limiting"
echo "  • Survives DHCP lease renewals"
echo ""
echo "Next steps:"
echo "  1. Test bandwidth on limited devices (visit fast.com)"
echo "  2. Monitor traffic: sudo ./monitor_traffic.sh"
echo "  3. Remove limits: sudo ./remove_limits.sh"
echo ""
echo "To add more devices:"
echo "  1. Find MAC address: sudo nmap -sn 192.168.1.0/24"
echo "  2. Edit this script and add to DEVICES array"
echo "  3. Run script again"
echo ""
print_info "MAC-based bandwidth limiting is now active!"
