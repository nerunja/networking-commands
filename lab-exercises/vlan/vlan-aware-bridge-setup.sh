#!/bin/bash

#############################################
# VLAN-Aware Bridge Network Setup Script
# 
# Purpose: Creates isolated network namespaces with
#          proper VLAN tagging for inter-VLAN routing
#
# Author: Network Specialist
# Date: 2025-11-01
# Version: 1.0
#
# Topology:
#   PC10 (VLAN 10) ──┐
#                    ├── VLAN-aware Bridge ── Router (inter-VLAN routing)
#   PC20 (VLAN 20) ──┘
#
# Usage: sudo ./vlan-aware-bridge-setup.sh
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

print_status "Starting VLAN-Aware Bridge Network Setup"
echo ""

print_status "Cleaning Up Existing Setup"
ip netns delete pc10 2>/dev/null && print_warning "Removed existing pc10 namespace" || true
ip netns delete pc20 2>/dev/null && print_warning "Removed existing pc20 namespace" || true
ip netns delete router 2>/dev/null && print_warning "Removed existing router namespace" || true
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
# PC10 to Switch
ip link add veth-pc10 type veth peer name veth-sw10
print_success "Created veth pair: veth-pc10 <-> veth-sw10"

# PC20 to Switch
ip link add veth-pc20 type veth peer name veth-sw20
print_success "Created veth pair: veth-pc20 <-> veth-sw20"

# Switch to Router (Trunk)
ip link add veth-trunk type veth peer name veth-router
print_success "Created veth pair: veth-trunk <-> veth-router"
echo ""

print_status "Moving Interfaces to Namespaces"
ip link set veth-pc10 netns pc10
print_success "Moved veth-pc10 to pc10 namespace"
ip link set veth-pc20 netns pc20
print_success "Moved veth-pc20 to pc20 namespace"
ip link set veth-router netns router
print_success "Moved veth-router to router namespace"
echo ""

print_status "Creating VLAN-Aware Bridge"
# Create bridge with VLAN filtering enabled
ip link add br0 type bridge vlan_filtering 1
ip link set br0 up
print_success "Created bridge: br0 (VLAN filtering enabled)"
echo ""

print_status "Adding Ports to Bridge"
ip link set veth-sw10 master br0
print_success "Added veth-sw10 to br0"
ip link set veth-sw20 master br0
print_success "Added veth-sw20 to br0"
ip link set veth-trunk master br0
print_success "Added veth-trunk to br0"
echo ""

print_status "Bringing Up Switch-Side Interfaces"
ip link set veth-sw10 up
ip link set veth-sw20 up
ip link set veth-trunk up
print_success "All switch-side interfaces are UP"
echo ""

print_status "Configuring VLANs on Bridge Ports"
echo "Configuring veth-sw10 as ACCESS port for VLAN 10..."
bridge vlan del dev veth-sw10 vid 1  # Remove default VLAN 1
bridge vlan add dev veth-sw10 vid 10 pvid untagged
print_success "veth-sw10: ACCESS port VLAN 10 (pvid untagged)"

echo "Configuring veth-sw20 as ACCESS port for VLAN 20..."
bridge vlan del dev veth-sw20 vid 1
bridge vlan add dev veth-sw20 vid 20 pvid untagged
print_success "veth-sw20: ACCESS port VLAN 20 (pvid untagged)"

echo "Configuring veth-trunk as TRUNK port for VLANs 10 and 20..."
bridge vlan del dev veth-trunk vid 1
bridge vlan add dev veth-trunk vid 10  # Tagged
bridge vlan add dev veth-trunk vid 20  # Tagged
print_success "veth-trunk: TRUNK port VLANs 10,20 (tagged)"

echo "Configuring bridge itself..."
bridge vlan del dev br0 vid 1 self
bridge vlan add dev br0 vid 10 self
bridge vlan add dev br0 vid 20 self
print_success "Bridge br0: VLANs 10,20 configured"
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
# Bring up trunk interface first (parent interface)
ip netns exec router ip link set veth-router up
print_success "Router trunk interface UP"

# Create VLAN sub-interfaces on router
echo "Creating VLAN sub-interfaces..."
ip netns exec router ip link add link veth-router name veth-router.10 type vlan id 10
ip netns exec router ip link add link veth-router name veth-router.20 type vlan id 20
print_success "Created VLAN sub-interfaces: veth-router.10, veth-router.20"

# Assign IP addresses to VLAN sub-interfaces
echo "Assigning IP addresses..."
ip netns exec router ip addr add 192.168.10.1/24 dev veth-router.10
ip netns exec router ip addr add 192.168.20.1/24 dev veth-router.20
print_success "Router IPs: 192.168.10.1/24 (VLAN 10), 192.168.20.1/24 (VLAN 20)"

# Bring up all router interfaces
echo "Bringing up router interfaces..."
ip netns exec router ip link set veth-router.10 up
ip netns exec router ip link set veth-router.20 up
ip netns exec router ip link set lo up
print_success "All router interfaces UP"

# Enable IP forwarding for inter-VLAN routing
echo "Enabling IP forwarding..."
ip netns exec router sysctl -w net.ipv4.ip_forward=1 > /dev/null
print_success "IP forwarding enabled"
echo ""

print_status "Setup Complete!"
echo ""

print_status "VLAN Configuration on Bridge"
bridge vlan show
echo ""

print_status "Router Interface Configuration"
ip netns exec router ip addr show | grep -E "veth-router|inet "
echo ""

print_status "Network Topology Summary"
echo "┌─────────────────────────────────────────────────────────────┐"
echo "│  PC10 (192.168.10.10) ─┐                                   │"
echo "│         VLAN 10         ├─→ VLAN-aware Bridge ─→ Router    │"
echo "│  PC20 (192.168.20.20) ─┘      (br0)           (forwards)   │"
echo "└─────────────────────────────────────────────────────────────┘"
echo ""

print_status "Running Connectivity Tests"
echo ""

echo "Test 1: PC10 → Router Gateway (VLAN 10)"
if ip netns exec pc10 ping -c 3 -W 2 192.168.10.1 > /dev/null 2>&1; then
    print_success "PC10 can reach router (192.168.10.1)"
else
    print_error "PC10 cannot reach router (192.168.10.1)"
fi
echo ""

echo "Test 2: PC20 → Router Gateway (VLAN 20)"
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
echo "  - Check VLAN config:      sudo bridge vlan show"
echo "  - Test PC10 → PC20:       sudo ip netns exec pc10 ping 192.168.20.20"
echo "  - Enter PC10 shell:       sudo ip netns exec pc10 bash"
echo "  - Capture traffic:        sudo tcpdump -i br0 -n -e"
echo "  - Run cleanup script:     sudo ./cleanup.sh"
echo ""
print_success "VLAN-aware bridge network setup completed successfully!"
