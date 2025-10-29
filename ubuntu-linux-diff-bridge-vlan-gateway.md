# VLAN vs Bridge vs Gateway on Ubuntu Linux

A concise, Ubuntu-focused guide comparing **VLANs**, **bridges**, and **gateways**, with runnable examples and Netplan snippets. (GitHub Flavored Markdown)

---

## What each one is

**VLAN (802.1Q)** — Layer‑2 *segmentation*. It tags Ethernet frames so multiple isolated “virtual LANs” can share one physical NIC/switch link. No IP forwarding by itself.  
Use when you need separate L2 segments (e.g., prod vs. dev) over the same wire.

**Bridge (Linux bridge)** — Layer‑2 *switch* in software. It ties interfaces into one broadcast domain and learns MACs, like a basic switch.  
Use for KVM/containers, bonding a NIC to VMs (br0), or transparently joining ports.

**Gateway (router/default route)** — Layer‑3 *forwarder*. It moves packets between IP networks (e.g., VLAN 10 → Internet), applies routing/NAT/firewall.  
Use when traffic must cross subnets or reach the Internet.

---

## How they differ (quick table)

| Thing   | OSI layer | Purpose                      | Typical Ubuntu object         | IP lives on?                                 |
|--------|-----------|------------------------------|-------------------------------|----------------------------------------------|
| VLAN   | L2        | Isolate traffic with tags    | `eth0.10`                     | On the VLAN sub‑interface or bridge over it  |
| Bridge | L2        | Join ports into one LAN      | `br0`                         | On the **bridge** (not on member NICs)       |
| Gateway| L3        | Route/NAT between networks   | kernel routing + `nftables`   | On routed interfaces                          |

> **Rule of thumb:** VLAN segments L2, a bridge *joins* L2, a gateway *routes* L3.

---

## Canonical Ubuntu patterns

### 1) Make a VLAN sub‑interface

**Runtime (iproute2):**
```bash
# create VLAN 10 on eth0 and assign an address
sudo ip link add link eth0 name eth0.10 type vlan id 10
sudo ip addr add 10.0.10.2/24 dev eth0.10
sudo ip link set eth0.10 up
```

**Persist (Netplan):**
```yaml
# /etc/netplan/10-vlan.yaml
network:
  version: 2
  ethernets:
    eth0: {}
  vlans:
    eth0.10:
      id: 10
      link: eth0
      addresses: [10.0.10.2/24]
```

---

### 2) Bridge a NIC (for VMs/containers)

**Runtime (iproute2 + bridge):**
```bash
# create a bridge and enslave eth0; put the IP on the bridge
sudo ip link add br0 type bridge
sudo ip link set eth0 master br0
sudo ip addr flush dev eth0
sudo ip addr add 192.168.1.10/24 dev br0
sudo ip link set eth0 up
sudo ip link set br0 up
```

**Persist (Netplan):**
```yaml
# /etc/netplan/20-bridge.yaml
network:
  version: 2
  ethernets:
    eth0: {}
  bridges:
    br0:
      interfaces: [eth0]
      addresses: [192.168.1.10/24]
      routes:
        - to: default
          via: 192.168.1.1
```

> **Tip:** When a NIC is part of a bridge, assign the IP to the *bridge device* (e.g., `br0`), not the enslaved NIC (e.g., `eth0`).

---

### 3) Act as a gateway (route/NAT between LAN and WAN)

**Enable IPv4 forwarding:**
```bash
echo net.ipv4.ip_forward=1 | sudo tee /etc/sysctl.d/99-forward.conf
sudo sysctl -p /etc/sysctl.d/99-forward.conf
```

**Simple NAT (nftables):**
```bash
sudo nft add table ip nat
sudo nft 'add chain ip nat postrouting { type nat hook postrouting priority 100; }'
sudo nft add rule ip nat postrouting oifname "wan0" masquerade
```

Now set your hosts to use this machine’s LAN IP as their **default gateway** (via static config or DHCP).

---

## How they combine (common design)

- Switch trunk → `eth0` carrying VLANs 10/20.  
- Create `eth0.10` and `eth0.20`.  
- Bridge each to its own VM bridge (`br10` over `eth0.10`, `br20` over `eth0.20`) so VMs attach at L2 to the right VLAN.  
- Put IPs on `br10`/`br20`. If this box must move traffic between them or to the Internet, enable routing/NAT: now it’s a **gateway** for those VLANs.

```
[LAN 10] <---> br10 ---                         \ 
                          (router/NAT) ---- Internet
                         /
[LAN 20] <---> br20 ---/
```

---

## Gotchas
- Don’t assign an IP to a physical port that’s enslaved to a bridge; put it on the bridge.  
- A VLAN only isolates at L2; inter‑VLAN traffic requires a **gateway** (router or L3 switch).  
- Changing a server’s primary NIC to a bridge may drop remote access until the bridge has the IP—schedule maintenance windows.

---

## Handy checks

```bash
ip -br a            # concise interface/IP view
ip -d link show     # show VLAN/bridge details
bridge link         # L2 membership
ip route            # routing table
```

---

### Glossary

- **Enslave**: Attach an interface (e.g., `eth0`) to a higher-level device (e.g., `br0`).
- **Masquerade**: A form of NAT that rewrites source IP/port to the egress interface’s address.
- **Trunk**: A switch port carrying multiple VLANs via 802.1Q tags.
- **Access port**: A switch port carrying a single, untagged VLAN.

---

*Tested on modern Ubuntu (Netplan-based) systems. Adapt paths and interface names (`eth0`, `wan0`) to your environment.*
