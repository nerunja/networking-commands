# VLAN Tagged/Trunk Ports vs Untagged/Access Ports - Comprehensive Guide

**Author:** Networking Specialist  
**Target OS:** Ubuntu Linux (primarily), with notes for Windows and macOS  
**Last Updated:** October 2025

---

## Table of Contents

1. [Core Concepts](#1-core-concepts)
2. [Visual Representation](#2-visual-representation)
3. [Practical Ubuntu Lab Setup](#3-practical-ubuntu-lab-setup)
4. [Scenario 1: Simple VLAN Configuration](#4-scenario-1-simple-vlan-configuration-single-host)
5. [Scenario 2: Linux Bridge with VLANs](#5-scenario-2-linux-bridge-with-vlans)
6. [Scenario 3: Complete Multi-VLAN Lab](#6-scenario-3-complete-multi-vlan-lab-setup)
7. [Testing and Verification](#7-testing-and-verification)
8. [Advanced Testing: VLAN Isolation](#8-advanced-testing-vlan-isolation)
9. [Real-World VLAN Use Cases](#9-real-world-vlan-use-cases)
10. [Troubleshooting Commands](#10-troubleshooting-commands)
11. [Common Issues and Solutions](#11-common-issues-and-solutions)
12. [Making Configuration Persistent](#12-making-configuration-persistent)
13. [Summary: Key Differences](#13-summary-key-differences)
14. [Quick Reference Commands](#14-quick-reference-commands)

---

## 1. Core Concepts

### VLAN (Virtual Local Area Network)

A VLAN logically segments a physical network into multiple isolated broadcast domains. Devices in different VLANs cannot communicate directly without a router, even if they're on the same physical switch.

### Tagged/Trunk Ports

- **Purpose**: Carries traffic for **multiple VLANs** simultaneously
- **Frame Format**: Adds an 802.1Q tag (4 bytes) to Ethernet frames identifying the VLAN
- **Common Use**: Switch-to-switch connections, switch-to-router connections
- **Tag Structure**: Contains VLAN ID (12 bits = 4096 possible VLANs)

### Untagged/Access Ports

- **Purpose**: Carries traffic for **one VLAN only**
- **Frame Format**: Standard Ethernet frames (no VLAN tag)
- **Common Use**: End-user device connections (PCs, printers, phones)
- **Behavior**: Automatically assigns traffic to a specific VLAN

---

## 2. Visual Representation

```
┌─────────────────────────────────────────────────────────────┐
│                    VLAN TOPOLOGY EXAMPLE                     │
└─────────────────────────────────────────────────────────────┘

VLAN 10 (Sales)          VLAN 20 (IT)           VLAN 30 (HR)
    
PC1 (10.0.10.10)      PC3 (10.0.20.10)      PC5 (10.0.30.10)
       │                     │                     │
       │ Access              │ Access              │ Access
       │ (Untagged)          │ (Untagged)          │ (Untagged)
       │ VLAN 10             │ VLAN 20             │ VLAN 30
       │                     │                     │
    ┌──┴─────────────────────┴─────────────────────┴──┐
    │            Switch 1 (Ubuntu Bridge)             │
    │  Port 1-8: Access Ports                         │
    │  Port 9: Trunk Port (All VLANs)                 │
    └──────────────────────┬──────────────────────────┘
                           │ Trunk
                           │ (Tagged: VLAN 10,20,30)
                           │
    ┌──────────────────────┴──────────────────────────┐
    │            Switch 2 (Ubuntu Bridge)             │
    │  Port 1-8: Access Ports                         │
    │  Port 9: Trunk Port (All VLANs)                 │
    └──┬─────────────────────┬─────────────────────┬──┘
       │ Access              │ Access              │ Access
       │ VLAN 10             │ VLAN 20             │ VLAN 30
       │                     │                     │
PC2 (10.0.10.20)      PC4 (10.0.20.20)      PC6 (10.0.30.20)
```

---

## 3. Practical Ubuntu Lab Setup

### Lab Prerequisites

```bash
# Install required packages
sudo apt update
sudo apt install -y \
    bridge-utils \
    vlan \
    net-tools \
    iproute2 \
    tcpdump \
    ethtool

# Load 8021q kernel module (for VLAN support)
sudo modprobe 8021q

# Make it persistent across reboots
echo "8021q" | sudo tee -a /etc/modules

# Verify module is loaded
lsmod | grep 8021q
```

---

## 4. Scenario 1: Simple VLAN Configuration (Single Host)

### Creating VLAN Interfaces

```bash
# Assume eth0 is your physical interface

# Create VLAN 10 interface (Sales)
sudo ip link add link eth0 name eth0.10 type vlan id 10
sudo ip addr add 10.0.10.1/24 dev eth0.10
sudo ip link set eth0.10 up

# Create VLAN 20 interface (IT)
sudo ip link add link eth0 name eth0.20 type vlan id 20
sudo ip addr add 10.0.20.1/24 dev eth0.20
sudo ip link set eth0.20 up

# Create VLAN 30 interface (HR)
sudo ip link add link eth0 name eth0.30 type vlan id 30
sudo ip addr add 10.0.30.1/24 dev eth0.30
sudo ip link set eth0.30 up

# Verify VLANs
ip -d link show type vlan
ip addr show
```

### Understanding the Output

```bash
# When you see this:
# eth0.10@eth0: <BROADCAST,MULTICAST,UP,LOWER_UP>
# The ".10" indicates VLAN ID 10
# The "@eth0" shows it's based on physical interface eth0
# This is a TAGGED interface
```

---

## 5. Scenario 2: Linux Bridge with VLANs

### Creating a Software Switch with VLAN Support

```bash
# Create a bridge (acts as a virtual switch)
sudo ip link add br0 type bridge
sudo ip link set br0 up

# Enable VLAN filtering on the bridge
sudo ip link set br0 type bridge vlan_filtering 1

# Add physical interfaces to bridge
sudo ip link set eth1 master br0
sudo ip link set eth2 master br0
sudo ip link set eth3 master br0

# Configure eth1 as ACCESS port for VLAN 10
sudo bridge vlan del dev eth1 vid 1  # Remove default VLAN
sudo bridge vlan add dev eth1 vid 10 pvid untagged

# Configure eth2 as ACCESS port for VLAN 20
sudo bridge vlan del dev eth2 vid 1
sudo bridge vlan add dev eth2 vid 20 pvid untagged

# Configure eth3 as TRUNK port (carries VLAN 10, 20, 30)
sudo bridge vlan del dev eth3 vid 1
sudo bridge vlan add dev eth3 vid 10
sudo bridge vlan add dev eth3 vid 20
sudo bridge vlan add dev eth3 vid 30

# View VLAN configuration
bridge vlan show
```

**Expected Output:**

```
port    vlan ids
eth1    10 PVID Egress Untagged
eth2    20 PVID Egress Untagged
eth3    10
        20
        30
br0     1 PVID Egress Untagged
```

**Explanation:**

- **PVID** (Port VLAN ID): Default VLAN for untagged traffic
- **Egress Untagged**: Removes VLAN tag when forwarding
- eth1 and eth2 are ACCESS ports (single VLAN, untagged)
- eth3 is a TRUNK port (multiple VLANs, tagged)

---

## 6. Scenario 3: Complete Multi-VLAN Lab Setup

### Network Topology

```
┌──────────────┐         ┌──────────────┐
│   PC-VLAN10  │         │   PC-VLAN20  │
│ 10.0.10.10   │         │ 10.0.20.10   │
└──────┬───────┘         └──────┬───────┘
       │ eth1 (Access)          │ eth2 (Access)
       │ VLAN 10                │ VLAN 20
       │                        │
    ┌──┴────────────────────────┴────┐
    │   Ubuntu Bridge (br-vlans)     │
    │   Acting as Layer 2 Switch     │
    └──────────────┬─────────────────┘
                   │ eth3 (Trunk)
                   │ VLANs: 10, 20
                   │
            ┌──────┴───────┐
            │   Router/    │
            │   Firewall   │
            └──────────────┘
```

### Step-by-Step Configuration

```bash
#!/bin/bash
# Complete VLAN Lab Setup Script

# 1. Create namespace for isolated testing (optional but recommended)
sudo ip netns add vlan-lab

# 2. Create virtual ethernet pairs (simulating cables)
sudo ip link add veth-pc10 type veth peer name veth-sw10
sudo ip link add veth-pc20 type veth peer name veth-sw20
sudo ip link add veth-trunk type veth peer name veth-router

# 3. Create bridge (software switch)
sudo ip link add br-vlans type bridge
sudo ip link set br-vlans type bridge vlan_filtering 1

# 4. Attach switch-side interfaces to bridge
sudo ip link set veth-sw10 master br-vlans
sudo ip link set veth-sw20 master br-vlans
sudo ip link set veth-trunk master br-vlans

# 5. Configure veth-sw10 as ACCESS port for VLAN 10
sudo bridge vlan del dev veth-sw10 vid 1
sudo bridge vlan add dev veth-sw10 vid 10 pvid untagged

# 6. Configure veth-sw20 as ACCESS port for VLAN 20
sudo bridge vlan del dev veth-sw20 vid 1
sudo bridge vlan add dev veth-sw20 vid 20 pvid untagged

# 7. Configure veth-trunk as TRUNK port
sudo bridge vlan del dev veth-trunk vid 1
sudo bridge vlan add dev veth-trunk vid 10
sudo bridge vlan add dev veth-trunk vid 20

# 8. Bring everything up
sudo ip link set veth-pc10 up
sudo ip link set veth-sw10 up
sudo ip link set veth-pc20 up
sudo ip link set veth-sw20 up
sudo ip link set veth-trunk up
sudo ip link set veth-router up
sudo ip link set br-vlans up

# 9. Configure "PC" interfaces with IP addresses
sudo ip addr add 10.0.10.10/24 dev veth-pc10
sudo ip addr add 10.0.20.10/24 dev veth-pc20

# 10. Configure router side with VLAN subinterfaces
sudo ip link add link veth-router name veth-router.10 type vlan id 10
sudo ip link add link veth-router name veth-router.20 type vlan id 20
sudo ip addr add 10.0.10.1/24 dev veth-router.10
sudo ip addr add 10.0.20.1/24 dev veth-router.20
sudo ip link set veth-router.10 up
sudo ip link set veth-router.20 up

# Enable IP forwarding (router functionality)
sudo sysctl -w net.ipv4.ip_forward=1

echo "VLAN Lab Setup Complete!"
echo "View configuration with: bridge vlan show"
```

---

## 7. Testing and Verification

### Verify VLAN Configuration

```bash
# Show bridge VLAN table
bridge vlan show

# Show detailed link information
ip -d link show

# Show all VLAN interfaces
ip link show type vlan

# Show bridge forwarding database
bridge fdb show br br-vlans
```

### Traffic Testing

```bash
# Terminal 1: Capture on VLAN 10 interface
sudo tcpdump -i veth-pc10 -e -n

# Terminal 2: Capture on trunk port (see VLAN tags)
sudo tcpdump -i veth-trunk -e -n vlan

# Terminal 3: Generate traffic from VLAN 10
ping -c 4 10.0.10.1

# Terminal 4: Generate traffic from VLAN 20
ping -c 4 10.0.20.1
```

### Analyzing VLAN Tags

When you capture on the trunk port, you'll see:

```
# Tagged frame (on trunk)
12:34:56:78:9a:bc > aa:bb:cc:dd:ee:ff, ethertype 802.1Q (0x8100), length 102: 
vlan 10, p 0, ethertype IPv4, 10.0.10.10 > 10.0.10.1: ICMP echo request

# Key parts:
# - ethertype 802.1Q: Indicates VLAN tagging
# - vlan 10: VLAN ID in the tag
```

On access ports, you won't see the VLAN tag:

```
# Untagged frame (on access port)
12:34:56:78:9a:bc > aa:bb:cc:dd:ee:ff, ethertype IPv4 (0x0800), length 98: 
10.0.10.10 > 10.0.10.1: ICMP echo request

# No "vlan X" - the tag was removed by the bridge
```

---

## 8. Advanced Testing: VLAN Isolation

### Test Script

```bash
#!/bin/bash
# Test VLAN isolation

echo "=== Testing VLAN Isolation ==="

# Test 1: Same VLAN communication (should work)
echo "Test 1: Ping within VLAN 10"
ping -c 2 -I veth-pc10 10.0.10.1
if [ $? -eq 0 ]; then
    echo "✓ VLAN 10 communication: SUCCESS"
else
    echo "✗ VLAN 10 communication: FAILED"
fi

# Test 2: Different VLAN communication without routing (should fail)
echo "Test 2: Ping from VLAN 10 to VLAN 20 (should fail without router)"
ping -c 2 -I veth-pc10 10.0.20.10
if [ $? -ne 0 ]; then
    echo "✓ VLAN isolation: WORKING (as expected)"
else
    echo "✗ VLAN isolation: BROKEN (security issue!)"
fi

# Test 3: With routing enabled (should work)
echo "Test 3: Ping across VLANs through router"
sudo ip route add 10.0.20.0/24 via 10.0.10.1 dev veth-pc10
ping -c 2 10.0.20.10
if [ $? -eq 0 ]; then
    echo "✓ Inter-VLAN routing: SUCCESS"
else
    echo "✗ Inter-VLAN routing: FAILED"
fi
```

---

## 9. Real-World VLAN Use Cases

### Example 1: Corporate Network Segmentation

```bash
# Create VLANs for different departments
sudo ip link add link eth0 name eth0.10 type vlan id 10  # Management
sudo ip link add link eth0 name eth0.20 type vlan id 20  # Employees
sudo ip link add link eth0 name eth0.30 type vlan id 30  # Guest WiFi
sudo ip link add link eth0 name eth0.99 type vlan id 99  # Servers

# Assign IPs
sudo ip addr add 192.168.10.1/24 dev eth0.10
sudo ip addr add 192.168.20.1/24 dev eth0.20
sudo ip addr add 192.168.30.1/24 dev eth0.30
sudo ip addr add 192.168.99.1/24 dev eth0.99

# Bring up interfaces
for vlan in 10 20 30 99; do
    sudo ip link set eth0.$vlan up
done
```

### Example 2: VoIP and Data Separation

```bash
# VLAN 100: Data traffic
# VLAN 200: Voice traffic (VoIP phones)

# Create VLANs
sudo ip link add link eth0 name eth0.100 type vlan id 100
sudo ip link add link eth0 name eth0.200 type vlan id 200

# Configure with different QoS priorities
sudo ip link set eth0.100 up
sudo ip link set eth0.200 up

# Set higher priority for voice VLAN (if supported)
sudo tc qdisc add dev eth0.200 root prio
```

### Example 3: Multi-Tenant Network

```bash
# Create isolated VLANs for different tenants/customers
sudo ip link add link eth0 name eth0.101 type vlan id 101  # Tenant A
sudo ip link add link eth0 name eth0.102 type vlan id 102  # Tenant B
sudo ip link add link eth0 name eth0.103 type vlan id 103  # Tenant C

# Assign different subnets
sudo ip addr add 10.101.0.1/24 dev eth0.101
sudo ip addr add 10.102.0.1/24 dev eth0.102
sudo ip addr add 10.103.0.1/24 dev eth0.103

# Bring up interfaces
for vlan in 101 102 103; do
    sudo ip link set eth0.$vlan up
done
```

---

## 10. Troubleshooting Commands

```bash
# Check if 8021q module is loaded
lsmod | grep 8021q

# Verify VLAN interface exists
ip link show type vlan

# Check VLAN configuration on bridge
bridge vlan show

# Capture and analyze VLAN tagged traffic
sudo tcpdump -i eth0 -e -n vlan

# Check for VLAN tag stripping issues
ethtool -k eth0 | grep vlan

# View kernel VLAN configuration
cat /proc/net/vlan/config

# Check bridge settings
bridge -d link show

# Verify MAC learning on bridge
bridge fdb show dev br0

# Test connectivity
ping -c 4 <target_ip>
arping -I eth0.10 <target_ip>

# Check routing table
ip route show

# Verify ARP table
ip neigh show

# Check firewall rules (might block traffic)
sudo iptables -L -v -n
sudo nft list ruleset

# Monitor real-time traffic
sudo iftop -i eth0.10

# Check interface statistics
ip -s link show eth0.10

# Verify packet counters
cat /proc/net/dev

# Check for errors
dmesg | grep -i eth0
journalctl -xe | grep -i network
```

---

## 11. Common Issues and Solutions

### Issue 1: No VLAN tag seen on trunk

**Symptoms:** Traffic not passing between switches, no VLAN tags visible in tcpdump

**Solutions:**

```bash
# Verify VLAN filtering is enabled
sudo ip link set br0 type bridge vlan_filtering 1

# Verify trunk port doesn't have 'untagged' flag
bridge vlan show

# Ensure physical interface doesn't strip tags
ethtool -K eth0 rxvlan off txvlan off
```

### Issue 2: Can't communicate across VLANs

**Symptoms:** Devices in different VLANs cannot ping each other

**Solutions:**

```bash
# This is EXPECTED behavior - VLANs isolate traffic
# Solution: Enable routing between VLANs
sudo sysctl -w net.ipv4.ip_forward=1

# Make it persistent
echo "net.ipv4.ip_forward = 1" | sudo tee -a /etc/sysctl.conf

# Add routes
sudo ip route add 10.0.20.0/24 via 10.0.10.1

# Or configure a router interface with VLAN subinterfaces
```

### Issue 3: VLAN interface won't come up

**Symptoms:** Interface shows "DOWN" in `ip link show`

**Solutions:**

```bash
# Check physical interface is up
sudo ip link set eth0 up

# Then bring up VLAN interface
sudo ip link set eth0.10 up

# Check for errors
dmesg | tail -20

# Verify 8021q module is loaded
lsmod | grep 8021q

# Check for conflicting configurations
ip addr show eth0
```

### Issue 4: Duplicate IP addresses

**Symptoms:** Intermittent connectivity, ARP conflicts

**Solutions:**

```bash
# Check for duplicate IPs
sudo arping -I eth0.10 -c 3 10.0.10.1

# View ARP table
ip neigh show

# Clear ARP cache
sudo ip neigh flush dev eth0.10

# Use unique IP ranges for each VLAN
```

### Issue 5: Bridge not forwarding traffic

**Symptoms:** Devices on same VLAN but different ports can't communicate

**Solutions:**

```bash
# Verify bridge is up
ip link show br0

# Check VLAN membership
bridge vlan show

# Enable forwarding on bridge
sudo sysctl -w net.bridge.bridge-nf-call-iptables=0

# Check if STP is blocking
bridge link show

# Disable STP if not needed
sudo ip link set br0 type bridge stp_state 0
```

### Issue 6: Performance issues with VLANs

**Symptoms:** High latency, packet loss, slow throughput

**Solutions:**

```bash
# Check interface MTU
ip link show eth0

# Adjust MTU if needed (account for VLAN overhead)
sudo ip link set eth0 mtu 1504

# Check for errors/drops
ethtool -S eth0 | grep -i error
ethtool -S eth0 | grep -i drop

# Optimize ring buffers
sudo ethtool -G eth0 rx 4096 tx 4096

# Check CPU usage
top -p $(pgrep -d',' -f bridge)
```

---

## 12. Making Configuration Persistent

### Using Netplan (Ubuntu 18.04+)

```yaml
# /etc/netplan/01-vlans.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: no
  
  vlans:
    vlan10:
      id: 10
      link: eth0
      addresses:
        - 10.0.10.1/24
    
    vlan20:
      id: 20
      link: eth0
      addresses:
        - 10.0.20.1/24
    
    vlan30:
      id: 30
      link: eth0
      addresses:
        - 10.0.30.1/24

  bridges:
    br0:
      interfaces: [eth1, eth2, eth3]
      parameters:
        stp: false
        forward-delay: 0
```

Apply configuration:

```bash
# Test configuration
sudo netplan try

# Apply permanently
sudo netplan apply

# Debug configuration
sudo netplan --debug apply
```

### Using /etc/network/interfaces (older Ubuntu/Debian)

```bash
# /etc/network/interfaces
auto eth0
iface eth0 inet manual

auto eth0.10
iface eth0.10 inet static
    address 10.0.10.1
    netmask 255.255.255.0
    vlan-raw-device eth0

auto eth0.20
iface eth0.20 inet static
    address 10.0.20.1
    netmask 255.255.255.0
    vlan-raw-device eth0

auto eth0.30
iface eth0.30 inet static
    address 10.0.30.1
    netmask 255.255.255.0
    vlan-raw-device eth0

# Bridge with VLANs
auto br0
iface br0 inet static
    address 192.168.1.1
    netmask 255.255.255.0
    bridge_ports eth1 eth2 eth3
    bridge_stp off
    bridge_fd 0
    bridge_vlan_aware yes
```

Apply configuration:

```bash
# Restart networking
sudo systemctl restart networking

# Or bring up specific interface
sudo ifup eth0.10
```

### Using systemd-networkd

```ini
# /etc/systemd/network/10-eth0.network
[Match]
Name=eth0

[Network]
VLAN=vlan10
VLAN=vlan20
VLAN=vlan30

# /etc/systemd/network/20-vlan10.netdev
[NetDev]
Name=vlan10
Kind=vlan

[VLAN]
Id=10

# /etc/systemd/network/20-vlan10.network
[Match]
Name=vlan10

[Network]
Address=10.0.10.1/24

# Repeat for vlan20 and vlan30
```

Enable and start:

```bash
sudo systemctl enable systemd-networkd
sudo systemctl restart systemd-networkd
```

---

## 13. Summary: Key Differences

| Feature | Access Port (Untagged) | Trunk Port (Tagged) |
|---------|------------------------|---------------------|
| **VLANs Carried** | Single VLAN | Multiple VLANs |
| **Frame Format** | Standard Ethernet | 802.1Q tagged |
| **Frame Size** | 1518 bytes (max) | 1522 bytes (max, +4 for tag) |
| **Tag Handling** | Adds tag on ingress, removes on egress | Preserves tags |
| **Typical Use** | End devices (PCs, phones, printers) | Switch-to-switch, switch-to-router |
| **Configuration** | `pvid untagged` | Multiple VLAN IDs without untagged |
| **Security** | Simpler - device can't change VLAN | More complex - must trust connected device |
| **Network Design** | Edge ports | Core/distribution ports |
| **Default VLAN** | Has PVID (Port VLAN ID) | May have native VLAN for untagged traffic |
| **Complexity** | Low | Medium to High |
| **Use Case** | Client connections | Inter-switch links, uplinks |

### 802.1Q Frame Structure

```
┌────────────┬────────────┬────────┬─────┬────────┬─────┬─────┐
│ Dest MAC   │ Source MAC │  TPID  │ TCI │  Type  │Data │ FCS │
│  (6 bytes) │  (6 bytes) │(2 byte)│(2 b)│(2 byte)│     │(4 b)│
└────────────┴────────────┴────────┴─────┴────────┴─────┴─────┘
                           └──────────┬──────────┘
                               802.1Q Tag (4 bytes)
                               
TPID: Tag Protocol Identifier (0x8100)
TCI: Tag Control Information
  ├── Priority (3 bits) - QoS
  ├── DEI (1 bit) - Drop Eligible Indicator
  └── VLAN ID (12 bits) - 0-4095
```

---

## 14. Quick Reference Commands

### VLAN Interface Management

```bash
# Create VLAN interface
sudo ip link add link eth0 name eth0.10 type vlan id 10

# Delete VLAN interface
sudo ip link del eth0.10

# Show all VLAN interfaces
ip link show type vlan

# Show detailed VLAN info
ip -d link show eth0.10

# Bring up/down VLAN interface
sudo ip link set eth0.10 up
sudo ip link set eth0.10 down

# Assign IP address
sudo ip addr add 10.0.10.1/24 dev eth0.10

# Change VLAN priority
sudo ip link set eth0.10 type vlan egress-qos-map 0:1 1:2
```

### Bridge VLAN Management

```bash
# Create bridge
sudo ip link add br0 type bridge

# Enable VLAN filtering
sudo ip link set br0 type bridge vlan_filtering 1

# Add interface to bridge
sudo ip link set eth1 master br0

# Configure as access port
sudo bridge vlan add dev eth1 vid 10 pvid untagged

# Configure as trunk port
sudo bridge vlan add dev eth1 vid 10
sudo bridge vlan add dev eth1 vid 20
sudo bridge vlan add dev eth1 vid 30

# Remove VLAN from port
sudo bridge vlan del dev eth1 vid 10

# Show VLAN configuration
bridge vlan show

# Show detailed VLAN info
bridge -d vlan show
```

### Traffic Capture and Analysis

```bash
# Capture VLAN tagged traffic
sudo tcpdump -i eth0 -e vlan

# Capture specific VLAN
sudo tcpdump -i eth0 -e vlan 10

# Capture to file
sudo tcpdump -i eth0 -e vlan -w capture.pcap

# Verbose capture with ASCII
sudo tcpdump -i eth0 -e -vv -A vlan

# Capture only VLAN tags
sudo tcpdump -i eth0 '(vlan)'

# Monitor specific VLAN traffic
sudo tcpdump -i eth0.10 -e -n
```

### Diagnostic Commands

```bash
# Show VLAN kernel config
cat /proc/net/vlan/config
cat /proc/net/vlan/eth0.10

# Check 8021q module
lsmod | grep 8021q
modinfo 8021q

# Verify VLAN support
ethtool -k eth0 | grep vlan

# Check bridge configuration
bridge link show
bridge fdb show

# Show routing table
ip route show table all

# Test connectivity
ping -I eth0.10 10.0.10.1
arping -I eth0.10 10.0.10.1

# Check statistics
ip -s link show eth0.10
ethtool -S eth0 | grep vlan
```

### System Configuration

```bash
# Load 8021q module
sudo modprobe 8021q

# Make persistent
echo "8021q" | sudo tee -a /etc/modules

# Enable IP forwarding
sudo sysctl -w net.ipv4.ip_forward=1

# Make persistent
echo "net.ipv4.ip_forward = 1" | sudo tee -a /etc/sysctl.conf

# Disable reverse path filtering (if needed)
sudo sysctl -w net.ipv4.conf.all.rp_filter=0
sudo sysctl -w net.ipv4.conf.eth0.rp_filter=0

# Check all network sysctls
sysctl -a | grep net.ipv4
```

---

## 15. Advanced Topics

### Native VLAN

The native VLAN is used for untagged traffic on a trunk port. By default, this is VLAN 1.

```bash
# On a trunk port, set native VLAN to 99
sudo bridge vlan add dev eth3 vid 99 pvid untagged

# This means:
# - Untagged traffic received will be assigned to VLAN 99
# - Traffic for VLAN 99 will be sent untagged
# - All other VLANs will be tagged
```

### VLAN Hopping Attack Prevention

```bash
# 1. Disable unused ports
sudo ip link set eth4 down

# 2. Don't use VLAN 1 (default)
# Change native VLAN on trunks
sudo bridge vlan add dev eth3 vid 999 pvid untagged

# 3. Explicitly configure all ports
# Don't leave ports in default state

# 4. Use private VLANs (if supported)
# Isolate hosts within the same VLAN
```

### Inter-VLAN Routing (Router on a Stick)

```bash
# Configure router interface with subinterfaces
sudo ip link add link eth0 name eth0.10 type vlan id 10
sudo ip link add link eth0 name eth0.20 type vlan id 20
sudo ip link add link eth0 name eth0.30 type vlan id 30

# Assign gateway IPs
sudo ip addr add 10.0.10.1/24 dev eth0.10
sudo ip addr add 10.0.20.1/24 dev eth0.20
sudo ip addr add 10.0.30.1/24 dev eth0.30

# Bring up interfaces
sudo ip link set eth0 up
sudo ip link set eth0.10 up
sudo ip link set eth0.20 up
sudo ip link set eth0.30 up

# Enable forwarding
sudo sysctl -w net.ipv4.ip_forward=1

# Add firewall rules (optional)
sudo iptables -A FORWARD -i eth0.10 -o eth0.20 -j ACCEPT
sudo iptables -A FORWARD -i eth0.20 -o eth0.10 -j ACCEPT
```

### QoS with VLANs

```bash
# Set VLAN priority (CoS - Class of Service)
# Priority levels: 0-7 (7 is highest)

# Create VLAN with priority mapping
sudo ip link add link eth0 name eth0.200 type vlan id 200

# Set egress priority mapping (socket priority -> VLAN priority)
sudo ip link set eth0.200 type vlan egress-qos-map 0:1 1:2 2:3 3:4 4:5 5:6 6:7 7:7

# Set ingress priority mapping (VLAN priority -> socket priority)
sudo ip link set eth0.200 type vlan ingress-qos-map 0:0 1:1 2:2 3:3 4:4 5:5 6:6 7:7

# Apply traffic control
sudo tc qdisc add dev eth0.200 root prio
```

### VLAN Pruning

Limit which VLANs traverse a trunk to reduce broadcast traffic:

```bash
# Only allow VLANs 10 and 20 on trunk
sudo bridge vlan del dev eth3 vid 1-4094  # Remove all
sudo bridge vlan add dev eth3 vid 10
sudo bridge vlan add dev eth3 vid 20

# Verify
bridge vlan show dev eth3
```

---

## 16. Security Best Practices

### 1. VLAN Segmentation

```bash
# Separate sensitive networks
# - VLAN 10: Management (switches, routers)
# - VLAN 20: Servers (production)
# - VLAN 30: Workstations
# - VLAN 40: Guest/IoT devices
# - VLAN 50: DMZ (public-facing)
```

### 2. Private VLANs (PVLAN)

While not natively supported in Linux bridge, you can achieve similar isolation:

```bash
# Use ebtables to block inter-host communication
sudo ebtables -A FORWARD -i eth1 -o eth2 -j DROP
sudo ebtables -A FORWARD -i eth2 -o eth1 -j DROP

# Allow only to gateway/router
sudo ebtables -A FORWARD -i eth1 -o eth3 -j ACCEPT
```

### 3. ACLs Between VLANs

```bash
# Use iptables/nftables for inter-VLAN filtering

# Allow VLAN 30 (workstations) to access VLAN 20 (servers) on port 443 only
sudo iptables -A FORWARD -i eth0.30 -o eth0.20 -p tcp --dport 443 -j ACCEPT
sudo iptables -A FORWARD -i eth0.30 -o eth0.20 -j DROP

# Allow return traffic
sudo iptables -A FORWARD -i eth0.20 -o eth0.30 -m state --state ESTABLISHED,RELATED -j ACCEPT
```

### 4. Port Security

```bash
# Limit MAC addresses per port (not native to Linux bridge, use ebtables)
sudo ebtables -A INPUT -i eth1 -s ! 00:11:22:33:44:55 -j DROP

# Or use arp filtering
echo 1 | sudo tee /proc/sys/net/ipv4/conf/eth1/arp_filter
```

### 5. DHCP Snooping Equivalent

```bash
# Use iptables to limit DHCP responses to trusted ports
sudo iptables -A FORWARD -i eth1 -p udp --sport 67 --dport 68 -j DROP
sudo iptables -A FORWARD -i eth3 -p udp --sport 67 --dport 68 -j ACCEPT
```

---

## 17. Monitoring and Logging

### Real-time VLAN Monitoring

```bash
# Watch VLAN interface statistics
watch -n 1 'ip -s link show type vlan'

# Monitor bridge forwarding database
watch -n 2 'bridge fdb show br br0'

# Live traffic monitoring
sudo iftop -i eth0.10

# Monitor with bmon
sudo bmon

# Detailed packet analysis
sudo tshark -i eth0 -Y vlan

# Monitor VLAN-specific traffic
sudo tcpdump -i eth0 -n vlan 10 and icmp
```

### Logging VLAN Events

```bash
# Enable kernel logging for bridge
echo 1 | sudo tee /sys/class/net/br0/bridge/multicast_querier

# Monitor syslog for network events
sudo tail -f /var/log/syslog | grep -i 'eth0\|vlan\|bridge'

# Use journalctl for systemd
sudo journalctl -u systemd-networkd -f

# Log VLAN changes
sudo auditctl -w /proc/net/vlan/config -p wa -k vlan_changes
```

---

## 18. Performance Tuning

### Optimize VLAN Performance

```bash
# Increase ring buffer sizes
sudo ethtool -G eth0 rx 4096 tx 4096

# Enable hardware VLAN offloading (if supported)
sudo ethtool -K eth0 rxvlan on txvlan on

# Disable if causing issues
sudo ethtool -K eth0 rxvlan off txvlan off

# Check offload settings
ethtool -k eth0 | grep vlan

# Increase MTU for jumbo frames
sudo ip link set eth0 mtu 9000
sudo ip link set eth0.10 mtu 9000

# Tune kernel parameters
sudo sysctl -w net.core.netdev_max_backlog=5000
sudo sysctl -w net.core.rmem_max=134217728
sudo sysctl -w net.core.wmem_max=134217728

# Disable GRO on VLAN interfaces if causing issues
sudo ethtool -K eth0.10 gro off
```

---

## 19. Automation Scripts

### Complete VLAN Setup Script

```bash
#!/bin/bash
# vlan-setup.sh - Automated VLAN configuration

set -e

# Configuration
PHYSICAL_IF="eth0"
VLANS=(10 20 30)
VLAN_IPS=("10.0.10.1/24" "10.0.20.1/24" "10.0.30.1/24")

# Load module
sudo modprobe 8021q

# Create VLAN interfaces
for i in "${!VLANS[@]}"; do
    VLAN="${VLANS[$i]}"
    IP="${VLAN_IPS[$i]}"
    
    echo "Creating VLAN $VLAN..."
    sudo ip link add link "$PHYSICAL_IF" name "${PHYSICAL_IF}.${VLAN}" type vlan id "$VLAN"
    sudo ip addr add "$IP" dev "${PHYSICAL_IF}.${VLAN}"
    sudo ip link set "${PHYSICAL_IF}.${VLAN}" up
done

# Enable forwarding
sudo sysctl -w net.ipv4.ip_forward=1

echo "VLAN setup complete!"
ip link show type vlan
```

### VLAN Cleanup Script

```bash
#!/bin/bash
# vlan-cleanup.sh - Remove all VLAN interfaces

set -e

echo "Removing all VLAN interfaces..."

# Get all VLAN interfaces
VLAN_IFS=$(ip -o link show type vlan | awk -F': ' '{print $2}')

for vlan_if in $VLAN_IFS; do
    echo "Removing $vlan_if..."
    sudo ip link del "$vlan_if"
done

echo "Cleanup complete!"
```

---

## 20. Additional Resources

### Official Documentation

- **Linux VLAN Documentation**: https://www.kernel.org/doc/Documentation/networking/vlan.txt
- **iproute2 Documentation**: https://wiki.linuxfoundation.org/networking/iproute2
- **Bridge Documentation**: https://www.kernel.org/doc/Documentation/networking/bridge.txt

### RFCs

- **RFC 7042**: IANA Considerations and IETF Protocol and Documentation Usage
- **IEEE 802.1Q**: Standard for Local and Metropolitan Area Networks—Virtual Bridged Local Area Networks

### Tools

- **Wireshark**: Network protocol analyzer
- **tcpdump**: Command-line packet analyzer
- **bridge-utils**: Utilities for configuring Linux Ethernet bridges
- **vlan**: VLAN configuration tools

### Testing Tools

```bash
# Install testing tools
sudo apt install -y \
    iperf3 \
    netperf \
    mtr \
    nmap \
    hping3
```

---

## 21. Exam Scenarios and Practice Questions

### Scenario 1: Design a Multi-Department Network

**Requirements:**
- 4 departments: Sales, IT, HR, Management
- Each department in separate VLAN
- Only IT can access all VLANs
- Management can access Sales and HR
- Sales and HR isolated from each other

**Solution:**

```bash
# VLAN assignments
# VLAN 10: Sales
# VLAN 20: IT
# VLAN 30: HR
# VLAN 40: Management

# Create VLANs
for vlan in 10 20 30 40; do
    sudo ip link add link eth0 name eth0.$vlan type vlan id $vlan
    sudo ip addr add 10.0.$vlan.1/24 dev eth0.$vlan
    sudo ip link set eth0.$vlan up
done

# Enable routing
sudo sysctl -w net.ipv4.ip_forward=1

# Firewall rules
# IT can access all
sudo iptables -A FORWARD -i eth0.20 -j ACCEPT
sudo iptables -A FORWARD -o eth0.20 -m state --state ESTABLISHED,RELATED -j ACCEPT

# Management can access Sales and HR
sudo iptables -A FORWARD -i eth0.40 -o eth0.10 -j ACCEPT
sudo iptables -A FORWARD -i eth0.40 -o eth0.30 -j ACCEPT
sudo iptables -A FORWARD -i eth0.10 -o eth0.40 -m state --state ESTABLISHED,RELATED -j ACCEPT
sudo iptables -A FORWARD -i eth0.30 -o eth0.40 -m state --state ESTABLISHED,RELATED -j ACCEPT

# Block Sales <-> HR
sudo iptables -A FORWARD -i eth0.10 -o eth0.30 -j DROP
sudo iptables -A FORWARD -i eth0.30 -o eth0.10 -j DROP

# Default drop
sudo iptables -P FORWARD DROP
```

### Scenario 2: Troubleshoot VLAN Communication

**Problem:** Devices in VLAN 10 cannot communicate

**Troubleshooting Steps:**

```bash
# 1. Check if VLAN interface exists
ip link show eth0.10

# 2. Check if interface is up
ip link show eth0.10 | grep UP

# 3. Check IP configuration
ip addr show eth0.10

# 4. Check 8021q module
lsmod | grep 8021q

# 5. Check physical interface
ip link show eth0

# 6. Test local connectivity
ping -I eth0.10 10.0.10.1

# 7. Check ARP
ip neigh show dev eth0.10

# 8. Capture traffic
sudo tcpdump -i eth0.10 -e -n

# 9. Check bridge configuration (if applicable)
bridge vlan show

# 10. Check for firewall blocks
sudo iptables -L -v -n | grep 10.0.10
```

---

## 22. Conclusion

VLANs are fundamental to modern network design, providing:

- **Segmentation**: Logical separation of network traffic
- **Security**: Isolation of sensitive data and systems
- **Efficiency**: Reduced broadcast domains
- **Flexibility**: Easy network reorganization without physical changes
- **Scalability**: Support for large, complex networks

### Key Takeaways

1. **Access ports** (untagged) connect end devices to a single VLAN
2. **Trunk ports** (tagged) carry multiple VLANs between switches
3. **802.1Q** is the standard for VLAN tagging
4. **Linux bridges** with VLAN filtering provide switch-like functionality
5. **Inter-VLAN routing** requires Layer 3 functionality
6. **Security** should be enforced between VLANs with firewalls/ACLs

### Next Steps

1. Practice in a lab environment
2. Implement VLANs on production networks (with proper planning)
3. Learn about advanced topics like QoS, VLAN stacking (Q-in-Q)
4. Explore SDN (Software-Defined Networking) for VLAN automation
5. Study network security in depth

---

## License

This guide is provided for educational purposes. Use the information responsibly and only on networks you own or have permission to configure.

**Author**: Networking Specialist  
**Version**: 1.0  
**Date**: October 2025

---

**End of Guide**
