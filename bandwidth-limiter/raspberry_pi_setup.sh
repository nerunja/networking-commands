#!/bin/bash
#
# Smart TV Bandwidth Limiter - Raspberry Pi Gateway Setup
# Version: 1.0.0
# Description: Complete setup for Raspberry Pi as dedicated bandwidth-limiting gateway
#
# Usage: sudo ./raspberry_pi_setup.sh
#

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check root
if [[ $EUID -ne 0 ]]; then
   print_error "This script must be run as root (use sudo)"
   exit 1
fi

echo ""
echo "============================================"
echo "  Raspberry Pi Bandwidth Limiter Setup"
echo "============================================"
echo ""
print_warning "This script will configure your Raspberry Pi as a gateway"
print_warning "Make sure you have TWO network interfaces configured!"
echo ""
read -p "Press Enter to continue or Ctrl+C to abort..."
echo ""

# ============================================================================
# CONFIGURATION SECTION - MODIFY THESE VALUES
# ============================================================================

# Network Configuration
UPSTREAM_INTERFACE="eth0"       # Interface to router
DOWNSTREAM_INTERFACE="eth1"     # Interface to Smart TVs (or USB Ethernet)

# IP Configuration
UPSTREAM_IP="192.168.1.2"       # Pi's IP on main network
UPSTREAM_NETMASK="255.255.255.0"
UPSTREAM_GATEWAY="192.168.1.1"  # Your router

DOWNSTREAM_IP="192.168.2.1"     # Pi's IP on Smart TV network
DOWNSTREAM_NETMASK="255.255.255.0"
DOWNSTREAM_DHCP_START="192.168.2.10"
DOWNSTREAM_DHCP_END="192.168.2.50"

# Bandwidth Limits
BANDWIDTH_LIMIT="5mbit"         # Per device limit
BANDWIDTH_CEILING="10mbit"      # Burst ceiling
TOTAL_BANDWIDTH="100mbit"       # Total available

# Smart TV MAC addresses (optional - for specific limiting)
declare -A SMART_TVS=(
    ["aa:bb:cc:dd:ee:ff"]="LivingRoom_TV"
    ["11:22:33:44:55:66"]="Bedroom_TV"
)

# ============================================================================
# END CONFIGURATION SECTION
# ============================================================================

print_info "Configuration Summary:"
echo "  Upstream: $UPSTREAM_INTERFACE ($UPSTREAM_IP)"
echo "  Downstream: $DOWNSTREAM_INTERFACE ($DOWNSTREAM_IP)"
echo "  Bandwidth limit: $BANDWIDTH_LIMIT per TV"
echo ""

# Step 1: Install required packages
print_info "Step 1: Installing required packages..."
apt update
apt install -y \
    dnsmasq \
    iptables \
    iptables-persistent \
    iproute2 \
    net-tools \
    tcpdump \
    iftop
print_success "Packages installed"
echo ""

# Step 2: Configure network interfaces
print_info "Step 2: Configuring network interfaces..."

# Backup existing config
if [ -f /etc/network/interfaces ]; then
    cp /etc/network/interfaces /etc/network/interfaces.backup
    print_success "Backed up /etc/network/interfaces"
fi

# Configure netplan (Ubuntu) or interfaces (Raspbian)
if [ -d /etc/netplan ]; then
    # Ubuntu/netplan configuration
    cat > /etc/netplan/01-bandwidth-limiter.yaml << EOF
network:
  version: 2
  ethernets:
    $UPSTREAM_INTERFACE:
      dhcp4: false
      addresses: [$UPSTREAM_IP/24]
      gateway4: $UPSTREAM_GATEWAY
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
    $DOWNSTREAM_INTERFACE:
      dhcp4: false
      addresses: [$DOWNSTREAM_IP/24]
EOF
    netplan apply
    print_success "Netplan configured"
else
    # Raspbian/interfaces configuration
    cat > /etc/network/interfaces << EOF
# Upstream interface (to router)
auto $UPSTREAM_INTERFACE
iface $UPSTREAM_INTERFACE inet static
    address $UPSTREAM_IP
    netmask $UPSTREAM_NETMASK
    gateway $UPSTREAM_GATEWAY
    dns-nameservers 8.8.8.8 8.8.4.4

# Downstream interface (to Smart TVs)
auto $DOWNSTREAM_INTERFACE
iface $DOWNSTREAM_INTERFACE inet static
    address $DOWNSTREAM_IP
    netmask $DOWNSTREAM_NETMASK
EOF
    print_success "Network interfaces configured"
fi
echo ""

# Step 3: Configure DHCP server for Smart TV network
print_info "Step 3: Configuring DHCP server..."

# Stop dnsmasq
systemctl stop dnsmasq 2>/dev/null || true

# Backup original config
mv /etc/dnsmasq.conf /etc/dnsmasq.conf.backup 2>/dev/null || true

# Create new dnsmasq configuration
cat > /etc/dnsmasq.conf << EOF
# DHCP Server Configuration for Smart TV Network
interface=$DOWNSTREAM_INTERFACE
dhcp-range=$DOWNSTREAM_DHCP_START,$DOWNSTREAM_DHCP_END,12h
dhcp-option=3,$DOWNSTREAM_IP
dhcp-option=6,8.8.8.8,8.8.4.4
server=8.8.8.8
server=8.8.4.4
log-queries
log-dhcp
EOF

systemctl enable dnsmasq
systemctl start dnsmasq
print_success "DHCP server configured and started"
echo ""

# Step 4: Enable IP forwarding
print_info "Step 4: Enabling IP forwarding..."
sysctl -w net.ipv4.ip_forward=1 > /dev/null
if ! grep -q "net.ipv4.ip_forward=1" /etc/sysctl.conf; then
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
fi
print_success "IP forwarding enabled"
echo ""

# Step 5: Configure iptables
print_info "Step 5: Configuring firewall rules..."

# Flush existing rules
iptables -F
iptables -t nat -F
iptables -t mangle -F

# Allow forwarding
iptables -P FORWARD ACCEPT

# NAT for outgoing traffic
iptables -t nat -A POSTROUTING -o $UPSTREAM_INTERFACE -j MASQUERADE

# Forward traffic between interfaces
iptables -A FORWARD -i $DOWNSTREAM_INTERFACE -o $UPSTREAM_INTERFACE -j ACCEPT
iptables -A FORWARD -i $UPSTREAM_INTERFACE -o $DOWNSTREAM_INTERFACE \
    -m state --state RELATED,ESTABLISHED -j ACCEPT

# Save rules
netfilter-persistent save
print_success "Firewall configured"
echo ""

# Step 6: Setup traffic shaping
print_info "Step 6: Configuring traffic shaping..."

# Clear existing rules
tc qdisc del dev $DOWNSTREAM_INTERFACE root 2>/dev/null || true

# Create HTB hierarchy
tc qdisc add dev $DOWNSTREAM_INTERFACE root handle 1: htb default 30
tc class add dev $DOWNSTREAM_INTERFACE parent 1: classid 1:1 htb rate $TOTAL_BANDWIDTH

# Limited class for Smart TVs
tc class add dev $DOWNSTREAM_INTERFACE parent 1:1 classid 1:10 htb \
    rate $BANDWIDTH_LIMIT ceil $BANDWIDTH_CEILING prio 2

# Unlimited class for other devices
tc class add dev $DOWNSTREAM_INTERFACE parent 1:1 classid 1:30 htb \
    rate 90mbit ceil $TOTAL_BANDWIDTH prio 1

print_success "Traffic control configured"
echo ""

# Step 7: Apply limits to specific MACs (if configured)
if [ ${#SMART_TVS[@]} -gt 0 ]; then
    print_info "Step 7: Applying MAC-based limits..."
    counter=10
    for mac in "${!SMART_TVS[@]}"; do
        device_name="${SMART_TVS[$mac]}"
        
        # Create class
        tc class add dev $DOWNSTREAM_INTERFACE parent 1:1 classid 1:$counter htb \
            rate $BANDWIDTH_LIMIT ceil $BANDWIDTH_CEILING prio 2
        
        # Mark packets
        iptables -t mangle -A POSTROUTING -m mac --mac-source $mac \
            -j MARK --set-mark $counter
        
        # Filter
        tc filter add dev $DOWNSTREAM_INTERFACE protocol ip parent 1:0 prio 1 \
            handle $counter fw flowid 1:$counter
        
        print_success "Limited $device_name ($mac)"
        ((counter++))
    done
else
    print_info "Step 7: No specific MACs configured (subnet-wide limit applied)"
fi
echo ""

# Step 8: Create startup service
print_info "Step 8: Creating systemd service..."

cat > /etc/systemd/system/bandwidth-limiter.service << 'EOF'
[Unit]
Description=Bandwidth Limiter for Smart TVs
After=network.target dnsmasq.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/bin/bandwidth-limiter-start.sh
ExecStop=/usr/local/bin/bandwidth-limiter-stop.sh

[Install]
WantedBy=multi-user.target
EOF

# Create start script
cat > /usr/local/bin/bandwidth-limiter-start.sh << EOF
#!/bin/bash
# Start bandwidth limiter
sysctl -w net.ipv4.ip_forward=1
iptables -t nat -A POSTROUTING -o $UPSTREAM_INTERFACE -j MASQUERADE
tc qdisc add dev $DOWNSTREAM_INTERFACE root handle 1: htb default 30
tc class add dev $DOWNSTREAM_INTERFACE parent 1: classid 1:1 htb rate $TOTAL_BANDWIDTH
tc class add dev $DOWNSTREAM_INTERFACE parent 1:1 classid 1:10 htb rate $BANDWIDTH_LIMIT ceil $BANDWIDTH_CEILING
EOF

# Create stop script
cat > /usr/local/bin/bandwidth-limiter-stop.sh << EOF
#!/bin/bash
# Stop bandwidth limiter
tc qdisc del dev $DOWNSTREAM_INTERFACE root 2>/dev/null || true
iptables -t nat -F
EOF

chmod +x /usr/local/bin/bandwidth-limiter-start.sh
chmod +x /usr/local/bin/bandwidth-limiter-stop.sh

systemctl daemon-reload
systemctl enable bandwidth-limiter.service
systemctl start bandwidth-limiter.service

print_success "Systemd service created and enabled"
echo ""

# Step 9: Create monitoring script
print_info "Step 9: Creating monitoring tools..."

cat > /usr/local/bin/monitor-bandwidth << 'MONITOR'
#!/bin/bash
echo "=== Bandwidth Monitor ==="
echo ""
echo "Traffic Control Status:"
tc -s qdisc show dev DOWNSTREAM_INTERFACE
echo ""
echo "Active Connections:"
iftop -i DOWNSTREAM_INTERFACE -t -s 5
MONITOR

sed -i "s/DOWNSTREAM_INTERFACE/$DOWNSTREAM_INTERFACE/g" /usr/local/bin/monitor-bandwidth
chmod +x /usr/local/bin/monitor-bandwidth

print_success "Monitoring tools installed"
echo ""

# Final summary
print_success "============================================"
print_success "  Raspberry Pi Gateway Setup Complete!"
print_success "============================================"
echo ""
echo "Network Configuration:"
echo "  • Upstream: $UPSTREAM_INTERFACE at $UPSTREAM_IP"
echo "  • Downstream: $DOWNSTREAM_INTERFACE at $DOWNSTREAM_IP"
echo "  • DHCP Range: $DOWNSTREAM_DHCP_START - $DOWNSTREAM_DHCP_END"
echo ""
echo "Bandwidth Limits:"
echo "  • Per device: $BANDWIDTH_LIMIT (ceiling: $BANDWIDTH_CEILING)"
echo "  • Total available: $TOTAL_BANDWIDTH"
echo ""
echo "Next Steps:"
echo "  1. Connect Smart TVs to the $DOWNSTREAM_INTERFACE network"
echo "  2. They will get IPs via DHCP ($DOWNSTREAM_DHCP_START-$DOWNSTREAM_DHCP_END)"
echo "  3. Bandwidth limits are automatically applied"
echo ""
echo "Monitoring:"
echo "  • View traffic: sudo monitor-bandwidth"
echo "  • Check logs: journalctl -u bandwidth-limiter"
echo "  • DHCP leases: cat /var/lib/misc/dnsmasq.leases"
echo ""
echo "Management:"
echo "  • Start: sudo systemctl start bandwidth-limiter"
echo "  • Stop: sudo systemctl stop bandwidth-limiter"
echo "  • Status: sudo systemctl status bandwidth-limiter"
echo ""
print_success "Raspberry Pi is now a bandwidth-limiting gateway!"
print_info "Reboot recommended: sudo reboot"
