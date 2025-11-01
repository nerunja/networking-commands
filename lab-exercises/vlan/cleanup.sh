#!/bin/bash

#############################################
# Network Cleanup Script
# 
# Purpose: Remove all network namespaces, bridges,
#          and virtual interfaces created by setup scripts
#
# Author: Network Specialist
# Date: 2025-11-01
# Version: 1.0
#
# Usage: sudo ./cleanup.sh
#############################################

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}===${NC} $1 ${BLUE}===${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   print_error "This script must be run as root (use sudo)"
   exit 1
fi

print_status "Network Cleanup Script"
echo ""

# Ask for confirmation
read -p "$(echo -e ${YELLOW}This will remove ALL network namespaces and bridges. Continue? [y/N]: ${NC})" -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_info "Cleanup cancelled"
    exit 0
fi

echo ""
print_status "Starting Cleanup Process"
echo ""

# =============================================================================
# Step 1: Remove Network Namespaces
# =============================================================================
print_status "Removing Network Namespaces"

# List existing namespaces first
EXISTING_NS=$(ip netns list 2>/dev/null)
if [ -n "$EXISTING_NS" ]; then
    print_info "Found existing namespaces:"
    echo "$EXISTING_NS"
    echo ""
fi

# Remove pc10 namespace
if ip netns list 2>/dev/null | grep -q "pc10"; then
    ip netns delete pc10 2>/dev/null
    if [ $? -eq 0 ]; then
        print_success "Removed namespace: pc10"
    else
        print_error "Failed to remove namespace: pc10"
    fi
else
    print_info "Namespace 'pc10' does not exist"
fi

# Remove pc20 namespace
if ip netns list 2>/dev/null | grep -q "pc20"; then
    ip netns delete pc20 2>/dev/null
    if [ $? -eq 0 ]; then
        print_success "Removed namespace: pc20"
    else
        print_error "Failed to remove namespace: pc20"
    fi
else
    print_info "Namespace 'pc20' does not exist"
fi

# Remove router namespace
if ip netns list 2>/dev/null | grep -q "router"; then
    ip netns delete router 2>/dev/null
    if [ $? -eq 0 ]; then
        print_success "Removed namespace: router"
    else
        print_error "Failed to remove namespace: router"
    fi
else
    print_info "Namespace 'router' does not exist"
fi

echo ""

# =============================================================================
# Step 2: Remove Bridges
# =============================================================================
print_status "Removing Bridges"

# Remove br0 (VLAN-aware bridge)
if ip link show br0 &>/dev/null; then
    ip link set br0 down 2>/dev/null
    ip link delete br0 2>/dev/null
    if [ $? -eq 0 ]; then
        print_success "Removed bridge: br0"
    else
        print_error "Failed to remove bridge: br0"
    fi
else
    print_info "Bridge 'br0' does not exist"
fi

# Remove br10 (separate bridge for VLAN 10)
if ip link show br10 &>/dev/null; then
    ip link set br10 down 2>/dev/null
    ip link delete br10 2>/dev/null
    if [ $? -eq 0 ]; then
        print_success "Removed bridge: br10"
    else
        print_error "Failed to remove bridge: br10"
    fi
else
    print_info "Bridge 'br10' does not exist"
fi

# Remove br20 (separate bridge for VLAN 20)
if ip link show br20 &>/dev/null; then
    ip link set br20 down 2>/dev/null
    ip link delete br20 2>/dev/null
    if [ $? -eq 0 ]; then
        print_success "Removed bridge: br20"
    else
        print_error "Failed to remove bridge: br20"
    fi
else
    print_info "Bridge 'br20' does not exist"
fi

echo ""

# =============================================================================
# Step 3: Remove Virtual Ethernet Pairs
# =============================================================================
print_status "Removing Virtual Ethernet Pairs"

# Note: Deleting one end of a veth pair automatically removes the other end
# Also, deleting a namespace removes all interfaces inside it

# Remove any remaining veth pairs in default namespace
VETH_INTERFACES=(
    "veth-pc10"
    "veth-pc20"
    "veth-sw10"
    "veth-sw20"
    "veth-trunk"
    "veth-router"
    "veth-r10"
    "veth-r20"
    "veth-sw-r10"
    "veth-sw-r20"
)

for iface in "${VETH_INTERFACES[@]}"; do
    if ip link show "$iface" &>/dev/null; then
        ip link delete "$iface" 2>/dev/null
        if [ $? -eq 0 ]; then
            print_success "Removed interface: $iface"
        else
            print_warning "Could not remove interface: $iface (may already be gone)"
        fi
    fi
done

echo ""

# =============================================================================
# Step 4: Verification
# =============================================================================
print_status "Verification"

# Check for remaining namespaces
REMAINING_NS=$(ip netns list 2>/dev/null | grep -E "pc10|pc20|router")
if [ -z "$REMAINING_NS" ]; then
    print_success "All target namespaces removed"
else
    print_warning "Some namespaces still exist:"
    echo "$REMAINING_NS"
fi

# Check for remaining bridges
REMAINING_BRIDGES=""
for bridge in br0 br10 br20; do
    if ip link show "$bridge" &>/dev/null; then
        REMAINING_BRIDGES="$REMAINING_BRIDGES $bridge"
    fi
done

if [ -z "$REMAINING_BRIDGES" ]; then
    print_success "All target bridges removed"
else
    print_warning "Some bridges still exist:$REMAINING_BRIDGES"
fi

# Check for remaining veth interfaces
REMAINING_VETH=$(ip link show | grep -E "veth-(pc|sw|trunk|router|r)" | awk -F: '{print $2}' | tr -d ' ')
if [ -z "$REMAINING_VETH" ]; then
    print_success "All target veth interfaces removed"
else
    print_warning "Some veth interfaces still exist:"
    echo "$REMAINING_VETH"
fi

echo ""

# =============================================================================
# Step 5: Summary
# =============================================================================
print_status "Cleanup Summary"
echo ""

# Show current state
echo "Current namespaces:"
CURRENT_NS=$(ip netns list 2>/dev/null)
if [ -z "$CURRENT_NS" ]; then
    echo "  (none)"
else
    echo "$CURRENT_NS"
fi
echo ""

echo "Current bridges:"
CURRENT_BRIDGES=$(ip link show type bridge 2>/dev/null | grep "^[0-9]" | awk -F: '{print $2}' | tr -d ' ')
if [ -z "$CURRENT_BRIDGES" ]; then
    echo "  (none)"
else
    echo "$CURRENT_BRIDGES"
fi
echo ""

echo "Current veth interfaces:"
CURRENT_VETH=$(ip link show type veth 2>/dev/null | grep "^[0-9]" | awk -F: '{print $2}' | awk '{print $1}')
if [ -z "$CURRENT_VETH" ]; then
    echo "  (none)"
else
    echo "$CURRENT_VETH"
fi
echo ""

# Final status
if [ -z "$REMAINING_NS" ] && [ -z "$REMAINING_BRIDGES" ] && [ -z "$REMAINING_VETH" ]; then
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  ✅ Cleanup completed successfully!${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    print_info "Your system is now clean. You can run setup scripts again if needed."
    exit 0
else
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}  ⚠️  Cleanup completed with warnings${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    print_warning "Some resources could not be removed. This is usually harmless."
    print_info "You may need to manually remove them or reboot the system."
    exit 0
fi
