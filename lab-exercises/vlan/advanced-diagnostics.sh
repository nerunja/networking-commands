#!/bin/bash

#############################################
# Advanced Network Diagnostics Script
# 
# Purpose: Deep troubleshooting with packet captures,
#          detailed analysis, and debugging tools
#
# Author: Network Specialist
# Date: 2025-11-01
# Version: 1.0
#
# Usage: sudo ./advanced-diagnostics.sh [options]
#############################################

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Function to print colored output
print_header() {
    echo ""
    echo -e "${MAGENTA}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${MAGENTA}  $1${NC}"
    echo -e "${MAGENTA}═══════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_section() {
    echo ""
    echo -e "${CYAN}━━━ $1 ━━━${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   print_error "This script must be run as root (use sudo)"
   exit 1
fi

print_header "Advanced Network Diagnostics Tool"

# =============================================================================
# Section 1: System Information
# =============================================================================
print_section "1. System Information"

echo "Kernel version:"
uname -r
echo ""

echo "IP utilities version:"
ip -V
echo ""

echo "Bridge utilities:"
which bridge && bridge -V || print_warning "bridge-utils not installed"
echo ""

# =============================================================================
# Section 2: Complete Network Topology Map
# =============================================================================
print_section "2. Network Topology Map"

echo "=== Network Namespaces ==="
ip netns list
echo ""

echo "=== Bridges ==="
ip link show type bridge
echo ""

echo "=== Virtual Ethernet Pairs ==="
ip link show type veth
echo ""

if ip link show br0 &>/dev/null; then
    echo "=== Bridge Port Membership (br0) ==="
    bridge link show br0
    echo ""
    
    echo "=== VLAN Configuration (br0) ==="
    bridge vlan show
    echo ""
fi

if ip link show br10 &>/dev/null; then
    echo "=== Bridge Port Membership (br10) ==="
    bridge link show br10
    echo ""
fi

if ip link show br20 &>/dev/null; then
    echo "=== Bridge Port Membership (br20) ==="
    bridge link show br20
    echo ""
fi

# =============================================================================
# Section 3: Detailed Interface Analysis
# =============================================================================
print_section "3. Detailed Interface Analysis"

echo "=== PC10 Namespace ==="
if ip netns exec pc10 true 2>/dev/null; then
    echo "Interfaces:"
    ip netns exec pc10 ip addr show
    echo ""
    echo "Link status:"
    ip netns exec pc10 ip link show
    echo ""
    echo "Routes:"
    ip netns exec pc10 ip route
    echo ""
    echo "ARP/Neighbor table:"
    ip netns exec pc10 ip neigh
else
    print_warning "PC10 namespace not found"
fi
echo ""

echo "=== PC20 Namespace ==="
if ip netns exec pc20 true 2>/dev/null; then
    echo "Interfaces:"
    ip netns exec pc20 ip addr show
    echo ""
    echo "Link status:"
    ip netns exec pc20 ip link show
    echo ""
    echo "Routes:"
    ip netns exec pc20 ip route
    echo ""
    echo "ARP/Neighbor table:"
    ip netns exec pc20 ip neigh
else
    print_warning "PC20 namespace not found"
fi
echo ""

echo "=== Router Namespace ==="
if ip netns exec router true 2>/dev/null; then
    echo "Interfaces:"
    ip netns exec router ip addr show
    echo ""
    echo "Link status:"
    ip netns exec router ip link show
    echo ""
    echo "Routes:"
    ip netns exec router ip route
    echo ""
    echo "ARP/Neighbor table:"
    ip netns exec router ip neigh
    echo ""
    echo "IP forwarding status:"
    ip netns exec router sysctl net.ipv4.ip_forward
    echo ""
    echo "IPv4 routing configuration:"
    ip netns exec router sysctl -a 2>/dev/null | grep "net.ipv4.conf" | grep -E "forwarding|rp_filter"
else
    print_warning "Router namespace not found"
fi
echo ""

# =============================================================================
# Section 4: Traffic Statistics
# =============================================================================
print_section "4. Interface Traffic Statistics"

echo "=== PC10 veth-pc10 Statistics ==="
if ip netns exec pc10 true 2>/dev/null; then
    ip netns exec pc10 ip -s link show veth-pc10
else
    print_warning "Cannot access PC10 namespace"
fi
echo ""

echo "=== PC20 veth-pc20 Statistics ==="
if ip netns exec pc20 true 2>/dev/null; then
    ip netns exec pc20 ip -s link show veth-pc20
else
    print_warning "Cannot access PC20 namespace"
fi
echo ""

if ip link show br0 &>/dev/null; then
    echo "=== Bridge br0 Statistics ==="
    ip -s link show br0
    echo ""
    
    echo "=== Bridge Ports Statistics ==="
    for port in veth-sw10 veth-sw20 veth-trunk; do
        if ip link show $port &>/dev/null; then
            echo "--- $port ---"
            ip -s link show $port
            echo ""
        fi
    done
fi

# =============================================================================
# Section 5: ARP Analysis
# =============================================================================
print_section "5. ARP/Neighbor Discovery Analysis"

echo "Testing ARP resolution from PC10 to router..."
if ip netns exec pc10 true 2>/dev/null; then
    print_info "Clearing ARP cache..."
    ip netns exec pc10 ip neigh flush all
    
    print_info "Sending ARP request..."
    if command -v arping &> /dev/null; then
        ip netns exec pc10 timeout 3 arping -c 3 -I veth-pc10 192.168.10.1 2>&1 || print_warning "arping failed"
    else
        print_warning "arping not installed (sudo apt install arping)"
        ip netns exec pc10 ping -c 1 192.168.10.1 > /dev/null 2>&1
    fi
    
    echo ""
    echo "ARP table after request:"
    ip netns exec pc10 ip neigh
fi
echo ""

# =============================================================================
# Section 6: Packet Capture Analysis
# =============================================================================
print_section "6. Live Packet Capture (10 seconds)"

print_warning "Starting packet captures... Press Ctrl+C to stop early"
echo ""

CAPTURE_DIR="/tmp/vlan-diagnostics-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$CAPTURE_DIR"
print_info "Captures will be saved to: $CAPTURE_DIR"
echo ""

# Function to capture packets
capture_packets() {
    local interface=$1
    local namespace=$2
    local filename="$CAPTURE_DIR/${interface}.pcap"
    
    if [ -n "$namespace" ]; then
        print_info "Capturing on $namespace:$interface..."
        timeout 10 ip netns exec $namespace tcpdump -i $interface -w $filename -c 100 2>/dev/null &
    else
        print_info "Capturing on $interface..."
        timeout 10 tcpdump -i $interface -w $filename -c 100 2>/dev/null &
    fi
}

# Start captures
if ip netns exec pc10 true 2>/dev/null; then
    capture_packets "veth-pc10" "pc10"
fi

if ip netns exec router true 2>/dev/null; then
    if ip netns exec router ip link show veth-router &>/dev/null; then
        capture_packets "veth-router" "router"
    fi
    if ip netns exec router ip link show veth-r10 &>/dev/null; then
        capture_packets "veth-r10" "router"
    fi
fi

if ip link show br0 &>/dev/null; then
    capture_packets "br0" ""
fi

# Generate some test traffic
sleep 2
print_info "Generating test traffic..."
if ip netns exec pc10 true 2>/dev/null; then
    ip netns exec pc10 ping -c 5 -i 0.5 192.168.10.1 > /dev/null 2>&1 &
    ip netns exec pc10 ping -c 5 -i 0.5 192.168.20.20 > /dev/null 2>&1 &
fi

# Wait for captures to complete
wait

echo ""
print_success "Packet captures complete!"
echo ""
echo "Capture files:"
ls -lh "$CAPTURE_DIR"
echo ""
print_info "Analyze captures with: tcpdump -r $CAPTURE_DIR/<file>.pcap -n -e"
print_info "Or use Wireshark: wireshark $CAPTURE_DIR/<file>.pcap"
echo ""

# =============================================================================
# Section 7: Quick Packet Analysis
# =============================================================================
print_section "7. Quick Packet Analysis"

for pcapfile in "$CAPTURE_DIR"/*.pcap; do
    if [ -f "$pcapfile" ]; then
        echo "=== $(basename $pcapfile) ==="
        echo "Packet count:"
        tcpdump -r "$pcapfile" 2>/dev/null | wc -l
        
        echo ""
        echo "Protocol distribution:"
        tcpdump -r "$pcapfile" -n 2>/dev/null | awk '{print $3}' | sort | uniq -c | sort -rn | head -10
        
        echo ""
        echo "First 5 packets:"
        tcpdump -r "$pcapfile" -n -e 2>/dev/null | head -5
        echo ""
        echo "---"
        echo ""
    fi
done

# =============================================================================
# Section 8: Connectivity Matrix
# =============================================================================
print_section "8. Connectivity Matrix"

test_connectivity() {
    local source_ns=$1
    local dest_ip=$2
    local desc=$3
    
    if ip netns exec $source_ns ping -c 1 -W 1 $dest_ip > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} $desc"
        return 0
    else
        echo -e "  ${RED}✗${NC} $desc"
        return 1
    fi
}

if ip netns exec pc10 true 2>/dev/null && ip netns exec pc20 true 2>/dev/null && ip netns exec router true 2>/dev/null; then
    echo "Testing all paths..."
    echo ""
    
    test_connectivity "pc10" "192.168.10.1" "PC10 → Router (VLAN 10 GW)"
    test_connectivity "pc10" "192.168.20.1" "PC10 → Router (VLAN 20 GW)"
    test_connectivity "pc10" "192.168.20.20" "PC10 → PC20 (Inter-VLAN)"
    echo ""
    
    test_connectivity "pc20" "192.168.20.1" "PC20 → Router (VLAN 20 GW)"
    test_connectivity "pc20" "192.168.10.1" "PC20 → Router (VLAN 10 GW)"
    test_connectivity "pc20" "192.168.10.10" "PC20 → PC10 (Inter-VLAN)"
    echo ""
    
    test_connectivity "router" "192.168.10.10" "Router → PC10"
    test_connectivity "router" "192.168.20.20" "Router → PC20"
else
    print_warning "One or more namespaces not available for connectivity testing"
fi
echo ""

# =============================================================================
# Section 9: Firewall Rules
# =============================================================================
print_section "9. Firewall Rules (iptables)"

echo "=== Router Namespace iptables ==="
if ip netns exec router true 2>/dev/null; then
    echo "Filter table:"
    ip netns exec router iptables -L -n -v
    echo ""
    echo "NAT table:"
    ip netns exec router iptables -t nat -L -n -v
else
    print_warning "Router namespace not found"
fi
echo ""

echo "=== Host iptables (default namespace) ==="
echo "Filter table:"
iptables -L -n -v | head -20
echo "(showing first 20 lines only)"
echo ""

# =============================================================================
# Section 10: Recommendations
# =============================================================================
print_section "10. Diagnostic Recommendations"

echo "Based on this analysis, here are some recommendations:"
echo ""

# Check for common issues
ISSUES_FOUND=0

# Check IP forwarding
if ip netns exec router true 2>/dev/null; then
    IP_FORWARD=$(ip netns exec router sysctl -n net.ipv4.ip_forward 2>/dev/null)
    if [ "$IP_FORWARD" != "1" ]; then
        print_error "IP forwarding is DISABLED in router namespace"
        echo "  Fix: sudo ip netns exec router sysctl -w net.ipv4.ip_forward=1"
        ((ISSUES_FOUND++))
    fi
fi

# Check VLAN filtering
if ip link show br0 &>/dev/null; then
    VLAN_FILTER=$(ip -d link show br0 | grep "vlan_filtering")
    if ! echo "$VLAN_FILTER" | grep -q "vlan_filtering 1"; then
        print_error "VLAN filtering is NOT enabled on br0"
        echo "  Fix: sudo ip link set br0 type bridge vlan_filtering 1"
        ((ISSUES_FOUND++))
    fi
fi

# Check interface status
for ns in pc10 pc20 router; do
    if ip netns exec $ns true 2>/dev/null; then
        DOWN_IFACES=$(ip netns exec $ns ip link show | grep "state DOWN" | awk '{print $2}' | tr -d ':')
        if [ -n "$DOWN_IFACES" ]; then
            print_warning "Interfaces DOWN in $ns: $DOWN_IFACES"
            echo "  Fix: sudo ip netns exec $ns ip link set <interface> up"
            ((ISSUES_FOUND++))
        fi
    fi
done

if [ $ISSUES_FOUND -eq 0 ]; then
    print_success "No obvious configuration issues detected"
else
    echo ""
    print_warning "Found $ISSUES_FOUND potential issue(s) - see above for details"
fi

echo ""
print_info "Capture files saved to: $CAPTURE_DIR"
print_info "Use 'wireshark' or 'tcpdump -r' to analyze packet captures"
echo ""

# =============================================================================
# Section 11: Useful Commands Reference
# =============================================================================
print_section "11. Useful Commands Reference"

cat << 'EOF'
=== Namespace Commands ===
  List namespaces:           sudo ip netns list
  Execute in namespace:      sudo ip netns exec <ns> <command>
  Enter namespace shell:     sudo ip netns exec <ns> bash

=== Interface Commands ===
  Show interfaces:           sudo ip link show
  Show IP addresses:         sudo ip addr show
  Interface statistics:      sudo ip -s link show <interface>
  Bring interface up:        sudo ip link set <interface> up

=== Bridge Commands ===
  Show bridge ports:         sudo bridge link show
  Show VLAN config:          sudo bridge vlan show
  Bridge statistics:         sudo bridge -s link show

=== Packet Capture ===
  Capture on interface:      sudo tcpdump -i <interface> -n -e
  Capture to file:           sudo tcpdump -i <interface> -w file.pcap
  Read capture file:         sudo tcpdump -r file.pcap -n -e
  Capture VLAN tags:         sudo tcpdump -i <interface> -e vlan

=== Testing Commands ===
  Ping test:                 sudo ip netns exec <ns> ping <ip>
  Traceroute:                sudo ip netns exec <ns> traceroute <ip>
  ARP ping:                  sudo ip netns exec <ns> arping -I <iface> <ip>
  Check connectivity:        sudo ip netns exec <ns> nc -zv <ip> <port>

=== Troubleshooting ===
  Check VLAN filtering:      sudo ip -d link show br0 | grep vlan_filtering
  Check IP forwarding:       sudo ip netns exec router sysctl net.ipv4.ip_forward
  Clear ARP cache:           sudo ip netns exec <ns> ip neigh flush all
  View routing table:        sudo ip netns exec <ns> ip route
  Check firewall:            sudo ip netns exec <ns> iptables -L -n

EOF

print_header "Diagnostics Complete!"
print_info "Review the output above for detailed network analysis"
print_info "Packet captures are available in: $CAPTURE_DIR"
