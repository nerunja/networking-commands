# VLANs vs Bridges in Linux: Single Host vs Multi-Host Scope

**Updated:** 2025-10-29  
**Context:** Learning networking on Linux

---

## TL;DR

- **VLANs (802.1Q)** are Layer-2 *labels* on frames and can be used **locally on a single host** *or* **across multiple hosts/switches** when links are configured as **trunks** to carry the VLAN tag end-to-end.  
- A **Linux bridge** (e.g., `br0`) is a **software switch that exists on one host**. It **does not automatically span multiple hosts**, but multiple hosts’ bridges can participate in the **same L2 domain** via physical switches (optionally on a VLAN). To extend a single L2 segment over an L3 network, use an **overlay** (e.g., **VXLAN**/**GRETAP**) and attach the tunnel interface to the bridge.
- Rules of thumb: Use **VLANs to define L2 boundaries across the network**; use a **bridge to forward frames between interfaces on one host**; use **VXLAN/GRE** when you must stretch L2 over L3. Enable **STP** when a bridge has redundant paths.

---

## What is a VLAN (802.1Q)?

- Adds a 12-bit **VLAN ID** tag to Ethernet frames.  
- Segments a single physical network into multiple **isolated broadcast domains**.  
- **Where it applies:**
  - **Single host:** for isolating VMs/containers, or segregating host traffic (e.g., mgmt vs storage) using VLAN sub-interfaces.
  - **Multi-host:** when switches/links in between are configured to **carry the VLAN** (i.e., **trunk ports**), the same VLAN ID can span racks/rooms/sites.
- **Key port types:**  
  - **Access/untagged:** one VLAN is *implicitly* associated (PVID). Frames are untagged on the wire.  
  - **Trunk/tagged:** carries one or more VLANs; frames include 802.1Q tags.

### Linux VLAN quick commands
```bash
# Create VLAN ID 20 on physical NIC eno1
ip link add link eno1 name eno1.20 type vlan id 20
ip link set eno1.20 up
# Assign IP (optional)
ip addr add 192.0.2.10/24 dev eno1.20
```

---

## What is a Linux Bridge?

- Kernel component that **forwards Ethernet frames** between member interfaces (ports) like a **software switch**.  
- Ports can be: physical NICs, VLAN sub-interfaces (e.g., `eno1.20`), TAP/VETH from VMs/containers, or tunnel interfaces (VXLAN, GRETAP).  
- A bridge instance (e.g., `br0`) is **local to one host**. It doesn’t “become” a distributed switch by itself, but you can connect many hosts’ bridges together via physical switches/VLANs or overlays.

### Linux bridge quick commands
```bash
# Create a bridge and add ports
ip link add br0 type bridge
ip link set br0 up

# Add a VLAN sub-interface to the bridge
ip link set eno1.20 master br0

# (Recommended) enable STP if redundant paths exist
ip link set dev br0 type bridge stp_state 1
```

> **Note on `vnet0`:** In KVM/libvirt setups, interfaces like `vnet0` are **auto-created** when a VM starts, and libvirt will attach them to `br0` if the guest’s NIC is configured to use that bridge. You **don’t** usually create `vnet0` by hand. If you want to attach a guest/container interface **manually**, use a TAP or VETH as shown below.

---

## Patterns & Topologies

### 1) Single-host isolation (local VLAN + bridge) — using a TAP (manual)

```
VM/namespace tap (tap0) ──┐
                          ├── br0 ── eno1.20 (VLAN 20) ── eno1 ──(to switch)
Host services on VLAN 20 ─┘
```

```bash
# VLAN subinterface
ip link add link eno1 name eno1.20 type vlan id 20
ip link set eno1.20 up

# Bridge
ip link add br0 type bridge
ip link set br0 up
ip link set eno1.20 master br0

# TAP device for a VM/namespace you manage manually
ip tuntap add dev tap0 mode tap   # or: ip tuntap add tap0 mode tap user $USER
ip link set tap0 up
ip link set tap0 master br0

# Optional: put an IP on the bridge (L3 for the host)
ip addr add 192.0.2.2/24 dev br0
```

### 1b) Single-host isolation — using a VETH pair (containers/netns)

```bash
# Create a veth pair: one end on the host bridge, one end to a namespace/container
ip link add veth0 type veth peer name vpeer0

# Host side
ip link set veth0 up
ip link set veth0 master br0

# Move the peer into a namespace (example with ip netns)
ip netns add ns1
ip link set vpeer0 netns ns1

# Inside the namespace
ip -n ns1 link set lo up
ip -n ns1 link set vpeer0 up
ip -n ns1 addr add 192.0.2.100/24 dev vpeer0
```

### 2) Multi-host, same VLAN across hosts

```
Host A: tap0/veth ─┐              ┌─ tap0/veth :Host B
                   ├─ br0 ─ eno1 ─┼─ Switch (trunk allows VLAN 20) ─ eno1 ─ br0 ─
Host A: eno1.20 ───┘              └─ eno1.20 :Host B
```

- Configure `eno1` switch ports as **trunks** carrying VLAN 20.  
- Workloads on VLAN 20 across hosts share the **same L2 broadcast domain**.

### 3) Stretch L2 over L3 with an overlay (VXLAN/GRE)

- Use when hosts are separated by routed networks or different sites.

```bash
# VXLAN ID 20 between HostA (local A.B.C.A) and HostB (remote A.B.C.B)
ip link add vxlan20 type vxlan id 20 dev eno1 dstport 4789 \
  local A.B.C.A remote A.B.C.B

ip link set vxlan20 up
ip link set vxlan20 master br0
```

- Each host’s bridge attaches the **tunnel interface**, creating a **virtual L2 segment** across an L3 path.

---

## Validation & Troubleshooting

```bash
# Show bridges and ports
bridge link
bridge vlan show
bridge fdb show

# Verify tags on a NIC
ip -d link show dev eno1.20

# Capture to confirm VLAN tagging
tcpdump -ni eno1 vlan and host 192.0.2.50

# Check STP state (if enabled)
bridge spanning-tree show
```

---

## Pitfalls & Tips

- **STP/loops:** If a bridge connects to multiple paths to the same L2, enable STP or design loop-free topologies.  
- **Mismatched VLAN IDs:** All devices on the path must agree on VLAN IDs; trunk ports must **allow** the VLAN.  
- **Untagged vs tagged confusion:** Access (untagged) ports strip/add tags; trunk (tagged) ports carry tags.  
- **MTU with overlays:** VXLAN/GRE adds overhead; adjust MTU or enable jumbo frames.  
- **IP assignment:** Typically assign IPs **on the bridge** (e.g., `br0`), not on member ports.  
- **Security:** Use ebtables/nftables for L2 filtering if needed; consider DHCP snooping and ARP inspection in multi-tenant setups.

---

## FAQ

**Q: Can a single Linux bridge span multiple hosts?**  
*A:* Not by itself. A bridge instance is per-host. To achieve cross-host L2, connect bridges via switches/VLANs or use overlays (VXLAN/GRE).

**Q: Do VLANs work without any switch configuration?**  
*A:* For **purely local** use (e.g., between VMs on one host), yes. To **extend** the VLAN beyond the host, the upstream switch ports must be configured appropriately (trunk/access).

**Q: When should I use VXLAN instead of plain VLANs?**  
*A:* When hosts are separated by L3 routing, or when you need large scale (24-bit VNI), or when the physical network can’t carry the desired VLANs end-to-end.
