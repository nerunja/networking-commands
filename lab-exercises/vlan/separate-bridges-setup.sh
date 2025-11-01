#!/bin/bash

#############################################
# Separate Bridges Network Setup Script
# 
# Purpose: Creates isolated network namespaces with
#          separate bridges per VLAN (simpler approach)
#
# Author: Network Specialist
# Date: 2025-11-01
# Version: 1.0
#
# Topology:
#   PC10 (VLAN 10) ── br10 ── Router
#   PC20 (VLAN 20) ── br20 ── Router
#
# Usage: sudo ./separate-bridges-setup.sh
#############################################

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}===${NC} $1 ${BLUE}===${NC}"
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

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   print_error "This script must be run as root (use sudo)"
   exit 1
fi

print_status "Starting Separate Bridges Network Setup"
echo ""

print_status "Cleaning Up Existing Setup"
ip netns delete pc10 2>/dev/null && print_warning "Removed existing pc10 namespace" || true
ip netns delete pc20 2>/dev/null && print_warning "Removed existing pc20 namespace" || true
ip netns delete router 2>/dev/null && print_warning "Removed existing router namespace" || true
ip link delete br10 2>/dev/null && print_warning "Removed existing br10 bridge" || true
ip link delete br20 2>/dev/null && print_warning "Removed existing br20 bridge" || true
ip link delete br0 2>/dev/null && print_warning "Removed existing br0 bridge" || true
echo ""

print_status "Creating Network Namespaces"
ip netns add pc10
print_success "Created namespace: pc10"
ip netns add pc20
print_success "Created namespace: pc20"
ip netns add router
print_success "Created namespace: router"
echo ""

print_status "Creating Virtual Ethernet Pairs"
# PC10 to Bridge 10
ip link add veth-pc10 type veth peer name veth-sw10
print_success "Created veth pair: veth-pc10 <-> veth-sw10"

# PC20 to Bridge 20
ip link add veth-pc20 type veth peer name veth-sw20
print_success "Created veth pair: veth-pc20 <-> veth-sw20"

# Router VLAN 10 to Bridge 10
ip link add veth-r10 type veth peer name veth-sw-r10
print_success "Created veth pair: veth-r10 <-> veth-sw-r10"

# Router VLAN 20 to Bridge 20
ip link add veth-r20 type veth peer name veth-sw-r20
print_success "Created veth pair: veth-r20 <-> veth-sw-r20"
echo ""

print_status "Moving Interfaces to Namespaces"
ip link set veth-pc10 netns pc10
print_success "Moved veth-pc10 to pc10 namespace"
ip link set veth-pc20 netns pc20
print_success "Moved veth-pc20 to pc20 namespace"
ip link set veth-r10 netns router
print_success "Moved veth-r10 to router namespace"
ip link set veth-r20 netns router
print_success "Moved veth-r20 to router namespace"
echo ""

print_status "Creating Separate Bridges"
# One bridge per VLAN
ip link add br10 type bridge
ip link add br20 type bridge
ip link set br10 up
ip link set br20 up
print_success "Created and enabled bridges: br10 (VLAN 10), br20 (VLAN 20)"
echo ""

print_status "Connecting Ports to Bridges"
# Bridge 10 (VLAN 10)
ip link set veth-sw10 master br10
print_success "Connected veth-sw10 to br10"
ip link set veth-sw-r10 master br10
print_success "Connected veth-sw-r10 to br10"

# Bridge 20 (VLAN 20)
ip link set veth-sw20 master br20
print_success "Connected veth-sw20 to br20"
ip link set veth-sw-r20 master br20
print_success "Connected veth-sw-r20 to br20"
echo ""

print_status "Bringing Up Switch Interfaces"
ip link set veth-sw10 up
ip link set veth-sw-r10 up
ip link set veth-sw20 up
ip link set veth-sw-r20 up
print_success "All switch-side interfaces are UP"
echo ""

print_status "Configuring PC10 (VLAN 10)"
ip netns exec pc10 ip addr add 192.168.10.10/24 dev veth-pc10
ip netns exec pc10 ip link set veth-pc10 up
ip netns exec pc10 ip link set lo up
ip netns exec pc10 ip route add default via 192.168.10.1
print_success "PC10: 192.168.10.10/24 (gateway: 192.168.10.1)"
echo ""

print_status "Configuring PC20 (VLAN 20)"
ip netns exec pc20 ip addr add 192.168.20.20/24 dev veth-pc20
ip netns exec pc20 ip link set veth-pc20 up
ip netns exec pc20 ip link set lo up
ip netns exec pc20 ip route add default via 192.168.20.1
print_success "PC20: 192.168.20.20/24 (gateway: 192.168.20.1)"
echo ""

print_status "Configuring Router"
# No VLAN sub-interfaces needed - direct interfaces per VLAN
echo "Configuring router interfaces..."
ip netns exec router ip addr add 192.168.10.1/24 dev veth-r10
ip netns exec router ip addr add 192.168.20.1/24 dev veth-r20
print_success "Router IPs: 192.168.10.1/24 (veth-r10), 192.168.20.1/24 (veth-r20)"

echo "Bringing up router interfaces..."
ip netns exec router ip link set veth-r10 up
ip netns exec router ip link set veth-r20 up
ip netns exec router ip link set lo up
print_success "All router interfaces UP"

echo "Enabling IP forwarding..."
ip netns exec router sysctl -w net.ipv4.ip_forward=1 > /dev/null
print_success "IP forwarding enabled"
echo ""

print_status "Setup Complete!"
echo ""

print_status "Bridge Configuration"
echo "Bridge 10 (VLAN 10):"
bridge link show br10
echo ""
echo "Bridge 20 (VLAN 20):"
bridge link show br20
echo ""

print_status "Router Interface Configuration"
ip netns exec router ip addr show | grep -E "veth-r|inet "
echo ""

print_status "Network Topology Summary"
echo "┌─────────────────────────────────────────────────────────────┐"
echo "│  PC10 (192.168.10.10) ── br10 ── Router (veth-r10)         │"
echo "│                                                             │"
echo "│  PC20 (192.168.20.20) ── br20 ── Router (veth-r20)         │"
echo "│                                    ↓                        │"
echo "│                              IP Forwarding                  │"
echo "└─────────────────────────────────────────────────────────────┘"
echo ""

print_status "Running Connectivity Tests"
echo ""

echo "Test 1: PC10 → Router (192.168.10.1)"
if ip netns exec pc10 ping -c 3 -W 2 192.168.10.1 > /dev/null 2>&1; then
    print_success "PC10 can reach router (192.168.10.1)"
else
    print_error "PC10 cannot reach router (192.168.10.1)"
fi
echo ""

echo "Test 2: PC20 → Router (192.168.20.1)"
if ip netns exec pc20 ping -c 3 -W 2 192.168.20.1 > /dev/null 2>&1; then
    print_success "PC20 can reach router (192.168.20.1)"
else
    print_error "PC20 cannot reach router (192.168.20.1)"
fi
echo ""

echo "Test 3: Inter-VLAN Routing (PC10 → PC20)"
if ip netns exec pc10 ping -c 3 -W 2 192.168.20.20 > /dev/null 2>&1; then
    print_success "PC10 can reach PC20 (192.168.20.20) via router"
else
    print_error "PC10 cannot reach PC20 (192.168.20.20)"
fi
echo ""

echo "Test 4: Inter-VLAN Routing (PC20 → PC10)"
if ip netns exec pc20 ping -c 3 -W 2 192.168.10.10 > /dev/null 2>&1; then
    print_success "PC20 can reach PC10 (192.168.10.10) via router"
else
    print_error "PC20 cannot reach PC10 (192.168.10.10)"
fi
echo ""

print_status "All Tests Complete!"
echo ""
echo "Useful commands:"
echo "  - List namespaces:        sudo ip netns list"
echo "  - Check bridge 10:        sudo bridge link show br10"
echo "  - Check bridge 20:        sudo bridge link show br20"
echo "  - Test PC10 → PC20:       sudo ip netns exec pc10 ping 192.168.20.20"
echo "  - Enter PC10 shell:       sudo ip netns exec pc10 bash"
echo "  - Capture on br10:        sudo tcpdump -i br10 -n"
echo "  - Capture on br20:        sudo tcpdump -i br20 -n"
echo "  - Run cleanup script:     sudo ./cleanup.sh"
echo ""
print_success "Separate bridges network setup completed successfully!"
