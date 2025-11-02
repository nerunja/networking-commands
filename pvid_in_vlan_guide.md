# PVID in VLAN

**PVID** stands for **Port VLAN ID** (also called **Port VLAN Identifier** or **Native VLAN** in Cisco terminology).

## Table of Contents
- [What is PVID?](#what-is-pvid)
- [Key Concepts](#key-concepts)
- [Practical Examples](#practical-examples)
- [Linux Configuration](#linux-configuration-example-ubuntu)
- [Common Use Cases](#common-use-cases)
- [Important Considerations](#important-considerations)
- [Switch Configuration Comparison](#switch-configuration-comparison)
- [Summary](#summary)

---

## What is PVID?

PVID is the VLAN ID assigned to **untagged traffic** entering a switch port. When a frame arrives at a switch port without a VLAN tag (802.1Q tag), the switch automatically assigns it to the VLAN specified by that port's PVID.

---

## Key Concepts

### How PVID Works:

1. **Untagged Ingress Traffic**: When untagged frames enter a port, they are tagged with the port's PVID
2. **Default Assignment**: PVID is typically set to VLAN 1 by default on most switches
3. **Single Assignment**: Each port can have only ONE PVID at a time
4. **Tag Addition**: The switch adds an 802.1Q VLAN tag internally for switching decisions

### PVID vs Tagged VLANs:

```
Port Configuration Example:
- PVID: 10 (untagged traffic goes to VLAN 10)
- Tagged VLANs: 20, 30, 40 (can carry tagged traffic for these VLANs)
```

---

## Practical Examples

### Scenario 1: Access Port

```
Port 1 Configuration:
- PVID: 10
- Mode: Access (untagged)

Result: 
- All traffic from devices on Port 1 → VLAN 10
- Devices don't need VLAN awareness
```

### Scenario 2: Trunk Port

```
Port 2 Configuration:
- PVID: 1 (native VLAN)
- Tagged VLANs: 10, 20, 30
- Mode: Trunk

Result:
- Tagged frames for VLANs 10, 20, 30 → pass through with tags
- Untagged frames → assigned to VLAN 1 (PVID)
```

---

## Linux Configuration Example (Ubuntu)

### Using `bridge` command with VLANs:

```bash
# Create bridge
sudo ip link add name br0 type bridge
sudo ip link set br0 type bridge vlan_filtering 1

# Add interface to bridge
sudo ip link set eth0 master br0

# Set PVID (untagged VLAN)
sudo bridge vlan add dev eth0 vid 10 pvid untagged

# Add tagged VLANs
sudo bridge vlan add dev eth0 vid 20
sudo bridge vlan add dev eth0 vid 30

# View VLAN configuration
sudo bridge vlan show
```

### Configuration file (`/etc/netplan/*.yaml`):

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
      addresses: [192.168.10.1/24]
    vlan20:
      id: 20
      link: eth0
      addresses: [192.168.20.1/24]
```

### Verification Commands:

```bash
# Linux bridge VLANs
sudo bridge vlan show

# Check interface VLAN membership
ip -d link show

# View VLAN interfaces
ip link show type vlan

# Display detailed bridge info
sudo bridge -d link show
```

---

## Common Use Cases

### 1. Access Ports (End devices)
- PVID = assigned VLAN
- All traffic untagged
- Devices don't need VLAN support

**Example:**
```bash
# Configure port for VLAN 10 access
sudo bridge vlan add dev eth0 vid 10 pvid untagged
sudo bridge vlan del dev eth0 vid 1  # Remove default VLAN
```

### 2. Trunk Ports (Switch-to-switch)
- PVID = native/default VLAN (usually VLAN 1)
- Multiple tagged VLANs allowed
- Management traffic often uses PVID

**Example:**
```bash
# Configure trunk port with PVID 1 and tagged VLANs 10, 20, 30
sudo bridge vlan add dev eth1 vid 1 pvid untagged
sudo bridge vlan add dev eth1 vid 10
sudo bridge vlan add dev eth1 vid 20
sudo bridge vlan add dev eth1 vid 30
```

### 3. Hybrid Ports (Mixed traffic)
- PVID for untagged traffic
- Additional tagged VLANs for specific services

**Example:**
```bash
# Hybrid port: PVID 10 for untagged, VLANs 20-30 tagged
sudo bridge vlan add dev eth2 vid 10 pvid untagged
sudo bridge vlan add dev eth2 vid 20
sudo bridge vlan add dev eth2 vid 30
```

---

## Important Considerations

### Security:

- **Native VLAN mismatch** can cause security issues
- Always ensure PVID matches on both ends of trunk links
- Consider using a dedicated unused VLAN as PVID on trunks
- Avoid VLAN hopping attacks by properly configuring PVID

**Security Best Practice:**
```bash
# Use non-default PVID on trunk ports
sudo bridge vlan add dev eth1 vid 999 pvid untagged  # Use unused VLAN
sudo bridge vlan add dev eth1 vid 10
sudo bridge vlan add dev eth1 vid 20
```

### Best Practices:

1. **Document PVID assignments** for all ports
2. **Use consistent PVID on trunk links** (native VLAN)
3. **Avoid using VLAN 1 as PVID** when possible (security)
4. **Disable unused VLANs** on ports
5. **Use VLAN pruning** on trunk ports
6. **Monitor VLAN configurations** regularly
7. **Test changes** in lab environment first

### Common Issues and Solutions:

| Issue | Cause | Solution |
|-------|-------|----------|
| Traffic not reaching VLAN | Wrong PVID set | Verify PVID with `bridge vlan show` |
| Native VLAN mismatch | Different PVID on trunk ends | Match PVID on both sides |
| Untagged traffic dropped | No PVID configured | Add PVID: `bridge vlan add vid X pvid untagged` |
| VLAN hopping | Insecure trunk config | Use non-default native VLAN |

---

## Switch Configuration Comparison

| Vendor | PVID Equivalent | Command Example |
|--------|----------------|-----------------|
| **Generic Linux** | PVID | `bridge vlan add vid 10 pvid untagged` |
| **Cisco** | Native VLAN | `switchport trunk native vlan 10` |
| **HP/Aruba** | Untagged VLAN | `vlan 10 untagged 1` |
| **Juniper** | Native VLAN | `set native-vlan-id 10` |
| **Mikrotik** | PVID | `/interface bridge vlan add pvid=10` |
| **Dell** | Native VLAN | `switchport trunk native vlan 10` |

### Cisco IOS Example:

```cisco
interface GigabitEthernet0/1
 description Access Port - VLAN 10
 switchport mode access
 switchport access vlan 10
 spanning-tree portfast

interface GigabitEthernet0/2
 description Trunk Port - Native VLAN 999
 switchport trunk encapsulation dot1q
 switchport mode trunk
 switchport trunk native vlan 999
 switchport trunk allowed vlan 10,20,30
```

### HP/Aruba Example:

```
vlan 10
  name "Data VLAN"
  untagged 1-24
  tagged 25-26
vlan 20
  name "Voice VLAN"
  tagged 1-26
```

---

## Advanced Configuration Examples

### Linux Bridge VLAN Filtering

```bash
#!/bin/bash
# Complete VLAN bridge setup script

# Create bridge with VLAN filtering
sudo ip link add name br0 type bridge
sudo ip link set br0 type bridge vlan_filtering 1
sudo ip link set br0 up

# Configure access ports (eth0-eth3) - VLAN 10
for i in {0..3}; do
  sudo ip link set eth$i master br0
  sudo ip link set eth$i up
  sudo bridge vlan del dev eth$i vid 1  # Remove default
  sudo bridge vlan add dev eth$i vid 10 pvid untagged
done

# Configure trunk port (eth4)
sudo ip link set eth4 master br0
sudo ip link set eth4 up
sudo bridge vlan add dev eth4 vid 999 pvid untagged  # Native VLAN
sudo bridge vlan add dev eth4 vid 10
sudo bridge vlan add dev eth4 vid 20
sudo bridge vlan add dev eth4 vid 30

# Configure bridge itself
sudo bridge vlan add dev br0 vid 999 pvid untagged self
sudo bridge vlan add dev br0 vid 10 self
sudo bridge vlan add dev br0 vid 20 self
sudo bridge vlan add dev br0 vid 30 self

# Show configuration
sudo bridge vlan show
```

### Netplan Configuration with Multiple VLANs

```yaml
network:
  version: 2
  renderer: networkd
  
  ethernets:
    eth0:
      dhcp4: no
      dhcp6: no
    
  vlans:
    # Management VLAN
    vlan10:
      id: 10
      link: eth0
      addresses:
        - 192.168.10.1/24
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
      routes:
        - to: 0.0.0.0/0
          via: 192.168.10.254
    
    # Data VLAN
    vlan20:
      id: 20
      link: eth0
      addresses:
        - 192.168.20.1/24
    
    # Voice VLAN
    vlan30:
      id: 30
      link: eth0
      addresses:
        - 192.168.30.1/24
```

Apply with: `sudo netplan apply`

---

## Troubleshooting Guide

### Check VLAN Configuration

```bash
# View all VLAN assignments
sudo bridge vlan show

# Check specific interface
sudo bridge vlan show dev eth0

# View detailed link information
ip -d link show

# Check VLAN interfaces
ip link show type vlan

# Display bridge details
sudo bridge -d link show
```

### Test VLAN Connectivity

```bash
# Create test VLAN interface
sudo ip link add link eth0 name eth0.10 type vlan id 10
sudo ip addr add 192.168.10.2/24 dev eth0.10
sudo ip link set eth0.10 up

# Ping through VLAN
ping -I eth0.10 192.168.10.1

# Capture VLAN traffic
sudo tcpdump -i eth0 -e -n vlan 10

# Remove test interface
sudo ip link del eth0.10
```

### Common Debug Commands

```bash
# Enable bridge debugging
echo 1 | sudo tee /sys/class/net/br0/bridge/multicast_snooping

# View bridge forwarding database
sudo bridge fdb show

# Check bridge multicast status
sudo bridge mdb show

# Monitor bridge events
sudo bridge monitor
```

---

## Summary

**PVID is essential for:**
- ✅ Assigning untagged traffic to specific VLANs
- ✅ Enabling non-VLAN-aware devices to communicate
- ✅ Defining default VLAN behavior on switch ports
- ✅ Proper trunk link configuration between switches

**Key Takeaways:**
1. Every port has exactly **one PVID**
2. PVID determines which VLAN **untagged frames** belong to
3. Trunk ports use PVID for **native/default VLAN**
4. Access ports typically have PVID = assigned VLAN
5. **Security**: Use non-default PVID on trunk ports

The PVID ensures that even devices without VLAN tagging capability can be properly segmented into VLANs through switch port configuration.

---

## Quick Reference Card

```
┌─────────────────────────────────────────────────────────┐
│  PVID Quick Reference                                   │
├─────────────────────────────────────────────────────────┤
│  Add PVID:                                              │
│  sudo bridge vlan add dev eth0 vid 10 pvid untagged    │
│                                                         │
│  Add tagged VLAN:                                       │
│  sudo bridge vlan add dev eth0 vid 20                  │
│                                                         │
│  Delete VLAN:                                           │
│  sudo bridge vlan del dev eth0 vid 1                   │
│                                                         │
│  Show configuration:                                    │
│  sudo bridge vlan show                                  │
│                                                         │
│  Default PVID: 1                                        │
│  Range: 1-4094 (4095 reserved)                         │
└─────────────────────────────────────────────────────────┘
```

---

## Additional Resources

### Documentation
- [IEEE 802.1Q Standard](https://standards.ieee.org/standard/802_1Q-2018.html)
- [Linux Bridge VLAN Documentation](https://www.kernel.org/doc/Documentation/networking/switchdev.txt)
- [ip-link man page](https://man7.org/linux/man-pages/man8/ip-link.8.html)
- [bridge man page](https://man7.org/linux/man-pages/man8/bridge.8.html)

### Tools
- `bridge` - Show/manipulate bridge addresses and devices
- `ip` - Show/manipulate routing, devices, policy routing
- `tcpdump` - Dump traffic on a network
- `wireshark` - Network protocol analyzer

### Related Topics
- 802.1Q VLAN Tagging
- Switch Port Modes (Access, Trunk, Hybrid)
- VLAN Trunking Protocol (VTP)
- Inter-VLAN Routing
- VLAN Security Best Practices

---

**Created:** 2025-11-02  
**Format:** GitHub Flavored Markdown (GFM)  
**License:** Free to use for educational purposes
