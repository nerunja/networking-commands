# VLAN Network Namespace Scripts

A collection of shell scripts for creating, testing, and managing VLAN-based network topologies using Linux network namespaces.

## 📁 Files Included

| File | Description |
|------|-------------|
| `vlan-aware-bridge-setup.sh` | Creates a VLAN-aware bridge topology (recommended) |
| `separate-bridges-setup.sh` | Creates separate bridges per VLAN (simpler alternative) |
| `network-test.sh` | Comprehensive network testing and verification |
| `advanced-diagnostics.sh` | Deep troubleshooting with packet captures |
| `cleanup.sh` | Removes all network namespaces and bridges |
| `vlan-networking-troubleshooting-guide.md` | Complete documentation |

## 🚀 Quick Start

### Step 1: Make Scripts Executable

```bash
chmod +x *.sh
```

### Step 2: Choose Your Setup Method

#### Option A: VLAN-Aware Bridge (Recommended)
```bash
sudo ./vlan-aware-bridge-setup.sh
```

**Features:**
- Single bridge with VLAN filtering
- Simulates real enterprise switch behavior
- Trunk port with VLAN tagging
- More realistic network topology

#### Option B: Separate Bridges
```bash
sudo ./separate-bridges-setup.sh
```

**Features:**
- One bridge per VLAN
- Simpler configuration
- Easier to understand
- Good for learning

### Step 3: Verify Setup

```bash
sudo ./network-test.sh
```

This will run comprehensive tests and show you a detailed report.

### Step 4: Clean Up When Done

```bash
sudo ./cleanup.sh
```

## 📊 Network Topology

### VLAN-Aware Bridge Topology
```
┌─────────────────────────────────────────────────────────────┐
│  PC10 (192.168.10.10) ─┐                                   │
│         VLAN 10         ├─→ VLAN-aware Bridge ─→ Router    │
│  PC20 (192.168.20.20) ─┘      (br0)           (forwards)   │
└─────────────────────────────────────────────────────────────┘
```

### Separate Bridges Topology
```
┌─────────────────────────────────────────────────────────────┐
│  PC10 (192.168.10.10) ── br10 ── Router (inter-VLAN)       │
│  PC20 (192.168.20.20) ── br20 ── Router (routing)          │
└─────────────────────────────────────────────────────────────┘
```

## 📖 Script Details

### 1. vlan-aware-bridge-setup.sh

**Purpose:** Create a production-like VLAN network with proper tagging

**What it does:**
- Creates 3 network namespaces (pc10, pc20, router)
- Sets up virtual ethernet pairs
- Creates VLAN-aware bridge with filtering enabled
- Configures access ports (untagged) for PCs
- Configures trunk port (tagged) for router
- Creates VLAN sub-interfaces on router
- Enables IP forwarding for inter-VLAN routing
- Runs basic connectivity tests

**Usage:**
```bash
sudo ./vlan-aware-bridge-setup.sh
```

**Expected Output:**
```
✅ Setup Complete!
✅ PC10 can reach router (192.168.10.1)
✅ PC20 can reach router (192.168.20.1)
✅ PC10 can reach PC20 via router
✅ PC20 can reach PC10 via router
```

---

### 2. separate-bridges-setup.sh

**Purpose:** Create a simpler VLAN network using separate bridges

**What it does:**
- Creates 3 network namespaces
- Sets up virtual ethernet pairs
- Creates two separate bridges (br10, br20)
- Connects PCs and router to respective bridges
- Enables IP forwarding for inter-VLAN routing
- Runs basic connectivity tests

**Usage:**
```bash
sudo ./separate-bridges-setup.sh
```

**When to use:**
- Learning VLAN concepts
- Simpler troubleshooting
- Don't need realistic VLAN tagging

---

### 3. network-test.sh

**Purpose:** Comprehensive network verification and testing

**What it does:**
- Verifies namespace existence
- Checks bridge configuration
- Validates VLAN settings
- Tests interface status
- Verifies routing configuration
- Tests connectivity (intra-VLAN and inter-VLAN)
- Checks ARP tables
- Runs traceroute tests
- Shows traffic statistics
- Provides detailed pass/fail report

**Usage:**
```bash
sudo ./network-test.sh
```

**Output includes:**
- ✅ Passed tests in green
- ❌ Failed tests in red
- ⚠️  Warnings in yellow
- Detailed diagnostic information
- Summary with total pass/fail count

**Example:**
```
═══════════════════════════════════════════════════════════
  Network Verification and Testing Suite
═══════════════════════════════════════════════════════════

━━━ 1. Network Namespace Verification ━━━
→ Checking if namespaces exist...
✅ PASS: Namespace 'pc10' exists
✅ PASS: Namespace 'pc20' exists
✅ PASS: Namespace 'router' exists
...

Total Tests:   15
Passed:        15
Failed:        0
Warnings:      0

✅ ALL TESTS PASSED - Network is fully operational!
```

---

### 4. advanced-diagnostics.sh

**Purpose:** Deep troubleshooting with packet captures and analysis

**What it does:**
- Shows system information
- Maps complete network topology
- Analyzes all interfaces in detail
- Shows traffic statistics
- Tests ARP resolution
- Captures live packets (10 seconds)
- Analyzes packet captures
- Tests connectivity matrix
- Checks firewall rules
- Provides recommendations
- Saves packet captures to files

**Usage:**
```bash
sudo ./advanced-diagnostics.sh
```

**Features:**
- Saves packet captures to `/tmp/vlan-diagnostics-<timestamp>/`
- Creates .pcap files for analysis
- Shows quick packet statistics
- Tests all connectivity paths
- Identifies common issues
- Provides fix suggestions

**Analyze captures:**
```bash
# View capture with tcpdump
sudo tcpdump -r /tmp/vlan-diagnostics-*/br0.pcap -n -e

# Open in Wireshark (if installed)
wireshark /tmp/vlan-diagnostics-*/br0.pcap
```

---

### 5. cleanup.sh

**Purpose:** Complete removal of all network configurations

**What it does:**
- Removes all created namespaces
- Deletes all bridges (br0, br10, br20)
- Removes virtual ethernet pairs
- Verifies cleanup completion
- Shows remaining resources (if any)

**Usage:**
```bash
sudo ./cleanup.sh
```

**Safety features:**
- Asks for confirmation before proceeding
- Shows what will be removed
- Provides verification after cleanup
- Lists any remaining resources

**Example:**
```bash
$ sudo ./cleanup.sh
This will remove ALL network namespaces and bridges. Continue? [y/N]: y

✅ Removed namespace: pc10
✅ Removed namespace: pc20
✅ Removed namespace: router
✅ Removed bridge: br0
✅ All target interfaces removed

✅ Cleanup completed successfully!
```

## 🔍 Common Use Cases

### Use Case 1: Learning VLANs

```bash
# Setup
sudo ./vlan-aware-bridge-setup.sh

# Explore
sudo ip netns exec pc10 bash       # Enter PC10
ping 192.168.10.1                  # Test gateway
ping 192.168.20.20                 # Test inter-VLAN
exit

# Learn about VLAN config
sudo bridge vlan show

# Cleanup
sudo ./cleanup.sh
```

### Use Case 2: Testing Network Tools

```bash
# Setup
sudo ./vlan-aware-bridge-setup.sh

# Test nmap from PC10
sudo ip netns exec pc10 nmap -sn 192.168.20.0/24

# Test traceroute
sudo ip netns exec pc10 traceroute 192.168.20.20

# Cleanup
sudo ./cleanup.sh
```

### Use Case 3: Troubleshooting Practice

```bash
# Setup
sudo ./vlan-aware-bridge-setup.sh

# Intentionally break something
sudo ip netns exec router sysctl -w net.ipv4.ip_forward=0

# Run diagnostics
sudo ./network-test.sh              # Will show failures
sudo ./advanced-diagnostics.sh      # Deep analysis

# Fix and verify
sudo ip netns exec router sysctl -w net.ipv4.ip_forward=1
sudo ./network-test.sh              # Should pass now
```

### Use Case 4: Packet Analysis

```bash
# Setup
sudo ./vlan-aware-bridge-setup.sh

# Run diagnostics with captures
sudo ./advanced-diagnostics.sh

# Analyze captures
CAPTURE_DIR=$(ls -td /tmp/vlan-diagnostics-* | head -1)
sudo tcpdump -r $CAPTURE_DIR/br0.pcap -n -e vlan
```

## 🛠️ Manual Commands

### Enter a Namespace
```bash
sudo ip netns exec pc10 bash
# Now you're "inside" PC10
# All commands run in PC10's network
exit  # to leave
```

### Test Connectivity
```bash
# From PC10 to router
sudo ip netns exec pc10 ping -c 3 192.168.10.1

# From PC10 to PC20 (inter-VLAN)
sudo ip netns exec pc10 ping -c 3 192.168.20.20
```

### View Configuration
```bash
# Show VLAN configuration
sudo bridge vlan show

# Show interfaces in namespace
sudo ip netns exec pc10 ip addr show

# Show routing table
sudo ip netns exec router ip route

# Show ARP table
sudo ip netns exec pc10 ip neigh
```

### Packet Capture
```bash
# Capture on bridge
sudo tcpdump -i br0 -n -e

# Capture in namespace
sudo ip netns exec pc10 tcpdump -i veth-pc10 -n

# Capture with VLAN tags visible
sudo tcpdump -i veth-trunk -n -e vlan
```

## 🐛 Troubleshooting

### Problem: "Destination Host Unreachable"

**Solution 1:** Check VLAN filtering
```bash
sudo ip -d link show br0 | grep vlan_filtering
# Should show: vlan_filtering 1
```

**Solution 2:** Check IP forwarding
```bash
sudo ip netns exec router sysctl net.ipv4.ip_forward
# Should show: net.ipv4.ip_forward = 1
```

**Solution 3:** Run diagnostics
```bash
sudo ./network-test.sh
sudo ./advanced-diagnostics.sh
```

### Problem: "Cannot find device"

**Solution:** Namespace doesn't exist
```bash
# Check namespaces
sudo ip netns list

# Re-run setup
sudo ./vlan-aware-bridge-setup.sh
```

### Problem: Scripts fail with errors

**Solution:** Clean up and start fresh
```bash
sudo ./cleanup.sh
sudo ./vlan-aware-bridge-setup.sh
```

## 📚 Additional Resources

### Learn More About:
- **Network Namespaces:** `man ip-netns`
- **Bridge Configuration:** `man bridge`
- **VLAN Tagging:** `man ip-link`
- **Packet Capture:** `man tcpdump`

### Related Guides:
- See `vlan-networking-troubleshooting-guide.md` for detailed documentation
- Nmap guide for network scanning
- Bettercap guide for network analysis

## ⚠️ Important Notes

### Requirements
- Ubuntu Linux (or Debian-based)
- Root/sudo access
- iproute2 package (usually pre-installed)
- bridge-utils (optional, for bridge command)

### Safety
- These scripts only affect network namespaces
- They don't modify your main network configuration
- Safe to use on production systems
- All changes are isolated to namespaces
- Can be completely removed with cleanup.sh

### Performance
- Minimal CPU usage
- Minimal memory usage
- No impact on host networking
- Virtual interfaces have near-zero latency

## 🎯 Script Execution Order

**Recommended workflow:**

1. **Setup** → Run either setup script
   ```bash
   sudo ./vlan-aware-bridge-setup.sh
   ```

2. **Verify** → Run test script
   ```bash
   sudo ./network-test.sh
   ```

3. **Diagnose** → If issues, run diagnostics
   ```bash
   sudo ./advanced-diagnostics.sh
   ```

4. **Use** → Interact with network
   ```bash
   sudo ip netns exec pc10 bash
   ```

5. **Cleanup** → Remove everything
   ```bash
   sudo ./cleanup.sh
   ```

## 📝 Examples

### Example 1: Quick Test
```bash
sudo ./vlan-aware-bridge-setup.sh && sudo ./network-test.sh
```

### Example 2: Full Diagnostic Run
```bash
sudo ./vlan-aware-bridge-setup.sh
sudo ./network-test.sh
sudo ./advanced-diagnostics.sh
# Review captures
ls -lh /tmp/vlan-diagnostics-*/
sudo ./cleanup.sh
```

### Example 3: Manual Exploration
```bash
sudo ./vlan-aware-bridge-setup.sh
sudo ip netns exec pc10 bash
ping -c 3 192.168.10.1
ping -c 3 192.168.20.20
ip addr show
ip route
exit
sudo ./cleanup.sh
```

## 🤝 Support

If you encounter issues:

1. Read the error messages carefully
2. Run `sudo ./network-test.sh` for diagnosis
3. Check `vlan-networking-troubleshooting-guide.md`
4. Run `sudo ./advanced-diagnostics.sh` for deep analysis
5. Review packet captures in `/tmp/vlan-diagnostics-*/`

## 📄 License

These scripts are provided for educational purposes. Use responsibly in authorized environments only.

---

**Version:** 1.0  
**Last Updated:** 2025-11-01  
**Author:** Network Specialist
