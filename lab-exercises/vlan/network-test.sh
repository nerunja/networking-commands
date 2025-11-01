#!/bin/bash

#############################################
# Network Verification and Testing Script
# 
# Purpose: Comprehensive testing and diagnostics for
#          VLAN network namespace setup
#
# Author: Network Specialist
# Date: 2025-11-01
# Version: 1.0
#
# Usage: sudo ./network-test.sh
#############################################

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
WARNING_TESTS=0

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

print_test() {
    echo -e "${BLUE}→${NC} $1"
}

print_success() {
    echo -e "${GREEN}✅ PASS:${NC} $1"
    ((PASSED_TESTS++))
    ((TOTAL_TESTS++))
}

print_error() {
    echo -e "${RED}❌ FAIL:${NC} $1"
    ((FAILED_TESTS++))
    ((TOTAL_TESTS++))
}

print_warning() {
    echo -e "${YELLOW}⚠️  WARN:${NC} $1"
    ((WARNING_TESTS++))
}

print_info() {
    echo -e "${CYAN}ℹ️  INFO:${NC} $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}❌ This script must be run as root (use sudo)${NC}"
   exit 1
fi

print_header "Network Verification and Testing Suite"

# =============================================================================
# Section 1: Namespace Verification
# =============================================================================
print_section "1. Network Namespace Verification"

print_test "Checking if namespaces exist..."
NAMESPACES=$(ip netns list 2>/dev/null)

if echo "$NAMESPACES" | grep -q "pc10"; then
    print_success "Namespace 'pc10' exists"
else
    print_error "Namespace 'pc10' not found"
fi

if echo "$NAMESPACES" | grep -q "pc20"; then
    print_success "Namespace 'pc20' exists"
else
    print_error "Namespace 'pc20' not found"
fi

if echo "$NAMESPACES" | grep -q "router"; then
    print_success "Namespace 'router' exists"
else
    print_error "Namespace 'router' not found"
fi

echo ""
print_info "All namespaces:"
echo "$NAMESPACES"

# =============================================================================
# Section 2: Bridge Configuration
# =============================================================================
print_section "2. Bridge Configuration"

print_test "Checking for bridges..."

if ip link show br0 &>/dev/null; then
    print_success "Bridge 'br0' exists"
    
    # Check VLAN filtering
    VLAN_FILTERING=$(ip -d link show br0 | grep "vlan_filtering")
    if echo "$VLAN_FILTERING" | grep -q "vlan_filtering 1"; then
        print_success "VLAN filtering is enabled on br0"
        
        echo ""
        print_info "VLAN configuration on br0:"
        bridge vlan show
        
    else
        print_warning "VLAN filtering is NOT enabled on br0 (separate bridges mode?)"
    fi
elif ip link show br10 &>/dev/null && ip link show br20 &>/dev/null; then
    print_success "Bridges 'br10' and 'br20' exist (separate bridges mode)"
    
    echo ""
    print_info "Bridge 10 ports:"
    bridge link show br10
    
    echo ""
    print_info "Bridge 20 ports:"
    bridge link show br20
else
    print_error "No bridges found (neither br0 nor br10/br20)"
fi

# =============================================================================
# Section 3: Interface Configuration
# =============================================================================
print_section "3. Interface Configuration"

print_test "Checking PC10 interfaces..."
PC10_ADDR=$(ip netns exec pc10 ip addr show veth-pc10 2>/dev/null | grep "inet ")
if echo "$PC10_ADDR" | grep -q "192.168.10.10"; then
    print_success "PC10 interface configured: 192.168.10.10/24"
else
    print_error "PC10 interface not properly configured"
fi
echo "$PC10_ADDR" | grep "inet "

print_test "Checking PC20 interfaces..."
PC20_ADDR=$(ip netns exec pc20 ip addr show veth-pc20 2>/dev/null | grep "inet ")
if echo "$PC20_ADDR" | grep -q "192.168.20.20"; then
    print_success "PC20 interface configured: 192.168.20.20/24"
else
    print_error "PC20 interface not properly configured"
fi
echo "$PC20_ADDR" | grep "inet "

print_test "Checking Router interfaces..."
ROUTER_ADDR=$(ip netns exec router ip addr show 2>/dev/null | grep "inet ")
if echo "$ROUTER_ADDR" | grep -q "192.168.10.1"; then
    print_success "Router VLAN 10 interface: 192.168.10.1/24"
else
    print_error "Router VLAN 10 interface not configured"
fi
if echo "$ROUTER_ADDR" | grep -q "192.168.20.1"; then
    print_success "Router VLAN 20 interface: 192.168.20.1/24"
else
    print_error "Router VLAN 20 interface not configured"
fi
echo "$ROUTER_ADDR" | grep "inet "

# =============================================================================
# Section 4: Routing Configuration
# =============================================================================
print_section "4. Routing Configuration"

print_test "Checking IP forwarding in router..."
IP_FORWARD=$(ip netns exec router sysctl net.ipv4.ip_forward 2>/dev/null)
if echo "$IP_FORWARD" | grep -q "net.ipv4.ip_forward = 1"; then
    print_success "IP forwarding is enabled"
else
    print_error "IP forwarding is NOT enabled"
fi

print_test "Checking PC10 default route..."
PC10_ROUTE=$(ip netns exec pc10 ip route | grep "default")
if echo "$PC10_ROUTE" | grep -q "192.168.10.1"; then
    print_success "PC10 default route via 192.168.10.1"
else
    print_error "PC10 default route not configured"
fi
echo "$PC10_ROUTE"

print_test "Checking PC20 default route..."
PC20_ROUTE=$(ip netns exec pc20 ip route | grep "default")
if echo "$PC20_ROUTE" | grep -q "192.168.20.1"; then
    print_success "PC20 default route via 192.168.20.1"
else
    print_error "PC20 default route not configured"
fi
echo "$PC20_ROUTE"

echo ""
print_info "Router routing table:"
ip netns exec router ip route

# =============================================================================
# Section 5: Link Status
# =============================================================================
print_section "5. Link Status"

print_test "Checking interface status..."

check_interface_status() {
    local ns=$1
    local iface=$2
    local status=$(ip netns exec $ns ip link show $iface 2>/dev/null | grep "state")
    
    if echo "$status" | grep -q "state UP"; then
        print_success "$ns:$iface is UP"
    else
        print_error "$ns:$iface is DOWN or not found"
        echo "$status"
    fi
}

check_interface_status "pc10" "veth-pc10"
check_interface_status "pc20" "veth-pc20"

if ip link show br0 &>/dev/null; then
    # VLAN-aware bridge mode
    check_interface_status "router" "veth-router"
    check_interface_status "router" "veth-router.10"
    check_interface_status "router" "veth-router.20"
else
    # Separate bridges mode
    check_interface_status "router" "veth-r10"
    check_interface_status "router" "veth-r20"
fi

# =============================================================================
# Section 6: Connectivity Tests
# =============================================================================
print_section "6. Connectivity Tests"

print_test "Test 1: PC10 → Router Gateway (192.168.10.1)"
if ip netns exec pc10 ping -c 3 -W 2 192.168.10.1 > /dev/null 2>&1; then
    print_success "PC10 can reach router gateway (VLAN 10)"
else
    print_error "PC10 cannot reach router gateway"
    print_info "Attempting verbose ping..."
    ip netns exec pc10 ping -c 2 192.168.10.1
fi

print_test "Test 2: PC20 → Router Gateway (192.168.20.1)"
if ip netns exec pc20 ping -c 3 -W 2 192.168.20.1 > /dev/null 2>&1; then
    print_success "PC20 can reach router gateway (VLAN 20)"
else
    print_error "PC20 cannot reach router gateway"
    print_info "Attempting verbose ping..."
    ip netns exec pc20 ping -c 2 192.168.20.1
fi

print_test "Test 3: Inter-VLAN Routing (PC10 → PC20)"
if ip netns exec pc10 ping -c 3 -W 2 192.168.20.20 > /dev/null 2>&1; then
    print_success "PC10 can reach PC20 via inter-VLAN routing"
else
    print_error "PC10 cannot reach PC20"
    print_info "Attempting verbose ping..."
    ip netns exec pc10 ping -c 2 192.168.20.20
fi

print_test "Test 4: Inter-VLAN Routing (PC20 → PC10)"
if ip netns exec pc20 ping -c 3 -W 2 192.168.10.10 > /dev/null 2>&1; then
    print_success "PC20 can reach PC10 via inter-VLAN routing"
else
    print_error "PC20 cannot reach PC10"
    print_info "Attempting verbose ping..."
    ip netns exec pc20 ping -c 2 192.168.10.10
fi

# =============================================================================
# Section 7: ARP Tables
# =============================================================================
print_section "7. ARP/Neighbor Tables"

echo "PC10 ARP table:"
ip netns exec pc10 ip neigh
echo ""

echo "PC20 ARP table:"
ip netns exec pc20 ip neigh
echo ""

echo "Router ARP table:"
ip netns exec router ip neigh
echo ""

# =============================================================================
# Section 8: Advanced Diagnostics
# =============================================================================
print_section "8. Advanced Diagnostics"

print_test "Checking for packet loss patterns..."
echo "PC10 → Router (10 packets):"
ip netns exec pc10 ping -c 10 -i 0.2 192.168.10.1 2>/dev/null | tail -2

echo ""
echo "PC20 → Router (10 packets):"
ip netns exec pc20 ping -c 10 -i 0.2 192.168.20.1 2>/dev/null | tail -2

print_test "Checking MTU settings..."
echo "PC10 MTU: $(ip netns exec pc10 ip link show veth-pc10 | grep mtu | awk '{print $5}')"
echo "PC20 MTU: $(ip netns exec pc20 ip link show veth-pc20 | grep mtu | awk '{print $5}')"

if ip link show br0 &>/dev/null; then
    echo "Bridge MTU: $(ip link show br0 | grep mtu | awk '{print $5}')"
fi

# =============================================================================
# Section 9: Traceroute Tests
# =============================================================================
print_section "9. Traceroute Tests"

if command -v traceroute &> /dev/null; then
    print_test "Traceroute: PC10 → PC20"
    ip netns exec pc10 traceroute -n -m 5 192.168.20.20 2>/dev/null || print_warning "Traceroute failed"
    echo ""
    
    print_test "Traceroute: PC20 → PC10"
    ip netns exec pc20 traceroute -n -m 5 192.168.10.10 2>/dev/null || print_warning "Traceroute failed"
else
    print_warning "traceroute not installed (sudo apt install traceroute)"
fi

# =============================================================================
# Section 10: Traffic Statistics
# =============================================================================
print_section "10. Traffic Statistics"

echo "PC10 interface statistics:"
ip netns exec pc10 ip -s link show veth-pc10 | grep -A 3 "RX:"
echo ""

echo "PC20 interface statistics:"
ip netns exec pc20 ip -s link show veth-pc20 | grep -A 3 "RX:"
echo ""

if ip link show br0 &>/dev/null; then
    echo "Bridge statistics:"
    ip -s link show br0 | grep -A 3 "RX:"
fi

# =============================================================================
# Test Summary
# =============================================================================
print_header "Test Summary"

echo -e "${CYAN}Total Tests:${NC}   $TOTAL_TESTS"
echo -e "${GREEN}Passed:${NC}        $PASSED_TESTS"
echo -e "${RED}Failed:${NC}        $FAILED_TESTS"
echo -e "${YELLOW}Warnings:${NC}      $WARNING_TESTS"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  ✅ ALL TESTS PASSED - Network is fully operational!${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    exit 0
else
    echo -e "${RED}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${RED}  ❌ SOME TESTS FAILED - See details above${NC}"
    echo -e "${RED}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "Troubleshooting tips:"
    echo "  1. Check VLAN configuration:     sudo bridge vlan show"
    echo "  2. Verify IP forwarding:         sudo ip netns exec router sysctl net.ipv4.ip_forward"
    echo "  3. Check interface status:       sudo ip netns exec pc10 ip link"
    echo "  4. Capture packets:              sudo tcpdump -i br0 -n -e"
    echo "  5. View detailed guide:          cat vlan-networking-troubleshooting-guide.md"
    exit 1
fi
