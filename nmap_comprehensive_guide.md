# Comprehensive Nmap Guide for Ubuntu Linux

## Table of Contents
1. [Installation](#installation)
2. [Basic Scanning](#basic-scanning)
3. [Host Discovery](#host-discovery)
4. [Port Scanning Techniques](#port-scanning-techniques)
5. [Service and Version Detection](#service-and-version-detection)
6. [OS Detection](#os-detection)
7. [NSE Scripts](#nse-scripts)
8. [Timing and Performance](#timing-and-performance)
9. [Output Formats](#output-formats)
10. [Firewall/IDS Evasion](#firewallidis-evasion)
11. [Advanced Operations](#advanced-operations)
12. [Practical Examples](#practical-examples)

---

## Installation

```bash
# Update package list
sudo apt update

# Install nmap
sudo apt install nmap

# Verify installation
nmap --version
```

---

## Basic Scanning

### Single Host Scan
```bash
# Scan a single IP address
nmap 192.168.1.1

# Scan a hostname
nmap scanme.nmap.org
```

### Multiple Hosts
```bash
# Scan multiple specific hosts
nmap 192.168.1.1 192.168.1.2 192.168.1.3

# Scan a range of IPs
nmap 192.168.1.1-20

# Scan an entire subnet
nmap 192.168.1.0/24

# Scan multiple subnets
nmap 192.168.1.0/24 192.168.2.0/24
```

### Scan from Input File
```bash
# Scan targets listed in a file (one per line)
nmap -iL targets.txt

# Exclude hosts from scan
nmap 192.168.1.0/24 --exclude 192.168.1.1
nmap 192.168.1.0/24 --excludefile exclude.txt
```

---

## Host Discovery

### Ping Scans (Host Discovery)
```bash
# Ping scan only (no port scan)
nmap -sn 192.168.1.0/24

# TCP SYN ping (default ports 80 and 443)
nmap -PS 192.168.1.1

# TCP SYN ping on specific ports
nmap -PS22,80,443 192.168.1.1

# TCP ACK ping
nmap -PA 192.168.1.1

# UDP ping
nmap -PU 192.168.1.1

# ICMP echo ping
nmap -PE 192.168.1.1

# ICMP timestamp ping
nmap -PP 192.168.1.1

# ICMP address mask ping
nmap -PM 192.168.1.1

# IP protocol ping
nmap -PO 192.168.1.1

# ARP ping (local network only)
nmap -PR 192.168.1.0/24

# Disable ping (treat all hosts as online)
nmap -Pn 192.168.1.1
```

---

## Port Scanning Techniques

### TCP Scans
```bash
# TCP SYN scan (stealth scan, default with root)
sudo nmap -sS 192.168.1.1

# TCP Connect scan (default without root)
nmap -sT 192.168.1.1

# TCP ACK scan (for firewall rule mapping)
sudo nmap -sA 192.168.1.1

# TCP Window scan
sudo nmap -sW 192.168.1.1

# TCP Maimon scan
sudo nmap -sM 192.168.1.1

# TCP NULL scan
sudo nmap -sN 192.168.1.1

# TCP FIN scan
sudo nmap -sF 192.168.1.1

# TCP Xmas scan
sudo nmap -sX 192.168.1.1
```

### UDP Scan
```bash
# UDP scan (slower than TCP)
sudo nmap -sU 192.168.1.1

# Combined TCP and UDP scan
sudo nmap -sS -sU 192.168.1.1
```

### Other Scan Types
```bash
# SCTP INIT scan
sudo nmap -sY 192.168.1.1

# SCTP COOKIE ECHO scan
sudo nmap -sZ 192.168.1.1

# IP protocol scan
sudo nmap -sO 192.168.1.1

# FTP bounce scan (rarely works today)
nmap -b ftp.server.com 192.168.1.1
```

### Port Specification
```bash
# Scan specific ports
nmap -p 22 192.168.1.1

# Scan multiple ports
nmap -p 22,80,443 192.168.1.1

# Scan port range
nmap -p 1-100 192.168.1.1

# Scan all 65535 ports
nmap -p- 192.168.1.1

# Scan top N most common ports
nmap --top-ports 10 192.168.1.1
nmap --top-ports 100 192.168.1.1

# Scan ports by name
nmap -p http,https,ssh 192.168.1.1

# Scan UDP and TCP ports
sudo nmap -p U:53,111,137,T:21-25,80,443 192.168.1.1

# Fast scan (100 most common ports)
nmap -F 192.168.1.1

# Scan only if port is open
nmap --open 192.168.1.1
```

---

## Service and Version Detection

```bash
# Version detection
nmap -sV 192.168.1.1

# Intensity level (0-9, default is 7)
nmap -sV --version-intensity 5 192.168.1.1

# Light version detection (intensity 2)
nmap -sV --version-light 192.168.1.1

# Aggressive version detection (intensity 9)
nmap -sV --version-all 192.168.1.1

# Show version scan details
nmap -sV --version-trace 192.168.1.1
```

---

## OS Detection

```bash
# Enable OS detection
sudo nmap -O 192.168.1.1

# Aggressive OS detection
sudo nmap -O --osscan-guess 192.168.1.1

# Limit OS detection to promising targets
sudo nmap -O --osscan-limit 192.168.1.1

# Set maximum number of retries
sudo nmap -O --max-os-tries 1 192.168.1.1
```

---

## NSE Scripts

### Script Categories
```bash
# Run default scripts
nmap -sC 192.168.1.1
# OR
nmap --script=default 192.168.1.1

# Run specific script
nmap --script=http-title 192.168.1.1

# Run multiple scripts
nmap --script=http-title,http-headers 192.168.1.1

# Run scripts by category
nmap --script=vuln 192.168.1.1
nmap --script=exploit 192.168.1.1
nmap --script=auth 192.168.1.1
nmap --script=discovery 192.168.1.1
nmap --script=safe 192.168.1.1
nmap --script=intrusive 192.168.1.1
nmap --script=malware 192.168.1.1

# Run multiple categories
nmap --script="default and safe" 192.168.1.1
nmap --script="default or safe" 192.168.1.1
nmap --script="not intrusive" 192.168.1.1

# Run all scripts except specific ones
nmap --script="all and not http-*" 192.168.1.1
```

### Popular NSE Scripts
```bash
# HTTP enumeration
nmap --script=http-enum 192.168.1.1

# HTTP methods check
nmap --script=http-methods 192.168.1.1

# SSL/TLS information
nmap --script=ssl-cert,ssl-enum-ciphers 192.168.1.1

# SMB enumeration
nmap --script=smb-enum-shares,smb-enum-users 192.168.1.1

# SMB vulnerabilities
nmap --script=smb-vuln-* 192.168.1.1

# DNS enumeration
nmap --script=dns-brute scanme.nmap.org

# SSH information
nmap --script=ssh-hostkey,ssh-auth-methods 192.168.1.1

# FTP anonymous login
nmap --script=ftp-anon 192.168.1.1

# MySQL information
nmap --script=mysql-info 192.168.1.1

# Vulnerability scanning
nmap --script=vuln 192.168.1.1

# Broadcast scripts (discover hosts)
nmap --script=broadcast-*

# Pass arguments to scripts
nmap --script=http-title --script-args http.useragent="Mozilla" 192.168.1.1
```

### Script Management
```bash
# Update script database
sudo nmap --script-updatedb

# Get help for a script
nmap --script-help http-title

# List all available scripts
ls /usr/share/nmap/scripts/

# Search for scripts
ls /usr/share/nmap/scripts/ | grep http
```

---

## Timing and Performance

### Timing Templates
```bash
# Paranoid (0) - Very slow, IDS evasion
nmap -T0 192.168.1.1

# Sneaky (1) - Slow, IDS evasion
nmap -T1 192.168.1.1

# Polite (2) - Slower, less bandwidth
nmap -T2 192.168.1.1

# Normal (3) - Default timing
nmap -T3 192.168.1.1

# Aggressive (4) - Faster, assumes fast network
nmap -T4 192.168.1.1

# Insane (5) - Very fast, may miss results
nmap -T5 192.168.1.1
```

### Parallelization
```bash
# Minimum parallelism
nmap --min-parallelism 10 192.168.1.1

# Maximum parallelism
nmap --max-parallelism 100 192.168.1.1

# Minimum host group size
nmap --min-hostgroup 50 192.168.1.0/24

# Maximum host group size
nmap --max-hostgroup 100 192.168.1.0/24
```

### Timing Control
```bash
# Minimum RTT timeout
nmap --min-rtt-timeout 100ms 192.168.1.1

# Maximum RTT timeout
nmap --max-rtt-timeout 2000ms 192.168.1.1

# Initial RTT timeout
nmap --initial-rtt-timeout 500ms 192.168.1.1

# Maximum retries
nmap --max-retries 3 192.168.1.1

# Host timeout
nmap --host-timeout 30m 192.168.1.0/24

# Scan delay (time between probes)
nmap --scan-delay 1s 192.168.1.1

# Maximum scan delay
nmap --max-scan-delay 10s 192.168.1.1
```

### Rate Limiting
```bash
# Maximum packets per second
nmap --max-rate 100 192.168.1.1

# Minimum packets per second
nmap --min-rate 10 192.168.1.1
```

---

## Output Formats

### Standard Output
```bash
# Normal output
nmap 192.168.1.1

# Verbose output
nmap -v 192.168.1.1

# Very verbose
nmap -vv 192.168.1.1

# Debugging
nmap -d 192.168.1.1

# More debugging
nmap -dd 192.168.1.1
```

### File Output
```bash
# Normal output to file
nmap -oN output.txt 192.168.1.1

# XML output
nmap -oX output.xml 192.168.1.1

# Grepable output
nmap -oG output.gnmap 192.168.1.1

# All formats
nmap -oA outputname 192.168.1.1

# Script kiddie output (just for fun)
nmap -oS output.txt 192.168.1.1

# Append to file instead of overwrite
nmap -oN output.txt --append-output 192.168.1.1
```

### Interactive Output
```bash
# Show host status while scanning
nmap --stats-every 10s 192.168.1.0/24

# Disable runtime interaction
nmap --noninteractive 192.168.1.1

# Show reason for port state
nmap --reason 192.168.1.1

# Show packets sent and received
nmap --packet-trace 192.168.1.1
```

---

## Firewall/IDS Evasion

### Fragment Packets
```bash
# Fragment packets
sudo nmap -f 192.168.1.1

# Set custom MTU
sudo nmap --mtu 24 192.168.1.1
```

### Decoy Scanning
```bash
# Use decoys
sudo nmap -D RND:10 192.168.1.1

# Specify decoy IPs
sudo nmap -D 192.168.1.5,192.168.1.6,ME 192.168.1.1
```

### Source Port Manipulation
```bash
# Use specific source port
sudo nmap --source-port 53 192.168.1.1
# OR
sudo nmap -g 53 192.168.1.1
```

### Spoofing
```bash
# Spoof source IP
sudo nmap -S 192.168.1.5 192.168.1.1

# Spoof MAC address
sudo nmap --spoof-mac 0 192.168.1.1
sudo nmap --spoof-mac Apple 192.168.1.1
sudo nmap --spoof-mac 00:11:22:33:44:55 192.168.1.1
```

### Other Evasion Techniques
```bash
# Randomize host order
nmap --randomize-hosts 192.168.1.0/24

# Add random data to packets
sudo nmap --data-length 25 192.168.1.1

# Use bad checksums
sudo nmap --badsum 192.168.1.1

# Idle/Zombie scan
sudo nmap -sI zombie.host.com 192.168.1.1
```

---

## Advanced Operations

### IPv6 Scanning
```bash
# IPv6 scan
nmap -6 2001:db8::1

# IPv6 ping sweep
nmap -6 -sn 2001:db8::/64
```

### Interface and Routing
```bash
# Specify network interface
nmap -e eth0 192.168.1.1

# Disable ARP/ND ping
nmap --disable-arp-ping 192.168.1.1

# DNS resolution
nmap -n 192.168.1.1  # Never resolve
nmap -R 192.168.1.1  # Always resolve

# Specify DNS servers
nmap --dns-servers 8.8.8.8,8.8.4.4 192.168.1.1

# Traceroute
nmap --traceroute 192.168.1.1
```

### Aggressive Scan
```bash
# Aggressive mode (OS detection, version detection, script scanning, traceroute)
sudo nmap -A 192.168.1.1

# Aggressive mode with specific ports
sudo nmap -A -p- 192.168.1.1
```

### Resume Scans
```bash
# Resume interrupted scan
nmap --resume output.gnmap
```

### Privileged vs Unprivileged
```bash
# Always use privileged mode
sudo nmap --privileged 192.168.1.1

# Never use privileged mode
nmap --unprivileged 192.168.1.1
```

---

## Practical Examples

### Quick Network Survey
```bash
# Quick scan of live hosts and open ports
nmap -T4 -F 192.168.1.0/24
```

### Comprehensive Single Host Scan
```bash
# Full scan with OS detection, version detection, and default scripts
sudo nmap -A -T4 -p- 192.168.1.1
```

### Web Server Enumeration
```bash
# Scan web server with HTTP scripts
nmap -p 80,443 --script=http-enum,http-title,http-headers 192.168.1.1
```

### Vulnerability Assessment
```bash
# Scan for common vulnerabilities
sudo nmap -sV --script=vuln 192.168.1.1
```

### Stealth Scan
```bash
# Slow, fragmented scan with decoys
sudo nmap -sS -T1 -f -D RND:10 192.168.1.1
```

### Network Discovery
```bash
# Find all live hosts on network
nmap -sn 192.168.1.0/24

# Find hosts with specific ports open
nmap -p 22 --open 192.168.1.0/24
```

### SMB Share Discovery
```bash
# Enumerate SMB shares
nmap -p 445 --script=smb-enum-shares,smb-enum-users 192.168.1.1
```

### SSL/TLS Analysis
```bash
# Check SSL/TLS configuration
nmap -p 443 --script=ssl-cert,ssl-enum-ciphers,ssl-known-key 192.168.1.1
```

### Database Service Discovery
```bash
# Scan for database services
nmap -p 1433,3306,5432,1521 --script=ms-sql-info,mysql-info,pgsql-info,oracle-info 192.168.1.0/24
```

### Scan with Custom NSE Script
```bash
# Run custom script with arguments
nmap --script=/path/to/custom-script.nse --script-args arg1=value1 192.168.1.1
```

### Monitor for New Hosts
```bash
# Continuous scan every 5 minutes
watch -n 300 'nmap -sn 192.168.1.0/24'
```

### Export Results for Analysis
```bash
# Scan and export to multiple formats
sudo nmap -A -oA network-scan 192.168.1.0/24

# Convert XML to HTML
xsltproc network-scan.xml -o network-scan.html
```

---

## Tips and Best Practices

1. **Use sudo for advanced scans**: Many scan types require root privileges (SYN scan, OS detection, etc.)

2. **Start with host discovery**: Use `-sn` to find live hosts before port scanning

3. **Adjust timing**: Use `-T4` for faster scans on reliable networks, `-T2` for slower/unreliable networks

4. **Save output**: Always use `-oA` to save results in multiple formats

5. **Be ethical**: Only scan networks and systems you own or have permission to test

6. **Check firewall logs**: Your scans may trigger IDS/IPS alerts

7. **Update regularly**: Keep nmap and its scripts updated
   ```bash
   sudo apt update && sudo apt upgrade nmap
   sudo nmap --script-updatedb
   ```

8. **Combine options**: Most options can be combined for comprehensive scans
   ```bash
   sudo nmap -sS -sV -O -A -T4 -p- --script=default 192.168.1.1
   ```

9. **Read the documentation**: Use `man nmap` or `nmap --help` for detailed information

10. **Test in lab environment**: Practice scanning techniques in isolated lab networks first

---

## Common Port Numbers Reference

- **20/21**: FTP
- **22**: SSH
- **23**: Telnet
- **25**: SMTP
- **53**: DNS
- **80**: HTTP
- **110**: POP3
- **143**: IMAP
- **443**: HTTPS
- **445**: SMB
- **3306**: MySQL
- **3389**: RDP
- **5432**: PostgreSQL
- **8080**: HTTP Alternate

---

## Legal Disclaimer

**Important**: Only use nmap on networks and systems you own or have explicit permission to scan. Unauthorized scanning may be illegal in your jurisdiction and could result in serious consequences. Always obtain written permission before scanning any network or system you don't own.

---

## Additional Resources

- Official Documentation: https://nmap.org/book/
- NSE Script Library: https://nmap.org/nsedoc/
- Man Page: `man nmap`
- Nmap Reference Guide: https://nmap.org/book/man.html
