# Differences Between Switch, Bridge, and Router

## Overview Comparison

| Feature | Bridge | Switch | Router |
|---------|--------|--------|--------|
| **OSI Layer** | Layer 2 (Data Link) | Layer 2 (Data Link) | Layer 3 (Network) |
| **Decision Based On** | MAC addresses | MAC addresses | IP addresses |
| **Ports** | Typically 2-4 | Many (8-48+) | Typically 2-8 |
| **Speed** | Slower | Fast (hardware-based) | Moderate to Fast |
| **Broadcast Domain** | Same domain | Same domain | Separates domains |
| **Purpose** | Connect segments | Connect devices in LAN | Connect different networks |

---

## Bridge

### What It Is
A **bridge** connects two or more network segments at the Data Link Layer (Layer 2), making them appear as a single network.

### Key Characteristics
- **Software-based** decision making (originally)
- Maintains a **MAC address table**
- Forwards frames based on MAC addresses
- Reduces collisions by dividing collision domains
- All ports share the same bandwidth
- Typically has **2-4 ports**

### How It Works
```
1. Receives frame on one port
2. Reads destination MAC address
3. Looks up MAC in forwarding table
4. Forwards only to destination port (if known)
5. Floods to all ports if destination unknown
```

### Use Cases
- Connecting two network segments
- Extending network range
- Reducing traffic on busy segments
- Legacy device (mostly replaced by switches)

---

## Switch

### What It Is
A **switch** is essentially a "multiport bridge" with hardware-based forwarding, connecting multiple devices within a LAN.

### Key Characteristics
- **Hardware-based** (ASIC chips for fast forwarding)
- Maintains MAC address table (CAM table)
- Each port is a separate collision domain
- **Full-duplex** communication possible
- Dedicated bandwidth per port
- Many ports (typically 8, 16, 24, 48+)
- Much faster than bridges

### How It Works
```
1. Receives frame on ingress port
2. Reads source MAC → learns/updates MAC table
3. Reads destination MAC
4. Looks up in MAC table
5. Forwards to specific egress port (unicast)
6. Floods to all ports (except source) if unknown
```

### Types of Switches
- **Unmanaged**: Plug-and-play, no configuration
- **Managed**: Configurable (VLANs, QoS, port mirroring)
- **Layer 3 Switch**: Can route between VLANs

### Use Cases
- Building local area networks (LANs)
- Connecting computers, printers, servers
- Creating VLANs (managed switches)
- High-performance office networks

---

## Router

### What It Is
A **router** connects different networks at the Network Layer (Layer 3), routing packets between them based on IP addresses.

### Key Characteristics
- Works at **Layer 3** (Network Layer)
- Uses **IP addresses** for routing decisions
- Maintains **routing tables**
- **Separates broadcast domains**
- Connects different networks (LAN to LAN, LAN to WAN)
- Performs **NAT** (Network Address Translation)
- Provides security/firewall features
- Can connect different network types

### How It Works
```
1. Receives packet on one interface
2. Reads destination IP address
3. Consults routing table
4. Determines best path/next hop
5. Decrements TTL (Time To Live)
6. Recalculates checksum
7. Forwards to appropriate interface
8. May perform NAT if needed
```

### Routing Table Example
```
Destination     Gateway         Interface   Metric
192.168.1.0/24  0.0.0.0        eth0        0
10.0.0.0/8      192.168.1.1    eth0        10
0.0.0.0/0       203.0.113.1    eth1        0  (default route)
```

### Use Cases
- Connecting LAN to Internet (ISP)
- Connecting multiple office locations
- Connecting different subnets
- Inter-VLAN routing
- Providing internet access
- VPN connections

---

## Key Differences Explained

### 1. **OSI Layer Operation**

**Bridge/Switch (Layer 2):**
```
Only see: [MAC addresses]
Frame: [Dest MAC | Source MAC | Data | FCS]
```

**Router (Layer 3):**
```
See: [IP addresses]
Packet: [Dest IP | Source IP | Protocol | Data]
```

### 2. **Addressing**

| Device | Uses | Example |
|--------|------|---------|
| Bridge | MAC addresses | `00:1A:2B:3C:4D:5E` |
| Switch | MAC addresses | `00:1A:2B:3C:4D:5E` |
| Router | IP addresses | `192.168.1.1` |

### 3. **Broadcast Behavior**

**Switches and Bridges:**
- Forward broadcast frames to **all ports** (except source)
- All connected devices in **same broadcast domain**
```
PC1 sends broadcast → Switch floods to all ports
```

**Routers:**
- **Block broadcasts** by default
- Each interface is a **separate broadcast domain**
```
PC1 sends broadcast → Router stops it (doesn't forward)
```

### 4. **Collision and Broadcast Domains**

```
BRIDGE:
[PC1]--\
        [Bridge]--[Segment 2 with multiple PCs]
[PC2]--/
- 2 collision domains
- 1 broadcast domain

SWITCH:
[PC1]---[Port 1]
[PC2]---[Port 2]  [Switch]
[PC3]---[Port 3]
[PC4]---[Port 4]
- 4 collision domains (one per port)
- 1 broadcast domain

ROUTER:
[Network 192.168.1.0/24]---[Port 1] [Router] [Port 2]---[Network 10.0.0.0/24]
- Multiple collision domains
- 2 broadcast domains (one per network)
```

---

## When to Use Each Device

### Use a **Bridge** When:
- Connecting two similar network segments
- Need simple connectivity (legacy systems)
- Cost is a major factor
- *Note: Bridges are largely obsolete; use switches instead*

### Use a **Switch** When:
- Building a LAN
- Connecting multiple devices in same network
- Need high-speed connectivity
- Want to reduce collisions
- Need VLANs (managed switch)
- Devices are in same IP subnet

### Use a **Router** When:
- Connecting to the Internet
- Connecting different networks/subnets
- Need security/firewall features
- Need NAT for private IP addresses
- Inter-VLAN routing required
- Connecting branch offices
- Need traffic control between networks

---

## Modern Network Architecture

### Typical Home/Small Office:
```
[Internet] ← WAN connection
    |
[Router] ← Layer 3 (routing, NAT, firewall)
    |
[Switch] ← Layer 2 (connecting local devices)
    |
[PC1] [PC2] [PC3] [Printer]
```

### Enterprise Network:
```
[Internet]
    |
[Edge Router] ← Border routing, security
    |
[Core Switch] ← Layer 3 switching, fast routing
    |
[Distribution Switches] ← Layer 2/3, VLANs
    |
[Access Switches] ← Layer 2, end-user connections
    |
[End Devices]
```

---

## Technical Deep Dive

### MAC Address Table (Switch/Bridge)

**Example MAC Table:**
```
Port    MAC Address         Age
1       00:11:22:33:44:55   30 sec
2       AA:BB:CC:DD:EE:FF   45 sec
3       11:22:33:44:55:66   10 sec
```

**Learning Process:**
1. Frame arrives on port 2 with source MAC `AA:BB:CC:DD:EE:FF`
2. Switch learns: "Device with MAC AA:BB:CC:DD:EE:FF is on port 2"
3. Entry added/updated in MAC table with timestamp
4. Entries age out (typically 300 seconds) if no traffic seen

### Routing Table (Router)

**Example Routing Table:**
```
Destination     Netmask         Gateway         Interface   Metric
192.168.1.0     255.255.255.0   0.0.0.0        eth0        0
10.0.0.0        255.0.0.0       192.168.1.1    eth0        10
172.16.0.0      255.255.0.0     192.168.1.254  eth0        5
0.0.0.0         0.0.0.0         203.0.113.1    eth1        0
```

**Routing Decision Process:**
1. Packet arrives with destination IP `10.5.3.100`
2. Router checks routing table for longest prefix match
3. Matches `10.0.0.0/8` route
4. Next hop: `192.168.1.1` via `eth0`
5. Router forwards packet to next hop

---

## Performance Comparison

### Throughput

| Device Type | Typical Throughput | Latency |
|-------------|-------------------|---------|
| Bridge | 100 Mbps - 1 Gbps | 50-100 μs |
| Switch | 1 Gbps - 100 Gbps | 5-20 μs |
| Router | 100 Mbps - 40 Gbps | 50-500 μs |

### Processing Method

**Bridge:**
- Software-based frame processing
- Slower decision making
- Limited scalability

**Switch:**
- ASIC (Application-Specific Integrated Circuit)
- Hardware-based forwarding
- Wire-speed performance
- Highly scalable

**Router:**
- Software or hardware-based (modern routers use ASICs)
- More complex processing (routing algorithms)
- Higher latency due to Layer 3 operations
- Advanced features (NAT, ACLs, QoS)

---

## VLAN Considerations

### Switch with VLANs

**Configuration Example:**
```
VLAN 10: Sales Department    → Ports 1-8
VLAN 20: Engineering         → Ports 9-16
VLAN 30: Management          → Ports 17-24
```

**Benefits:**
- Logical network segmentation
- Separate broadcast domains within one switch
- Enhanced security
- Reduced broadcast traffic

**Limitation:**
- Cannot communicate between VLANs without a router or Layer 3 switch

### Inter-VLAN Routing

**Router-on-a-Stick:**
```
[Switch with VLANs] ---trunk---> [Router] ---trunk---> [Switch]
     |                             |
   VLAN 10                    Subinterfaces:
   VLAN 20                    eth0.10 (VLAN 10)
   VLAN 30                    eth0.20 (VLAN 20)
                              eth0.30 (VLAN 30)
```

**Layer 3 Switch:**
- Combines switching and routing
- Routes between VLANs at wire speed
- More efficient than router-on-a-stick

---

## Security Aspects

### Bridge Security
- Minimal security features
- Transparent to higher layers
- Can be configured to filter MAC addresses

### Switch Security Features
- **Port security**: Limit MAC addresses per port
- **DHCP snooping**: Prevent rogue DHCP servers
- **Dynamic ARP Inspection**: Prevent ARP spoofing
- **Private VLANs**: Isolate ports
- **802.1X**: Port-based authentication

### Router Security Features
- **Access Control Lists (ACLs)**: Filter traffic
- **Firewall**: Stateful packet inspection
- **NAT**: Hide internal IP addresses
- **VPN**: Secure remote access
- **Intrusion Prevention**: Detect/block attacks
- **DMZ**: Isolate public-facing servers

---

## Practical Examples

### Example 1: Small Office Network

**Scenario:** 10 computers, 2 printers, internet connection

**Solution:**
```
[Internet]
    |
[Router] (NAT, DHCP, Firewall)
    |
[8-port Switch]
    |
[PC1] [PC2] [PC3] [PC4] [PC5] [Printer1] [Printer2]
```

**Why this setup:**
- Router provides internet access and security
- Switch connects local devices efficiently
- All devices in same subnet (e.g., 192.168.1.0/24)

### Example 2: Multi-Department Office

**Scenario:** 50 users across 3 departments, need separation

**Solution:**
```
[Internet]
    |
[Firewall/Router]
    |
[Layer 3 Core Switch]
    |
[Access Switch 1]  [Access Switch 2]  [Access Switch 3]
        |                  |                  |
   Sales VLAN         Eng VLAN          Admin VLAN
   (VLAN 10)          (VLAN 20)         (VLAN 30)
```

**Why this setup:**
- VLANs provide logical separation
- Layer 3 switch routes between VLANs
- Access switches connect end devices
- Security policies enforced at Layer 3

### Example 3: Remote Office Connection

**Scenario:** Connect branch office to headquarters

**Solution:**
```
[HQ Network] --- [Router] === VPN Tunnel === [Router] --- [Branch Network]
   192.168.1.0/24                                          192.168.2.0/24
```

**Why this setup:**
- Different subnets require routing
- VPN provides secure connection over internet
- Routers handle routing between networks

---

## Troubleshooting Guide

### Switch Issues

**Problem:** Devices can't communicate
```bash
# Check MAC address table
show mac address-table

# Check port status
show interface status

# Check for port security violations
show port-security
```

**Problem:** Broadcast storm
```bash
# Enable spanning-tree protocol
spanning-tree mode rapid-pvst

# Check for loops
show spanning-tree
```

### Router Issues

**Problem:** Can't reach other networks
```bash
# Check routing table
ip route show
# or on Cisco
show ip route

# Check interface status
ip link show
# or
show interface brief

# Test connectivity
ping <destination>
traceroute <destination>
```

**Problem:** NAT not working
```bash
# Check NAT translations
iptables -t nat -L -v
# or on Cisco
show ip nat translations

# Verify NAT rules
iptables -t nat -L -n -v
```

---

## Command Reference

### Linux Bridge Commands

```bash
# Install bridge utilities
sudo apt install bridge-utils

# Create bridge
sudo brctl addbr br0

# Add interface to bridge
sudo brctl addif br0 eth0

# Show bridge info
brctl show

# Show MAC table
brctl showmacs br0

# Delete bridge
sudo brctl delbr br0
```

### Linux Switch/VLAN Commands

```bash
# Install VLAN support
sudo apt install vlan

# Load 8021q module
sudo modprobe 8021q

# Create VLAN interface
sudo ip link add link eth0 name eth0.10 type vlan id 10

# Bring up VLAN interface
sudo ip link set eth0.10 up

# Show VLAN configuration
cat /proc/net/vlan/config
```

### Linux Router Commands

```bash
# Enable IP forwarding
sudo sysctl -w net.ipv4.ip_forward=1

# Make permanent
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf

# Add static route
sudo ip route add 10.0.0.0/8 via 192.168.1.1

# Show routing table
ip route show
# or
route -n

# Add NAT rule (masquerading)
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# Save iptables rules
sudo iptables-save | sudo tee /etc/iptables/rules.v4
```

---

## Summary Table

| Aspect | Bridge | Switch | Router |
|--------|--------|--------|--------|
| **Layer** | 2 | 2 | 3 |
| **Addressing** | MAC | MAC | IP |
| **Ports** | 2-4 | 8-48+ | 2-8 |
| **Speed** | Slow | Very Fast | Fast |
| **Intelligence** | Low | Medium | High |
| **Broadcast** | Forwards | Forwards | Blocks |
| **Collision Domains** | Reduces | Each port | Each interface |
| **Broadcast Domains** | 1 | 1 (or VLANs) | Separates |
| **Cost** | Low | Low-Medium | Medium-High |
| **Use Case** | Legacy | LAN | Inter-network |
| **Configuration** | Simple | Medium | Complex |
| **Security** | Minimal | Medium | High |

---

## Key Takeaways

1. **Bridges** are legacy devices, mostly replaced by switches
2. **Switches** are the backbone of modern LANs, providing fast Layer 2 connectivity
3. **Routers** connect different networks and provide Layer 3 intelligence
4. **Layer 3 switches** blur the line between switches and routers
5. Modern networks use a combination of switches and routers
6. Choose based on your needs:
   - Same network? → **Switch**
   - Different networks? → **Router**
   - VLANs with routing? → **Layer 3 Switch**

---

## Additional Resources

### Documentation
- [IEEE 802.1D - MAC Bridges](https://www.ieee802.org/1/pages/802.1D.html)
- [IEEE 802.1Q - VLANs](https://www.ieee802.org/1/pages/802.1Q.html)
- [RFC 791 - Internet Protocol](https://tools.ietf.org/html/rfc791)
- [Cisco Networking Basics](https://www.cisco.com/c/en/us/support/index.html)

### Tools for Testing
- **Wireshark**: Network protocol analyzer
- **tcpdump**: Command-line packet analyzer
- **iperf3**: Network bandwidth testing
- **Nmap**: Network discovery and security auditing
- **Bettercap**: Network attack and monitoring

### Books
- "Computer Networking: A Top-Down Approach" by Kurose and Ross
- "Interconnections: Bridges, Routers, Switches, and Internetworking Protocols" by Radia Perlman
- "TCP/IP Illustrated" by W. Richard Stevens

---

## Glossary

- **ASIC**: Application-Specific Integrated Circuit - hardware chip for fast packet processing
- **CAM**: Content Addressable Memory - fast memory for MAC address lookup
- **NAT**: Network Address Translation - translates private IPs to public IPs
- **VLAN**: Virtual Local Area Network - logical network segmentation
- **STP**: Spanning Tree Protocol - prevents loops in switched networks
- **ACL**: Access Control List - rules for filtering traffic
- **MAC**: Media Access Control - physical address of network interface
- **TTL**: Time To Live - hop limit for packets
- **MTU**: Maximum Transmission Unit - largest packet size
- **Broadcast Domain**: Set of devices that receive broadcast frames
- **Collision Domain**: Network segment where collisions can occur

---

*Document created for networking education purposes. Understanding the differences between these devices is fundamental to network design and troubleshooting.*
