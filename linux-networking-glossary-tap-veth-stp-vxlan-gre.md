# Linux Networking Glossary: TAP, VETH, STP, VXLAN/GRE

**Updated:** 2025-10-29  
**Audience:** Learners working with Linux bridges, VLANs, and overlays

---

## TAP (as in TUN/TAP)

**What it is:** A **virtual Ethernet NIC** created by the kernel that user space (or a hypervisor) can read/write like a real NIC.  
**Why it exists:** To connect a VM or a userspace program to the host’s Layer‑2 network (e.g., a bridge) just like a physical NIC would.

**Common uses**
- KVM/libvirt auto‑creates `vnetX` TAPs for guests.
- DIY VM/namespace networking where you manually create a `tap0` and plug it into `br0`.

**Quick example**
```bash
# Create a TAP and attach to a bridge
ip tuntap add dev tap0 mode tap       # add 'user $USER' if needed
ip link set tap0 up
ip link set br0 up || ip link add br0 type bridge && ip link set br0 up
ip link set tap0 master br0
```

**Mental model**
```
[VM or program] ⇄ (TAP) tap0 ⇄ [bridge br0] ⇄ other ports/NICs
```

---

## VETH (Virtual Ethernet pair)

**What it is:** A **pair of connected virtual NICs**; packets entering one end pop out the other.  
**Why it exists:** To connect **namespaces/containers** to the host (or to each other) at Layer‑2.

**Common uses**
- Docker/Podman/CNI under the hood.
- Manual container or network namespace wiring to a bridge.

**Quick example**
```bash
# Create a veth pair
ip link add veth0 type veth peer name vpeer0

# Host side: attach to bridge
ip link set br0 up || ip link add br0 type bridge && ip link set br0 up
ip link set veth0 up
ip link set veth0 master br0

# Move the other end into a namespace/container
ip netns add ns1
ip link set vpeer0 netns ns1
ip -n ns1 link set lo up
ip -n ns1 link set vpeer0 up
ip -n ns1 addr add 192.0.2.10/24 dev vpeer0
```

**Mental model**
```
host veth0 ⇄ vpeer0 in ns1
  │                      │
  └─(master br0)         └─(IP in namespace)
```

---

## STP (Spanning Tree Protocol)

**What it is:** A Layer‑2 control protocol that **prevents Ethernet loops** by putting some bridge ports into a **blocking** state.  
**Why it exists:** In bridged networks, loops cause broadcast storms and MAC table instability. STP auto‑selects a **loop‑free tree**.

**When to use**
- Your `br0` has **two or more** paths into the **same L2 domain** (e.g., dual uplinks to switches, or multiple bridges interconnected).

**Quick example (Linux bridge)**
```bash
# Enable classic STP on a Linux bridge
ip link set dev br0 type bridge stp_state 1
# Inspect
bridge spanning-tree show
```
> For faster convergence (RSTP/MSTP), run a userspace daemon (e.g., mstpd).

**Rule of thumb**
- If you create **redundant L2 paths**, enable STP or redesign to avoid loops.

---

## VXLAN / GRE (L2 overlays)

**What they are:** Technologies that **encapsulate L2 frames** inside outer packets so an L2 segment can cross an **L3 (routed) network**.

### VXLAN
- Encapsulates in **UDP/4789** with a **24‑bit VNI** (≈16 million segments).
- Works well for multi‑host, large‑scale, and **NAT‑friendly** transport.
- Often used in clouds and data centers.

**Quick example**
```bash
# Create VXLAN VNI 42 between two hosts (A and B)
# On Host A:
ip link add vxlan42 type vxlan id 42 dev eno1 local A.A.A.A remote B.B.B.B dstport 4789
ip link set vxlan42 up
ip link set br0 up || ip link add br0 type bridge && ip link set br0 up
ip link set vxlan42 master br0

# On Host B: mirror the vxlan42 with local/remote swapped, then attach to its br0
```

### GRE / GRETAP
- Encapsulates in **IP protocol 47** (no ports).  
- **GRETAP** specifically carries Ethernet (L2) so you can bridge it.
- Simple **point‑to‑point** tunnels; NAT can be tricky without helpers.

**Quick example**
```bash
# Create a L2 GRETAP between Host A and B
# On Host A:
ip link add gretap1 type gretap local A.A.A.A remote B.B.B.B
ip link set gretap1 up
ip link set br0 up || ip link add br0 type bridge && ip link set br0 up
ip link set gretap1 master br0

# On Host B: create gretap1 with local/remote swapped and attach to br0
```

### Choosing between them
- **VXLAN:** better for **scale**, multi‑tenant segmentation (VNI), and **NAT traversal** (UDP).  
- **GRE/GRETAP:** **simple** point‑to‑point L2; good for labs or small setups.

**Overhead & MTU**
- Encapsulation reduces effective MTU. As a rough guide: **VXLAN ~50 B**, **GRE ~24 B** overhead. Adjust MTU or enable jumbo frames.

**Security note**
- VXLAN/GRE provide **no encryption**. If needed, run them **inside IPsec/WireGuard**.

---

## TL;DR mapping

- **TAP:** virtual **NIC** for VMs/userspace; plug into a **bridge**.  
- **VETH:** **pair** to connect host ⇄ **namespace/container**; one end to bridge.  
- **STP:** protects bridged L2 from **loops**; enable if you have redundant L2 paths.  
- **VXLAN/GRE:** **overlays** to extend L2 across **L3**; attach tunnel interface to a bridge.

---

## Mini checklists

**Connecting a VM via TAP**
- [ ] `ip tuntap add tap0 mode tap`  
- [ ] `ip link set tap0 master br0`  
- [ ] `ip link set tap0 up`

**Connecting a container via VETH**
- [ ] `ip link add veth0 type veth peer name vpeer0`  
- [ ] `ip link set veth0 master br0 && ip link set veth0 up`  
- [ ] Move `vpeer0` into container/ns and configure IP

**Stretching L2 over L3**
- [ ] Choose **VXLAN** (UDP/4789, VNI) or **GRETAP** (IP proto 47)  
- [ ] Create the tunnel on **both ends**  
- [ ] `ip link set <tunnel> master br0` on each host  
- [ ] Adjust **MTU**; consider **encryption** if needed
