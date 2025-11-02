#!/bin/bash
#
# Remove Bandwidth Limits - Cleanup Script
# Version: 1.0.0
# Description: Removes all traffic control rules and bandwidth limiting
#
# Usage: sudo ./remove_limits.sh
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
echo "============================================"
echo "  Remove Bandwidth Limits"
echo "============================================"
echo ""
print_warning "This will remove ALL traffic control rules and bandwidth limits"
read -p "Are you sure you want to continue? (y/N): " confirm
echo ""

if [[ ! $confirm =~ ^[Yy]$ ]]; then
    print_info "Aborted by user"
    exit 0
fi

# Get list of all network interfaces
INTERFACES=$(ip link show | grep -oP '^\d+: \K[^:]+(?=:)')

print_info "Removing traffic control rules from all interfaces..."
echo ""

removed_count=0
for iface in $INTERFACES; do
    # Check if interface has tc rules
    if tc qdisc show dev $iface 2>/dev/null | grep -q "qdisc"; then
        print_info "Removing tc rules from $iface..."
        
        # Remove root qdisc (this removes all classes and filters too)
        tc qdisc del dev $iface root 2>/dev/null && {
            print_success "Removed root qdisc from $iface"
            ((removed_count++))
        } || print_warning "No root qdisc on $iface"
        
        # Remove ingress qdisc if present
        tc qdisc del dev $iface ingress 2>/dev/null && {
            print_success "Removed ingress qdisc from $iface"
        } || true
    fi
done

echo ""
if [ $removed_count -eq 0 ]; then
    print_warning "No traffic control rules found on any interface"
else
    print_success "Removed tc rules from $removed_count interface(s)"
fi

# Clear iptables rules
print_info "Cleaning up iptables rules..."
echo ""

# Save current rule count
nat_rules=$(iptables -t nat -L POSTROUTING -n --line-numbers | tail -n +3 | wc -l)
mangle_rules=$(iptables -t mangle -L -n | tail -n +3 | wc -l)

# Ask before clearing iptables
if [ $nat_rules -gt 0 ] || [ $mangle_rules -gt 0 ]; then
    echo "Found iptables rules:"
    echo "  NAT rules: $nat_rules"
    echo "  Mangle rules: $mangle_rules"
    echo ""
    read -p "Clear iptables NAT and mangle tables? (y/N): " clear_iptables
    
    if [[ $clear_iptables =~ ^[Yy]$ ]]; then
        # Flush NAT table
        iptables -t nat -F POSTROUTING 2>/dev/null && \
            print_success "Cleared NAT POSTROUTING rules"
        
        # Flush mangle table
        iptables -t mangle -F 2>/dev/null && \
            print_success "Cleared mangle table rules"
        
        # Save rules if using persistent iptables
        if command -v netfilter-persistent &> /dev/null; then
            print_info "Saving iptables configuration..."
            netfilter-persistent save
            print_success "iptables rules saved"
        fi
    else
        print_info "Skipped iptables cleanup (NAT/masquerading may still be active)"
    fi
else
    print_info "No iptables rules to clear"
fi

echo ""

# Check IP forwarding
print_info "Checking IP forwarding status..."
ip_forward=$(cat /proc/sys/net/ipv4/ip_forward)

if [ "$ip_forward" == "1" ]; then
    echo "IP forwarding is currently enabled"
    read -p "Disable IP forwarding? (y/N): " disable_forward
    
    if [[ $disable_forward =~ ^[Yy]$ ]]; then
        sysctl -w net.ipv4.ip_forward=0 > /dev/null
        print_success "IP forwarding disabled"
        
        # Remove from sysctl.conf
        if grep -q "net.ipv4.ip_forward=1" /etc/sysctl.conf; then
            sed -i '/net.ipv4.ip_forward=1/d' /etc/sysctl.conf
            print_success "Removed from /etc/sysctl.conf"
        fi
    else
        print_info "IP forwarding left enabled"
    fi
else
    print_info "IP forwarding is already disabled"
fi

echo ""

# Check for systemd service
if [ -f /etc/systemd/system/bandwidth-limiter.service ]; then
    print_info "Found bandwidth-limiter systemd service"
    read -p "Disable and remove service? (y/N): " remove_service
    
    if [[ $remove_service =~ ^[Yy]$ ]]; then
        systemctl stop bandwidth-limiter.service 2>/dev/null || true
        systemctl disable bandwidth-limiter.service 2>/dev/null || true
        rm /etc/systemd/system/bandwidth-limiter.service
        systemctl daemon-reload
        print_success "Service removed"
        
        # Remove helper scripts
        rm -f /usr/local/bin/bandwidth-limiter-start.sh
        rm -f /usr/local/bin/bandwidth-limiter-stop.sh
        print_success "Helper scripts removed"
    fi
fi

echo ""

# Verify removal
print_info "Verifying cleanup..."
echo ""

all_clear=true

for iface in $INTERFACES; do
    if tc qdisc show dev $iface 2>/dev/null | grep -q "htb\|tbf"; then
        print_warning "Traffic control still active on $iface"
        all_clear=false
    fi
done

if [ "$all_clear" = true ]; then
    print_success "All traffic control rules removed"
else
    print_warning "Some traffic control rules may still be active"
    echo "Run: tc qdisc show"
fi

echo ""

# Display current status
print_info "Current Network Status:"
echo ""
echo "IP Forwarding: $(cat /proc/sys/net/ipv4/ip_forward)"
echo ""
echo "Traffic Control Status:"
for iface in $INTERFACES; do
    has_tc=$(tc qdisc show dev $iface 2>/dev/null | grep -c "qdisc" || echo "0")
    if [ "$has_tc" != "0" ]; then
        echo "  $iface: $(tc qdisc show dev $iface | head -1)"
    fi
done

echo ""
echo "NAT Rules: $(iptables -t nat -L POSTROUTING -n --line-numbers | tail -n +3 | wc -l)"
echo "Mangle Rules: $(iptables -t mangle -L -n | tail -n +3 | wc -l)"

echo ""
print_success "============================================"
print_success "  Cleanup Complete"
print_success "============================================"
echo ""
echo "Your network should now be operating without bandwidth limits."
echo ""
echo "To re-enable bandwidth limiting:"
echo "  • sudo ./setup_traffic_shaping.sh (IP-based)"
echo "  • sudo ./limit_by_mac.sh (MAC-based)"
echo "  • sudo ./limit_by_interface.sh (Interface-based)"
echo "  • sudo ./raspberry_pi_setup.sh (Raspberry Pi)"
echo ""
print_info "All traffic control rules have been removed!"
