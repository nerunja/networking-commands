# Comprehensive Networking Expert Curriculum for Ubuntu Linux

## 🎯 Learning Path Overview

This curriculum is designed to take you from foundational concepts to advanced networking expertise on Ubuntu Linux, with emphasis on practical skills and security.

---

## **Phase 1: Networking Fundamentals (4-6 weeks)**

### Module 1.1: Core Networking Concepts
- **OSI Model & TCP/IP Stack**
  - All 7 layers in detail
  - Encapsulation and de-encapsulation
  - Protocol interactions

- **IP Addressing & Subnetting**
  - IPv4 addressing and CIDR notation
  - Subnetting and supernetting
  - IPv6 fundamentals
  - Private vs public IP ranges

- **Network Protocols**
  - TCP vs UDP
  - ICMP, ARP, DHCP, DNS
  - HTTP/HTTPS basics
  - Common port numbers (memorize top 100)

### Module 1.2: Network Hardware & Topologies
- Switches, routers, hubs, and bridges
- Network topologies (star, mesh, ring)
- VLANs and trunking concepts
- MAC addresses and switching

---

## **Phase 2: Linux/Ubuntu Networking Basics (3-4 weeks)**

### Module 2.1: Linux Fundamentals
- **Command Line Mastery**
  - File system navigation
  - File permissions and ownership
  - Package management (apt, dpkg, snap)
  - System services (systemd)
  - Text editors (vim/nano)

- **User & Permission Management**
  - sudo and root access
  - User groups and privileges
  - File permissions (chmod, chown)

### Module 2.2: Basic Network Configuration
- **Network Interface Management**
  ```bash
  ip addr, ip link, ip route
  ifconfig (legacy)
  nmcli, nmtui (NetworkManager)
  netplan configuration
  ```

- **DNS Configuration**
  - /etc/hosts
  - /etc/resolv.conf
  - systemd-resolved

- **Basic Network Commands**
  ```bash
  ping, traceroute, mtr
  netstat, ss
  dig, nslookup, host
  curl, wget
  ```

---

## **Phase 3: Intermediate Ubuntu Networking (4-6 weeks)**

### Module 3.1: Advanced Network Configuration
- **Static IP Configuration**
  - Netplan YAML configuration
  - Network interface bonding
  - Bridge configuration

- **Routing & Forwarding**
  - Static routing
  - IP forwarding
  - Policy-based routing
  - iptables basics

- **Network Services**
  - DHCP server setup (isc-dhcp-server)
  - DNS server (bind9, dnsmasq)
  - FTP/SFTP servers
  - Web server basics (Apache/Nginx)

### Module 3.2: Network Monitoring & Troubleshooting
- **Diagnostic Tools**
  ```bash
  tcpdump
  wireshark/tshark
  iftop, nethogs, iptraf-ng
  ethtool
  lsof for network connections
  ```

- **Log Analysis**
  - /var/log/syslog
  - journalctl for network services
  - Log rotation and management

- **Performance Monitoring**
  - sar, vmstat, iostat
  - Bandwidth monitoring
  - Network latency analysis

---

## **Phase 4: Network Security Fundamentals (4-5 weeks)**

### Module 4.1: Firewall & Access Control
- **iptables/nftables**
  - Filter, NAT, mangle tables
  - Common rules and chains
  - Port forwarding and masquerading
  - Rate limiting and connection tracking

- **UFW (Uncomplicated Firewall)**
  - Basic configuration
  - Application profiles
  - Logging and monitoring

- **fail2ban**
  - Intrusion prevention
  - Custom jail configuration
  - Log monitoring

### Module 4.2: Secure Communication
- **SSH**
  - Key-based authentication
  - SSH config file
  - Port forwarding and tunneling
  - SSH hardening

- **VPN Technologies**
  - OpenVPN setup and configuration
  - WireGuard basics
  - IPsec fundamentals

- **SSL/TLS**
  - Certificate management
  - Let's Encrypt with certbot
  - HTTPS configuration

---

## **Phase 5: Network Reconnaissance & Scanning (3-4 weeks)**

### Module 5.1: Information Gathering
- **Passive Reconnaissance**
  - WHOIS lookups
  - DNS enumeration (dig, dnsenum, fierce)
  - Google dorking
  - Shodan, Censys

- **Active Reconnaissance**
  - **Nmap (Deep Dive)** ⭐
    - All scan types
    - NSE scripts
    - OS and service detection
    - Custom timing and evasion
    - Output parsing and analysis

- **Network Mapping**
  - netdiscover
  - arp-scan
  - fping
  - masscan for large networks

### Module 5.2: Service Enumeration
- Banner grabbing
- SMB enumeration (enum4linux, smbclient)
- SNMP enumeration (snmpwalk)
- Directory enumeration (gobuster, dirb)

---

## **Phase 6: Advanced Network Attacks & Defense (5-6 weeks)**

### Module 6.1: Man-in-the-Middle Attacks
- **Bettercap (Deep Dive)** ⭐
  - ARP spoofing
  - DNS spoofing
  - HTTP/HTTPS interception
  - SSL stripping
  - Packet sniffing
  - Wireless attacks
  - Caplet scripting

- **Other MITM Tools**
  - Ettercap
  - mitmproxy
  - Responder

### Module 6.2: Network Exploitation
- **Password Attacks**
  - Hydra for brute forcing
  - Medusa
  - John the Ripper for hash cracking
  - Hashcat

- **Wireless Security**
  - WiFi fundamentals (802.11)
  - Aircrack-ng suite
  - WPA/WPA2 attacks
  - WPS attacks
  - Evil twin attacks
  - Wireless packet injection

### Module 6.3: Network Defense
- **Intrusion Detection Systems**
  - Snort configuration
  - Suricata setup
  - AIDE (file integrity)

- **Network Security Monitoring**
  - Security Onion
  - Zeek (Bro) IDS
  - ELK Stack for log analysis

---

## **Phase 7: Advanced Topics (6-8 weeks)**

### Module 7.1: Advanced Protocols & Services
- **Network Automation**
  - Bash scripting for networking
  - Python with scapy
  - Ansible for network automation
  - Netmiko for device management

- **Advanced Routing**
  - OSPF, BGP basics
  - FRRouting on Linux
  - MPLS concepts
  - SD-WAN fundamentals

- **Load Balancing**
  - HAProxy
  - Nginx as load balancer
  - Keepalived for HA

### Module 7.2: Containerization & Virtualization
- **Docker Networking**
  - Bridge, host, overlay networks
  - Container networking
  - Docker Compose networking

- **Virtualization**
  - KVM/QEMU networking
  - Virtual networking with libvirt
  - Open vSwitch

### Module 7.3: Cloud Networking (Ubuntu focus)
- **AWS/Azure/GCP Basics**
  - VPC configuration
  - Security groups
  - Cloud networking concepts

- **Software Defined Networking**
  - OpenFlow basics
  - Mininet for SDN testing

---

## **Phase 8: Specialized Skills (Ongoing)**

### Module 8.1: Penetration Testing Frameworks
- **Metasploit Framework**
  - Exploitation basics
  - Auxiliary modules
  - Post-exploitation

- **Other Frameworks**
  - Cobalt Strike (for red team)
  - Burp Suite for web applications
  - OWASP ZAP

### Module 8.2: Network Forensics
- **Packet Analysis**
  - Advanced Wireshark
  - NetworkMiner
  - Xplico

- **Incident Response**
  - Log correlation
  - IOC identification
  - Timeline analysis

### Module 8.3: Compliance & Best Practices
- Security frameworks (NIST, ISO 27001)
- Network hardening checklists
- Documentation practices
- Change management

---

## **Essential Tools to Master**

### Category: Discovery & Reconnaissance
- ✅ **nmap** (comprehensive guide provided)
- ping, traceroute, mtr
- netdiscover, arp-scan
- masscan
- Shodan CLI

### Category: Packet Analysis
- Wireshark/tshark
- tcpdump
- **bettercap** (comprehensive guide provided)
- Ettercap

### Category: Network Management
- ip suite (iproute2)
- iptables/nftables
- netplan
- NetworkManager (nmcli)

### Category: Monitoring & Performance
- iftop, nethogs, nload
- vnstat
- sar, iotop
- Nagios/Zabbix

### Category: Security Testing
- Hydra, Medusa
- Aircrack-ng suite
- John the Ripper, Hashcat
- Metasploit
- Burp Suite

### Category: Scripting & Automation
- Bash
- Python (with scapy, paramiko, netmiko)
- Ansible

---

## **Practical Projects to Build Skills**

### Beginner Projects
1. **Home Lab Network**
   - Set up multiple VMs with different network configurations
   - Configure DHCP and DNS servers
   - Implement firewall rules

2. **Network Scanner**
   - Write a Python script using scapy
   - Implement basic port scanning
   - Add service detection

3. **Network Monitor Dashboard**
   - Use iftop, nethogs for real-time monitoring
   - Create bash scripts for automated checks
   - Set up alerting

### Intermediate Projects
4. **Corporate Network Simulation**
   - Multiple VLANs
   - DMZ configuration
   - VPN server
   - IDS/IPS implementation

5. **Web Server Hardening**
   - Set up LAMP/LEMP stack
   - Implement SSL/TLS
   - Configure fail2ban
   - Set up reverse proxy

6. **Wireless Penetration Testing Lab**
   - Set up vulnerable AP
   - Practice WPA2 cracking
   - Evil twin setup
   - Deauth attacks

### Advanced Projects
7. **Complete Security Assessment**
   - Perform network reconnaissance
   - Document vulnerabilities
   - Exploit findings ethically
   - Write professional report

8. **Automated Network Security Scanner**
   - Integrate nmap + vulnerability scanners
   - Python orchestration
   - Report generation
   - Scheduled scanning

9. **Network Forensics Lab**
   - Capture and analyze malicious traffic
   - Identify attack patterns
   - Create IOCs
   - Timeline reconstruction

10. **SDN Implementation**
    - Set up Mininet environment
    - Program OpenFlow switches
    - Implement custom routing logic

---

## **Certification Path (Optional)**

### Entry Level
- **CompTIA Network+**
- **Linux Professional Institute LPIC-1**

### Intermediate
- **Cisco CCNA**
- **CompTIA Security+**
- **Linux Professional Institute LPIC-2**

### Advanced
- **Offensive Security OSCP** (Penetration Testing)
- **Cisco CCNP**
- **GIAC GPEN** (Penetration Tester)
- **Certified Ethical Hacker (CEH)**

### Expert Level
- **Offensive Security OSCE/OSEE**
- **GIAC GXPN** (Exploit Researcher)
- **Cisco CCIE** (Enterprise Infrastructure)

---

## **Learning Resources**

### Books
- "TCP/IP Illustrated" by Richard Stevens
- "The Linux Command Line" by William Shotts
- "Practical Packet Analysis" by Chris Sanders
- "The Web Application Hacker's Handbook"
- "Network Security Assessment" by Chris McNab

### Online Resources
- **TryHackMe** (hands-on labs)
- **HackTheBox** (penetration testing practice)
- **OverTheWire** (wargames)
- **CyberDefenders** (blue team practice)
- **YouTube channels**: NetworkChuck, David Bombal, IppSec

### Documentation
- Ubuntu Server Documentation
- Nmap Reference Guide
- Bettercap Documentation
- Linux man pages
- RFC documents for protocols

---

## **Study Schedule Template**

### Daily (1-3 hours)
- 30 min: Reading/theory
- 30 min: Hands-on practice
- 30 min: Tool mastery
- 30 min: Project work

### Weekly
- Complete one module from current phase
- Practice with CTF challenges
- Document learnings in a blog/notes
- Review previous topics

### Monthly
- Complete a practical project
- Take practice exams (if pursuing certs)
- Contribute to open-source tools
- Present/teach what you've learned

---

## **Success Metrics**

✅ **Phase 1-2**: Can configure basic Ubuntu network settings, understand protocol stack

✅ **Phase 3-4**: Can set up network services, implement firewall rules, troubleshoot connectivity

✅ **Phase 5-6**: Can perform network reconnaissance, understand attack vectors, use nmap/bettercap effectively

✅ **Phase 7-8**: Can design secure networks, automate tasks, perform professional security assessments

---

## **Final Tips**

1. **Build a Home Lab**: Use VirtualBox/VMware/Proxmox with multiple Ubuntu VMs
2. **Practice Ethically**: Never attack systems you don't own or have permission to test
3. **Document Everything**: Keep detailed notes, screenshots, and command references
4. **Join Communities**: Reddit r/networking, r/netsec; Discord servers; Local meetups
5. **Stay Current**: Follow security blogs, CVE databases, attend conferences
6. **Teach Others**: Best way to solidify knowledge
7. **Get Hands-On**: Theory is important, but practical experience is crucial
8. **Be Patient**: Networking expertise takes time; focus on depth over breadth initially

---

## **Additional Resources in This Package**

This curriculum package includes:
- ✅ **nmap_comprehensive_guide.md** - Complete Nmap reference with all commands
- ✅ **bettercap_comprehensive_guide.md** - Complete Bettercap reference with examples
- ✅ **networking_expert_curriculum.md** - This curriculum document

---

## **Estimated Timeline**

**6-12 months** for strong foundation  
**2-3 years** for expert-level mastery with continuous learning

---

## **Legal & Ethical Reminder**

⚠️ **IMPORTANT**: All tools and techniques described in this curriculum are for educational purposes and authorized security testing only. Never use these tools on systems you don't own or have explicit written permission to test. Unauthorized access is illegal and unethical.

---

## **Getting Started Checklist**

- [ ] Set up Ubuntu Linux VM or dedicated machine
- [ ] Complete Phase 1 reading on networking fundamentals
- [ ] Practice basic Linux commands daily
- [ ] Install essential networking tools (nmap, wireshark, tcpdump)
- [ ] Set up a home lab with at least 2-3 VMs
- [ ] Join online communities and forums
- [ ] Start a learning journal/blog
- [ ] Pick your first beginner project

---

**Good luck on your networking journey! 🚀**

*Remember: The journey to expertise is a marathon, not a sprint. Focus on understanding concepts deeply rather than rushing through topics.*

---

**Document Version**: 1.0  
**Last Updated**: November 2025  
**Created for**: Ubuntu Linux Networking Specialists
