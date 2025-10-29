# Ubuntu Linux Networking Essentials (Beginner → Intermediate → Advanced)

A practical, end‑to‑end learning document on **Ubuntu Linux networking essentials**, organized by level—**beginner → intermediate → advanced**—and by **task**. It focuses on the **modern toolchain** used on Ubuntu 20.04, 22.04 and 24.04 (and later), with **copy‑pasteable examples** and explanations. Where there are multiple ways to do something, this guide shows the most common patterns you’ll actually use in the field.

> **Conventions**
> - `$` means run as an unprivileged user (use `sudo` when needed).
> - Replace interface names (e.g., `ens3`, `eth0`, `wlan0`) and IPs with yours (`ip -br a` shows what you have).
> - If you’re on a remote host, be careful with commands that change IP/routing/firewall—you can lock yourself out.

---

## 0) How Ubuntu networking fits together (fast map)

- **Configuration key files & tools**
  - **Netplan** (`/etc/netplan/*.yaml`) → applies to either **NetworkManager** (desktop/laptop) or **systemd‑networkd** (server/cloud), depending on your profile.
  - **DNS** via **systemd‑resolved** (stub at `127.0.0.53`) with `resolvectl`.
- **Command pillars**
  - Day‑to‑day: `ip` (addr/link/route/neigh), `ss`, `ping`/`tracepath`/`traceroute`/`mtr`, `dig`/`host`/`resolvectl`, `curl`/`wget`.
  - Management: `nmcli` (NetworkManager) or `netplan` + `networkctl` (systemd‑networkd).
  - Diagnostics: `tcpdump`/`tshark`, `ethtool`, `iw`/`rfkill`, `journalctl`.
  - Security: **UFW** (friendly), **nftables** (native), (`iptables` is legacy compatibility).
  - Virtual/Lab: `ip netns`, `bridge`, `vlan`, `tc`, `wireguard (wg, wg‑quick)`, `nc`/`socat`, `iperf3`.

**Check what’s managing your NICs now:**
```bash
systemctl is-active NetworkManager && echo "NM in use"
systemctl is-active systemd-networkd && echo "networkd in use"
netplan status           # shows which renderer manages each interface
```

---

# 1) Beginner: See, test, and understand

### 1.1 Inspect interfaces, addresses, routes (`ip`)
```bash
ip -br a            # brief addresses (IPv4+IPv6)
ip a show dev ens3  # detailed view for one interface
ip -br l            # brief link state (UP/DOWN, MTU)
ip -4 r             # IPv4 routes
ip -6 r             # IPv6 routes
ip route get 1.1.1.1      # which route/NIC/GW to a destination?
ip neigh show              # ARP/ND cache
ip -j a | jq .             # JSON for scripts (install jq first)
```

### 1.1.1 Public IP check

To find your public (external) IP address:

```bash
curl ifconfig.me
```

Or visit https://ifconfig.me/ in a browser.

### 1.2 Connectivity tests (`ping`, `tracepath`, `traceroute`, `mtr`)
```bash
ping -c4 8.8.8.8                 # ICMP reachability
ping -c4 -I ens3 8.8.8.8         # via a specific interface
ping -c4 -6 2606:4700:4700::1111 # IPv6

tracepath 8.8.8.8                # often preinstalled; no root needed
sudo apt install traceroute mtr -y
traceroute -n 8.8.8.8
mtr -rwzbc 100 8.8.8.8           # report mode, 100 cycles
```

### 1.3 DNS checks (`resolvectl`, `dig`, `host`)
```bash
resolvectl status        # which DNS servers do we use? per-link DNS?
resolvectl query ubuntu.com
sudo apt install dnsutils -y
dig A ubuntu.com +short
dig @1.1.1.1 AAAA ubuntu.com
host -t MX ubuntu.com
```

### 1.4 Who is listening? Which connections exist? (`ss`, `lsof`)
```bash
ss -tulpn                        # TCP/UDP listeners + PIDs
ss -s                            # protocol summary
ss -nti '( dport = :ssh )'       # TCP info on SSH flows
sudo apt install lsof -y
sudo lsof -i -P -n | head -20
```

### 1.5 Quick HTTP checks (`curl`, `wget`)
```bash
curl -I https://example.com      # only headers
curl -v http://localhost:8080/
wget --spider -S https://example.com
```

### 1.6 Logs
```bash
journalctl -u NetworkManager --since "1 hour ago"
journalctl -u systemd-networkd --since today
journalctl -u systemd-resolved --since today
dmesg | grep -iE 'eth|enp|ens|link|mtu'
```

---

# 2) Intermediate: Configure and manage

## 2.1 Configure with **Netplan** (systemd‑networkd renderer)
> Works best on servers/cloud images that use networkd.

**Static IPv4 + DHCPv6, with DNS, gateway**
```yaml
# /etc/netplan/01-lan.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    ens3:
      addresses: [192.0.2.10/24]
      gateway4: 192.0.2.1
      nameservers:
        addresses: [1.1.1.1, 9.9.9.9]
      dhcp6: true
```
Apply safely:
```bash
sudo netplan try        # gives a rollback window if remote
sudo netplan apply
netplan status
```

**VLAN on top of `ens3`**
```yaml
# /etc/netplan/02-vlan.yaml
network:
  version: 2
  vlans:
    ens3.100:
      id: 100
      link: ens3
      addresses: [10.10.100.2/24]
```

**Linux bridge for KVM/LXD containers**
```yaml
# /etc/netplan/03-bridge.yaml
network:
  version: 2
  renderer: networkd
  bridges:
    br0:
      interfaces: [ens3]
      addresses: [192.0.2.20/24]
      gateway4: 192.0.2.1
      nameservers:
        addresses: [1.1.1.1, 9.9.9.9]
```

## 2.2 Configure with **NetworkManager** (`nmcli`)  
> Common on desktops/laptops and sometimes servers. Netplan may delegate to NetworkManager.

**Show devices & connections**
```bash
nmcli dev status
nmcli connection show
```

**Static IP on `ens3` (new connection):**
```bash
nmcli con add type ethernet ifname ens3 con-name ens3-static \
  ipv4.addresses 192.0.2.30/24 ipv4.gateway 192.0.2.1 \
  ipv4.dns "1.1.1.1 9.9.9.9" ipv4.method manual
nmcli con up ens3-static
```

**DHCP (switch an existing connection)**
```bash
nmcli con mod "Wired connection 1" ipv4.method auto
nmcli con up "Wired connection 1"
```

**Wi‑Fi quick connect**
```bash
nmcli dev wifi list
nmcli dev wifi connect "SSID-NAME" password "supersecret"
```

## 2.3 The `ip` command—frequently‑used writes
```bash
# Bring link up/down; set MTU
sudo ip link set dev ens3 up
sudo ip link set dev ens3 mtu 9000

# Add/remove addresses
sudo ip addr add 192.0.2.50/24 dev ens3
sudo ip addr del 192.0.2.50/24 dev ens3

# Routes (v4+v6)
sudo ip route add 198.51.100.0/24 via 192.0.2.1 dev ens3
sudo ip -6 route add 2001:db8:2::/64 via 2001:db8:1::1 dev ens3

# Flush neighbors (ARP/ND); useful after changes
sudo ip neigh flush dev ens3

# Monitor changes live (great for debugging)
sudo ip monitor all
```

## 2.4 Name resolution details (`resolvectl`)
```bash
resolvectl status                # current DNS servers/scopes
resolvectl dns ens3 9.9.9.9      # set per-link DNS (temporary)
resolvectl domain ens3 "~corp.local"  # search/route-only domain
```

## 2.5 Packet capture basics (`tcpdump`)
```bash
sudo tcpdump -i any -nn -s0 -vvv port 53
sudo tcpdump -i ens3 host 203.0.113.5 and tcp port 443
sudo tcpdump -i ens3 vlan 100
sudo tcpdump -i ens3 -w /tmp/cap.pcap   # save for Wireshark
sudo tcpdump -r /tmp/cap.pcap           # read back
```

## 2.6 Wireless & physical link tools
```bash
sudo apt install ethtool iw rfkill -y

sudo ethtool ens3                # link speed/duplex/offloads
sudo ethtool -k ens3             # offload features
sudo ethtool -K ens3 tx off gso off gro off   # toggle features

rfkill list                      # see soft/hard blocks
rfkill unblock all

iw dev                           # modern Wi‑Fi info
iw dev wlan0 link                # what AP am I on?
```

## 2.7 Quick servers & clients for testing (`nc`, `iperf3`, `socat`)
```bash
sudo apt install netcat-openbsd iperf3 socat -y

# Netcat
nc -l 0.0.0.0 8080                # listen; Ctrl+C to stop
echo "hello" | nc 127.0.0.1 8080

# Iperf3 (throughput)
# Server:
iperf3 -s
# Client:
iperf3 -c <server-ip> -t 30

# Socat: TCP proxy example
socat TCP-LISTEN:9000,fork TCP:10.0.0.10:80
```

## 2.8 Friendly firewall: **UFW**
```bash
sudo ufw status verbose
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp
sudo ufw allow 80,443/tcp
sudo ufw allow from 10.0.0.0/8 to any port 22 proto tcp
sudo ufw delete allow 80/tcp
sudo ufw enable
```
> Tip: `sudo ufw app list` shows application profiles (if installed).

---

# 3) Advanced: Design, isolate, route, secure, and tune

## 3.1 Policy routing (multiple tables) with `ip rule`
Scenario: send traffic from `192.0.2.0/24` out via GW A, and from `198.51.100.0/24` via GW B.

1) Create tables in `/etc/iproute2/rt_tables`:
```
100 uplinkA
200 uplinkB
```
2) Routes in each table:
```bash
sudo ip route add default via 192.0.2.1 dev ens3 table uplinkA
sudo ip route add default via 198.51.100.1 dev ens4 table uplinkB
```
3) Rules that select a table:
```bash
sudo ip rule add from 192.0.2.0/24 lookup uplinkA
sudo ip rule add from 198.51.100.0/24 lookup uplinkB
ip rule show
```

## 3.2 Network namespaces (clean labs on one box)
Create two isolated hosts and a router on one machine:
```bash
# Create namespaces
sudo ip netns add blue
sudo ip netns add red

# veth pair blue<->router, red<->router
sudo ip link add veth-b type veth peer name veth-b-r
sudo ip link add veth-r type veth peer name veth-r-r

# Move one end into each namespace
sudo ip link set veth-b netns blue
sudo ip link set veth-r netns red

# Assign IPs
sudo ip netns exec blue ip addr add 10.10.1.2/24 dev veth-b
sudo ip netns exec blue ip link set veth-b up

sudo ip addr add 10.10.1.1/24 dev veth-b-r
sudo ip link set veth-b-r up

sudo ip netns exec red ip addr add 10.10.2.2/24 dev veth-r
sudo ip netns exec red ip link set veth-r up

sudo ip addr add 10.10.2.1/24 dev veth-r-r
sudo ip link set veth-r-r up

# Default routes in namespaces via the "router" ends on host
sudo ip netns exec blue ip route add default via 10.10.1.1
sudo ip netns exec red  ip route add default via 10.10.2.1

# Test
sudo ip netns exec blue ping -c2 10.10.2.2
```

## 3.3 VLANs, bridges, bonds—`ip` / `bridge` (modern)  
**VLAN**
```bash
sudo ip link add link ens3 name ens3.100 type vlan id 100
sudo ip addr add 10.100.0.2/24 dev ens3.100
sudo ip link set ens3.100 up
```

**Bridge**
```bash
sudo ip link add br0 type bridge
sudo ip link set ens3 master br0
sudo ip addr add 192.0.2.40/24 dev br0
sudo ip link set br0 up
```

**Bond (active‑backup)**
```bash
sudo ip link add bond0 type bond mode active-backup
sudo ip link set ens3 master bond0
sudo ip link set ens4 master bond0
sudo ip addr add 192.0.2.60/24 dev bond0
sudo ip link set bond0 up
```

## 3.4 Native firewall with **nftables** (recommended over iptables)
```bash
sudo apt install nftables -y
sudo systemctl enable --now nftables

# See current ruleset
sudo nft list ruleset

# Minimal IPv4 NAT (masquerade) for router use-case
sudo nft add table ip nat
sudo nft 'add chain ip nat postrouting { type nat hook postrouting priority 100; }'
sudo nft add rule ip nat postrouting oifname "ens3" masquerade
```
> Equivalent legacy with iptables (if you must):
```bash
sudo sysctl -w net.ipv4.ip_forward=1
sudo iptables -t nat -A POSTROUTING -o ens3 -j MASQUERADE
```

**Port forward (DNAT) with nftables**
```bash
# Forward 8080 on router's WAN to 10.0.0.10:80 on LAN
sudo nft add table ip nat
sudo nft 'add chain ip nat prerouting { type nat hook prerouting priority -100; }'
sudo nft add rule ip nat prerouting iifname "ens3" tcp dport 8080 dnat to 10.0.0.10:80
```

## 3.5 Deep packet work: `tcpdump` filters you’ll actually use
```bash
# Only SYNs (new TCP connections)
sudo tcpdump -i any 'tcp[tcpflags] & (tcp-syn) != 0 and tcp[tcpflags] & (tcp-ack) = 0'

# Exclude noisy SSH while remoted in
sudo tcpdump -i ens3 not port 22

# HTTP/2 over TLS SNI (requires -s0 and verbose)
sudo tcpdump -i ens3 -s0 -vvv -n 'tcp port 443' | grep -i 'server_name'
```

## 3.6 Tunneling & VPNs

**WireGuard (fast, simple)**
```bash
sudo apt install wireguard -y
umask 077
wg genkey | tee /etc/wireguard/privatekey | wg pubkey > /etc/wireguard/publickey
# /etc/wireguard/wg0.conf
[Interface]
PrivateKey = <contents of /etc/wireguard/privatekey>
Address = 10.6.0.1/24
ListenPort = 51820

[Peer]
PublicKey = <peer-public-key>
AllowedIPs = 10.6.0.2/32
Endpoint = peer.example.com:51820
PersistentKeepalive = 25

sudo wg-quick up wg0
wg show
```

**IPIP/GRE/VXLAN (built‑in)**
```bash
# GRE point-to-point
sudo ip tunnel add gre1 mode gre local 203.0.113.1 remote 203.0.113.2 ttl 255
sudo ip addr add 10.200.0.1/30 dev gre1
sudo ip link set gre1 up

# VXLAN id 42 with a remote peer (simple unicast example)
sudo ip link add vxlan42 type vxlan id 42 dev ens3 remote 198.51.100.2 dstport 4789
sudo ip addr add 10.42.0.1/24 dev vxlan42
sudo ip link set vxlan42 up
```

## 3.7 Traffic control & impairment lab (`tc`)
```bash
sudo apt install iproute2 -y   # usually present
# Add 100 ms delay and 1% loss to egress on ens3
sudo tc qdisc add dev ens3 root netem delay 100ms loss 1%
# Remove it
sudo tc qdisc del dev ens3 root
```

## 3.8 IPv6 essentials (real‑world)
```bash
# Show IPv6 routes and neighbors
ip -6 r; ip -6 neigh

# Add a static IPv6 and default route
sudo ip -6 addr add 2001:db8:1::10/64 dev ens3
sudo ip -6 route add default via 2001:db8:1::1 dev ens3

# ICMPv6 neighbor discovery test
ping -6 -c4 fe80::1%ens3
```

## 3.9 Service exposure and port probing (be ethical)
```bash
ss -tulpn | grep LISTEN
nc -zv example.com 1-1024           # quick client-side port scan
```
> **Only scan hosts/networks you own or have permission to test.**

## 3.10 Performance tuning quick checks
```bash
# Offloads and ring buffers
sudo ethtool -k ens3
sudo ethtool -g ens3

# Backlog queue sizes
sysctl net.core.somaxconn
sysctl net.core.netdev_max_backlog

# Enable IPv4 forwarding (router use cases)
echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward
# Persist in /etc/sysctl.d/99-sysctl.conf:
# net.ipv4.ip_forward=1
```

---

# 4) Typical “mini‑projects” (copy‑paste labs)

## A) “Why can’t I reach the site?”—structured triage
```bash
# 1) Local NIC and IP?
ip -br a

# 2) Can I reach default GW and outside IP?
ip route get 1.1.1.1
ping -c2 $(ip route | awk '/default/ {print $3}')
ping -c2 1.1.1.1

# 3) DNS working?
resolvectl status
dig +short ubuntu.com

# 4) Is the site reachable at L3/L4?
traceroute -n 151.101.2.132
ss -nti '( dport = :443 )'  # any TLS flows? (run while curling)
curl -I https://ubuntu.com

# 5) If still stuck, capture:
sudo tcpdump -i any -s0 -n host 151.101.2.132 and tcp port 443
```

## B) Configure a **static IP** (two paths)

**With Netplan (networkd)**
```yaml
# /etc/netplan/10-static.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    ens3:
      addresses: [192.0.2.10/24]
      gateway4: 192.0.2.1
      nameservers: { addresses: [1.1.1.1, 9.9.9.9] }
```
```bash
sudo netplan try && sudo netplan apply
```

**With NetworkManager (nmcli)**
```bash
nmcli con add type ethernet ifname ens3 con-name ens3-static \
  ipv4.method manual ipv4.addresses 192.0.2.10/24 ipv4.gateway 192.0.2.1 \
  ipv4.dns "1.1.1.1 9.9.9.9"
nmcli con up ens3-static
```

## C) Create a **VLAN interface** and put a host on it
```bash
sudo ip link add link ens3 name ens3.200 type vlan id 200
sudo ip addr add 10.200.0.10/24 dev ens3.200
sudo ip link set ens3.200 up
ping -c2 10.200.0.1
```

## D) Make your Ubuntu box a simple **NAT gateway** (lab)
```bash
# Enable forward
echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward
# nftables masquerade (WAN ens3, LAN ens4)
sudo nft add table ip nat
sudo nft 'add chain ip nat postrouting { type nat hook postrouting priority 100; }'
sudo nft add rule ip nat postrouting oifname "ens3" masquerade
```

## E) **WireGuard** site‑to‑site (quick)
- On **Site A**: address `10.6.0.1/24`, listen `51820`.
- On **Site B**: address `10.6.0.2/24`, peer with A.
See section **3.6** for the exact `wg-quick` file format and commands.

## F) **Traffic shaping** for a test
```bash
sudo tc qdisc add dev ens3 root netem delay 80ms loss 0.5% rate 10mbit
# ... run your app tests ...
sudo tc qdisc del dev ens3 root
```

---

# 5) Command‑by‑command “you’ll actually use these” reference

Below is a compact list of the *most useful* unique usages per command—things that cover the majority of admin work.

### `ip` (iproute2)
- **Show**: `ip -br a`, `ip -br l`, `ip -4 r`, `ip -6 r`, `ip route get DST`, `ip neigh`
- **Set link**: `ip link set dev IF up|down`, `ip link set dev IF mtu N`
- **Addresses**: `ip addr add|del IP/prefix dev IF`
- **Routes**: `ip route add|del PREFIX via GW dev IF`, `ip -6 route add ...`
- **Rules**: `ip rule add from SRC lookup TABLE`
- **Monitor**: `ip monitor all`
- **VLAN**: `ip link add link IF name IF.VID type vlan id VID`
- **Bridge**: `ip link add br0 type bridge; ip link set IF master br0`
- **Bond**: `ip link add bond0 type bond mode active-backup`
- **Tunnels**: `ip tunnel add NAME mode gre|ipip local A remote B`
- **Namespaces**: `ip netns add NAME; ip netns exec NAME CMD`

### `ss`
- Listeners: `ss -tulpn`
- Summary: `ss -s`
- Flow details: `ss -nti '( dport = :80 )'`
- State filters: `ss state established '( sport = :ssh )'`

### `ping` / `tracepath` / `traceroute` / `mtr`
- `ping -c N HOST`, `ping -6 HOST`, `ping -I IF HOST`
- `tracepath HOST` (no root), `traceroute -n HOST`
- `mtr -rwzbc 100 HOST` (quick report)

### `dig` / `host` / `resolvectl`
- `dig +short A|AAAA|MX|TXT name`
- `dig @SERVER name`
- `host -t TYPE name`
- `resolvectl status`, `resolvectl query name`, `resolvectl dns IF X.X.X.X`

### `nmcli`
- Show: `nmcli dev status`, `nmcli con show`
- Add static: *(see 2.2)*; DHCP: `nmcli con mod NAME ipv4.method auto`
- Wi‑Fi: `nmcli dev wifi list`, `nmcli dev wifi connect SSID password ...`

### `netplan`
- `netplan get`, `netplan status`, `netplan try`, `netplan apply`

### `tcpdump`
- Save pcap: `tcpdump -i IF -s0 -w file.pcap`
- Common filters: `host`, `port`, `vlan`, `not port 22`
- Verbose TLS SNI: `-vvv` and grep `server_name`

### `ethtool`
- Show link: `ethtool IF`
- Offloads: `ethtool -k IF` / toggle with `-K`
- Rings: `ethtool -g IF`

### `iw` / `rfkill`
- `iw dev`, `iw dev wlan0 link`
- `rfkill list`, `rfkill unblock wifi`

### `nft` (nftables)
- Show all: `nft list ruleset`
- Add NAT table & masquerade: *(see 3.4)*
- DNAT/port forward: *(see 3.4)*

### `ufw`
- Defaults, allow/deny, enable: *(see 2.8)*

### `wg` / `wg-quick`
- Generate keys, `wg-quick up|down wg0`, `wg show`: *(see 3.6)*

### `tc`
- Impairment: `tc qdisc add dev IF root netem delay X loss Y rate Z`
- Remove: `tc qdisc del dev IF root`

### `nc` / `socat` / `iperf3`
- Listener & client tests, simple proxies, throughput: *(see 2.7)*

---

# 6) Common gotchas & fixes

- **`/etc/resolv.conf` is a stub** pointing to `127.0.0.53` when `systemd‑resolved` is used; do DNS per‑link via `resolvectl` or via your network manager (Netplan/NM), not by editing the stub.
- **Legacy tools** (`ifconfig`, `route`, `brctl`, `netstat`) are deprecated; prefer `ip`, `ss`, `bridge`.
- **Remote changes**: use `netplan try` (rolls back if you lose connectivity).
- **Firewalls & containers**: docker/podman may auto‑manipulate iptables/nft; check `nft list ruleset` and docker’s networks.
- **MTU problems**: symptoms include hanging HTTPS/SSH. Try `ping -M do -s 1472 8.8.8.8` (IPv4) to find a workable MTU; clamp MSS on tunnels if needed.
- **IPv6 sometimes “half‑works”**: check default route and RA/DHCPv6; ensure firewall allows ICMPv6.

---

# 7) Quick curricula (what to learn in order)

**Beginner (hours → days)**  
1) `ip -br a`, `ip r`, `ping`, `tracepath`, `dig`, `ss`, `curl`, logs (`journalctl`).  
2) Understand Netplan and your renderer (NM vs networkd).

**Intermediate (days → weeks)**  
3) Netplan/NM configuration (static, VLAN, bridge), `tcpdump` basics, UFW, `nft` intros.  
4) Wi‑Fi and link debugging (`ethtool`, `iw`, `rfkill`).  
5) Namespaces & simple labs (`ip netns`, `tc` for impairment).

**Advanced (weeks → ongoing)**  
6) Policy routing (`ip rule`), multi‑WAN, WireGuard/VXLAN/GRE, nftables design.  
7) Performance tuning and deep packet analysis.

---

## Appendix: Safe ways to experiment

- **Use network namespaces** (Section 3.2) to avoid breaking your live stack.
- **If on a server over SSH**, always keep a second session open during changes.
- **Export before you change**:
  - `sudo nft list ruleset > ~/nft-backup.txt`
  - `sudo ip -s -s link show > ~/links.txt`
  - `sudo cp -a /etc/netplan ~/netplan-backup`

---

*Last updated: 2025-10-28.*
