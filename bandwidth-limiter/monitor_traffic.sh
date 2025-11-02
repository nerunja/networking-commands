#!/bin/bash
#
# Traffic Monitoring Script for Bandwidth Limiter
# Version: 1.0.0
# Description: Real-time monitoring of bandwidth usage and traffic control
#
# Usage: sudo ./monitor_traffic.sh
#

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}        ${GREEN}Bandwidth Limiter - Traffic Monitor${NC}             ${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
}

print_section() {
    echo ""
    echo -e "${BLUE}━━━ $1 ━━━${NC}"
}

# Check root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}[ERROR]${NC} This script must be run as root (use sudo)"
   exit 1
fi

# Function to detect which interface has tc configured
detect_interface() {
    for iface in $(ip link show | grep -oP '^\d+: \K[^:]+(?=:)'); do
        if tc qdisc show dev $iface 2>/dev/null | grep -q "htb\|tbf"; then
            echo $iface
            return
        fi
    done
    echo ""
}

# Detect interface
INTERFACE=$(detect_interface)

if [ -z "$INTERFACE" ]; then
    echo -e "${RED}[ERROR]${NC} No traffic control found on any interface"
    echo ""
    echo "Available interfaces:"
    ip link show | grep -oP '^\d+: \K[^:]+(?=:)'
    echo ""
    echo "Please run one of the setup scripts first:"
    echo "  • sudo ./setup_traffic_shaping.sh"
    echo "  • sudo ./limit_by_mac.sh"
    echo "  • sudo ./limit_by_interface.sh"
    exit 1
fi

# Function to format bytes
format_bytes() {
    local bytes=$1
    if [ $bytes -lt 1024 ]; then
        echo "${bytes}B"
    elif [ $bytes -lt 1048576 ]; then
        echo "$(($bytes / 1024))KB"
    elif [ $bytes -lt 1073741824 ]; then
        echo "$(($bytes / 1048576))MB"
    else
        echo "$(($bytes / 1073741824))GB"
    fi
}

# Function to calculate rate in Mbps
calculate_rate() {
    local bytes=$1
    local seconds=$2
    local bits=$((bytes * 8))
    local mbps=$(echo "scale=2; $bits / $seconds / 1000000" | bc 2>/dev/null || echo "0")
    echo "${mbps}Mbps"
}

# Main monitoring loop
clear
print_header
echo ""
echo -e "${GREEN}Monitoring interface:${NC} $INTERFACE"
echo -e "${YELLOW}Press Ctrl+C to exit${NC}"
echo ""

# Check if required tools are installed
command -v iftop &> /dev/null && HAS_IFTOP=1 || HAS_IFTOP=0
command -v nethogs &> /dev/null && HAS_NETHOGS=1 || HAS_NETHOGS=0

if [ $HAS_IFTOP -eq 0 ]; then
    echo -e "${YELLOW}[INFO]${NC} Install iftop for better monitoring: sudo apt install iftop"
fi

# Function to display menu
show_menu() {
    clear
    print_header
    echo ""
    echo -e "${GREEN}Monitoring:${NC} $INTERFACE"
    echo ""
    echo "Choose monitoring mode:"
    echo "  1) Quick Summary (default)"
    echo "  2) Real-time tc statistics"
    echo "  3) Top bandwidth consumers (iftop)"
    echo "  4) Per-process bandwidth (nethogs)"
    echo "  5) Connection tracking"
    echo "  6) Export statistics to file"
    echo "  7) Exit"
    echo ""
    read -p "Select option [1-7]: " choice
    echo ""
}

# Function for quick summary
quick_summary() {
    while true; do
        clear
        print_header
        
        print_section "Traffic Control Status on $INTERFACE"
        tc -s qdisc show dev $INTERFACE
        
        print_section "Traffic Classes and Usage"
        tc -s class show dev $INTERFACE | while read line; do
            if [[ $line =~ class\ htb\ ([0-9:]+) ]]; then
                echo -e "${GREEN}Class ${BASH_REMATCH[1]}${NC}"
            elif [[ $line =~ rate\ ([0-9.]+)([KMG]?bit) ]]; then
                echo -e "  Rate: ${YELLOW}${BASH_REMATCH[1]}${BASH_REMATCH[2]}${NC}"
            elif [[ $line =~ Sent\ ([0-9]+)\ bytes ]]; then
                bytes=${BASH_REMATCH[1]}
                formatted=$(format_bytes $bytes)
                echo -e "  Sent: ${CYAN}$formatted${NC}"
            fi
        done
        
        print_section "Network Statistics"
        # Get interface stats
        rx_bytes=$(cat /sys/class/net/$INTERFACE/statistics/rx_bytes 2>/dev/null || echo 0)
        tx_bytes=$(cat /sys/class/net/$INTERFACE/statistics/tx_bytes 2>/dev/null || echo 0)
        rx_packets=$(cat /sys/class/net/$INTERFACE/statistics/rx_packets 2>/dev/null || echo 0)
        tx_packets=$(cat /sys/class/net/$INTERFACE/statistics/tx_packets 2>/dev/null || echo 0)
        
        echo -e "Received:    ${CYAN}$(format_bytes $rx_bytes)${NC} ($rx_packets packets)"
        echo -e "Transmitted: ${CYAN}$(format_bytes $tx_bytes)${NC} ($tx_packets packets)"
        
        print_section "Active Connections"
        conn_count=$(ss -tan | grep ESTAB | wc -l)
        echo -e "Established connections: ${GREEN}$conn_count${NC}"
        
        print_section "Top 5 Active IPs"
        ss -tan | grep ESTAB | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -rn | head -5
        
        echo ""
        echo -e "${YELLOW}Updating every 2 seconds... Press Ctrl+C to return to menu${NC}"
        sleep 2
    done
}

# Function for real-time tc stats
tc_stats() {
    clear
    print_header
    echo ""
    echo -e "${GREEN}Real-time Traffic Control Statistics${NC}"
    echo -e "${YELLOW}Press Ctrl+C to return to menu${NC}"
    echo ""
    watch -n 1 -c "tc -s class show dev $INTERFACE"
}

# Function for iftop monitoring
iftop_monitor() {
    if [ $HAS_IFTOP -eq 0 ]; then
        echo -e "${RED}[ERROR]${NC} iftop not installed"
        echo "Install: sudo apt install iftop"
        read -p "Press Enter to continue..."
        return
    fi
    clear
    print_header
    echo ""
    echo -e "${GREEN}Top Bandwidth Consumers${NC}"
    echo ""
    iftop -i $INTERFACE -t -s 10 -n
    read -p "Press Enter to continue..."
}

# Function for nethogs monitoring
nethogs_monitor() {
    if [ $HAS_NETHOGS -eq 0 ]; then
        echo -e "${RED}[ERROR]${NC} nethogs not installed"
        echo "Install: sudo apt install nethogs"
        read -p "Press Enter to continue..."
        return
    fi
    clear
    print_header
    echo ""
    echo -e "${GREEN}Per-Process Bandwidth Usage${NC}"
    echo -e "${YELLOW}Press q to exit nethogs${NC}"
    echo ""
    sleep 2
    nethogs $INTERFACE
}

# Function for connection tracking
connection_tracking() {
    clear
    print_header
    
    while true; do
        clear
        print_header
        
        print_section "Active TCP Connections on $INTERFACE"
        ss -tanp | grep ESTAB | grep -v "127.0.0.1" | head -20
        
        print_section "Connection Summary"
        echo "ESTABLISHED: $(ss -tan | grep ESTAB | wc -l)"
        echo "TIME_WAIT:   $(ss -tan | grep TIME-WAIT | wc -l)"
        echo "LISTEN:      $(ss -tln | grep LISTEN | wc -l)"
        
        print_section "Top 10 Connected IPs"
        ss -tan | grep ESTAB | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -rn | head -10
        
        echo ""
        echo -e "${YELLOW}Updating every 3 seconds... Press Ctrl+C to return to menu${NC}"
        sleep 3
    done
}

# Function to export statistics
export_stats() {
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    OUTPUT_FILE="bandwidth_stats_${TIMESTAMP}.txt"
    
    echo "Exporting statistics to $OUTPUT_FILE..."
    
    {
        echo "Bandwidth Limiter Statistics Export"
        echo "Generated: $(date)"
        echo "Interface: $INTERFACE"
        echo ""
        
        echo "=== Traffic Control Configuration ==="
        tc qdisc show dev $INTERFACE
        echo ""
        tc class show dev $INTERFACE
        echo ""
        tc filter show dev $INTERFACE
        echo ""
        
        echo "=== Traffic Statistics ==="
        tc -s qdisc show dev $INTERFACE
        echo ""
        tc -s class show dev $INTERFACE
        echo ""
        
        echo "=== Interface Statistics ==="
        ip -s link show $INTERFACE
        echo ""
        
        echo "=== Active Connections ==="
        ss -tan | head -50
        echo ""
        
        echo "=== iptables Rules ==="
        iptables -t nat -L -v -n
        echo ""
        iptables -t mangle -L -v -n
        echo ""
        
    } > "$OUTPUT_FILE"
    
    echo -e "${GREEN}[SUCCESS]${NC} Statistics exported to: $OUTPUT_FILE"
    echo ""
    read -p "Press Enter to continue..."
}

# Trap Ctrl+C to return to menu instead of exiting
trap 'echo ""; return' INT

# Main loop
while true; do
    show_menu
    
    case $choice in
        1)
            quick_summary
            ;;
        2)
            tc_stats
            ;;
        3)
            iftop_monitor
            ;;
        4)
            nethogs_monitor
            ;;
        5)
            connection_tracking
            ;;
        6)
            export_stats
            ;;
        7)
            echo "Exiting monitor..."
            exit 0
            ;;
        *)
            quick_summary
            ;;
    esac
done
