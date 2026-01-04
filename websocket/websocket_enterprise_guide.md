# WebSocket in Enterprise Networks: Complete Guide

## Table of Contents
1. [Overview](#overview)
2. [Why Enterprises Block WebSocket](#why-enterprises-block-websocket)
3. [Common Enterprise Configurations](#common-enterprise-configurations)
4. [Detection and Inspection Methods](#detection-and-inspection-methods)
5. [Enterprise Policies by Industry](#enterprise-policies-by-industry)
6. [Testing for Restrictions](#testing-for-restrictions)
7. [Commonly Allowed Services](#commonly-allowed-services)
8. [Workarounds and Alternatives](#workarounds-and-alternatives)
9. [Enterprise Security Controls](#enterprise-security-controls)
10. [Best Practices](#best-practices)
11. [ISP Restrictions](#isp-restrictions)
12. [Troubleshooting Guide](#troubleshooting-guide)

---

## Overview

### Quick Answer
**Yes, WebSocket is commonly blocked or restricted in enterprise environments**, particularly the unencrypted `ws://` protocol. However, encrypted `wss://` (WebSocket Secure) over port 443 is usually allowed since it resembles HTTPS traffic.

### Blocking Summary

| Protocol | Port | Enterprise Status | Reason |
|----------|------|-------------------|--------|
| `ws://` | 80 | ❌ Usually Blocked | Unencrypted, easy to detect |
| `ws://` | Other | ❌ Always Blocked | Non-standard ports blocked |
| `wss://` | 443 | ✅ Often Allowed | Looks like HTTPS traffic |
| `wss://` | 8080/8443 | ⚠️ May Be Blocked | Non-standard ports suspicious |

### Key Statistics
- **60-70%** of enterprises block unencrypted WebSocket traffic
- **30-40%** restrict or whitelist WSS traffic
- **90%+** allow WSS on port 443 for approved applications
- **99%+** allow business-critical SaaS (Teams, Slack, etc.)

---

## Why Enterprises Block WebSocket

### 1. Security Concerns

#### Bypass Traditional Security Controls
```
Traditional HTTP Security:
┌─────────────┐
│   Firewall  │  ✓ Inspects each request/response
│             │  ✓ Short-lived connections
│   Proxy     │  ✓ Easy to log and audit
│             │  ✓ Content filtering per request
└─────────────┘

WebSocket Challenge:
┌─────────────┐
│   Firewall  │  ✗ Single long-lived connection
│             │  ✗ Bidirectional traffic flow
│   Proxy     │  ✗ Continuous data stream
│             │  ✗ Harder to inspect mid-stream
└─────────────┘
```

#### Protocol Tunneling Risk
WebSocket can tunnel other protocols, bypassing security:

```bash
# Example: SSH over WebSocket
# Client connects via WebSocket, tunnels SSH traffic
# Firewall only sees WebSocket, not SSH

WebSocket Connection (wss://example.com:443)
    │
    ├─→ Appears as HTTPS
    │
    └─→ Actually tunneling:
        ├─ SSH
        ├─ VPN
        ├─ Database connections
        └─ Other restricted protocols
```

### 2. Data Loss Prevention (DLP)

```
DLP Challenges with WebSocket:

Traditional HTTP:
Request  → [DLP Scan] → Forward
Response ← [DLP Scan] ← Receive
         (Each transaction scanned)

WebSocket:
Initial  → [DLP Scan] → Upgrade to WebSocket
Stream   ↔ [Limited Inspection] ↔ Continuous
         (Hard to inspect streaming data)
```

**Problems:**
- Continuous data flow difficult to buffer and scan
- Real-time inspection causes latency
- Encrypted WSS makes content inspection impossible without SSL interception
- Can exfiltrate data slowly over time
- Fragmented messages harder to reassemble

### 3. Network Resource Management

```
Resource Exhaustion Scenarios:

HTTP Keep-Alive:
Connection pool: 100 connections
Max idle time: 5 seconds
Predictable resource usage

WebSocket:
Connection pool: 100 connections  
Max idle time: Hours or days
Unpredictable resource usage

Problem:
├─ Proxy server connection limits
├─ Memory consumption per connection
├─ CPU for maintaining state
├─ Bandwidth for continuous traffic
└─ Connection table exhaustion
```

### 4. Compliance and Auditing

```
Audit Requirements:
✓ Who accessed what data?
✓ When was data accessed?
✓ What data was transferred?
✓ Was access authorized?

WebSocket Complications:
✗ Single connection, multiple transactions
✗ Streaming data harder to log
✗ Binary frames not human-readable
✗ Difficult to replay for investigation
✗ Fragmented messages across frames
```

### 5. Malware and Command & Control (C2)

```
Malware C2 Over WebSocket:

Traditional C2:
Malware → HTTP POST → C2 Server
         ↓ (Easy to detect)
     Periodic beacons
     Predictable patterns

WebSocket C2:
Malware ⟷ WebSocket ⟷ C2 Server
         ↓ (Harder to detect)
     Persistent connection
     Bidirectional commands
     Looks like normal traffic
     Can use compression/encryption
```

**Examples of Malware Using WebSocket:**
- Hidden Cobra (North Korea APT)
- Various banking Trojans
- Ransomware C2 channels
- Cryptominers

### 6. Bandwidth and QoS Issues

```
Quality of Service Concerns:

Business-Critical:
├─ Video conferencing (Teams, Zoom)
├─ VoIP calls
├─ ERP systems
└─ Email

vs. Uncontrolled WebSocket:
├─ Gaming
├─ Streaming media
├─ Personal chat apps
└─ Unknown applications

Problem: Hard to prioritize without deep inspection
```

---

## Common Enterprise Configurations

### 1. Proxy Server Configurations

#### Squid Proxy (Common Corporate Proxy)

```bash
# Block all WebSocket connections
# /etc/squid/squid.conf

# Block CONNECT to non-standard ports
acl SSL_ports port 443
acl Safe_ports port 80 443
acl CONNECT method CONNECT
http_access deny CONNECT !SSL_ports

# Block WebSocket upgrade headers
acl websocket_upgrade req_header Upgrade -i websocket
http_access deny websocket_upgrade

# Allow specific domains only
acl allowed_websocket dstdomain .slack.com .teams.microsoft.com
http_access allow websocket_upgrade allowed_websocket

# Log all WebSocket attempts
access_log /var/log/squid/websocket.log websocket_upgrade
```

#### Blue Coat/Symantec ProxySG

```
; Block unencrypted WebSocket
define action block_websocket
    action.type=Block
    action.message="WebSocket connections are not allowed"
end

; Detect WebSocket upgrade
define condition websocket_detect
    request.header.Upgrade=websocket
end

; Block ws:// completely
<Proxy>
    condition=websocket_detect AND url.scheme=ws
    action=block_websocket
</Proxy>

; Whitelist WSS for approved domains
<Proxy>
    condition=websocket_detect AND url.scheme=wss AND url.host=matches("approved_domains")
    action=allow
</Proxy>
```

#### Zscaler Cloud Proxy

```yaml
# Zscaler Configuration Example

websocket_control:
  # Global policy
  default_action: block
  
  # Protocol rules
  rules:
    - name: "Block Unencrypted WebSocket"
      protocol: ws
      action: block
      log: true
    
    - name: "Allow Business Apps WSS"
      protocol: wss
      port: 443
      domains:
        - "*.slack.com"
        - "*.teams.microsoft.com"
        - "*.zoom.us"
      action: allow
      
    - name: "Inspect Other WSS"
      protocol: wss
      action: inspect
      ssl_inspection: enabled
```

### 2. Firewall Configurations

#### Palo Alto Networks

```xml
<!-- Application-based firewall rule -->
<security-rules>
  <entry name="Block-WebSocket">
    <application>
      <member>websocket</member>
    </application>
    <service>
      <member>application-default</member>
    </service>
    <source>
      <member>any</member>
    </source>
    <destination>
      <member>any</member>
    </destination>
    <action>deny</action>
    <log-setting>default</log-setting>
  </entry>
  
  <entry name="Allow-Business-WebSocket">
    <application>
      <member>ms-teams-websocket</member>
      <member>slack-websocket</member>
    </application>
    <action>allow</action>
  </entry>
</security-rules>
```

#### Fortinet FortiGate

```
# Application Control Profile
config application list
    edit "block-websocket"
        config entries
            edit 1
                set application "WebSocket"
                set action block
                set log enable
            next
            edit 2
                set category "Collaboration"
                set application "MS.Teams" "Slack"
                set action allow
            next
        end
    next
end

# Apply to policy
config firewall policy
    edit 1
        set srcintf "internal"
        set dstintf "wan1"
        set action accept
        set application-list "block-websocket"
    next
end
```

#### Cisco Firepower

```
# Access Control Policy
rule "Block WebSocket":
  application: websocket-protocol
  action: block
  log: enabled
  
rule "Allow Approved WebSocket Apps":
  application: microsoft-teams, slack, zoom
  action: allow
  inspection: deep-packet-inspection
  
rule "SSL Inspection for Unknown WSS":
  protocol: https
  port: 443
  url-category: web-communications
  action: decrypt-inspect-resign
```

### 3. Web Application Firewall (WAF)

```nginx
# ModSecurity Rules for WebSocket

# Detect WebSocket upgrade attempts
SecRule REQUEST_HEADERS:Upgrade "@streq websocket" \
    "id:1000,phase:1,deny,log,msg:'WebSocket Upgrade Blocked'"

# Rate limit WebSocket connections
SecRule REQUEST_HEADERS:Upgrade "@streq websocket" \
    "id:1001,phase:1,pass,setvar:ip.websocket_count=+1,expirevar:ip.websocket_count=60"

SecRule IP:websocket_count "@gt 5" \
    "id:1002,phase:1,deny,log,msg:'WebSocket Rate Limit Exceeded'"

# Allow specific paths
SecRule REQUEST_URI "@streq /api/websocket" \
    "id:1003,phase:1,pass,ctl:ruleRemoveById=1000"
```

### 4. Network Access Control (NAC)

```
Typical NAC Policies:

Device Posture:
├─ Corporate laptop: Allow WSS on 443
├─ BYOD phone: Block all WebSocket
├─ Guest device: Block all WebSocket
└─ IoT device: Block all WebSocket

User Role:
├─ Developer: Allow WSS on multiple ports
├─ Standard user: Allow WSS on 443 only
├─ Contractor: Allow approved apps only
└─ Guest: No WebSocket access

Location:
├─ Office network: Restricted WebSocket
├─ VPN connection: More permissive
├─ Public WiFi: Heavily restricted
└─ Home network: Full access (via VPN)
```

---

## Detection and Inspection Methods

### 1. HTTP Header Inspection

#### Signature Detection
```http
Typical WebSocket Handshake (Easy to Detect):

GET /chat HTTP/1.1
Host: example.com
Upgrade: websocket              ← Signature #1
Connection: Upgrade             ← Signature #2
Sec-WebSocket-Key: x3JJHMb...   ← Signature #3
Sec-WebSocket-Version: 13       ← Signature #4
Origin: https://example.com
```

#### Detection Methods
```python
# Pseudo-code for proxy detection

def detect_websocket_upgrade(request):
    """Detect WebSocket upgrade attempt"""
    
    indicators = {
        'upgrade_header': False,
        'connection_upgrade': False,
        'websocket_key': False,
        'websocket_version': False
    }
    
    # Check headers
    if 'Upgrade' in request.headers:
        if request.headers['Upgrade'].lower() == 'websocket':
            indicators['upgrade_header'] = True
    
    if 'Connection' in request.headers:
        if 'upgrade' in request.headers['Connection'].lower():
            indicators['connection_upgrade'] = True
    
    if 'Sec-WebSocket-Key' in request.headers:
        indicators['websocket_key'] = True
    
    if 'Sec-WebSocket-Version' in request.headers:
        indicators['websocket_version'] = True
    
    # Positive detection if 3+ indicators present
    detection_score = sum(indicators.values())
    
    if detection_score >= 3:
        return True, "WebSocket upgrade detected"
    
    return False, "Normal HTTP request"

# Action
if detect_websocket_upgrade(request):
    log_attempt()
    
    if domain in whitelist:
        allow_connection()
    else:
        block_connection()
        send_response(403, "WebSocket connections not allowed")
```

### 2. SSL/TLS Inspection (Man-in-the-Middle)

#### How It Works
```
Without SSL Inspection:
Client ⟷ [Encrypted TLS Tunnel] ⟷ Server
         └─ Proxy cannot see content

With SSL Inspection:
Client ⟷ Proxy ⟷ Server
       ↓       ↓
   Decrypt  Re-encrypt
       ↓
  [Inspect Content]
       ↓
  Apply Policies
```

#### Implementation
```
SSL Inspection Process:

1. Client initiates HTTPS connection
   ├─ Client → SYN → Proxy

2. Proxy intercepts and terminates TLS
   ├─ Proxy presents corporate certificate
   ├─ Certificate signed by enterprise CA
   └─ Must be installed on all devices

3. Proxy establishes new TLS to server
   ├─ Proxy → TLS Handshake → Server
   └─ Uses server's real certificate

4. Proxy inspects plaintext traffic
   ├─ Check for WebSocket upgrade
   ├─ Scan for malware/DLP violations
   └─ Apply content filtering

5. Decision
   ├─ Allow: Forward encrypted traffic
   └─ Block: Send 403/reset connection
```

#### Detection from Client Side
```bash
# Check if SSL inspection is active

# 1. View certificate chain
openssl s_client -connect example.com:443 -showcerts

# Look for:
# - Issuer: Corporate CA (not Let's Encrypt, DigiCert, etc.)
# - Certificate chain includes corporate intermediate

# 2. Check installed root certificates
# Linux
ls /etc/ssl/certs/ | grep -i "corporate\|company"

# Windows
certmgr.msc
# Look in "Trusted Root Certification Authorities"

# 3. Test with known certificate
# If you get a different certificate than expected,
# SSL inspection is likely active
```

### 3. Deep Packet Inspection (DPI)

#### Traffic Pattern Analysis
```python
# DPI Detection Heuristics

def analyze_websocket_traffic(connection):
    """Analyze traffic patterns for WebSocket"""
    
    characteristics = {
        'long_lived': False,
        'bidirectional': False,
        'small_frames': False,
        'persistent_after_upgrade': False,
        'frame_pattern': False
    }
    
    # Check connection duration
    if connection.duration > 300:  # 5 minutes
        characteristics['long_lived'] = True
    
    # Check bidirectional traffic
    if connection.client_packets > 10 and connection.server_packets > 10:
        characteristics['bidirectional'] = True
    
    # Analyze packet sizes
    avg_size = sum(connection.packet_sizes) / len(connection.packet_sizes)
    if avg_size < 1000:  # Small messages typical
        characteristics['small_frames'] = True
    
    # Check if connection persists after HTTP upgrade
    if connection.http_upgrade_seen and connection.active_after_upgrade:
        characteristics['persistent_after_upgrade'] = True
    
    # Look for WebSocket frame patterns
    # Frames start with specific byte patterns
    if detect_websocket_frame_headers(connection.packets):
        characteristics['frame_pattern'] = True
    
    # Scoring
    score = sum(characteristics.values())
    
    if score >= 4:
        return "WebSocket", 0.95
    elif score >= 3:
        return "Likely WebSocket", 0.75
    else:
        return "Not WebSocket", 0.0
```

#### Frame-Level Analysis
```
WebSocket Frame Detection:

Byte 0 (Frame Header):
┌─────────┬─────────┐
│ FIN RSV │ OPCODE  │
├─────────┼─────────┤
│  1 bit  │  4 bits │
└─────────┴─────────┘

Common Patterns:
0x81 = 10000001 = FIN + Text frame
0x82 = 10000010 = FIN + Binary frame
0x88 = 10001000 = FIN + Close frame
0x89 = 10001001 = FIN + Ping frame
0x8A = 10001010 = FIN + Pong frame

DPI Detection:
If frequent packets with these byte patterns detected
→ High probability of WebSocket traffic
→ Apply policies
```

### 4. Behavioral Analysis

```python
# Anomaly Detection for WebSocket

class WebSocketBehaviorAnalyzer:
    def __init__(self):
        self.baselines = {
            'connection_duration': 300,  # seconds
            'message_frequency': 10,     # per minute
            'data_volume': 1048576,      # bytes per hour
            'burst_threshold': 100       # messages per second
        }
    
    def analyze(self, connection):
        """Detect suspicious WebSocket behavior"""
        
        alerts = []
        
        # Check connection duration
        if connection.duration > self.baselines['connection_duration'] * 10:
            alerts.append("Unusually long connection")
        
        # Check message frequency
        freq = connection.message_count / (connection.duration / 60)
        if freq > self.baselines['message_frequency'] * 5:
            alerts.append("High message frequency")
        
        # Check data volume
        volume = connection.bytes_transferred / (connection.duration / 3600)
        if volume > self.baselines['data_volume']:
            alerts.append("High data volume - possible data exfiltration")
        
        # Check for burst traffic
        if connection.max_messages_per_second > self.baselines['burst_threshold']:
            alerts.append("Burst traffic detected - possible DoS or automation")
        
        # Check time patterns
        if is_outside_business_hours(connection.start_time):
            alerts.append("Activity outside business hours")
        
        # Check destination
        if not is_known_business_domain(connection.destination):
            alerts.append("Connection to unknown domain")
        
        return alerts
```

### 5. Protocol Fingerprinting

```bash
# Using nmap to detect WebSocket support

# Basic WebSocket detection
nmap -p 80,443,8080 --script http-websocket-info example.com

# Output:
# PORT    STATE SERVICE
# 443/tcp open  https
# | http-websocket-info:
# |   WebSocket supported: yes
# |   Upgrade path: /ws
# |   Protocols: chat, superchat
# |_  Extensions: permessage-deflate

# Comprehensive scan
nmap -sV -p 80,443,8080,8443 \
  --script "http-* and not http-brute" \
  example.com
```

---

## Enterprise Policies by Industry

### High Security Sectors

#### Financial Services (Banks, Investment Firms)
```yaml
Security Posture: MAXIMUM

WebSocket Policy:
  ws_protocol:
    status: BLOCKED
    ports: ALL
    reason: "Unencrypted connections prohibited"
  
  wss_protocol:
    status: WHITELIST_ONLY
    allowed_domains:
      - "*.bloomberg.com"
      - "*.refinitiv.com"
      - "internal.bank.com"
    ports: [443]
    ssl_inspection: MANDATORY
    
  monitoring:
    - All WebSocket connections logged
    - Real-time alerting on violations
    - Monthly audit reports
    - Incident response procedures

Compliance Requirements:
  - PCI DSS
  - SOX
  - GLBA
  - FINRA regulations
  
Additional Controls:
  - Two-factor authentication required
  - Certificate pinning
  - Data loss prevention
  - Encrypted endpoint storage
```

#### Healthcare (HIPAA-Regulated)
```yaml
Security Posture: VERY HIGH

WebSocket Policy:
  ws_protocol:
    status: BLOCKED
    
  wss_protocol:
    status: RESTRICTED
    requirements:
      - HIPAA-compliant applications only
      - Business Associate Agreement (BAA) required
      - End-to-end encryption mandatory
      - Audit logging enabled
    
    approved_applications:
      - "Telemedicine platforms (approved)"
      - "EHR systems (Epic, Cerner)"
      - "Secure messaging (TigerConnect)"
    
Compliance:
  - HIPAA Security Rule
  - HITECH Act
  - State privacy laws
  
Data Handling:
  - PHI transmission encrypted
  - Access controls strict
  - Automatic session timeout
  - Data retention policies
```

#### Government/Defense
```yaml
Security Posture: EXTREME

WebSocket Policy:
  ws_protocol:
    status: BLOCKED
    enforcement: STRICT
    
  wss_protocol:
    status: DENIED (default)
    exceptions:
      - Approved classified networks only
      - Air-gapped systems
      - Specific military applications
    
    security_requirements:
      - FIPS 140-2 compliant encryption
      - Multi-factor authentication
      - Certificate-based authentication
      - Continuous monitoring
      - Network segmentation

Compliance:
  - FISMA
  - NIST SP 800-53
  - FedRAMP (for cloud)
  - DoD STIGs

Additional:
  - No personal devices
  - Physical security controls
  - Personnel clearances required
  - Insider threat monitoring
```

### Medium Security Sectors

#### Corporate/Enterprise (Standard Business)
```yaml
Security Posture: MODERATE TO HIGH

WebSocket Policy:
  ws_protocol:
    status: BLOCKED
    
  wss_protocol:
    status: ALLOWED (with conditions)
    ports: [443]
    
    automatic_allow:
      - "*.microsoft.com"  # Teams
      - "*.slack.com"      # Slack
      - "*.zoom.us"        # Zoom
      - "*.salesforce.com" # Salesforce
      - "*.webex.com"      # Webex
      
    require_approval:
      - New SaaS applications
      - Developer tools
      - Custom applications
      
    monitoring:
      - Bandwidth usage tracked
      - Connection duration logged
      - Anomaly detection enabled

Compliance:
  - SOC 2 Type II
  - ISO 27001
  - GDPR (if applicable)
  
Balance:
  - Security vs. Productivity
  - User experience priority
  - Risk-based approach
```

#### Education (Universities, Schools)
```yaml
Security Posture: MODERATE

WebSocket Policy:
  ws_protocol:
    status: BLOCKED (student networks)
    status: ALLOWED (lab networks - for learning)
    
  wss_protocol:
    status: GENERALLY_ALLOWED
    restrictions:
      - Bandwidth limits on student networks
      - Time-based restrictions (peak hours)
      - Content filtering for minors (K-12)
    
    educational_use:
      - Programming labs: Full access
      - Library: Limited access
      - Dormitories: Bandwidth limits
      - Guest WiFi: Blocked

Focus Areas:
  - Educational access priority
  - Protect minors (COPPA compliance)
  - Research flexibility
  - Gaming/streaming bandwidth management
```

### Low Security / Permissive Environments

#### Tech Startups / Software Companies
```yaml
Security Posture: LOW TO MODERATE

WebSocket Policy:
  ws_protocol:
    status: ALLOWED (dev networks)
    status: BLOCKED (production)
    
  wss_protocol:
    status: ALLOWED
    ports: [443, 8080, 8443, custom]
    
  philosophy:
    - Trust developers
    - Minimal restrictions
    - Focus on endpoint security
    - Cloud-native approach
    
  monitoring:
    - Anomaly detection
    - Malware scanning
    - Network traffic analysis
    - Optional DLP

Security Model:
  - Endpoint protection priority
  - Zero-trust principles
  - Assume breach mentality
  - Developer productivity focus
```

---

## Testing for Restrictions

### Quick Tests

#### Test 1: Basic Connectivity
```bash
# Test unencrypted WebSocket (likely blocked)
wscat -c ws://echo.websocket.org

# Expected if blocked:
# Error: connect ETIMEDOUT
# Error: socket hang up
# Error: Unexpected server response: 403

# Test encrypted WebSocket
wscat -c wss://echo.websocket.org

# Expected if allowed:
# Connected (press CTRL+C to quit)
# > [You can send messages]
```

#### Test 2: Through Corporate Proxy
```bash
# Set proxy environment variables
export HTTP_PROXY="http://proxy.company.com:8080"
export HTTPS_PROXY="http://proxy.company.com:8080"

# Test with authentication if needed
export HTTP_PROXY="http://username:password@proxy.company.com:8080"

# Test WebSocket through proxy
wscat -c wss://echo.websocket.org

# Check for proxy rejection
# Common responses:
# - "407 Proxy Authentication Required"
# - "403 Forbidden"
# - "502 Bad Gateway"
```

#### Test 3: Different Ports
```bash
# Test standard HTTPS port (most likely to work)
wscat -c wss://example.com:443/ws

# Test alternate ports (likely blocked)
wscat -c wss://example.com:8080/ws
wscat -c wss://example.com:8443/ws
wscat -c wss://example.com:3000/ws

# Test with verbose output
wscat -c wss://example.com:443/ws -v
```

### Comprehensive Testing Script

```bash
#!/bin/bash
# websocket_test.sh - Test WebSocket connectivity in enterprise

echo "=== WebSocket Connectivity Test ==="
echo "Date: $(date)"
echo "Host: $(hostname)"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test targets
TARGETS=(
    "ws://echo.websocket.org"
    "wss://echo.websocket.org"
    "wss://echo.websocket.org:443"
    "wss://ws.postman-echo.com/raw"
)

echo "1. Testing Proxy Configuration"
echo "================================"
if [ -n "$HTTP_PROXY" ]; then
    echo -e "${YELLOW}HTTP_PROXY: $HTTP_PROXY${NC}"
else
    echo "No HTTP_PROXY set"
fi

if [ -n "$HTTPS_PROXY" ]; then
    echo -e "${YELLOW}HTTPS_PROXY: $HTTPS_PROXY${NC}"
else
    echo "No HTTPS_PROXY set"
fi
echo ""

echo "2. Testing WebSocket Connections"
echo "================================="

for target in "${TARGETS[@]}"; do
    echo -n "Testing: $target ... "
    
    # Try connection with timeout
    timeout 5 wscat -c "$target" --no-check -x "test" 2>&1 > /tmp/wstest.out
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}SUCCESS${NC}"
    elif grep -q "403" /tmp/wstest.out; then
        echo -e "${RED}BLOCKED (403 Forbidden)${NC}"
    elif grep -q "502" /tmp/wstest.out; then
        echo -e "${RED}BLOCKED (502 Bad Gateway - Proxy)${NC}"
    elif grep -q "timeout" /tmp/wstest.out; then
        echo -e "${RED}BLOCKED (Timeout - Firewall)${NC}"
    else
        echo -e "${RED}FAILED${NC}"
        cat /tmp/wstest.out | head -n 1
    fi
done
echo ""

echo "3. Testing SSL/TLS Inspection"
echo "=============================="

# Check certificate for known site
CERT=$(echo | openssl s_client -connect google.com:443 2>/dev/null | openssl x509 -noout -issuer)

if echo "$CERT" | grep -qi "corporate\|company\|enterprise"; then
    echo -e "${YELLOW}SSL INSPECTION DETECTED${NC}"
    echo "Issuer: $CERT"
else
    echo -e "${GREEN}No SSL inspection detected${NC}"
    echo "Issuer: $CERT"
fi
echo ""

echo "4. Testing Port Accessibility"
echo "=============================="
for port in 80 443 8080 8443; do
    echo -n "Port $port: "
    timeout 2 nc -zv echo.websocket.org $port 2>&1 | grep -q "succeeded" && \
        echo -e "${GREEN}OPEN${NC}" || \
        echo -e "${RED}BLOCKED${NC}"
done
echo ""

echo "5. DNS Resolution"
echo "================="
nslookup echo.websocket.org | grep -A 2 "Name:"
echo ""

echo "6. Traceroute (showing blocks)"
echo "=============================="
traceroute -m 10 -w 1 echo.websocket.org 2>&1 | head -n 5
echo ""

echo "=== Test Complete ==="
```

### Python Testing Script

```python
#!/usr/bin/env python3
"""
WebSocket Enterprise Testing Tool
Tests WebSocket connectivity and detects blocking methods
"""

import asyncio
import websockets
import socket
import ssl
import json
from datetime import datetime

class WebSocketTester:
    def __init__(self):
        self.results = []
    
    async def test_connection(self, uri, name):
        """Test WebSocket connection"""
        result = {
            'name': name,
            'uri': uri,
            'status': 'unknown',
            'error': None,
            'timestamp': datetime.now().isoformat()
        }
        
        try:
            async with websockets.connect(uri, timeout=5) as ws:
                await ws.send("test")
                response = await ws.recv()
                result['status'] = 'success'
                result['response'] = response[:100]  # First 100 chars
                
        except websockets.exceptions.InvalidStatusCode as e:
            result['status'] = 'blocked'
            result['error'] = f"HTTP {e.status_code}"
            
        except asyncio.TimeoutError:
            result['status'] = 'timeout'
            result['error'] = 'Connection timeout (firewall?)'
            
        except Exception as e:
            result['status'] = 'failed'
            result['error'] = str(e)
        
        self.results.append(result)
        return result
    
    def test_ssl_inspection(self, hostname='google.com'):
        """Check for SSL inspection"""
        try:
            context = ssl.create_default_context()
            with socket.create_connection((hostname, 443)) as sock:
                with context.wrap_socket(sock, server_hostname=hostname) as ssock:
                    cert = ssock.getpeercert()
                    issuer = dict(x[0] for x in cert['issuer'])
                    
                    # Check if issuer looks like corporate
                    org = issuer.get('organizationName', '')
                    
                    if any(keyword in org.lower() for keyword in 
                           ['corporate', 'company', 'enterprise', 'internal']):
                        return True, f"SSL Inspection detected: {org}"
                    
                    return False, f"No inspection detected: {org}"
                    
        except Exception as e:
            return None, f"Could not check: {str(e)}"
    
    def check_proxy(self):
        """Check proxy configuration"""
        import os
        
        http_proxy = os.environ.get('HTTP_PROXY') or os.environ.get('http_proxy')
        https_proxy = os.environ.get('HTTPS_PROXY') or os.environ.get('https_proxy')
        
        return {
            'http_proxy': http_proxy,
            'https_proxy': https_proxy,
            'proxy_configured': bool(http_proxy or https_proxy)
        }
    
    async def run_all_tests(self):
        """Run comprehensive test suite"""
        print("=" * 50)
        print("WebSocket Enterprise Connectivity Test")
        print("=" * 50)
        print()
        
        # Check proxy
        print("1. Proxy Configuration")
        print("-" * 50)
        proxy_info = self.check_proxy()
        print(f"HTTP Proxy: {proxy_info['http_proxy'] or 'None'}")
        print(f"HTTPS Proxy: {proxy_info['https_proxy'] or 'None'}")
        print()
        
        # Check SSL inspection
        print("2. SSL/TLS Inspection")
        print("-" * 50)
        ssl_detected, ssl_msg = self.test_ssl_inspection()
        print(ssl_msg)
        if ssl_detected:
            print("⚠️  SSL inspection is active")
        print()
        
        # Test WebSocket connections
        print("3. WebSocket Connection Tests")
        print("-" * 50)
        
        tests = [
            ("ws://echo.websocket.org", "Unencrypted WS (port 80)"),
            ("wss://echo.websocket.org", "Encrypted WSS (port 443)"),
            ("wss://echo.websocket.org:443", "WSS explicit port 443"),
            ("wss://ws.postman-echo.com/raw", "Postman Echo WSS"),
        ]
        
        for uri, name in tests:
            print(f"Testing: {name}")
            result = await self.test_connection(uri, name)
            
            if result['status'] == 'success':
                print(f"  ✓ SUCCESS")
            elif result['status'] == 'blocked':
                print(f"  ✗ BLOCKED - {result['error']}")
            elif result['status'] == 'timeout':
                print(f"  ✗ TIMEOUT - {result['error']}")
            else:
                print(f"  ✗ FAILED - {result['error']}")
            print()
        
        # Summary
        print("4. Summary")
        print("-" * 50)
        
        success_count = sum(1 for r in self.results if r['status'] == 'success')
        blocked_count = sum(1 for r in self.results if r['status'] == 'blocked')
        
        print(f"Total tests: {len(self.results)}")
        print(f"Successful: {success_count}")
        print(f"Blocked: {blocked_count}")
        
        if success_count == 0:
            print("\n⚠️  All WebSocket connections blocked")
            print("This is typical for high-security enterprise networks")
        elif blocked_count > 0:
            print("\n⚠️  Some WebSocket connections blocked")
            print("Encrypted WSS on port 443 may be your best option")
        else:
            print("\n✓ All tests successful - WebSocket appears unrestricted")
        
        # Save results
        with open('websocket_test_results.json', 'w') as f:
            json.dump({
                'timestamp': datetime.now().isoformat(),
                'proxy': proxy_info,
                'ssl_inspection': ssl_detected,
                'results': self.results
            }, f, indent=2)
        
        print("\nResults saved to: websocket_test_results.json")

if __name__ == "__main__":
    tester = WebSocketTester()
    asyncio.run(tester.run_all_tests())
```

### Using Network Tools

```bash
# Test with tcpdump
sudo tcpdump -i any -n -A 'host echo.websocket.org' &
wscat -c wss://echo.websocket.org
sudo pkill tcpdump

# Look for:
# - TCP SYN → SYN-ACK: Connection allowed
# - TCP RST: Connection reset (blocked)
# - No response: Firewall drop

# Test with nmap
nmap -p 80,443,8080 --script http-methods echo.websocket.org

# Test with curl (handshake only)
curl -i -N \
  -H "Connection: Upgrade" \
  -H "Upgrade: websocket" \
  -H "Sec-WebSocket-Version: 13" \
  -H "Sec-WebSocket-Key: $(openssl rand -base64 16)" \
  https://echo.websocket.org

# Expected responses:
# 101 Switching Protocols = Allowed
# 403 Forbidden = Blocked by policy
# 502 Bad Gateway = Proxy blocking
```

---

## Commonly Allowed Services

### Business-Critical SaaS Applications

#### Collaboration Tools
```
Microsoft Teams:
├─ Domains: *.teams.microsoft.com, *.skype.com
├─ Ports: 443 (WSS)
├─ Protocol: WebSocket over TLS
├─ Usage: Chat, video, presence
└─ Allow Reason: Business critical

Slack:
├─ Domains: *.slack.com, *.slack-msgs.com
├─ Ports: 443 (WSS)
├─ Protocol: WebSocket over TLS
├─ Usage: Real-time messaging, notifications
└─ Allow Reason: Team communication

Zoom:
├─ Domains: *.zoom.us
├─ Ports: 443 (WSS)
├─ Protocol: WebSocket for signaling
├─ Usage: Video conferencing
└─ Allow Reason: Essential for meetings
```

#### CRM and Business Tools
```
Salesforce:
├─ Domains: *.salesforce.com, *.force.com
├─ Ports: 443 (WSS)
├─ Usage: Real-time CRM updates
└─ Allow Reason: Core business application

ServiceNow:
├─ Domains: *.service-now.com
├─ Ports: 443 (WSS)
├─ Usage: Live updates, notifications
└─ Allow Reason: ITSM/workflow platform

Atlassian (Jira/Confluence):
├─ Domains: *.atlassian.net, *.atlassian.com
├─ Ports: 443 (WSS)
├─ Usage: Real-time collaboration
└─ Allow Reason: Development workflow
```

#### Cloud Office Suites
```
Google Workspace:
├─ Domains: *.google.com, *.googleapis.com
├─ Ports: 443 (WSS)
├─ Usage: Google Docs real-time editing
└─ Allow Reason: Productivity suite

Microsoft 365:
├─ Domains: *.office.com, *.office365.com
├─ Ports: 443 (WSS)
├─ Usage: Office Online collaboration
└─ Allow Reason: Cloud office suite

Dropbox:
├─ Domains: *.dropbox.com
├─ Ports: 443 (WSS)
├─ Usage: File sync notifications
└─ Allow Reason: File storage/sharing
```

### Common Whitelist Configuration

```nginx
# NGINX whitelist example
map $http_host $websocket_allowed {
    default 0;
    
    # Collaboration
    "~*\.teams\.microsoft\.com$" 1;
    "~*\.slack\.com$" 1;
    "~*\.zoom\.us$" 1;
    "~*\.webex\.com$" 1;
    
    # CRM
    "~*\.salesforce\.com$" 1;
    "~*\.force\.com$" 1;
    
    # Productivity
    "~*\.google\.com$" 1;
    "~*\.office\.com$" 1;
    "~*\.dropbox\.com$" 1;
    
    # Development
    "~*\.github\.com$" 1;
    "~*\.gitlab\.com$" 1;
    
    # Internal
    "internal\.company\.com" 1;
}

server {
    listen 80;
    
    location /ws {
        if ($websocket_allowed = 0) {
            return 403 "WebSocket access denied for this domain";
        }
        
        proxy_pass http://backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
    }
}
```

---

## Workarounds and Alternatives

### 1. Use WSS on Port 443

```javascript
// Best practice: Always use WSS on standard HTTPS port

// Good - Most likely to work
const ws = new WebSocket('wss://example.com:443/ws');

// Bad - Often blocked
const ws = new WebSocket('ws://example.com:80/ws');
const ws = new WebSocket('wss://example.com:8080/ws');

// Implementation tip: Don't hardcode port 443
// Let browser use default
const ws = new WebSocket('wss://example.com/ws');
```

### 2. HTTP Long Polling Fallback

```javascript
class CommunicationClient {
    constructor(url) {
        this.url = url;
        this.transport = null;
        this.init();
    }
    
    async init() {
        // Try WebSocket first
        if (await this.tryWebSocket()) {
            console.log('Using WebSocket');
            return;
        }
        
        // Fall back to long polling
        console.log('WebSocket unavailable, using long polling');
        this.useLongPolling();
    }
    
    async tryWebSocket() {
        return new Promise((resolve) => {
            const ws = new WebSocket(`wss://${this.url}/ws`);
            
            const timeout = setTimeout(() => {
                ws.close();
                resolve(false);
            }, 5000);
            
            ws.onopen = () => {
                clearTimeout(timeout);
                this.transport = ws;
                resolve(true);
            };
            
            ws.onerror = () => {
                clearTimeout(timeout);
                resolve(false);
            };
        });
    }
    
    useLongPolling() {
        this.transport = new LongPollingTransport(this.url);
    }
}

class LongPollingTransport {
    constructor(url) {
        this.url = url;
        this.poll();
    }
    
    async poll() {
        while (true) {
            try {
                const response = await fetch(`https://${this.url}/poll`, {
                    method: 'GET',
                    headers: { 'Accept': 'application/json' }
                });
                
                if (response.ok) {
                    const data = await response.json();
                    this.onmessage(data);
                }
                
            } catch (e) {
                console.error('Polling error:', e);
                await this.sleep(5000);
            }
        }
    }
    
    async send(data) {
        await fetch(`https://${this.url}/send`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(data)
        });
    }
    
    onmessage(data) {
        // Override this
    }
    
    sleep(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }
}
```

### 3. Server-Sent Events (SSE)

```javascript
// One-way communication (server to client)
// Usually allowed since it's standard HTTP

class SSEClient {
    constructor(url) {
        this.url = url;
        this.connect();
    }
    
    connect() {
        this.eventSource = new EventSource(`https://${this.url}/events`);
        
        this.eventSource.onopen = () => {
            console.log('SSE connection established');
        };
        
        this.eventSource.onmessage = (event) => {
            const data = JSON.parse(event.data);
            this.handleMessage(data);
        };
        
        this.eventSource.onerror = (error) => {
            console.error('SSE error:', error);
            // Will auto-reconnect
        };
    }
    
    // For sending data, use regular HTTP POST
    async send(data) {
        await fetch(`https://${this.url}/api`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(data)
        });
    }
    
    handleMessage(data) {
        // Process incoming message
    }
}
```

### 4. Socket.IO (Automatic Fallback)

```javascript
// Socket.IO tries multiple transports automatically

// Client
<script src="/socket.io/socket.io.js"></script>
<script>
    const socket = io('https://example.com', {
        // Transport priority
        transports: ['websocket', 'polling'],
        
        // Upgrade to WebSocket if possible
        upgrade: true,
        
        // Reconnection settings
        reconnection: true,
        reconnectionDelay: 1000,
        reconnectionDelayMax: 5000,
        reconnectionAttempts: 5
    });
    
    socket.on('connect', () => {
        console.log('Connected via:', socket.io.engine.transport.name);
        // Will show: "websocket" or "polling"
    });
    
    socket.on('upgrade', () => {
        console.log('Upgraded to:', socket.io.engine.transport.name);
    });
    
    socket.on('message', (data) => {
        console.log('Received:', data);
    });
    
    socket.emit('message', 'Hello server');
</script>

// Server (Node.js)
const io = require('socket.io')(server, {
    cors: {
        origin: "https://example.com",
        methods: ["GET", "POST"]
    },
    transports: ['websocket', 'polling']
});

io.on('connection', (socket) => {
    console.log('Client connected via:', socket.conn.transport.name);
    
    socket.on('message', (data) => {
        console.log('Received:', data);
        socket.emit('message', `Echo: ${data}`);
    });
});
```

### 5. HTTP/2 Server Push

```javascript
// Modern alternative for server-initiated communication
// Requires HTTP/2 support

// Server (Node.js with http2)
const http2 = require('http2');
const fs = require('fs');

const server = http2.createSecureServer({
    key: fs.readFileSync('key.pem'),
    cert: fs.readFileSync('cert.pem')
});

server.on('stream', (stream, headers) => {
    if (headers[':path'] === '/') {
        // Send HTML page
        stream.respond({
            'content-type': 'text/html',
            ':status': 200
        });
        stream.end('<html>...</html>');
        
        // Push additional resources
        stream.pushStream({ ':path': '/data.json' }, (err, pushStream) => {
            pushStream.respond({ ':status': 200 });
            pushStream.end(JSON.stringify({ message: 'pushed data' }));
        });
    }
});

server.listen(443);
```

### 6. Using VPN Tunnel

```bash
# Use VPN to bypass corporate restrictions
# ⚠️ WARNING: Check company policy first!

# Connect to personal VPN
sudo openvpn --config home-vpn.ovpn

# Or use WireGuard
sudo wg-quick up wg0

# Now WebSocket traffic goes through VPN tunnel
wscat -c ws://any-websocket-server.com

# Disconnect when done
sudo openvpn --config home-vpn.ovpn --down
```

**Important Considerations:**
- May violate company policy
- Could trigger security alerts
- May be grounds for termination
- Use only if explicitly allowed
- Better to request approval for needed tools

---

## Enterprise Security Controls

### 1. Network Segmentation

```
Enterprise Network Zones:

┌─────────────────────────────────────────┐
│         DMZ (Demilitarized Zone)        │
│  - Public-facing web servers            │
│  - WebSocket: WSS only, monitored       │
└─────────────────────────────────────────┘
                    ↕
┌─────────────────────────────────────────┐
│         Internal Corporate Network       │
│  - Workstations, internal servers       │
│  - WebSocket: Restricted/whitelisted    │
└─────────────────────────────────────────┘
                    ↕
┌─────────────────────────────────────────┐
│         Secure/Sensitive Zone           │
│  - Financial systems, HR database       │
│  - WebSocket: Blocked completely        │
└─────────────────────────────────────────┘
```

### 2. Zero Trust Architecture

```python
# Zero Trust WebSocket Authorization

class WebSocketAuthMiddleware:
    def __init__(self):
        self.trust_engine = TrustEngine()
    
    async def authorize_connection(self, websocket, request):
        """Continuous authorization for WebSocket"""
        
        # 1. Verify device posture
        device_trust = self.trust_engine.check_device(
            device_id=request.headers.get('X-Device-ID'),
            os_version=request.headers.get('X-OS-Version'),
            security_agent=request.headers.get('X-Security-Agent')
        )
        
        if not device_trust.compliant:
            return False, "Device does not meet security requirements"
        
        # 2. Verify user identity
        token = request.headers.get('Authorization')
        user_trust = self.trust_engine.verify_user(token)
        
        if not user_trust.valid:
            return False, "Invalid user credentials"
        
        # 3. Check user risk score
        risk_score = self.trust_engine.calculate_risk(
            user_id=user_trust.user_id,
            location=request.headers.get('X-Forwarded-For'),
            time=datetime.now(),
            behavior=self.trust_engine.get_user_behavior(user_trust.user_id)
        )
        
        if risk_score > 70:  # High risk
            return False, "User risk score too high"
        
        # 4. Verify application authorization
        app_access = self.trust_engine.check_application_access(
            user_id=user_trust.user_id,
            application=request.path,
            required_permissions=['websocket.connect']
        )
        
        if not app_access.authorized:
            return False, "User not authorized for this application"
        
        # 5. Check network context
        network_trust = self.trust_engine.check_network(
            source_ip=request.headers.get('X-Real-IP'),
            expected_networks=['corporate', 'vpn']
        )
        
        if not network_trust.trusted:
            return False, "Connection from untrusted network"
        
        # All checks passed
        return True, "Authorization successful"
    
    async def continuous_verification(self, websocket, user_id):
        """Re-verify trust continuously during connection"""
        
        while websocket.open:
            await asyncio.sleep(300)  # Check every 5 minutes
            
            # Re-calculate risk score
            current_risk = self.trust_engine.calculate_risk(
                user_id=user_id,
                location=websocket.remote_address,
                time=datetime.now()
            )
            
            if current_risk > 70:
                await websocket.close(1008, "Trust level degraded")
                break
```

### 3. Data Loss Prevention (DLP)

```python
# WebSocket DLP Implementation

class WebSocketDLP:
    def __init__(self):
        self.patterns = self.load_sensitive_patterns()
        self.classifier = SensitiveDataClassifier()
    
    def load_sensitive_patterns(self):
        """Load patterns for sensitive data"""
        return {
            'credit_card': r'\b\d{4}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}\b',
            'ssn': r'\b\d{3}-\d{2}-\d{4}\b',
            'email': r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b',
            'phone': r'\b\d{3}[-.]?\d{3}[-.]?\d{4}\b',
            'api_key': r'\b[A-Za-z0-9]{32,}\b'
        }
    
    async def scan_message(self, message, user_id, direction):
        """Scan WebSocket message for sensitive data"""
        
        violations = []
        
        # Pattern matching
        for data_type, pattern in self.patterns.items():
            matches = re.findall(pattern, message)
            if matches:
                violations.append({
                    'type': data_type,
                    'matches': len(matches),
                    'severity': 'high'
                })
        
        # ML-based classification
        classification = self.classifier.classify(message)
        if classification.contains_sensitive_data:
            violations.append({
                'type': classification.data_type,
                'confidence': classification.confidence,
                'severity': classification.severity
            })
        
        # Take action on violations
        if violations:
            await self.handle_violation(
                user_id=user_id,
                direction=direction,
                violations=violations,
                message=message
            )
            
            return False, violations
        
        return True, None
    
    async def handle_violation(self, user_id, direction, violations, message):
        """Handle DLP violation"""
        
        # Log incident
        self.log_incident({
            'timestamp': datetime.now().isoformat(),
            'user_id': user_id,
            'direction': direction,
            'violations': violations,
            'message_hash': hashlib.sha256(message.encode()).hexdigest()
        })
        
        # Alert security team
        if any(v['severity'] == 'high' for v in violations):
            await self.alert_security_team({
                'user_id': user_id,
                'violations': violations,
                'immediate_action': 'block'
            })
        
        # Block message
        # (Return False to prevent message from being sent/received)
```

### 4. Intrusion Detection for WebSocket

```python
# WebSocket IDS/IPS

class WebSocketIDS:
    def __init__(self):
        self.baseline = self.load_baseline()
        self.anomaly_detector = AnomalyDetector()
    
    def analyze_connection(self, connection):
        """Analyze WebSocket connection for suspicious activity"""
        
        alerts = []
        
        # 1. Connection duration anomaly
        if connection.duration > self.baseline['max_duration']:
            alerts.append({
                'type': 'long_connection',
                'severity': 'medium',
                'details': f"Connection lasted {connection.duration}s"
            })
        
        # 2. Message frequency anomaly
        msg_rate = connection.message_count / connection.duration
        if msg_rate > self.baseline['max_message_rate']:
            alerts.append({
                'type': 'high_frequency',
                'severity': 'high',
                'details': f"Message rate: {msg_rate}/s"
            })
        
        # 3. Data volume anomaly
        if connection.bytes_transferred > self.baseline['max_bytes']:
            alerts.append({
                'type': 'data_exfiltration',
                'severity': 'critical',
                'details': f"Transferred {connection.bytes_transferred} bytes"
            })
        
        # 4. Unusual timing pattern
        if self.is_outside_business_hours(connection.start_time):
            alerts.append({
                'type': 'off_hours_activity',
                'severity': 'medium',
                'details': f"Activity at {connection.start_time}"
            })
        
        # 5. Unknown destination
        if not self.is_approved_destination(connection.destination):
            alerts.append({
                'type': 'unauthorized_destination',
                'severity': 'high',
                'details': f"Connected to {connection.destination}"
            })
        
        # 6. Binary data in text frame
        if self.detect_binary_in_text_frame(connection.frames):
            alerts.append({
                'type': 'protocol_violation',
                'severity': 'high',
                'details': "Binary data in text frame (possible evasion)"
            })
        
        # 7. ML-based anomaly detection
        if self.anomaly_detector.is_anomalous(connection):
            alerts.append({
                'type': 'behavioral_anomaly',
                'severity': 'medium',
                'details': "Connection behavior differs from baseline"
            })
        
        return alerts
    
    def take_action(self, connection, alerts):
        """Take action based on alerts"""
        
        critical_count = sum(1 for a in alerts if a['severity'] == 'critical')
        high_count = sum(1 for a in alerts if a['severity'] == 'high')
        
        if critical_count > 0:
            # Immediate block
            connection.terminate()
            self.block_source_ip(connection.source_ip, duration=3600)
            self.notify_security_team(alerts, priority='critical')
        
        elif high_count >= 2:
            # Rate limit and alert
            connection.rate_limit(max_messages_per_second=1)
            self.notify_security_team(alerts, priority='high')
        
        elif len(alerts) > 0:
            # Log and monitor
            self.log_suspicious_activity(connection, alerts)
```

---

## Best Practices

### For Developers

#### 1. Always Use WSS
```javascript
// ✅ GOOD: Encrypted WebSocket
const ws = new WebSocket('wss://api.example.com/ws');

// ❌ BAD: Unencrypted WebSocket
const ws = new WebSocket('ws://api.example.com/ws');

// ✅ GOOD: Default to standard port
const ws = new WebSocket('wss://api.example.com/ws');

// ⚠️ RISKY: Non-standard port
const ws = new WebSocket('wss://api.example.com:8080/ws');
```

#### 2. Implement Fallback Strategy
```javascript
class ResilientConnection {
    constructor(baseUrl) {
        this.baseUrl = baseUrl;
        this.strategies = [
            this.tryWebSocket.bind(this),
            this.tryLongPolling.bind(this),
            this.trySSE.bind(this)
        ];
    }
    
    async connect() {
        for (const strategy of this.strategies) {
            const success = await strategy();
            if (success) {
                console.log(`Connected using ${strategy.name}`);
                return true;
            }
        }
        
        console.error('All connection strategies failed');
        return false;
    }
    
    async tryWebSocket() {
        try {
            this.connection = new WebSocket(`wss://${this.baseUrl}/ws`);
            await this.waitForConnection(this.connection);
            return true;
        } catch (e) {
            return false;
        }
    }
    
    async tryLongPolling() {
        // Implement long polling
        return false;
    }
    
    async trySSE() {
        // Implement SSE
        return false;
    }
}
```

#### 3. Handle Errors Gracefully
```javascript
const ws = new WebSocket('wss://api.example.com/ws');

ws.onerror = (error) => {
    console.warn('WebSocket error:', error);
    
    // Don't expose technical details to user
    showUserMessage('Connection issue. Retrying...');
    
    // Switch to fallback
    initializeFallback();
};

ws.onclose = (event) => {
    if (event.code === 1008) {
        // Policy violation
        showUserMessage('Access restricted by network policy');
    } else if (event.code === 1006) {
        // Abnormal closure (blocked?)
        showUserMessage('Connection blocked. Trying alternative...');
        initializeFallback();
    }
};
```

#### 4. Don't Tunnel Protocols
```javascript
// ❌ DON'T: Use WebSocket to bypass restrictions
// This violates security policies and may be illegal

// Don't tunnel SSH
// Don't tunnel VPN
// Don't bypass authentication
// Don't circumvent monitoring

// ✅ DO: Use WebSocket for its intended purpose
// Real-time data updates
// Chat/messaging
// Collaborative features
// Live notifications
```

#### 5. Implement Proper Authentication
```javascript
// ✅ GOOD: Authentication in initial handshake
const ws = new WebSocket('wss://api.example.com/ws');

ws.onopen = () => {
    // Send authentication token
    ws.send(JSON.stringify({
        type: 'auth',
        token: getAuthToken()
    }));
};

// ⚠️ LESS SECURE: Auth in URL
// Tokens may be logged by proxies
const token = getAuthToken();
const ws = new WebSocket(`wss://api.example.com/ws?token=${token}`);
```

### For Enterprises

#### 1. Risk-Based Policy
```yaml
Policy Framework:

Assess Risk:
  - Data sensitivity
  - User role
  - Device trust
  - Network location
  - Application criticality

Apply Controls:
  LOW RISK:
    - Standard user on corporate device
    - Approved business app
    - Corporate network
    Action: Allow WSS on 443
  
  MEDIUM RISK:
    - BYOD device
    - Approved app
    - VPN connection
    Action: Allow with SSL inspection
  
  HIGH RISK:
    - Unknown device
    - Unapproved app
    - Public WiFi
    Action: Block or require MFA
  
  CRITICAL RISK:
    - Sensitive data access
    - External network
    - Unknown app
    Action: Block
```

#### 2. Whitelist Known Good
```nginx
# Maintain whitelist of approved services

map $http_host $websocket_policy {
    default "block";
    
    # Tier 1: Business Critical (always allow)
    "~*\.teams\.microsoft\.com$" "allow";
    "~*\.slack\.com$" "allow";
    
    # Tier 2: Approved SaaS (allow with monitoring)
    "~*\.salesforce\.com$" "monitor";
    "~*\.zoom\.us$" "monitor";
    
    # Tier 3: Internal (allow)
    "internal\.company\.com" "allow";
    
    # Everything else: block
}
```

#### 3. Monitor and Alert
```python
# Monitoring strategy

class WebSocketMonitor:
    def monitor(self, connection):
        # Metrics to track
        metrics = {
            'connections_per_user': self.count_user_connections(),
            'data_volume': self.measure_data_volume(),
            'connection_duration': self.measure_duration(),
            'unusual_destinations': self.check_destinations(),
            'off_hours_activity': self.check_timing()
        }
        
        # Alert conditions
        if metrics['connections_per_user'] > 10:
            self.alert("Excessive connections from single user")
        
        if metrics['data_volume'] > 100_000_000:  # 100MB
            self.alert("High data volume - possible exfiltration")
        
        if metrics['unusual_destinations']:
            self.alert("Connection to unusual destination")
```

#### 4. Regular Policy Review
```
Policy Review Cycle:

Quarterly:
├─ Review blocked connection logs
├─ Identify false positives
├─ Update whitelist
└─ Adjust thresholds

Annually:
├─ Comprehensive policy review
├─ Threat landscape assessment
├─ Technology updates
└─ Compliance verification

After Incidents:
├─ Root cause analysis
├─ Policy effectiveness review
├─ Implement lessons learned
└─ Update procedures
```

#### 5. User Education
```
Training Topics:

Security Awareness:
├─ Why WebSocket is restricted
├─ Approved vs unapproved tools
├─ Request process for new tools
├─ Consequences of policy violations

Best Practices:
├─ Use approved collaboration tools
├─ Report blocking issues
├─ Don't use personal VPNs
├─ Don't attempt to bypass controls
```

---

## ISP Restrictions

### Common ISP Practices

#### 1. Residential ISPs
```
Typical Restrictions:

Comcast/Xfinity:
├─ Generally allows WebSocket
├─ May throttle during congestion
├─ Port 80/443: Usually open
└─ No specific WebSocket blocking

AT&T:
├─ Generally allows WebSocket
├─ May block non-standard ports
├─ Business plans less restricted
└─ Potential throttling on residential

Verizon:
├─ Generally allows WebSocket
├─ No specific blocking observed
├─ Standard ports typically open
└─ Fiber plans unrestricted
```

#### 2. Mobile Carriers
```
Mobile Network Considerations:

Connection Quality:
├─ NAT traversal challenges
├─ Frequent IP changes
├─ Connection drops during handoffs
└─ Higher latency

Restrictions:
├─ Port blocking on some carriers
├─ Aggressive timeouts
├─ Traffic shaping during congestion
└─ Tethering detection

Best Practices:
├─ Use WSS (encrypted)
├─ Implement keepalive pings
├─ Handle frequent reconnections
└─ Optimize for mobile bandwidth
```

#### 3. Testing ISP Restrictions
```bash
#!/bin/bash
# Test ISP WebSocket restrictions

echo "Testing ISP WebSocket Support"
echo "=============================="

# Test from home network (no corporate proxy)
echo "1. Testing standard WSS port 443"
timeout 10 wscat -c wss://echo.websocket.org && echo "✓ Port 443 OK" || echo "✗ Port 443 Blocked"

echo "2. Testing alternate ports"
for port in 8080 8443 9000; do
    timeout 10 wscat -c wss://echo.websocket.org:$port 2>/dev/null && \
        echo "✓ Port $port OK" || echo "✗ Port $port Blocked"
done

echo "3. Testing unencrypted WS"
timeout 10 wscat -c ws://echo.websocket.org && echo "✓ WS OK" || echo "✗ WS Blocked"

echo "4. Checking public IP"
curl -s ifconfig.me

echo "5. Testing latency"
ping -c 4 echo.websocket.org | tail -n 1
```

---

## Troubleshooting Guide

### Common Issues and Solutions

#### Issue 1: "Connection Refused" or "Connection Timeout"
```
Symptoms:
- Cannot connect to WebSocket server
- Connection hangs and times out
- No error details provided

Diagnosis:
└─ Check 1: Is server actually running?
   ├─ Test: netstat -tuln | grep 8765
   └─ Action: Start server if not running

└─ Check 2: Firewall blocking connection?
   ├─ Test: telnet example.com 443
   └─ Action: Allow port in firewall

└─ Check 3: Proxy blocking?
   ├─ Test: Check HTTP_PROXY environment
   └─ Action: Configure proxy settings

└─ Check 4: Corporate network?
   ├─ Test: Try from different network
   └─ Action: Use approved tools or WSS on 443
```

#### Issue 2: "403 Forbidden" or "502 Bad Gateway"
```
Symptoms:
- HTTP error instead of WebSocket upgrade
- Connection rejected by proxy/gateway

Diagnosis:
└─ 403 Forbidden: Policy Blocked
   ├─ Cause: Proxy/firewall policy
   ├─ Test: Check proxy logs
   └─ Solution: Use whitelisted domain or request access

└─ 502 Bad Gateway: Proxy Can't Reach Backend
   ├─ Cause: Backend server issue or proxy configuration
   ├─ Test: Direct connection to backend
   └─ Solution: Fix backend or proxy config
```

#### Issue 3: Connection Drops Frequently
```
Symptoms:
- WebSocket connects but drops after short time
- Reconnection required frequently

Causes and Solutions:

1. Idle Timeout:
   Solution: Implement ping/pong keepalive
   ```javascript
   setInterval(() => {
       if (ws.readyState === WebSocket.OPEN) {
           ws.send(JSON.stringify({ type: 'ping' }));
       }
   }, 30000);  // Every 30 seconds
   ```

2. Proxy Timeout:
   Solution: Configure proxy timeout
   ```nginx
   proxy_read_timeout 3600s;
   proxy_send_timeout 3600s;
   ```

3. Mobile Network Handoff:
   Solution: Implement reconnection logic
   ```javascript
   ws.onclose = () => {
       setTimeout(() => reconnect(), 1000);
   };
   ```

4. Aggressive NAT:
   Solution: Reduce ping interval, use WSS
```

#### Issue 4: SSL/Certificate Errors
```
Symptoms:
- "SSL certificate problem"
- "NET::ERR_CERT_AUTHORITY_INVALID"

Solutions:

1. Self-Signed Certificate (Development):
   ```javascript
   // Node.js client
   process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';  // Dev only!
   
   // Python client
   ssl_context = ssl.SSLContext()
   ssl_context.check_hostname = False
   ssl_context.verify_mode = ssl.CERT_NONE
   ```

2. Corporate SSL Inspection:
   - Install corporate root certificate
   - Or request exception for your application

3. Expired Certificate:
   - Renew certificate (Let's Encrypt, etc.)
   - Update configuration
```

#### Issue 5: Messages Not Received
```
Symptoms:
- Can connect but messages don't arrive
- No errors reported

Diagnosis:

1. Check browser console for errors
2. Verify message format (text vs binary)
3. Check server logs
4. Verify WebSocket readyState

Solution:
```javascript
// Verify connection state before sending
if (ws.readyState === WebSocket.OPEN) {
    ws.send(message);
} else {
    console.error('WebSocket not ready:', ws.readyState);
    // 0: CONNECTING
    // 1: OPEN
    // 2: CLOSING
    // 3: CLOSED
}

// Handle different message types
ws.onmessage = (event) => {
    if (typeof event.data === 'string') {
        // Text message
        console.log('Text:', event.data);
    } else {
        // Binary message
        console.log('Binary:', event.data);
    }
};
```

### Diagnostic Checklist

```markdown
WebSocket Connection Troubleshooting Checklist:

□ Network Level:
  □ Can ping server?
  □ Is port open? (telnet/nc test)
  □ Is DNS resolving correctly?
  □ On VPN? Try without VPN
  □ Try different network (mobile hotspot)

□ Protocol Level:
  □ Using ws:// or wss://?
  □ Correct port (443 for wss)?
  □ Upgrade headers sent?
  □ Server responding with 101?

□ Authentication:
  □ Token valid?
  □ Token in correct format?
  □ CORS configured correctly?
  □ Origin header allowed?

□ Application Level:
  □ Server actually running?
  □ Correct endpoint path?
  □ Message format correct?
  □ Handling errors properly?

□ Corporate Network:
  □ Check proxy settings
  □ SSL inspection active?
  □ WebSocket in approved list?
  □ Try business-approved app first

□ Monitoring:
  □ Check server logs
  □ Check firewall/proxy logs
  □ Use browser DevTools Network tab
  □ Capture traffic with tcpdump
```

---

## Quick Reference

### Enterprise WebSocket Decision Tree

```
Is WebSocket needed?
├─ YES → Continue
└─ NO → Use standard HTTP/REST

↓

Is encryption required? (always yes in enterprise)
├─ YES → Use wss://
└─ NO → STOP (unencrypted not allowed)

↓

What port?
├─ 443 → Best chance of success
├─ 8080/8443 → May be blocked
└─ Other → Likely blocked

↓

Is domain whitelisted?
├─ YES → Likely will work
├─ NO → Check if can be added
└─ UNKNOWN → Test connectivity

↓

Test Connection
├─ SUCCESS → Implement
├─ BLOCKED → Consider alternatives
└─ TIMEOUT → Check firewall rules

↓

If Blocked:
├─ Request whitelist addition
├─ Use fallback (polling/SSE)
├─ Try Socket.IO (auto-fallback)
└─ Escalate to IT if business critical
```

### Testing Commands Quick Reference

```bash
# Quick WebSocket test
wscat -c wss://echo.websocket.org

# With authentication
wscat -c wss://example.com -H "Authorization: Bearer token"

# Test specific port
wscat -c wss://example.com:8443/ws

# Test with curl (handshake only)
curl -i -N -H "Connection: Upgrade" -H "Upgrade: websocket" \
  -H "Sec-WebSocket-Version: 13" \
  -H "Sec-WebSocket-Key: $(openssl rand -base64 16)" \
  https://example.com/ws

# Check if port is open
nc -zv example.com 443

# Capture WebSocket traffic
sudo tcpdump -i any -A 'host example.com and port 443'

# Test through proxy
export HTTPS_PROXY="http://proxy.company.com:8080"
wscat -c wss://echo.websocket.org
```

---

## Summary

### Key Takeaways

1. **WebSocket is commonly restricted in enterprises** for security reasons
2. **WSS on port 443 has the best chance** of working through corporate networks
3. **Business-critical SaaS apps** are usually whitelisted
4. **Always implement fallback strategies** for resilience
5. **Respect corporate policies** - don't attempt to bypass security controls
6. **Test thoroughly** in target environment before production deployment

### Best Approach for Enterprise Deployment

```
1. Use WSS (never WS)
2. Use port 443
3. Implement fallback to long polling
4. Handle reconnection gracefully
5. Request IT approval if needed
6. Monitor for blocking issues
7. Provide alternative access methods
8. Document security considerations
```

---

**Document Version**: 1.0  
**Last Updated**: December 2025  
**Purpose**: Educational guide for understanding WebSocket restrictions in enterprise environments
