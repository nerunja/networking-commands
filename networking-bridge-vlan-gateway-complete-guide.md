# Complete Guide: Bridge, VLAN, and Gateway in Ubuntu Linux

**Author:** Network Specialist  
**Date:** October 31, 2025  
**Version:** 1.0

---

## Table of Contents

1. [Introduction](#introduction)
2. [Differences Between VLAN, Bridge, and Gateway](#differences-between-vlan-bridge-and-gateway)
   - [Bridge Overview](#1-bridge)
   - [VLAN Overview](#2-vlan-virtual-lan)
   - [Gateway Overview](#3-gateway)
   - [Key Differences Summary](#key-differences-summary)
   - [Practical Scenario](#practical-scenario)
   - [Simple Analogies](#simple-analogies)
   - [When to Use Each](#when-to-use-each)
3. [Practical Ubuntu Lab Configurations](#practical-ubuntu-lab-bridge-vlan-and-gateway-configuration)
   - [Lab Environment Setup](#lab-environment-setup)
   - [LAB 1: Bridge Configuration](#lab-1-bridge-configuration)
   - [LAB 2: VLAN Configuration](#lab-2-vlan-configuration)
   - [LAB 3: Gateway Configuration](#lab-3-gateway-configuration)
   - [LAB 4: Complete Integration](#lab-4-complete-integration---bridge--vlan--gateway)
4. [Troubleshooting](#troubleshooting-commands)
5. [Cleanup Scripts](#cleanup-scripts)
6. [Monitoring Tools](#monitoring-and-management-tools)

---

## Introduction

This comprehensive guide covers three fundamental networking concepts in Ubuntu Linux:
- **Bridge**: Layer 2 device connecting network segments
- **VLAN**: Logical network segmentation
- **Gateway**: Layer 3 routing between networks

The guide includes both theoretical explanations and hands-on practical lab configurations that you can implement in your Ubuntu environment.

---

## Differences Between VLAN, Bridge, and Gateway

These are three fundamental networking concepts that operate at different layers of the OSI model and serve different purposes.

---

### **1. Bridge**

#### **What it is:**
- A **Layer 2 (Data Link Layer)** device
- Connects two or more network segments at the MAC address level
- Makes multiple physical networks appear as one logical network

#### **Purpose:**
- Segments network traffic to reduce collisions
- Forwards frames based on MAC addresses
- Filters traffic between network segments
- Extends network reach

#### **How it works:**
```
Network A ←→ [Bridge] ←→ Network B
```
- Learns MAC addresses on each segment
- Forwards frames only to the segment where the destination MAC exists
- Floods unknown MAC addresses to all segments

#### **Ubuntu Example:**
```bash
# Create a bridge
sudo ip link add name br0 type bridge

# Add interfaces to bridge
sudo ip link set eth0 master br0
sudo ip link set eth1 master br0

# Bring bridge up
sudo ip link set br0 up
```

---

### **2. VLAN (Virtual LAN)**

#### **What it is:**
- A **logical segmentation** of a physical network
- Creates separate broadcast domains on the same physical infrastructure
- Works at **Layer 2** but provides logical separation

#### **Purpose:**
- Segment networks without additional hardware
- Improve security by isolating traffic
- Reduce broadcast domains
- Organize networks by function (e.g., departments, guest networks)

#### **How it works:**
```
Physical Switch
├── VLAN 10 (Sales Department)
├── VLAN 20 (IT Department)
└── VLAN 30 (Guest Network)
```
- Traffic in VLAN 10 cannot communicate with VLAN 20 without a router
- Each VLAN is a separate broadcast domain
- Uses VLAN tagging (802.1Q) to identify traffic

#### **Ubuntu Example:**
```bash
# Install VLAN package
sudo apt install vlan

# Load 8021q module
sudo modprobe 8021q

# Create VLAN interface (VLAN ID 10)
sudo ip link add link eth0 name eth0.10 type vlan id 10

# Assign IP to VLAN
sudo ip addr add 192.168.10.1/24 dev eth0.10

# Bring VLAN up
sudo ip link set eth0.10 up
```

---

### **3. Gateway**

#### **What it is:**
- A **Layer 3 (Network Layer)** device
- Routes traffic between different networks
- Typically a router or a device acting as a router

#### **Purpose:**
- Connect networks with different IP ranges
- Route packets between networks
- Provide access to external networks (like the Internet)
- Perform Network Address Translation (NAT)

#### **How it works:**
```
Local Network (192.168.1.0/24) ←→ [Gateway] ←→ Internet
```
- Routes packets based on IP addresses
- Makes routing decisions using routing tables
- Often the "default gateway" for devices on a network

#### **Ubuntu Example:**
```bash
# View current gateway
ip route show

# Add a default gateway
sudo ip route add default via 192.168.1.1

# Set default gateway (persistent)
# Edit /etc/netplan/*.yaml:
network:
  version: 2
  ethernets:
    eth0:
      addresses: [192.168.1.100/24]
      gateway4: 192.168.1.1
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]

# Apply configuration
sudo netplan apply
```

---

### **Key Differences Summary**

| Feature | Bridge | VLAN | Gateway |
|---------|--------|------|---------|
| **OSI Layer** | Layer 2 (Data Link) | Layer 2 (Data Link) | Layer 3 (Network) |
| **Operates on** | MAC addresses | VLAN tags + MAC addresses | IP addresses |
| **Primary Function** | Connect network segments | Logical network segmentation | Route between networks |
| **Scope** | Local network extension | Logical network isolation | Inter-network routing |
| **Broadcast Domain** | Single broadcast domain | Multiple broadcast domains | Separate broadcast domains |
| **Hardware** | Can be hardware or software | Requires VLAN-capable switches | Router or Layer 3 switch |
| **Use Case** | Extend network, connect segments | Segment LAN logically | Connect to Internet/other networks |

---

### **Practical Scenario**

Let's see how they work together in a real network:

```
┌─────────────────────────────────────────────────────┐
│                  Company Network                     │
│                                                      │
│  ┌──────────────┐  ┌──────────────┐                │
│  │   VLAN 10    │  │   VLAN 20    │                │
│  │   (Sales)    │  │   (IT Dept)  │                │
│  │ 192.168.10.0 │  │ 192.168.20.0 │                │
│  └──────┬───────┘  └──────┬───────┘                │
│         │                  │                         │
│         └──────┬───────────┘                         │
│                │                                     │
│         ┌──────▼───────┐                            │
│         │   Bridge     │ (Connects segments)        │
│         │   (br0)      │                            │
│         └──────┬───────┘                            │
│                │                                     │
│         ┌──────▼───────┐                            │
│         │   Gateway    │ (Routes to Internet)       │
│         │ 192.168.1.1  │                            │
│         └──────┬───────┘                            │
│                │                                     │
└────────────────┼─────────────────────────────────────┘
                 │
                 ▼
            [Internet]
```

**In this scenario:**
1. **VLANs** separate Sales and IT departments logically
2. **Bridge** might connect wired and wireless segments within each VLAN
3. **Gateway** routes traffic from both VLANs to the Internet

---

### **Simple Analogies**

- **Bridge**: Like a highway overpass connecting two roads - traffic flows between them, but they're still part of the same city (network)

- **VLAN**: Like separate apartment floors in the same building - shared infrastructure, but residents can't visit other floors without special access

- **Gateway**: Like a city's border crossing - controls traffic going in and out to other cities (networks)

---

### **When to Use Each**

#### **Use a Bridge when:**
- Connecting different physical network segments
- Extending network range
- Connecting VMs to physical networks
- Creating container networks

#### **Use VLANs when:**
- Need to segment network logically
- Improve security between departments
- Reduce broadcast traffic
- Organize network by function without new hardware

#### **Use a Gateway when:**
- Connecting to the Internet
- Routing between different IP subnets
- Connecting branch offices
- Providing NAT services
- Need firewall capabilities

---

## Practical Ubuntu Lab: Bridge, VLAN, and Gateway Configuration

Comprehensive hands-on labs for all three concepts.

---

### **Lab Environment Setup**

#### **Prerequisites**
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install required packages
sudo apt install -y bridge-utils vlan net-tools iproute2 iptables-persistent

# Load required kernel modules
sudo modprobe bridge
sudo modprobe 8021q

# Make modules load on boot
echo "bridge" | sudo tee -a /etc/modules
echo "8021q" | sudo tee -a /etc/modules

# Enable IP forwarding (needed for gateway/routing)
sudo sysctl -w net.ipv4.ip_forward=1

# Make IP forwarding persistent
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
```

---

## LAB 1: Bridge Configuration

### **Scenario 1: Basic Bridge (Connecting Two Network Interfaces)**

This is useful when you want to connect two physical networks or create a VM bridge.

```bash
# Check available interfaces
ip link show

# Example output shows: eth0, eth1, lo
```

#### **Method 1: Using ip commands (temporary)**

```bash
# Create bridge interface
sudo ip link add name br0 type bridge

# Add interfaces to the bridge
sudo ip link set eth0 master br0
sudo ip link set eth1 master br0

# Bring interfaces up
sudo ip link set eth0 up
sudo ip link set eth1 up
sudo ip link set br0 up

# Assign IP to bridge (if needed)
sudo ip addr add 192.168.1.10/24 dev br0

# Verify bridge configuration
ip link show master br0
bridge link show
```

#### **Method 2: Using Netplan (persistent configuration)**

```bash
# Backup existing netplan configuration
sudo cp /etc/netplan/01-netcfg.yaml /etc/netplan/01-netcfg.yaml.backup

# Edit netplan configuration
sudo nano /etc/netplan/01-netcfg.yaml
```

**Configuration file:**
```yaml
network:
  version: 2
  renderer: networkd
  
  ethernets:
    eth0:
      dhcp4: no
    eth1:
      dhcp4: no
  
  bridges:
    br0:
      interfaces:
        - eth0
        - eth1
      dhcp4: no
      addresses:
        - 192.168.1.10/24
      routes:
        - to: default
          via: 192.168.1.1
      nameservers:
        addresses:
          - 8.8.8.8
          - 8.8.4.4
```

```bash
# Test configuration
sudo netplan try

# Apply if successful
sudo netplan apply

# Verify
ip addr show br0
bridge link show
```

### **Scenario 2: Bridge for Virtual Machines (KVM/QEMU)**

```bash
# Install virtualization tools
sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils

# Create VM bridge
sudo nano /etc/netplan/01-netcfg.yaml
```

**Configuration:**
```yaml
network:
  version: 2
  renderer: networkd
  
  ethernets:
    enp0s3:
      dhcp4: no
  
  bridges:
    virbr0:
      interfaces:
        - enp0s3
      dhcp4: yes
      # Or static:
      # addresses: [192.168.100.1/24]
```

```bash
# Apply configuration
sudo netplan apply

# Verify bridge
brctl show
# or
bridge link show
```

### **Scenario 3: Bridge with STP (Spanning Tree Protocol)**

Prevents loops in bridged networks.

```bash
# Create bridge with STP enabled
sudo ip link add name br0 type bridge
sudo ip link set br0 type bridge stp_state 1

# Add interfaces
sudo ip link set eth0 master br0
sudo ip link set eth1 master br0

# Configure STP parameters
sudo ip link set br0 type bridge forward_delay 4
sudo ip link set br0 type bridge hello_time 2
sudo ip link set br0 type bridge max_age 20

# Bring up
sudo ip link set eth0 up
sudo ip link set eth1 up
sudo ip link set br0 up

# Verify STP status
bridge -d link show
cat /sys/class/net/br0/bridge/stp_state
```

### **Bridge Testing and Verification**

```bash
# Show bridge details
bridge link show

# Show MAC address table
bridge fdb show

# Show bridge statistics
ip -s link show br0

# Monitor bridge traffic
sudo tcpdump -i br0 -n

# Test connectivity
ping -I br0 192.168.1.1

# Remove bridge (cleanup)
sudo ip link set eth0 nomaster
sudo ip link set eth1 nomaster
sudo ip link delete br0
```

---

## LAB 2: VLAN Configuration

### **Scenario 1: Single Interface with Multiple VLANs**

Perfect for connecting to a managed switch with VLAN support.

```bash
# Ensure 8021q module is loaded
sudo modprobe 8021q
lsmod | grep 8021q

# Create VLAN interfaces
# VLAN 10 for Sales Department
sudo ip link add link eth0 name eth0.10 type vlan id 10

# VLAN 20 for IT Department
sudo ip link add link eth0 name eth0.20 type vlan id 20

# VLAN 30 for Guest Network
sudo ip link add link eth0 name eth0.30 type vlan id 30

# Assign IP addresses to VLANs
sudo ip addr add 192.168.10.1/24 dev eth0.10
sudo ip addr add 192.168.20.1/24 dev eth0.20
sudo ip addr add 192.168.30.1/24 dev eth0.30

# Bring interfaces up
sudo ip link set eth0 up
sudo ip link set eth0.10 up
sudo ip link set eth0.20 up
sudo ip link set eth0.30 up

# Verify VLAN configuration
ip -d link show | grep vlan
ip addr show | grep "192.168"
```

### **Scenario 2: Persistent VLAN Configuration with Netplan**

```bash
# Edit netplan configuration
sudo nano /etc/netplan/01-netcfg.yaml
```

**Configuration:**
```yaml
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
        - 192.168.10.1/24
    
    vlan20:
      id: 20
      link: eth0
      addresses:
        - 192.168.20.1/24
    
    vlan30:
      id: 30
      link: eth0
      addresses:
        - 192.168.30.1/24
      routes:
        - to: default
          via: 192.168.30.254
```

```bash
# Apply configuration
sudo netplan apply

# Verify
ip -d link show
ip addr show
```

### **Scenario 3: VLAN with DHCP Server**

Setting up DHCP for each VLAN.

```bash
# Install DHCP server
sudo apt install -y isc-dhcp-server

# Configure DHCP server
sudo nano /etc/dhcp/dhcpd.conf
```

**DHCP Configuration:**
```conf
# VLAN 10 - Sales Department
subnet 192.168.10.0 netmask 255.255.255.0 {
    range 192.168.10.100 192.168.10.200;
    option routers 192.168.10.1;
    option subnet-mask 255.255.255.0;
    option domain-name-servers 8.8.8.8, 8.8.4.4;
    default-lease-time 600;
    max-lease-time 7200;
}

# VLAN 20 - IT Department
subnet 192.168.20.0 netmask 255.255.255.0 {
    range 192.168.20.100 192.168.20.200;
    option routers 192.168.20.1;
    option subnet-mask 255.255.255.0;
    option domain-name-servers 8.8.8.8, 8.8.4.4;
    default-lease-time 600;
    max-lease-time 7200;
}

# VLAN 30 - Guest Network
subnet 192.168.30.0 netmask 255.255.255.0 {
    range 192.168.30.100 192.168.30.200;
    option routers 192.168.30.1;
    option subnet-mask 255.255.255.0;
    option domain-name-servers 8.8.8.8;
    default-lease-time 300;
    max-lease-time 3600;
}
```

```bash
# Specify interfaces for DHCP
sudo nano /etc/default/isc-dhcp-server
```

**Add:**
```
INTERFACESv4="vlan10 vlan20 vlan30"
```

```bash
# Restart DHCP service
sudo systemctl restart isc-dhcp-server
sudo systemctl enable isc-dhcp-server

# Check status
sudo systemctl status isc-dhcp-server

# View DHCP leases
cat /var/lib/dhcp/dhcpd.leases
```

### **Scenario 4: Inter-VLAN Routing**

Allow communication between VLANs (router on a stick).

```bash
# Enable IP forwarding (already done in setup)
sudo sysctl -w net.ipv4.ip_forward=1

# No additional routing needed if VLANs are on same machine
# Linux will route between interfaces automatically

# Verify routing table
ip route show

# Test inter-VLAN routing
# From VLAN 10 to VLAN 20
ping -I vlan10 192.168.20.1
```

### **Scenario 5: VLAN with Firewall Rules**

Control traffic between VLANs using iptables.

```bash
# Flush existing rules
sudo iptables -F
sudo iptables -X

# Set default policies
sudo iptables -P INPUT ACCEPT
sudo iptables -P FORWARD DROP
sudo iptables -P OUTPUT ACCEPT

# Allow established connections
sudo iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow VLAN 20 (IT) to access all VLANs
sudo iptables -A FORWARD -i vlan20 -j ACCEPT

# Allow VLAN 10 (Sales) to access only VLAN 20
sudo iptables -A FORWARD -i vlan10 -o vlan20 -j ACCEPT

# Block VLAN 30 (Guest) from accessing other VLANs
sudo iptables -A FORWARD -i vlan30 -o vlan10 -j DROP
sudo iptables -A FORWARD -i vlan30 -o vlan20 -j DROP

# Allow VLAN 30 to access Internet (if gateway configured)
sudo iptables -A FORWARD -i vlan30 -o eth1 -j ACCEPT

# Save rules
sudo netfilter-persistent save

# View rules
sudo iptables -L -v -n
```

### **VLAN Testing and Verification**

```bash
# Show VLAN interfaces
ip -d link show type vlan

# Show VLAN details
cat /proc/net/vlan/config

# Test VLAN tagging with tcpdump
sudo tcpdump -i eth0 -e -n vlan

# Monitor specific VLAN
sudo tcpdump -i vlan10 -n

# Test connectivity between VLANs
ping -c 4 -I vlan10 192.168.20.1

# Check VLAN statistics
ip -s link show vlan10

# Remove VLAN (cleanup)
sudo ip link delete vlan10
sudo ip link delete vlan20
sudo ip link delete vlan30
```

---

## LAB 3: Gateway Configuration

### **Scenario 1: Basic Gateway/Router Setup**

Turn Ubuntu into a router between two networks.

**Network Topology:**
```
Internet (eth0) ←→ [Ubuntu Gateway] ←→ Local Network (eth1)
WAN: 203.0.113.10/24           LAN: 192.168.1.1/24
```

```bash
# Configure WAN interface (eth0)
sudo ip addr add 203.0.113.10/24 dev eth0
sudo ip link set eth0 up

# Configure LAN interface (eth1)
sudo ip addr add 192.168.1.1/24 dev eth1
sudo ip link set eth1 up

# Add default route to Internet
sudo ip route add default via 203.0.113.1 dev eth0

# Verify routing table
ip route show

# Enable IP forwarding (already done)
sudo sysctl -w net.ipv4.ip_forward=1

# Test routing
ping -c 4 8.8.8.8
```

### **Scenario 2: NAT Gateway (Masquerading)**

Allow internal network to access Internet through gateway.

```bash
# Configure NAT using iptables
# Flush existing NAT rules
sudo iptables -t nat -F

# Enable masquerading for outgoing traffic
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# Allow forwarding from LAN to WAN
sudo iptables -A FORWARD -i eth1 -o eth0 -j ACCEPT

# Allow established connections back
sudo iptables -A FORWARD -i eth0 -o eth1 -m state --state ESTABLISHED,RELATED -j ACCEPT

# Save rules
sudo netfilter-persistent save

# Verify NAT rules
sudo iptables -t nat -L -v -n
```

### **Scenario 3: Gateway with Netplan (Persistent)**

```bash
# Edit netplan configuration
sudo nano /etc/netplan/01-netcfg.yaml
```

**Configuration:**
```yaml
network:
  version: 2
  renderer: networkd
  
  ethernets:
    eth0:  # WAN interface
      dhcp4: yes
      # Or static:
      # addresses:
      #   - 203.0.113.10/24
      # routes:
      #   - to: default
      #     via: 203.0.113.1
      nameservers:
        addresses:
          - 8.8.8.8
          - 8.8.4.4
    
    eth1:  # LAN interface
      dhcp4: no
      addresses:
        - 192.168.1.1/24
```

```bash
# Apply configuration
sudo netplan apply

# Verify
ip addr show
ip route show
```

### **Scenario 4: Multi-Network Gateway**

Gateway connecting multiple internal networks.

**Network Topology:**
```
                    [Ubuntu Gateway]
                          |
    ┌─────────────────────┼─────────────────────┐
    |                     |                     |
  eth0 (WAN)          eth1 (LAN1)          eth2 (LAN2)
203.0.113.10/24    192.168.1.1/24      192.168.2.1/24
```

```bash
# Configure interfaces
sudo ip addr add 203.0.113.10/24 dev eth0
sudo ip addr add 192.168.1.1/24 dev eth1
sudo ip addr add 192.168.2.1/24 dev eth2

# Bring interfaces up
sudo ip link set eth0 up
sudo ip link set eth1 up
sudo ip link set eth2 up

# Add default route
sudo ip route add default via 203.0.113.1 dev eth0

# Configure NAT for both LANs
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# Allow forwarding between LANs
sudo iptables -A FORWARD -i eth1 -o eth2 -j ACCEPT
sudo iptables -A FORWARD -i eth2 -o eth1 -j ACCEPT

# Allow forwarding to WAN
sudo iptables -A FORWARD -i eth1 -o eth0 -j ACCEPT
sudo iptables -A FORWARD -i eth2 -o eth0 -j ACCEPT
sudo iptables -A FORWARD -i eth0 -o eth1 -m state --state ESTABLISHED,RELATED -j ACCEPT
sudo iptables -A FORWARD -i eth0 -o eth2 -m state --state ESTABLISHED,RELATED -j ACCEPT

# Save rules
sudo netfilter-persistent save
```

### **Scenario 5: Gateway with Port Forwarding**

Forward external ports to internal servers.

```bash
# Example: Forward port 80 to internal web server
# External IP:80 → 192.168.1.100:80

# Enable port forwarding
sudo iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 80 -j DNAT --to-destination 192.168.1.100:80

# Allow forwarded traffic
sudo iptables -A FORWARD -i eth0 -o eth1 -p tcp --dport 80 -d 192.168.1.100 -j ACCEPT

# Example: Forward SSH to internal server
# External IP:2222 → 192.168.1.100:22
sudo iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 2222 -j DNAT --to-destination 192.168.1.100:22
sudo iptables -A FORWARD -i eth0 -o eth1 -p tcp --dport 22 -d 192.168.1.100 -j ACCEPT

# Example: Forward range of ports
sudo iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 3000:3100 -j DNAT --to-destination 192.168.1.100
sudo iptables -A FORWARD -i eth0 -o eth1 -p tcp --dport 3000:3100 -d 192.168.1.100 -j ACCEPT

# Save rules
sudo netfilter-persistent save

# Verify NAT rules
sudo iptables -t nat -L -v -n --line-numbers
```

### **Scenario 6: Gateway with DMZ**

Create a DMZ (Demilitarized Zone) for public-facing servers.

**Network Topology:**
```
Internet (eth0) ←→ [Gateway] ←→ LAN (eth1)
                       ↓
                   DMZ (eth2)
```

```bash
# Configure DMZ interface
sudo ip addr add 10.0.0.1/24 dev eth2
sudo ip link set eth2 up

# DMZ firewall rules
# Allow DMZ to access Internet
sudo iptables -A FORWARD -i eth2 -o eth0 -j ACCEPT
sudo iptables -A FORWARD -i eth0 -o eth2 -m state --state ESTABLISHED,RELATED -j ACCEPT

# Block DMZ from accessing LAN
sudo iptables -A FORWARD -i eth2 -o eth1 -j DROP

# Allow LAN to access DMZ
sudo iptables -A FORWARD -i eth1 -o eth2 -j ACCEPT

# Allow specific services from Internet to DMZ
# Web server in DMZ
sudo iptables -A FORWARD -i eth0 -o eth2 -p tcp --dport 80 -d 10.0.0.10 -j ACCEPT
sudo iptables -A FORWARD -i eth0 -o eth2 -p tcp --dport 443 -d 10.0.0.10 -j ACCEPT

# NAT for DMZ
sudo iptables -t nat -A POSTROUTING -s 10.0.0.0/24 -o eth0 -j MASQUERADE

# Port forwarding to DMZ web server
sudo iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 80 -j DNAT --to-destination 10.0.0.10:80
sudo iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 443 -j DNAT --to-destination 10.0.0.10:443

# Save rules
sudo netfilter-persistent save
```

### **Scenario 7: Gateway with QoS (Quality of Service)**

Prioritize traffic types.

```bash
# Install traffic control tools
sudo apt install -y iproute2

# Create qdisc for eth1 (LAN interface)
sudo tc qdisc add dev eth1 root handle 1: htb default 30

# Create classes with bandwidth limits
# Class 1:10 - High priority (VoIP, Gaming) - 50% bandwidth
sudo tc class add dev eth1 parent 1: classid 1:10 htb rate 50mbit ceil 100mbit prio 1

# Class 1:20 - Medium priority (Streaming) - 30% bandwidth
sudo tc class add dev eth1 parent 1: classid 1:20 htb rate 30mbit ceil 80mbit prio 2

# Class 1:30 - Low priority (Downloads) - 20% bandwidth
sudo tc class add dev eth1 parent 1: classid 1:30 htb rate 20mbit ceil 50mbit prio 3

# Create filters to classify traffic
# High priority - VoIP (UDP 5060), Gaming (UDP 27015)
sudo tc filter add dev eth1 protocol ip parent 1:0 prio 1 u32 match ip dport 5060 0xffff flowid 1:10
sudo tc filter add dev eth1 protocol ip parent 1:0 prio 1 u32 match ip dport 27015 0xffff flowid 1:10

# Medium priority - HTTP/HTTPS
sudo tc filter add dev eth1 protocol ip parent 1:0 prio 2 u32 match ip dport 80 0xffff flowid 1:20
sudo tc filter add dev eth1 protocol ip parent 1:0 prio 2 u32 match ip dport 443 0xffff flowid 1:20

# View QoS configuration
sudo tc -s qdisc show dev eth1
sudo tc -s class show dev eth1
```

### **Gateway Testing and Verification**

```bash
# Check IP forwarding
cat /proc/sys/net/ipv4/ip_forward

# View routing table
ip route show
route -n

# View NAT rules
sudo iptables -t nat -L -v -n

# View filter rules
sudo iptables -L -v -n

# Test gateway from client
# On client machine:
ip route add default via 192.168.1.1
ping 8.8.8.8

# Monitor gateway traffic
sudo tcpdump -i eth0 -n
sudo tcpdump -i eth1 -n

# Check connection tracking
sudo conntrack -L

# Monitor NAT translations
sudo conntrack -L -o extended | grep SNAT

# Test port forwarding
# From external network:
telnet <gateway-public-ip> 80

# Check gateway performance
sudo iftop -i eth0
sudo nethogs eth0

# View active connections
sudo netstat -tuln
sudo ss -tuln
```

---

## LAB 4: Complete Integration - Bridge + VLAN + Gateway

### **Advanced Scenario: Corporate Network Setup**

**Network Design:**
```
                    Internet
                       |
                   [eth0: WAN]
                       |
                [Ubuntu Gateway]
                       |
                  [br0: Bridge]
                       |
        ┌──────────────┼──────────────┐
        |              |              |
    [VLAN 10]      [VLAN 20]      [VLAN 30]
     Sales          IT Dept         Guest
  192.168.10.0   192.168.20.0   192.168.30.0
```

### **Step 1: Configure Bridge**

```bash
# Create bridge
sudo ip link add name br0 type bridge
sudo ip link set eth1 master br0
sudo ip link set br0 up
sudo ip link set eth1 up
```

### **Step 2: Configure VLANs on Bridge**

```bash
# Create VLAN interfaces on bridge
sudo ip link add link br0 name br0.10 type vlan id 10
sudo ip link add link br0 name br0.20 type vlan id 20
sudo ip link add link br0 name br0.30 type vlan id 30

# Assign IP addresses
sudo ip addr add 192.168.10.1/24 dev br0.10
sudo ip addr add 192.168.20.1/24 dev br0.20
sudo ip addr add 192.168.30.1/24 dev br0.30

# Bring up interfaces
sudo ip link set br0.10 up
sudo ip link set br0.20 up
sudo ip link set br0.30 up
```

### **Step 3: Configure Gateway and NAT**

```bash
# Configure WAN interface
sudo ip addr add dhcp dev eth0  # or static IP
sudo ip link set eth0 up

# Add default route
sudo ip route add default via <ISP-gateway> dev eth0

# Enable NAT for all VLANs
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# Allow forwarding
sudo iptables -A FORWARD -i br0.10 -o eth0 -j ACCEPT
sudo iptables -A FORWARD -i br0.20 -o eth0 -j ACCEPT
sudo iptables -A FORWARD -i br0.30 -o eth0 -j ACCEPT
sudo iptables -A FORWARD -i eth0 -m state --state ESTABLISHED,RELATED -j ACCEPT
```

### **Step 4: Configure DHCP for Each VLAN**

```bash
sudo nano /etc/dhcp/dhcpd.conf
```

**Add all VLAN subnets** (as shown in VLAN Lab Scenario 3)

### **Step 5: Configure Firewall Rules**

```bash
# Allow IT VLAN (20) full access
sudo iptables -A FORWARD -i br0.20 -j ACCEPT

# Restrict Sales VLAN (10)
sudo iptables -A FORWARD -i br0.10 -o br0.20 -p tcp --dport 445 -j ACCEPT  # SMB
sudo iptables -A FORWARD -i br0.10 -o br0.20 -p tcp --dport 3306 -j ACCEPT  # MySQL

# Isolate Guest VLAN (30)
sudo iptables -A FORWARD -i br0.30 -o br0.10 -j DROP
sudo iptables -A FORWARD -i br0.30 -o br0.20 -j DROP

# Save all rules
sudo netfilter-persistent save
```

### **Step 6: Netplan Configuration (Persistent)**

```bash
sudo nano /etc/netplan/01-netcfg.yaml
```

```yaml
network:
  version: 2
  renderer: networkd
  
  ethernets:
    eth0:  # WAN
      dhcp4: yes
    eth1:  # LAN trunk
      dhcp4: no
  
  bridges:
    br0:
      interfaces:
        - eth1
      dhcp4: no
  
  vlans:
    vlan10:
      id: 10
      link: br0
      addresses:
        - 192.168.10.1/24
    
    vlan20:
      id: 20
      link: br0
      addresses:
        - 192.168.20.1/24
    
    vlan30:
      id: 30
      link: br0
      addresses:
        - 192.168.30.1/24
```

```bash
# Apply configuration
sudo netplan apply
```

### **Step 7: Complete Verification**

```bash
# Verify all components
echo "=== Bridge Status ==="
bridge link show

echo "=== VLAN Interfaces ==="
ip -d link show | grep vlan

echo "=== IP Addresses ==="
ip addr show

echo "=== Routing Table ==="
ip route show

echo "=== NAT Rules ==="
sudo iptables -t nat -L -v -n

echo "=== Firewall Rules ==="
sudo iptables -L -v -n

echo "=== DHCP Status ==="
sudo systemctl status isc-dhcp-server

echo "=== Active Connections ==="
sudo ss -tuln
```

---

## Troubleshooting Commands

```bash
# Network diagnostics
sudo ethtool eth0  # Check link status
sudo mii-tool eth0  # Check media status

# DNS testing
nslookup google.com
dig google.com

# Routing diagnostics
traceroute 8.8.8.8
mtr google.com

# Packet capture
sudo tcpdump -i any -n host 192.168.1.100

# Check connectivity
ping -c 4 8.8.8.8
ping -c 4 google.com

# Test NAT
# From internal client, check public IP
curl ifconfig.me

# Monitor logs
sudo tail -f /var/log/syslog
sudo journalctl -u systemd-networkd -f

# Reset network
sudo systemctl restart systemd-networkd
sudo netplan apply
```

---

## Cleanup Scripts

### **Remove Bridge**
```bash
sudo ip link set eth1 nomaster
sudo ip link delete br0
```

### **Remove VLANs**
```bash
sudo ip link delete vlan10
sudo ip link delete vlan20
sudo ip link delete vlan30
```

### **Reset Firewall**
```bash
sudo iptables -F
sudo iptables -X
sudo iptables -t nat -F
sudo iptables -t nat -X
sudo iptables -P INPUT ACCEPT
sudo iptables -P FORWARD ACCEPT
sudo iptables -P OUTPUT ACCEPT
```

### **Reset Netplan**
```bash
sudo rm /etc/netplan/*
sudo nano /etc/netplan/01-netcfg.yaml
# Add basic DHCP configuration
sudo netplan apply
```

---

## Monitoring and Management Tools

```bash
# Install monitoring tools
sudo apt install -y iftop nethogs nload bmon iptraf-ng

# Monitor interface bandwidth
sudo iftop -i eth0

# Monitor per-process bandwidth
sudo nethogs eth0

# Simple bandwidth monitor
nload eth0

# Terminal-based monitoring
bmon

# Advanced IP traffic monitor
sudo iptraf-ng

# Web-based monitoring (optional)
sudo apt install -y netdata
sudo systemctl start netdata
# Access: http://localhost:19999
```

---

## Common Networking Commands Reference

### **Interface Management**
```bash
# Show all interfaces
ip link show
ifconfig -a

# Bring interface up/down
sudo ip link set eth0 up
sudo ip link set eth0 down

# Show IP addresses
ip addr show
ip a

# Add IP address
sudo ip addr add 192.168.1.10/24 dev eth0

# Remove IP address
sudo ip addr del 192.168.1.10/24 dev eth0
```

### **Routing**
```bash
# Show routing table
ip route show
route -n

# Add route
sudo ip route add 10.0.0.0/24 via 192.168.1.1

# Delete route
sudo ip route del 10.0.0.0/24

# Add default gateway
sudo ip route add default via 192.168.1.1
```

### **ARP Table**
```bash
# Show ARP table
ip neigh show
arp -a

# Clear ARP cache
sudo ip neigh flush all
```

### **DNS**
```bash
# Test DNS resolution
nslookup google.com
dig google.com
host google.com

# Check DNS configuration
cat /etc/resolv.conf
```

### **Network Statistics**
```bash
# Show network statistics
netstat -i
ip -s link

# Show listening ports
sudo netstat -tulpn
sudo ss -tulpn

# Show all connections
sudo netstat -tunap
sudo ss -tunap
```

---

## Best Practices and Security Considerations

### **Bridge Security**
1. Enable STP to prevent loops
2. Use port security on physical switches
3. Monitor MAC address table for anomalies
4. Implement VLAN filtering on bridge ports

### **VLAN Security**
1. Use private VLANs for sensitive data
2. Implement strict ACLs between VLANs
3. Disable unused VLANs
4. Use native VLAN sparingly (or not at all)
5. Enable VLAN pruning to reduce broadcast traffic

### **Gateway Security**
1. Enable stateful firewall rules
2. Implement rate limiting to prevent DoS
3. Use fail2ban for brute-force protection
4. Regularly update firewall rules
5. Log and monitor all traffic
6. Implement IDS/IPS (Snort, Suricata)
7. Use strong encryption for VPN connections
8. Disable unnecessary services

### **General Best Practices**
1. Always backup configurations before changes
2. Test in lab environment first
3. Document all network changes
4. Use persistent configurations (netplan)
5. Monitor logs regularly
6. Keep systems updated
7. Implement redundancy where critical
8. Use configuration management tools (Ansible, Puppet)

---

## Additional Resources and Further Reading

### **Official Documentation**
- Ubuntu Networking: https://ubuntu.com/server/docs/network-configuration
- Netplan: https://netplan.io/
- iptables: https://www.netfilter.org/documentation/
- iproute2: https://wiki.linuxfoundation.org/networking/iproute2

### **Books**
- "Linux Network Administrator's Guide" by Tony Bautts
- "TCP/IP Illustrated" by W. Richard Stevens
- "Linux Firewalls" by Steve Suehring
- "Computer Networks" by Andrew Tanenbaum

### **Online Resources**
- Linux networking mailing lists
- Ubuntu Forums: https://ubuntuforums.org/
- Stack Exchange Network Engineering
- Reddit: r/networking, r/linux, r/ubuntu

### **Certifications**
- CompTIA Network+
- Cisco CCNA
- Linux Professional Institute (LPIC-2)
- Red Hat Certified Engineer (RHCE)

---

## Glossary

**802.1Q**: IEEE standard for VLAN tagging on Ethernet networks

**ARP (Address Resolution Protocol)**: Protocol for mapping IP addresses to MAC addresses

**Bridge**: Network device that connects multiple network segments at Layer 2

**Broadcast Domain**: Network segment where broadcast traffic is received by all devices

**DMZ (Demilitarized Zone)**: Network segment for public-facing servers

**DHCP (Dynamic Host Configuration Protocol)**: Protocol for automatic IP address assignment

**Gateway**: Device that routes traffic between different networks

**MTU (Maximum Transmission Unit)**: Largest packet size that can be transmitted

**NAT (Network Address Translation)**: Technique for remapping IP addresses

**Netplan**: Ubuntu's network configuration tool

**OSI Model**: Seven-layer model for network communications

**QoS (Quality of Service)**: Traffic prioritization mechanism

**STP (Spanning Tree Protocol)**: Protocol for preventing network loops

**VLAN (Virtual LAN)**: Logical network segmentation

**VPN (Virtual Private Network)**: Encrypted connection over public networks

---

## Conclusion

This comprehensive guide has covered the fundamental concepts and practical implementations of Bridge, VLAN, and Gateway configurations in Ubuntu Linux. These networking concepts are essential building blocks for creating robust, scalable, and secure network infrastructures.

### **Key Takeaways:**

1. **Bridges** connect network segments at Layer 2, making multiple physical networks appear as one logical network
2. **VLANs** provide logical segmentation without additional hardware, improving security and reducing broadcast traffic
3. **Gateways** route traffic between different networks at Layer 3, enabling Internet connectivity and inter-network communication
4. Combining these technologies enables sophisticated network architectures
5. Proper security and firewall configuration is essential
6. Always test configurations in a lab environment before production deployment

### **Next Steps:**

1. Practice these configurations in a virtual lab environment
2. Explore advanced topics like VXLANs, MPLS, and SD-WAN
3. Learn about network automation using Ansible or Python
4. Study network security in depth (firewalls, IDS/IPS)
5. Consider professional certifications to validate your skills

---

## Document Information

**Version History:**
- v1.0 (October 31, 2025): Initial release

**Author:** Network Specialist  
**Contact:** via Claude AI interface  
**License:** Educational use only

---

**Note:** This guide is intended for educational and lab purposes. Always ensure you have proper authorization before making changes to production networks. The author and distributor assume no liability for any damages resulting from the use of this information.

---

*End of Document*
