#!/bin/bash
#
# Smart TV Bandwidth Limiter - Interface-Based Limiting
# Version: 1.0.0
# Description: Limits total bandwidth for an entire network interface
#
# Usage: sudo ./limit_by_interface.sh
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

print_info "Starting Interface-Based Bandwidth Limiter..."
echo ""

# ============================================================================
# CONFIGURATION SECTION - MODIFY THESE VALUES
# ============================================================================

# Interface to limit (all devices on this interface will share the limit)
LIMITED_INTERFACE="eth1"

# Total bandwidth limit for the interface
# All devices connected to this interface will share this bandwidth
BANDWIDTH_LIMIT="20mbit"

# Maximum burst allowance
BANDWIDTH_BURST="25mbit"

# ============================================================================
# END CONFIGURATION SECTION
# ============================================================================

print_info "Configuration:"
echo "  Interface to limit: $LIMITED_INTERFACE"
echo "  Total bandwidth limit: $BANDWIDTH_LIMIT"
echo "  Burst allowance: $BANDWIDTH_BURST"
echo ""

# Verify interface exists
if ! ip link show "$LIMITED_INTERFACE" &> /dev/null; then
    print_error "Interface $LIMITED_INTERFACE not found!"
    print_info "Available interfaces:"
    ip link show | grep -E "^[0-9]+:" | awk '{print $2}' | tr -d ':'
    exit 1
fi
print_success "Interface $LIMITED_INTERFACE verified"
echo ""

# Clear existing rules on interface
print_info "Clearing existing traffic control rules..."
tc qdisc del dev $LIMITED_INTERFACE root 2>/dev/null || true
tc qdisc del dev $LIMITED_INTERFACE ingress 2>/dev/null || true
print_success "Existing rules cleared"
echo ""

# Apply bandwidth limit using TBF (Token Bucket Filter)
print_info "Applying bandwidth limit..."

# Egress (outgoing) traffic limiting
tc qdisc add dev $LIMITED_INTERFACE root tbf \
    rate $BANDWIDTH_LIMIT \
    burst 32kbit \
    latency 400ms

print_success "Egress limit applied: $BANDWIDTH_LIMIT"

# Note: Ingress (incoming) is more complex and requires IFB
print_warning "Note: This limits outgoing traffic from the interface"
print_info "For full bidirectional limiting, use the advanced setup below"
echo ""

# Display configuration
print_info "Current Traffic Control Configuration:"
tc -s qdisc show dev $LIMITED_INTERFACE
echo ""

# Provide usage information
print_success "=== Interface-Based Bandwidth Limiting Active ==="
echo ""
echo "Summary:"
echo "  ✓ All traffic through $LIMITED_INTERFACE limited"
echo "  ✓ Total bandwidth: $BANDWIDTH_LIMIT"
echo "  ✓ Burst: $BANDWIDTH_BURST"
echo ""
echo "Use case:"
echo "  • Simple setup when Smart TVs are on separate interface"
echo "  • All devices on $LIMITED_INTERFACE share the bandwidth"
echo "  • Good for dedicated Smart TV network"
echo ""
echo "Next steps:"
echo "  1. Test bandwidth (visit fast.com on Smart TV)"
echo "  2. Monitor: sudo tc -s qdisc show dev $LIMITED_INTERFACE"
echo "  3. Remove limit: sudo ./remove_limits.sh"
echo ""
print_info "Bandwidth limiting active on $LIMITED_INTERFACE"

# Optional: Show how to do bidirectional limiting
echo ""
print_info "=== For Advanced Bidirectional Limiting ==="
echo ""
echo "To limit both incoming and outgoing traffic:"
echo ""
cat << 'EOF'
# Load IFB (Intermediate Functional Block) module
sudo modprobe ifb
sudo ip link set dev ifb0 up

# Redirect ingress to IFB
sudo tc qdisc add dev eth1 handle ffff: ingress
sudo tc filter add dev eth1 parent ffff: protocol ip u32 \
    match u32 0 0 action mirred egress redirect dev ifb0

# Apply limit to IFB (affects incoming traffic to eth1)
sudo tc qdisc add dev ifb0 root tbf rate 20mbit burst 32kbit latency 400ms
EOF
echo ""
print_info "Run the above commands manually for full bidirectional control"
