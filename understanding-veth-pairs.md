# Understanding veth Pairs in Linux Networking

## Overview

Virtual Ethernet (veth) pairs are a fundamental building block for Linux network virtualization. They act as **virtual network cables** connecting different network namespaces or network devices.

## What Are veth Pairs?

A veth pair consists of two virtual network interfaces that are interconnected. Think of them as:
- A virtual ethernet cable with two plugs
- Two ends of a pipe
- A bidirectional tunnel between network spaces

**Key characteristic**: Whatever enters one end, exits the other end immediately.

## The Command Structure

```bash
sudo ip link add veth-pc10 type veth peer name veth-sw10
```

### Command Breakdown

| Component | Description |
|-----------|-------------|
| `ip link add` | Create a new network interface |
| `veth-pc10` | Name of the first interface (end A) |
| `type veth` | Specify it's a virtual ethernet pair |
| `peer name veth-sw10` | Name of the paired interface (end B) |

## Your Script's veth Pairs

Your script creates four veth pairs:

```bash
# Create veth pairs
sudo ip link add veth-pc10 type veth peer name veth-sw10
sudo ip link add veth-pc20 type veth peer name veth-sw20
sudo ip link add veth-r10 type veth peer name veth-sw-r10
sudo ip link add veth-r20 type veth peer name veth-sw-r20
```

### Naming Convention

| Pair # | End A (Device Side) | End B (Switch Side) | Purpose |
|--------|---------------------|---------------------|---------|
| 1 | `veth-pc10` | `veth-sw10` | PC10 → Switch VLAN 10 |
| 2 | `veth-pc20` | `veth-sw20` | PC20 → Switch VLAN 20 |
| 3 | `veth-r10` | `veth-sw-r10` | Router → Switch VLAN 10 |
| 4 | `veth-r20` | `veth-sw-r20` | Router → Switch VLAN 20 |

## Visual Representation

### Single veth Pair

```
┌─────────────────────────────────────────────────┐
│          Virtual Ethernet Cable/Pair            │
│                                                 │
│   [veth-pc10] ←═══════════════→ [veth-sw10]   │
│                                                 │
│   Packets enter here          Exit here        │
└─────────────────────────────────────────────────┘
```

### Complete Network Topology

```
VLAN 10 Network (192.168.10.0/24):
┌─────────────┐                                  ┌─────────────┐
│   PC10      │      veth-pc10 ↔ veth-sw10      │   Bridge    │
│ Namespace   │━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━▶│    br10     │
│ .10.10/24   │                                  │  (Switch)   │
└─────────────┘                                  └──────┬──────┘
                                                        │
                                                        │ veth-sw-r10 ↔ veth-r10
                                                        │
┌─────────────┐                                  ┌─────┴───────┐
│   Router    │◀─────────────────────────────────┤   Router    │
│ Namespace   │                                  │  Namespace  │
│             │                                  │  .10.1/24   │
│             │──────────────────────────────────▶│  .20.1/24   │
│             │  veth-r20 ↔ veth-sw-r20          └─────┬───────┘
└─────────────┘                                        │
                                                        │
                                                  ┌─────┴──────┐
VLAN 20 Network (192.168.20.0/24):               │   Bridge   │
┌─────────────┐      veth-pc20 ↔ veth-sw20      │    br20    │
│   PC20      │━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━▶│  (Switch)  │
│ Namespace   │                                  └────────────┘
│ .20.20/24   │
└─────────────┘
```

## How They're Used: Step-by-Step

### Step 1: Create the Pairs (Both Ends in Host)

```bash
sudo ip link add veth-pc10 type veth peer name veth-sw10
```

Initially, both ends exist in the **default/host namespace**:

```
┌────────────────────────────────────────┐
│      Host/Default Namespace            │
│                                        │
│  [veth-pc10] ↔ [veth-sw10]            │
│                                        │
└────────────────────────────────────────┘
```

### Step 2: Move One End to a Namespace

```bash
sudo ip link set veth-pc10 netns pc10
```

Now they span two namespaces:

```
┌─────────────────┐        ┌──────────────────┐
│ PC10 Namespace  │        │ Host Namespace   │
│                 │        │                  │
│  [veth-pc10]    │↔═══════│  [veth-sw10]    │
│                 │        │                  │
└─────────────────┘        └──────────────────┘
```

### Step 3: Attach Other End to Bridge

```bash
sudo ip link set veth-sw10 master br10
```

The bridge acts as a virtual switch:

```
┌─────────────────┐        ┌──────────────────────────┐
│ PC10 Namespace  │        │    Host Namespace        │
│                 │        │                          │
│  [veth-pc10]    │↔═══════│  [veth-sw10] → [br10]   │
│                 │        │                (Bridge)  │
└─────────────────┘        └──────────────────────────┘
```

### Step 4: Configure IP and Bring Up

```bash
sudo ip netns exec pc10 ip addr add 192.168.10.10/24 dev veth-pc10
sudo ip netns exec pc10 ip link set veth-pc10 up
sudo ip link set veth-sw10 up
```

Now traffic can flow:

```
┌─────────────────────┐        ┌────────────────────────┐
│ PC10 Namespace      │        │    Host Namespace      │
│                     │        │                        │
│  [veth-pc10] (UP)   │↔═══════│  [veth-sw10] (UP)     │
│  192.168.10.10/24   │        │      ↓                 │
│                     │        │    [br10]              │
└─────────────────────┘        └────────────────────────┘
```

## Complete Connection Flow

When PC10 sends a packet to PC20:

```
1. PC10 sends packet to 192.168.20.20
   ↓
2. Packet exits veth-pc10 in pc10 namespace
   ↓
3. Packet enters veth-sw10 in host namespace
   ↓
4. br10 (bridge/switch) receives packet
   ↓
5. br10 forwards to veth-sw-r10 (router's interface)
   ↓
6. Packet enters veth-r10 in router namespace
   ↓
7. Router forwards between veth-r10 and veth-r20
   ↓
8. Packet exits veth-r20 in router namespace
   ↓
9. Packet enters veth-sw-r20 in host namespace
   ↓
10. br20 (bridge/switch) receives packet
    ↓
11. br20 forwards to veth-sw20
    ↓
12. Packet enters veth-pc20 in pc20 namespace
    ↓
13. PC20 receives packet
```

## Real-World Analogies

### Physical Network Analogy

| Virtual | Physical Equivalent |
|---------|-------------------|
| veth pair | Ethernet cable |
| veth-pc10 | Network card in PC |
| veth-sw10 | Port on network switch |
| bridge (br10) | Physical network switch |
| namespace | Separate physical computer |

### Plumbing Analogy

```
┌─────────┐         ┌─────────┐         ┌─────────┐
│  Faucet │═════════│  Pipe   │═════════│  Drain  │
│ (veth-A)│         │(virtual)│         │(veth-B) │
└─────────┘         └─────────┘         └─────────┘
```

Water (data) flows through the pipe in both directions.

## Key Properties

### 1. Always Created in Pairs
You cannot create a single veth interface - they always come in pairs.

```bash
# ✅ Correct - creates a pair
sudo ip link add veth0 type veth peer name veth1

# ❌ Impossible - no single veth
sudo ip link add veth0 type veth
```

### 2. Bidirectional Communication
Data flows both ways through the virtual cable.

```
veth-A ⇄ veth-B
  ↑       ↑
  └───────┘
Both can send and receive
```

### 3. Initially in Host Namespace
Both ends start in the default namespace until moved.

```bash
# After creation
ip link show | grep veth
# Shows: veth-pc10 and veth-sw10

# After moving
sudo ip link set veth-pc10 netns pc10
ip link show | grep veth
# Shows: only veth-sw10 (veth-pc10 is now in pc10 namespace)
```

### 4. Independent Configuration
Each end can have different settings:

```bash
# Configure end A
sudo ip netns exec pc10 ip addr add 192.168.10.10/24 dev veth-pc10
sudo ip netns exec pc10 ip link set veth-pc10 up

# Configure end B (different settings)
sudo ip link set veth-sw10 up
# No IP address needed on bridge port
```

### 5. Acts Like Physical Interface
Each veth interface behaves like a real NIC:
- Has a MAC address
- Can be brought up/down
- Can have IP address
- Can capture packets
- Can apply firewall rules

## Common Use Cases

### 1. Container Networking
Docker and other container runtimes use veth pairs to connect containers to the host.

```
Container ↔ veth pair ↔ Bridge ↔ Host network
```

### 2. Network Namespaces
Connecting isolated network environments (like your script).

### 3. Testing and Development
Creating virtual networks for testing without physical hardware.

### 4. Network Function Virtualization (NFV)
Building virtual routers, switches, and firewalls.

## Debugging veth Pairs

### List All veth Interfaces
```bash
# In host namespace
ip link show type veth

# In specific namespace
sudo ip netns exec pc10 ip link show
```

### Find Peer Interface
```bash
# Get interface index
ip link show veth-sw10
# Output: 4: veth-sw10@if3: <BROADCAST,MULTICAST,UP>
#                      ^^^
#                      Peer index is 3

# Find interface with index 3
ip link show | grep "^3:"
```

### Check Connectivity
```bash
# Ping through veth pair
sudo ip netns exec pc10 ping 192.168.10.1
```

### Monitor Traffic
```bash
# Capture packets on veth interface
sudo ip netns exec pc10 tcpdump -i veth-pc10

# Or from host side
sudo tcpdump -i veth-sw10
```

## Advanced Operations

### Create and Configure in One Command Chain
```bash
sudo ip link add veth0 type veth peer name veth1 && \
sudo ip link set veth0 netns ns1 && \
sudo ip netns exec ns1 ip addr add 10.0.0.1/24 dev veth0 && \
sudo ip netns exec ns1 ip link set veth0 up && \
sudo ip link set veth1 up
```

### Delete veth Pair
```bash
# Deleting one end deletes both
sudo ip link delete veth-sw10

# Or from namespace
sudo ip netns exec pc10 ip link delete veth-pc10
```

### Check if Pair Exists
```bash
if ip link show veth-sw10 &>/dev/null; then
    echo "veth pair exists"
else
    echo "veth pair does not exist"
fi
```

## Troubleshooting

### Problem: Cannot Ping Through veth Pair

**Check list:**
1. Are both ends UP?
   ```bash
   ip link show veth-sw10  # Should see UP
   sudo ip netns exec pc10 ip link show veth-pc10  # Should see UP
   ```

2. Are IP addresses configured?
   ```bash
   sudo ip netns exec pc10 ip addr show veth-pc10
   ```

3. Is packet forwarding enabled (if routing)?
   ```bash
   sudo ip netns exec router sysctl net.ipv4.ip_forward
   # Should show: net.ipv4.ip_forward = 1
   ```

4. Check routing table:
   ```bash
   sudo ip netns exec pc10 ip route show
   ```

### Problem: veth Pair Not Forwarding Traffic

**Solutions:**
1. Check bridge connection:
   ```bash
   bridge link show
   ```

2. Verify no firewall rules blocking:
   ```bash
   sudo ip netns exec pc10 iptables -L
   ```

3. Enable promiscuous mode (if needed):
   ```bash
   sudo ip link set veth-sw10 promisc on
   ```

## Best Practices

### 1. Consistent Naming Convention
Use descriptive names that indicate purpose:
- `veth-<device>-<network>` (e.g., `veth-pc10`)
- `veth-sw-<device>` for switch side (e.g., `veth-sw10`)

### 2. Clean Up After Testing
Always delete namespaces and interfaces when done:
```bash
sudo ip netns delete pc10
sudo ip link delete br10
```

### 3. Bring Interfaces Up
Don't forget to activate both ends:
```bash
sudo ip link set veth-sw10 up
sudo ip netns exec pc10 ip link set veth-pc10 up
```

### 4. Document Your Topology
Keep a diagram of which veth pairs connect what.

## Summary

**veth pairs** are virtual ethernet cables that:
- Connect network namespaces or devices
- Always come in pairs (two ends)
- Act like physical network cables
- Enable communication between isolated network environments
- Form the foundation of container networking

In your script, they connect:
- PCs to switches (bridges)
- Router to switches
- Creating a complete virtual network topology

## Additional Resources

- [Linux Network Namespaces Documentation](https://man7.org/linux/man-pages/man8/ip-netns.8.html)
- [iproute2 Documentation](https://man7.org/linux/man-pages/man8/ip-link.8.html)
- [Container Networking Deep Dive](https://www.kernel.org/doc/Documentation/networking/veth.txt)

---

**Created**: 2025-11-01  
**Topic**: Linux Networking, Network Namespaces, Virtual Ethernet  
**Skill Level**: Intermediate to Advanced
