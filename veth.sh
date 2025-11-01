#!/bin/bash

# Clean up
sudo ip netns delete pc10 2>/dev/null
sudo ip netns delete pc20 2>/dev/null
sudo ip netns delete router 2>/dev/null
sudo ip link delete br10 2>/dev/null
sudo ip link delete br20 2>/dev/null

# Create namespaces
sudo ip netns add pc10
sudo ip netns add pc20
sudo ip netns add router

# Create veth pairs
sudo ip link add veth-pc10 type veth peer name veth-sw10
sudo ip link add veth-pc20 type veth peer name veth-sw20
sudo ip link add veth-r10 type veth peer name veth-sw-r10
sudo ip link add veth-r20 type veth peer name veth-sw-r20

# Move to namespaces
sudo ip link set veth-pc10 netns pc10
sudo ip link set veth-pc20 netns pc20
sudo ip link set veth-r10 netns router
sudo ip link set veth-r20 netns router

# Create separate bridges for each VLAN
sudo ip link add br10 type bridge
sudo ip link add br20 type bridge
sudo ip link set br10 up
sudo ip link set br20 up

# Connect to bridges
sudo ip link set veth-sw10 master br10
sudo ip link set veth-sw-r10 master br10
sudo ip link set veth-sw20 master br20
sudo ip link set veth-sw-r20 master br20

# Bring up switch interfaces
sudo ip link set veth-sw10 up
sudo ip link set veth-sw-r10 up
sudo ip link set veth-sw20 up
sudo ip link set veth-sw-r20 up

# Configure PC10
sudo ip netns exec pc10 ip addr add 192.168.10.10/24 dev veth-pc10
sudo ip netns exec pc10 ip link set veth-pc10 up
sudo ip netns exec pc10 ip link set lo up
sudo ip netns exec pc10 ip route add default via 192.168.10.1

# Configure PC20
sudo ip netns exec pc20 ip addr add 192.168.20.20/24 dev veth-pc20
sudo ip netns exec pc20 ip link set veth-pc20 up
sudo ip netns exec pc20 ip link set lo up
sudo ip netns exec pc20 ip route add default via 192.168.20.1

# Configure Router
sudo ip netns exec router ip addr add 192.168.10.1/24 dev veth-r10
sudo ip netns exec router ip addr add 192.168.20.1/24 dev veth-r20
sudo ip netns exec router ip link set veth-r10 up
sudo ip netns exec router ip link set veth-r20 up
sudo ip netns exec router ip link set lo up
sudo ip netns exec router sysctl -w net.ipv4.ip_forward=1

echo "Testing..."
sudo ip netns exec pc10 ping -c 3 192.168.10.1
sudo ip netns exec pc20 ping -c 3 192.168.20.1
sudo ip netns exec pc10 ping -c 3 192.168.20.20
# ```

## Network Topology
# ```
# VLAN 10 Network:
# ┌─────────┐         ┌─────────┐         ┌─────────┐
# │  PC10   │─────────│  br10   │─────────│ Router  │
# │ .10.10  │         │(bridge) │         │ .10.1   │
# └─────────┘         └─────────┘         └─────────┘
# 
# VLAN 20 Network:
# ┌─────────┐         ┌─────────┐         ┌─────────┐
# │  PC20   │─────────│  br20   │─────────│ Router  │
# │ .20.20  │         │(bridge) │         │ .20.1   │
# └─────────┘         └─────────┘         └─────────┘
# 
# Router forwards between VLANs
# 
# Testing...
# PING 192.168.10.1 (192.168.10.1) 56(84) bytes of data.
# 64 bytes from 192.168.10.1: icmp_seq=1 ttl=64 time=0.063 ms
# 64 bytes from 192.168.10.1: icmp_seq=2 ttl=64 time=0.049 ms
# 64 bytes from 192.168.10.1: icmp_seq=3 ttl=64 time=0.122 ms
# 
# --- 192.168.10.1 ping statistics ---
# 3 packets transmitted, 3 received, 0% packet loss, time 2027ms
# rtt min/avg/max/mdev = 0.049/0.078/0.122/0.031 ms
# PING 192.168.20.1 (192.168.20.1) 56(84) bytes of data.
# 64 bytes from 192.168.20.1: icmp_seq=1 ttl=64 time=0.084 ms
# 64 bytes from 192.168.20.1: icmp_seq=2 ttl=64 time=0.095 ms
# 64 bytes from 192.168.20.1: icmp_seq=3 ttl=64 time=0.089 ms
# 
# --- 192.168.20.1 ping statistics ---
# 3 packets transmitted, 3 received, 0% packet loss, time 2035ms
# rtt min/avg/max/mdev = 0.084/0.089/0.095/0.004 ms
# PING 192.168.20.20 (192.168.20.20) 56(84) bytes of data.
# 64 bytes from 192.168.20.20: icmp_seq=1 ttl=63 time=0.050 ms
# 64 bytes from 192.168.20.20: icmp_seq=2 ttl=63 time=0.104 ms
# 64 bytes from 192.168.20.20: icmp_seq=3 ttl=63 time=0.086 ms
# 
# --- 192.168.20.20 ping statistics ---
# 3 packets transmitted, 3 received, 0% packet loss, time 2035ms
# rtt min/avg/max/mdev = 0.050/0.080/0.104/0.022 ms
# 
