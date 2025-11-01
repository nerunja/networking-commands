# VLAN Networking Troubleshooting Guide
## Linux Network Namespaces with VLAN-Aware Bridge

### Table of Contents
1. [Problem Overview](#problem-overview)
2. [Root Cause Analysis](#root-cause-analysis)
3. [Solution 1: VLAN-Aware Bridge](#solution-1-vlan-aware-bridge)
4. [Solution 2: Separate Bridges per VLAN](#solution-2-separate-bridges-per-vlan)
5. [Diagnostic Commands](#diagnostic-commands)
6. [Understanding VLAN Configuration](#understanding-vlan-configuration)
7. [Network Topology](#network-topology)
8. [Verification and Testing](#verification-and-testing)
9. [Troubleshooting Tips](#troubleshooting-tips)

---

## Problem Overview

### Symptoms
```bash
sudo ip netns exec pc10 ping 192.168.10.1
# Result: Destination Host Unreachable
```

### Error Pattern
- PC10 cannot reach router gateway (192.168.10.1)
- PC20 cannot reach router gateway (192.168.20.1)
- Inter-VLAN communication fails
- ARP resolution fails (packets never reach router)

### The Issue
The bridge is operating as a **simple L2 switch without VLAN awareness**. Traffic from untagged access ports (PC10, PC20) is being forwarded to the trunk port without proper VLAN tagging, causing the router's VLAN sub-interfaces to ignore the packets.

---

## Root Cause Analysis

### VLAN Tagging Mismatch

```
Current (Broken) Setup:
┌────────┐           ┌─────────┐           ┌────────┐
│  PC10  │──untagged→│  Bridge │──untagged→│ Router │
│(no tag)│           │(no VLAN)│           │(expects│
└────────┘           └─────────┘           │VLAN 10)│
                                           └────────┘
                     ❌ Packets dropped!
```

### What Should Happen

```
Correct Setup:
┌────────┐           ┌─────────────┐           ┌────────┐
│  PC10  │──untagged→│ VLAN-Aware  │──VLAN 10 →│ Router │
│(no tag)│           │   Bridge    │  tagged   │.10 sub │
└────────┘           │             │           │ -if    │
                     │  Tags with  │           └────────┘
                     │  VLAN ID    │
                     └─────────────┘
```

---

## Solution 1: VLAN-Aware Bridge

This solution uses a **single bridge with VLAN filtering** enabled, simulating a real enterprise switch with VLAN capabilities.

### Complete Working Script

```bash
#!/bin/bash

#############################################
# VLAN-Aware Bridge Network Setup Script
# Creates isolated network namespaces with
# proper VLAN tagging for inter-VLAN routing
#############################################

set -e  # Exit on error

echo "=== Cleaning Up Existing Setup ==="
sudo ip netns delete pc10 2>/dev/null || true
sudo ip netns delete pc20 2>/dev/null || true
sudo ip netns delete router 2>/dev/null || true
sudo ip link delete br0 2>/dev/null || true

echo "=== Creating Network Namespaces ==="
sudo ip netns add pc10
sudo ip netns add pc20
sudo ip netns add router

echo "=== Creating Virtual Ethernet Pairs ==="
# PC10 to Switch
sudo ip link add veth-pc10 type veth peer name veth-sw10

# PC20 to Switch
sudo ip link add veth-pc20 type veth peer name veth-sw20

# Switch to Router (Trunk)
sudo ip link add veth-trunk type veth peer name veth-router

echo "=== Moving Interfaces to Namespaces ==="
sudo ip link set veth-pc10 netns pc10
sudo ip link set veth-pc20 netns pc20
sudo ip link set veth-router netns router

echo "=== Creating VLAN-Aware Bridge ==="
# Create bridge with VLAN filtering enabled
sudo ip link add br0 type bridge vlan_filtering 1
sudo ip link set br0 up

echo "=== Adding Ports to Bridge ==="
sudo ip link set veth-sw10 master br0
sudo ip link set veth-sw20 master br0
sudo ip link set veth-trunk master br0

echo "=== Bringing Up Switch-Side Interfaces ==="
sudo ip link set veth-sw10 up
sudo ip link set veth-sw20 up
sudo ip link set veth-trunk up

echo "=== Configuring VLANs on Bridge Ports ==="

# Configure veth-sw10 as ACCESS port for VLAN 10
sudo bridge vlan del dev veth-sw10 vid 1  # Remove default VLAN 1
sudo bridge vlan add dev veth-sw10 vid 10 pvid untagged
# pvid = Port VLAN ID (default VLAN for untagged ingress)
# untagged = Remove VLAN tag on egress

# Configure veth-sw20 as ACCESS port for VLAN 20
sudo bridge vlan del dev veth-sw20 vid 1
sudo bridge vlan add dev veth-sw20 vid 20 pvid untagged

# Configure veth-trunk as TRUNK port (tagged for VLANs 10 and 20)
sudo bridge vlan del dev veth-trunk vid 1
sudo bridge vlan add dev veth-trunk vid 10  # Tagged
sudo bridge vlan add dev veth-trunk vid 20  # Tagged

# Configure bridge itself to participate in VLANs
sudo bridge vlan del dev br0 vid 1 self
sudo bridge vlan add dev br0 vid 10 self
sudo bridge vlan add dev br0 vid 20 self

echo "=== Configuring PC10 (VLAN 10) ==="
sudo ip netns exec pc10 ip addr add 192.168.10.10/24 dev veth-pc10
sudo ip netns exec pc10 ip link set veth-pc10 up
sudo ip netns exec pc10 ip link set lo up
sudo ip netns exec pc10 ip route add default via 192.168.10.1

echo "=== Configuring PC20 (VLAN 20) ==="
sudo ip netns exec pc20 ip addr add 192.168.20.20/24 dev veth-pc20
sudo ip netns exec pc20 ip link set veth-pc20 up
sudo ip netns exec pc20 ip link set lo up
sudo ip netns exec pc20 ip route add default via 192.168.20.1

echo "=== Configuring Router ==="
# Bring up trunk interface first (parent interface)
sudo ip netns exec router ip link set veth-router up

# Create VLAN sub-interfaces on router
sudo ip netns exec router ip link add link veth-router name veth-router.10 type vlan id 10
sudo ip netns exec router ip link add link veth-router name veth-router.20 type vlan id 20

# Assign IP addresses to VLAN sub-interfaces
sudo ip netns exec router ip addr add 192.168.10.1/24 dev veth-router.10
sudo ip netns exec router ip addr add 192.168.20.1/24 dev veth-router.20

# Bring up all router interfaces
sudo ip netns exec router ip link set veth-router.10 up
sudo ip netns exec router ip link set veth-router.20 up
sudo ip netns exec router ip link set lo up

# Enable IP forwarding for inter-VLAN routing
sudo ip netns exec router sysctl -w net.ipv4.ip_forward=1 > /dev/null

echo ""
echo "=== Setup Complete! ==="
echo ""
echo "=== VLAN Configuration on Bridge ==="
sudo bridge vlan show
echo ""
echo "=== Router Interface Configuration ==="
sudo ip netns exec router ip addr show
echo ""
echo "==================================="
echo "=== Connectivity Tests ==="
echo "==================================="
echo ""

echo "Test 1: PC10 → Router Gateway (VLAN 10)"
sudo ip netns exec pc10 ping -c 3 -W 1 192.168.10.1 && echo "✅ SUCCESS" || echo "❌ FAILED"
echo ""

echo "Test 2: PC20 → Router Gateway (VLAN 20)"
sudo ip netns exec pc20 ping -c 3 -W 1 192.168.20.1 && echo "✅ SUCCESS" || echo "❌ FAILED"
echo ""

echo "Test 3: Inter-VLAN Routing (PC10 → PC20)"
sudo ip netns exec pc10 ping -c 3 -W 1 192.168.20.20 && echo "✅ SUCCESS" || echo "❌ FAILED"
echo ""

echo "Test 4: Inter-VLAN Routing (PC20 → PC10)"
sudo ip netns exec pc20 ping -c 3 -W 1 192.168.10.10 && echo "✅ SUCCESS" || echo "❌ FAILED"
echo ""

echo "==================================="
echo "Network topology successfully created!"
echo "==================================="
```

### Save and Run

```bash
# Save the script
nano vlan-setup.sh

# Make it executable
chmod +x vlan-setup.sh

# Run it
sudo ./vlan-setup.sh
```

---

## Solution 2: Separate Bridges per VLAN

This alternative approach uses **one bridge per VLAN**, which is simpler but less realistic (doesn't simulate a real switch with VLAN trunking).

### Complete Script

```bash
#!/bin/bash

#############################################
# Separate Bridges Network Setup Script
# Uses one bridge per VLAN (simpler approach)
#############################################

set -e

echo "=== Cleaning Up Existing Setup ==="
sudo ip netns delete pc10 2>/dev/null || true
sudo ip netns delete pc20 2>/dev/null || true
sudo ip netns delete router 2>/dev/null || true
sudo ip link delete br10 2>/dev/null || true
sudo ip link delete br20 2>/dev/null || true

echo "=== Creating Network Namespaces ==="
sudo ip netns add pc10
sudo ip netns add pc20
sudo ip netns add router

echo "=== Creating Virtual Ethernet Pairs ==="
# PC10 to Bridge 10
sudo ip link add veth-pc10 type veth peer name veth-sw10

# PC20 to Bridge 20
sudo ip link add veth-pc20 type veth peer name veth-sw20

# Router VLAN 10 to Bridge 10
sudo ip link add veth-r10 type veth peer name veth-sw-r10

# Router VLAN 20 to Bridge 20
sudo ip link add veth-r20 type veth peer name veth-sw-r20

echo "=== Moving Interfaces to Namespaces ==="
sudo ip link set veth-pc10 netns pc10
sudo ip link set veth-pc20 netns pc20
sudo ip link set veth-r10 netns router
sudo ip link set veth-r20 netns router

echo "=== Creating Separate Bridges ==="
# One bridge per VLAN
sudo ip link add br10 type bridge
sudo ip link add br20 type bridge
sudo ip link set br10 up
sudo ip link set br20 up

echo "=== Connecting Ports to Bridges ==="
# Bridge 10 (VLAN 10)
sudo ip link set veth-sw10 master br10
sudo ip link set veth-sw-r10 master br10

# Bridge 20 (VLAN 20)
sudo ip link set veth-sw20 master br20
sudo ip link set veth-sw-r20 master br20

echo "=== Bringing Up Switch Interfaces ==="
sudo ip link set veth-sw10 up
sudo ip link set veth-sw-r10 up
sudo ip link set veth-sw20 up
sudo ip link set veth-sw-r20 up

echo "=== Configuring PC10 (VLAN 10) ==="
sudo ip netns exec pc10 ip addr add 192.168.10.10/24 dev veth-pc10
sudo ip netns exec pc10 ip link set veth-pc10 up
sudo ip netns exec pc10 ip link set lo up
sudo ip netns exec pc10 ip route add default via 192.168.10.1

echo "=== Configuring PC20 (VLAN 20) ==="
sudo ip netns exec pc20 ip addr add 192.168.20.20/24 dev veth-pc20
sudo ip netns exec pc20 ip link set veth-pc20 up
sudo ip netns exec pc20 ip link set lo up
sudo ip netns exec pc20 ip route add default via 192.168.20.1

echo "=== Configuring Router ==="
# No VLAN sub-interfaces needed - direct interfaces per VLAN
sudo ip netns exec router ip addr add 192.168.10.1/24 dev veth-r10
sudo ip netns exec router ip addr add 192.168.20.1/24 dev veth-r20
sudo ip netns exec router ip link set veth-r10 up
sudo ip netns exec router ip link set veth-r20 up
sudo ip netns exec router ip link set lo up
sudo ip netns exec router sysctl -w net.ipv4.ip_forward=1 > /dev/null

echo ""
echo "=== Setup Complete! ==="
echo ""
echo "=== Testing Connectivity ==="
echo ""

echo "Test 1: PC10 → Router"
sudo ip netns exec pc10 ping -c 3 -W 1 192.168.10.1 && echo "✅ SUCCESS" || echo "❌ FAILED"
echo ""

echo "Test 2: PC20 → Router"
sudo ip netns exec pc20 ping -c 3 -W 1 192.168.20.1 && echo "✅ SUCCESS" || echo "❌ FAILED"
echo ""

echo "Test 3: Inter-VLAN (PC10 → PC20)"
sudo ip netns exec pc10 ping -c 3 -W 1 192.168.20.20 && echo "✅ SUCCESS" || echo "❌ FAILED"
echo ""

echo "==================================="
echo "Network topology successfully created!"
echo "==================================="
```

---

## Diagnostic Commands

### Check Bridge VLAN Configuration

```bash
# Show VLAN configuration on all bridge ports
sudo bridge vlan show

# Expected output for VLAN-aware bridge:
# port              vlan-id  
# veth-sw10         10 PVID Egress Untagged
# veth-sw20         20 PVID Egress Untagged
# veth-trunk        10
#                   20
# br0               10
#                   20
```

### Check Interface Status

```bash
# List all network namespaces
sudo ip netns list

# Check interfaces in PC10 namespace
sudo ip netns exec pc10 ip addr show

# Check interfaces in router namespace
sudo ip netns exec router ip addr show

# Check routing table in PC10
sudo ip netns exec pc10 ip route

# Check routing table in router
sudo ip netns exec router ip route
```

### Check Bridge Configuration

```bash
# Show bridge details
sudo ip -d link show br0

# Show bridge ports
sudo bridge link show

# Check if VLAN filtering is enabled
sudo ip -d link show br0 | grep vlan_filtering
# Should show: vlan_filtering 1
```

### ARP and Neighbor Discovery

```bash
# Check ARP table in PC10
sudo ip netns exec pc10 ip neigh

# Check ARP table in router
sudo ip netns exec router ip neigh

# Manually trigger ARP
sudo ip netns exec pc10 arping -I veth-pc10 -c 3 192.168.10.1
```

### Packet Capture for Debugging

```bash
# Capture on bridge
sudo tcpdump -i br0 -n -e

# Capture in PC10 namespace
sudo ip netns exec pc10 tcpdump -i veth-pc10 -n -e

# Capture in router namespace
sudo ip netns exec router tcpdump -i veth-router -n -e

# Capture with VLAN tags visible
sudo tcpdump -i veth-trunk -n -e vlan

# Capture ICMP only
sudo ip netns exec router tcpdump -i veth-router icmp -n
```

### Check IP Forwarding

```bash
# Verify IP forwarding is enabled in router
sudo ip netns exec router sysctl net.ipv4.ip_forward

# Should return: net.ipv4.ip_forward = 1
```

---

## Understanding VLAN Configuration

### Bridge VLAN Commands Explained

```bash
# Enable VLAN filtering on bridge
sudo ip link add br0 type bridge vlan_filtering 1
```

#### Access Port Configuration

```bash
# Configure as ACCESS port (untagged)
sudo bridge vlan add dev veth-sw10 vid 10 pvid untagged

# Breakdown:
# - vid 10         : VLAN ID is 10
# - pvid           : Port VLAN ID (default VLAN for untagged ingress frames)
# - untagged       : Remove VLAN tag when sending frames out (egress)
```

**What happens:**
1. **Ingress (frames entering bridge):** Untagged frames are tagged with VLAN 10
2. **Egress (frames leaving bridge):** VLAN tag is removed before sending to PC

#### Trunk Port Configuration

```bash
# Configure as TRUNK port (tagged)
sudo bridge vlan add dev veth-trunk vid 10
sudo bridge vlan add dev veth-trunk vid 20

# Breakdown:
# - vid 10/20      : Allow VLANs 10 and 20
# - NO pvid        : Don't tag untagged frames
# - NO untagged    : Keep VLAN tags on egress
```

**What happens:**
1. **Ingress:** Accept frames tagged with VLAN 10 or 20
2. **Egress:** Keep VLAN tags when sending to router

### VLAN Configuration Table

| Port | Type | VLAN | PVID | Tagging on Egress |
|------|------|------|------|-------------------|
| veth-sw10 | Access | 10 | Yes (10) | Untagged |
| veth-sw20 | Access | 20 | Yes (20) | Untagged |
| veth-trunk | Trunk | 10, 20 | No | Tagged |
| br0 (self) | Bridge | 10, 20 | No | N/A |

### VLAN Frame Flow

```
PC10 (untagged) → veth-sw10 → Bridge (tags with VLAN 10) → veth-trunk (tagged) → Router.10

1. PC10 sends: [Ethernet Frame: no VLAN tag]
2. Bridge receives on veth-sw10 (PVID=10): adds VLAN 10 tag
3. Bridge forwards: [Ethernet Frame: VLAN 10 tag]
4. veth-trunk (trunk port): keeps VLAN tag
5. Router receives on veth-router.10: processes VLAN 10 frame
```

---

## Network Topology

### VLAN-Aware Bridge Topology

```
┌─────────────────────┐  ┌─────────────────────┐  ┌─────────────────────┐
│  Namespace: pc10    │  │  Namespace: pc20    │  │  Namespace: router  │
│                     │  │                     │  │                     │
│  veth-pc10          │  │  veth-pc20          │  │  veth-router        │
│  192.168.10.10/24   │  │  192.168.20.20/24   │  │  (trunk parent)     │
│                     │  │                     │  │                     │
│  Default GW:        │  │  Default GW:        │  │  veth-router.10     │
│  192.168.10.1       │  │  192.168.20.1       │  │  192.168.10.1/24    │
│                     │  │                     │  │                     │
│                     │  │                     │  │  veth-router.20     │
│                     │  │                     │  │  192.168.20.1/24    │
└──────────┬──────────┘  └──────────┬──────────┘  └──────────┬──────────┘
           │                        │                        │
           │ untagged               │ untagged               │ tagged
           │                        │                        │ (VLAN 10+20)
           │                        │                        │
┌──────────┴────────────────────────┴────────────────────────┴──────────┐
│                    Default Namespace (Host)                            │
│                                                                        │
│         veth-sw10              veth-sw20              veth-trunk      │
│              │                     │                       │          │
│              │  ACCESS VLAN 10     │  ACCESS VLAN 20      │ TRUNK    │
│              │  (pvid untagged)    │  (pvid untagged)     │ (tagged) │
│              │                     │                       │          │
│              └─────────┬───────────┴───────────┬───────────┘          │
│                        │                       │                      │
│                   ┌────┴───────────────────────┴────┐                 │
│                   │      br0 (VLAN-aware bridge)    │                 │
│                   │      vlan_filtering = 1         │                 │
│                   │      VLANs: 10, 20              │                 │
│                   └─────────────────────────────────┘                 │
│                                                                        │
└────────────────────────────────────────────────────────────────────────┘

Packet Flow Example (PC10 → PC20):
1. PC10 sends untagged frame → veth-pc10
2. Bridge receives on veth-sw10 (Access VLAN 10): adds VLAN 10 tag
3. Bridge forwards VLAN 10 frame → veth-trunk (trunk keeps tag)
4. Router receives on veth-router.10: processes, makes routing decision
5. Router forwards to veth-router.20: adds VLAN 20 tag
6. Bridge receives VLAN 20 frame on veth-trunk
7. Bridge forwards to veth-sw20 (Access VLAN 20): removes tag
8. PC20 receives untagged frame on veth-pc20
```

### Separate Bridges Topology

```
┌─────────────────────┐                              ┌─────────────────────┐
│  Namespace: pc10    │                              │  Namespace: router  │
│                     │                              │                     │
│  veth-pc10          │        ┌──────────┐          │  veth-r10           │
│  192.168.10.10/24   │────────│   br10   │──────────│  192.168.10.1/24    │
│                     │        │ (VLAN 10)│          │                     │
└─────────────────────┘        └──────────┘          │                     │
                                                      │                     │
┌─────────────────────┐                              │                     │
│  Namespace: pc20    │                              │  veth-r20           │
│                     │        ┌──────────┐          │  192.168.20.1/24    │
│  veth-pc20          │────────│   br20   │──────────│                     │
│  192.168.20.20/24   │        │ (VLAN 20)│          │  IP Forwarding:     │
│                     │        └──────────┘          │  Enabled            │
└─────────────────────┘                              └─────────────────────┘

Note: This approach uses separate bridges without VLAN tagging
      Each bridge represents a separate Layer 2 broadcast domain
```

---

## Verification and Testing

### Step-by-Step Verification

```bash
# 1. Verify namespaces were created
sudo ip netns list
# Expected: pc10, pc20, router

# 2. Verify VLAN filtering is enabled
sudo ip -d link show br0 | grep vlan_filtering
# Expected: vlan_filtering 1

# 3. Check VLAN configuration
sudo bridge vlan show
# Verify:
#   - veth-sw10: VLAN 10 PVID Untagged
#   - veth-sw20: VLAN 20 PVID Untagged
#   - veth-trunk: VLAN 10 and 20 (tagged)

# 4. Check router interfaces
sudo ip netns exec router ip addr show
# Verify:
#   - veth-router.10: 192.168.10.1/24
#   - veth-router.20: 192.168.20.1/24

# 5. Verify IP forwarding
sudo ip netns exec router sysctl net.ipv4.ip_forward
# Expected: net.ipv4.ip_forward = 1

# 6. Test Layer 2 connectivity (same VLAN)
sudo ip netns exec pc10 ping -c 3 192.168.10.1

# 7. Test inter-VLAN routing
sudo ip netns exec pc10 ping -c 3 192.168.20.20

# 8. Check ARP tables
sudo ip netns exec pc10 ip neigh
sudo ip netns exec router ip neigh
```

### Comprehensive Test Script

```bash
#!/bin/bash

echo "=== Network Verification Script ==="
echo ""

# Test 1: Namespace existence
echo "1. Checking namespaces..."
NAMESPACES=$(sudo ip netns list)
echo "$NAMESPACES"
echo ""

# Test 2: VLAN filtering
echo "2. Checking VLAN filtering..."
sudo ip -d link show br0 | grep vlan_filtering
echo ""

# Test 3: VLAN configuration
echo "3. VLAN configuration on bridge ports..."
sudo bridge vlan show
echo ""

# Test 4: PC10 connectivity
echo "4. Testing PC10 → Router (192.168.10.1)..."
sudo ip netns exec pc10 ping -c 3 -W 2 192.168.10.1
echo ""

# Test 5: PC20 connectivity
echo "5. Testing PC20 → Router (192.168.20.1)..."
sudo ip netns exec pc20 ping -c 3 -W 2 192.168.20.1
echo ""

# Test 6: Inter-VLAN routing
echo "6. Testing Inter-VLAN routing (PC10 → PC20)..."
sudo ip netns exec pc10 ping -c 3 -W 2 192.168.20.20
echo ""

# Test 7: Reverse inter-VLAN
echo "7. Testing Inter-VLAN routing (PC20 → PC10)..."
sudo ip netns exec pc20 ping -c 3 -W 2 192.168.10.10
echo ""

# Test 8: Routing tables
echo "8. Routing tables..."
echo "PC10 routing table:"
sudo ip netns exec pc10 ip route
echo ""
echo "Router routing table:"
sudo ip netns exec router ip route
echo ""

# Test 9: ARP tables
echo "9. ARP tables..."
echo "PC10 ARP table:"
sudo ip netns exec pc10 ip neigh
echo ""
echo "Router ARP table:"
sudo ip netns exec router ip neigh
echo ""

echo "=== Verification Complete ==="
```

---

## Troubleshooting Tips

### Issue: "Destination Host Unreachable"

**Possible Causes:**

1. **VLAN filtering not enabled**
   ```bash
   # Check
   sudo ip -d link show br0 | grep vlan_filtering
   
   # Fix
   sudo ip link set br0 type bridge vlan_filtering 1
   ```

2. **VLAN configuration missing or incorrect**
   ```bash
   # Check
   sudo bridge vlan show
   
   # Fix for access port
   sudo bridge vlan del dev veth-sw10 vid 1
   sudo bridge vlan add dev veth-sw10 vid 10 pvid untagged
   ```

3. **Router interfaces not up**
   ```bash
   # Check
   sudo ip netns exec router ip link show
   
   # Fix
   sudo ip netns exec router ip link set veth-router up
   sudo ip netns exec router ip link set veth-router.10 up
   sudo ip netns exec router ip link set veth-router.20 up
   ```

4. **IP forwarding not enabled**
   ```bash
   # Check
   sudo ip netns exec router sysctl net.ipv4.ip_forward
   
   # Fix
   sudo ip netns exec router sysctl -w net.ipv4.ip_forward=1
   ```

### Issue: "Network is unreachable"

**Cause:** Missing default route

```bash
# Check
sudo ip netns exec pc10 ip route

# Fix
sudo ip netns exec pc10 ip route add default via 192.168.10.1
```

### Issue: ARP Not Resolving

**Debug with packet capture:**

```bash
# Terminal 1: Capture on bridge
sudo tcpdump -i br0 -n -e arp

# Terminal 2: Send ping
sudo ip netns exec pc10 ping 192.168.10.1

# Look for:
# - ARP requests leaving veth-sw10
# - ARP requests arriving on veth-trunk with VLAN tag
# - ARP replies with correct VLAN tag
```

### Issue: Packets Not Crossing VLANs

**Check routing:**

```bash
# Verify router can see both networks
sudo ip netns exec router ip addr show

# Verify IP forwarding
sudo ip netns exec router sysctl net.ipv4.ip_forward

# Check iptables rules (if any)
sudo ip netns exec router iptables -L -n -v
```

### Complete Debug Session

```bash
# Terminal 1: Monitor bridge
sudo tcpdump -i br0 -n -e -vv

# Terminal 2: Monitor router
sudo ip netns exec router tcpdump -i veth-router -n -e -vv

# Terminal 3: Send test traffic
sudo ip netns exec pc10 ping 192.168.20.20

# What to look for:
# 1. PC10 sends ARP for gateway (192.168.10.1)
# 2. Bridge tags with VLAN 10
# 3. Router receives on veth-router.10
# 4. Router responds with ARP reply
# 5. ICMP echo request arrives at router
# 6. Router routes to VLAN 20
# 7. Router sends ICMP to PC20 via VLAN 20
```

---

## Common Commands Reference

### Network Namespace Commands

```bash
# Create namespace
sudo ip netns add <name>

# Delete namespace
sudo ip netns delete <name>

# List namespaces
sudo ip netns list

# Execute command in namespace
sudo ip netns exec <name> <command>

# Enter namespace shell
sudo ip netns exec <name> bash
```

### Bridge Commands

```bash
# Create bridge
sudo ip link add <name> type bridge

# Enable VLAN filtering
sudo ip link set <bridge> type bridge vlan_filtering 1

# Add port to bridge
sudo ip link set <interface> master <bridge>

# Show bridge ports
sudo bridge link show

# Show VLAN configuration
sudo bridge vlan show
```

### VLAN Commands

```bash
# Add VLAN to port (access)
sudo bridge vlan add dev <port> vid <vlan_id> pvid untagged

# Add VLAN to port (trunk)
sudo bridge vlan add dev <port> vid <vlan_id>

# Delete VLAN from port
sudo bridge vlan del dev <port> vid <vlan_id>

# Create VLAN sub-interface
sudo ip link add link <parent> name <parent>.<vlan_id> type vlan id <vlan_id>
```

### Testing Commands

```bash
# Ping test
sudo ip netns exec <namespace> ping -c 3 <ip>

# Traceroute
sudo ip netns exec <namespace> traceroute <ip>

# Check connectivity
sudo ip netns exec <namespace> nc -zv <ip> <port>

# HTTP test
sudo ip netns exec <namespace> curl <url>
```

---

## Cleanup Script

```bash
#!/bin/bash

echo "=== Cleaning Up Network Topology ==="

# Delete namespaces (this also removes interfaces in them)
sudo ip netns delete pc10 2>/dev/null || true
sudo ip netns delete pc20 2>/dev/null || true
sudo ip netns delete router 2>/dev/null || true

# Delete bridges
sudo ip link delete br0 2>/dev/null || true
sudo ip link delete br10 2>/dev/null || true
sudo ip link delete br20 2>/dev/null || true

# Delete any remaining veth pairs (cleanup)
sudo ip link delete veth-sw10 2>/dev/null || true
sudo ip link delete veth-sw20 2>/dev/null || true
sudo ip link delete veth-trunk 2>/dev/null || true
sudo ip link delete veth-sw-r10 2>/dev/null || true
sudo ip link delete veth-sw-r20 2>/dev/null || true

echo "Cleanup complete!"
```

---

## Additional Resources

### Official Documentation
- [Linux Bridge Documentation](https://wiki.linuxfoundation.org/networking/bridge)
- [iproute2 Documentation](https://wiki.linuxfoundation.org/networking/iproute2)
- [Network Namespaces](https://man7.org/linux/man-pages/man8/ip-netns.8.html)
- [VLAN on Linux](https://developers.redhat.com/blog/2017/09/14/vlan-filter-support-on-bridge)

### Related Guides
- Nmap Network Scanning Guide (included in project)
- Bettercap Network Analysis Guide (included in project)

### Learning Resources
- Practice in isolated VMs or containers
- Use packet captures to understand frame flow
- Experiment with different VLAN configurations
- Build complex multi-VLAN topologies

---

## Summary

### Key Takeaways

1. **VLAN-aware bridges require explicit configuration**
   - Enable `vlan_filtering 1`
   - Configure access ports with `pvid untagged`
   - Configure trunk ports with multiple VLANs (tagged)

2. **Access vs Trunk ports**
   - **Access:** Untagged for end devices (PCs, servers)
   - **Trunk:** Tagged for inter-switch/router links

3. **Router configuration**
   - Create VLAN sub-interfaces
   - Enable IP forwarding for inter-VLAN routing

4. **Network namespaces**
   - Provide complete network isolation
   - Must be created before moving interfaces

5. **Debugging approach**
   - Start with `ip link` status
   - Check VLAN configuration with `bridge vlan show`
   - Use `tcpdump` to see actual packet flow
   - Verify ARP resolution with `ip neigh`

### Quick Reference

```bash
# Enable VLAN filtering
sudo ip link set br0 type bridge vlan_filtering 1

# Access port (untagged)
sudo bridge vlan add dev <port> vid <vlan_id> pvid untagged

# Trunk port (tagged)
sudo bridge vlan add dev <port> vid <vlan_id>

# Check configuration
sudo bridge vlan show

# Test connectivity
sudo ip netns exec pc10 ping 192.168.10.1
```

---

**Created:** 2025-11-01  
**Last Updated:** 2025-11-01  
**Version:** 1.0  

---

## License

This guide is provided as-is for educational purposes. Use these techniques only in authorized test environments.
