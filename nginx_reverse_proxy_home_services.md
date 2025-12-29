# NGINX Reverse Proxy for Home LAN Services via OpenVPN

## Table of Contents
1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Why NGINX is Essential](#why-nginx-is-essential)
4. [Prerequisites](#prerequisites)
5. [Installation](#installation)
6. [Configuration Methods](#configuration-methods)
7. [Port-Based Routing Setup](#port-based-routing-setup)
8. [Subdomain-Based Routing Setup](#subdomain-based-routing-setup)
9. [SSL/TLS Configuration](#ssltls-configuration)
10. [DNS Configuration](#dns-configuration)
11. [Firewall Configuration](#firewall-configuration)
12. [Advanced CORS Handling](#advanced-cors-handling)
13. [Performance Optimization](#performance-optimization)
14. [Testing and Verification](#testing-and-verification)
15. [Troubleshooting](#troubleshooting)
16. [Monitoring and Logging](#monitoring-and-logging)
17. [Security Best Practices](#security-best-practices)
18. [Maintenance](#maintenance)

---

## Overview

This guide covers setting up NGINX as a reverse proxy to access multiple services on your home LAN through OpenVPN. This setup solves CORS issues, provides clean URLs, enables SSL/TLS encryption, and centralizes access control.

### Use Case
- **Current Setup**: Multiple home LAN devices running services (Langflow, etc.)
- **Access Method**: OpenVPN server for remote access
- **Problem**: Direct IP access causes CORS issues and is difficult to manage
- **Solution**: NGINX reverse proxy as central gateway

---

## Architecture

### Network Topology

```
┌─────────────────────────────────────────────────────────────────┐
│                        INTERNET (WAN)                            │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             │ VPN Connection
                             │
┌────────────────────────────▼────────────────────────────────────┐
│                   OpenVPN Server                                 │
│              (nerunja.mywire.org / itekk.in)                    │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             │ VPN Tunnel (10.8.0.0/24)
                             │
┌────────────────────────────▼────────────────────────────────────┐
│                  Home LAN (192.168.1.0/24)                      │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │          NGINX Reverse Proxy (192.168.1.x)               │  │
│  │                                                           │  │
│  │  Port 80/443 → Routes to internal services               │  │
│  └────┬─────────────┬─────────────┬─────────────────────────┘  │
│       │             │             │                             │
│       │             │             │                             │
│  ┌────▼────┐   ┌────▼────┐   ┌───▼─────┐                      │
│  │Langflow │   │Service 2│   │Service 3│                      │
│  │  :7860  │   │  :3000  │   │  :8080  │                      │
│  │192.168  │   │192.168  │   │192.168  │                      │
│  │ .1.10   │   │ .1.11   │   │ .1.12   │                      │
│  └─────────┘   └─────────┘   └─────────┘                      │
└─────────────────────────────────────────────────────────────────┘
```

### Traffic Flow

1. **External Client** → Connects to OpenVPN server
2. **OpenVPN** → Assigns client an IP in VPN subnet (10.8.0.x)
3. **Client** → Accesses NGINX at `langflow.itekk.in` or `192.168.1.x:8001`
4. **NGINX** → Routes request to appropriate internal service
5. **Internal Service** → Processes request and returns response
6. **NGINX** → Adds proper headers and returns to client

---

## Why NGINX is Essential

### Problems Without NGINX

1. **CORS (Cross-Origin Resource Sharing) Issues**
   - Direct IP access triggers browser security restrictions
   - API calls blocked between different ports/IPs
   - JavaScript applications fail to load resources

2. **Port Management Complexity**
   - Remember different ports for each service
   - Expose multiple ports through firewall
   - Difficult to manage and document

3. **No SSL/TLS**
   - Unencrypted traffic within VPN
   - No certificate management
   - Browser warnings for "insecure" sites

4. **Security Concerns**
   - Direct exposure of internal service ports
   - No centralized authentication
   - Difficult to implement rate limiting

5. **Poor User Experience**
   - Ugly URLs: `http://192.168.1.10:7860/app`
   - Hard to remember service locations
   - No meaningful service names

### Solutions with NGINX

✅ **CORS Handling**: Adds proper headers to allow cross-origin requests  
✅ **Port Consolidation**: All services accessible through port 80/443  
✅ **SSL/TLS**: Single point for certificate management  
✅ **Clean URLs**: `https://langflow.itekk.in` instead of `http://192.168.1.10:7860`  
✅ **Security Layer**: Add authentication, rate limiting, IP filtering  
✅ **Load Balancing**: Distribute traffic across multiple instances  
✅ **Caching**: Improve performance for static content  
✅ **WebSocket Support**: Proper handling for real-time applications  

---

## Prerequisites

### Required Components

- ✅ Ubuntu Linux system (can be any home LAN device)
- ✅ OpenVPN server configured and running
- ✅ VPN client successfully connecting
- ✅ Services running on home LAN devices
- ✅ Root/sudo access

### System Requirements

```bash
# Minimum specs for NGINX server
- CPU: 1 core (2+ recommended)
- RAM: 512 MB (1 GB+ recommended)
- Disk: 1 GB free space
- Network: Stable LAN connection
```

### Network Information Needed

- VPN server IP/hostname: `nerunja.mywire.org`
- Domain name: `itekk.in`
- NGINX server LAN IP: `192.168.1.x` (choose available IP)
- Service IPs and ports:
  - Langflow: `192.168.1.10:7860`
  - Service 2: `192.168.1.11:3000`
  - Service 3: `192.168.1.12:8080`

---

## Installation

### 1. Update System

```bash
# Update package repositories
sudo apt update

# Upgrade existing packages (optional but recommended)
sudo apt upgrade -y
```

### 2. Install NGINX

```bash
# Install NGINX
sudo apt install nginx -y

# Verify installation
nginx -v
# Expected output: nginx version: nginx/1.18.0 (Ubuntu) or similar

# Check NGINX status
sudo systemctl status nginx

# Enable NGINX to start on boot
sudo systemctl enable nginx

# Start NGINX if not running
sudo systemctl start nginx
```

### 3. Verify Installation

```bash
# Check if NGINX is listening
sudo ss -tlnp | grep nginx
# Should show ports 80 and possibly 443

# Test NGINX welcome page
curl http://localhost
# Should return HTML of default NGINX page

# Check from another device on LAN
curl http://192.168.1.x  # Replace with your NGINX server IP
```

### 4. Install Additional Tools

```bash
# Install SSL tools (for Let's Encrypt)
sudo apt install certbot python3-certbot-nginx -y

# Install useful utilities
sudo apt install curl wget net-tools -y
```

### 5. Basic NGINX Directory Structure

```bash
# View NGINX configuration structure
ls -la /etc/nginx/

# Important directories:
# /etc/nginx/nginx.conf          - Main configuration file
# /etc/nginx/sites-available/    - Available site configurations
# /etc/nginx/sites-enabled/      - Enabled site configurations (symlinks)
# /etc/nginx/conf.d/             - Additional configuration files
# /etc/nginx/snippets/           - Reusable configuration snippets
# /var/log/nginx/                - Log files
# /var/www/html/                 - Default web root
```

---

## Configuration Methods

You have two main approaches for routing traffic to your services:

### Method 1: Port-Based Routing
**Simple setup, each service on different port**

- **Pros**: Easy to configure, no DNS needed, works immediately
- **Cons**: Must remember ports, expose multiple ports, less professional
- **Best for**: Quick setup, testing, internal-only access

**URL Examples:**
- `http://192.168.1.x:8001` → Langflow
- `http://192.168.1.x:8002` → Service 2
- `http://192.168.1.x:8003` → Service 3

### Method 2: Subdomain-Based Routing
**Professional setup using domain names**

- **Pros**: Clean URLs, single port (80/443), easy SSL, professional
- **Cons**: Requires DNS configuration, slightly more complex
- **Best for**: Production use, multiple users, public-facing services

**URL Examples:**
- `https://langflow.itekk.in` → Langflow
- `https://app1.itekk.in` → Service 2
- `https://app2.itekk.in` → Service 3

**Recommendation**: Start with **Port-Based** for immediate functionality, migrate to **Subdomain-Based** for production use.

---

## Port-Based Routing Setup

### 1. Create Configuration File

```bash
# Remove default site (optional)
sudo rm /etc/nginx/sites-enabled/default

# Create new configuration
sudo nano /etc/nginx/sites-available/home-services
```

### 2. Port-Based Configuration

```nginx
# =============================================================================
# Langflow Service on Port 8001
# =============================================================================
server {
    listen 8001;
    listen [::]:8001;  # IPv6 support
    server_name _;     # Accept any hostname
    
    # Logging
    access_log /var/log/nginx/langflow-access.log;
    error_log /var/log/nginx/langflow-error.log;

    location / {
        # Backend service
        proxy_pass http://192.168.1.10:7860;
        
        # HTTP version
        proxy_http_version 1.1;
        
        # Essential proxy headers
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Port $server_port;
        
        # WebSocket support (critical for modern apps)
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # CORS headers to solve cross-origin issues
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, PATCH, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization' always;
        add_header 'Access-Control-Expose-Headers' 'Content-Length,Content-Range' always;
        
        # Handle preflight OPTIONS requests
        if ($request_method = 'OPTIONS') {
            add_header 'Access-Control-Allow-Origin' '*' always;
            add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, PATCH, OPTIONS' always;
            add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization' always;
            add_header 'Access-Control-Max-Age' 1728000;
            add_header 'Content-Type' 'text/plain; charset=utf-8';
            add_header 'Content-Length' 0;
            return 204;
        }
        
        # Timeouts (adjust based on your application needs)
        proxy_connect_timeout 600s;
        proxy_send_timeout 600s;
        proxy_read_timeout 600s;
        send_timeout 600s;
        
        # Buffer settings for large requests/responses
        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 24 4k;
        proxy_busy_buffers_size 8k;
        
        # Disable proxy cache for dynamic content
        proxy_cache_bypass $http_upgrade;
    }
}

# =============================================================================
# Service 2 on Port 8002
# =============================================================================
server {
    listen 8002;
    listen [::]:8002;
    server_name _;
    
    access_log /var/log/nginx/service2-access.log;
    error_log /var/log/nginx/service2-error.log;

    location / {
        proxy_pass http://192.168.1.11:3000;
        proxy_http_version 1.1;
        
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Add CORS headers if needed
        add_header 'Access-Control-Allow-Origin' '*' always;
    }
}

# =============================================================================
# Service 3 on Port 8003
# =============================================================================
server {
    listen 8003;
    listen [::]:8003;
    server_name _;
    
    access_log /var/log/nginx/service3-access.log;
    error_log /var/log/nginx/service3-error.log;

    location / {
        proxy_pass http://192.168.1.12:8080;
        proxy_http_version 1.1;
        
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# =============================================================================
# Health Check Endpoint (Optional but Recommended)
# =============================================================================
server {
    listen 8000;
    server_name _;
    
    location /health {
        access_log off;
        return 200 "NGINX is running\n";
        add_header Content-Type text/plain;
    }
    
    location /status {
        stub_status on;
        access_log off;
        allow 192.168.1.0/24;  # Allow only from local network
        allow 10.8.0.0/24;     # Allow from VPN network
        deny all;
    }
}
```

### 3. Enable Configuration

```bash
# Create symbolic link to enable the site
sudo ln -s /etc/nginx/sites-available/home-services /etc/nginx/sites-enabled/

# Test configuration for syntax errors
sudo nginx -t

# Expected output:
# nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
# nginx: configuration file /etc/nginx/nginx.conf test is successful

# If test passes, reload NGINX
sudo systemctl reload nginx

# Check status
sudo systemctl status nginx
```

### 4. Access Your Services

From any device connected to VPN:

```bash
# Langflow
http://192.168.1.x:8001

# Service 2
http://192.168.1.x:8002

# Service 3
http://192.168.1.x:8003

# Health check
http://192.168.1.x:8000/health
```

---

## Subdomain-Based Routing Setup

### 1. DNS Prerequisites

Before proceeding, ensure you have:
- Domain name: `itekk.in`
- Access to DNS management (GoDaddy)
- Decide on subdomain names:
  - `langflow.itekk.in`
  - `app1.itekk.in`
  - `app2.itekk.in`

### 2. Create Configuration File

```bash
# Create configuration for subdomain routing
sudo nano /etc/nginx/sites-available/home-services-subdomains
```

### 3. Subdomain-Based Configuration

```nginx
# =============================================================================
# Langflow Service - langflow.itekk.in
# =============================================================================
server {
    listen 80;
    listen [::]:80;
    server_name langflow.itekk.in;
    
    # Logging
    access_log /var/log/nginx/langflow-access.log;
    error_log /var/log/nginx/langflow-error.log;

    location / {
        # Backend service
        proxy_pass http://192.168.1.10:7860;
        proxy_http_version 1.1;
        
        # Proxy headers
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket support
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # CORS headers
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization' always;
        add_header 'Access-Control-Expose-Headers' 'Content-Length,Content-Range' always;
        add_header 'Access-Control-Allow-Credentials' 'true' always;
        
        # Preflight requests
        if ($request_method = 'OPTIONS') {
            add_header 'Access-Control-Allow-Origin' '*' always;
            add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS' always;
            add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization' always;
            add_header 'Access-Control-Max-Age' 1728000;
            add_header 'Content-Type' 'text/plain; charset=utf-8';
            add_header 'Content-Length' 0;
            return 204;
        }
        
        # Timeouts
        proxy_connect_timeout 600s;
        proxy_send_timeout 600s;
        proxy_read_timeout 600s;
        
        # Buffers
        proxy_buffering on;
        proxy_buffer_size 128k;
        proxy_buffers 4 256k;
        proxy_busy_buffers_size 256k;
    }
}

# =============================================================================
# Service 2 - app1.itekk.in
# =============================================================================
server {
    listen 80;
    listen [::]:80;
    server_name app1.itekk.in;
    
    access_log /var/log/nginx/app1-access.log;
    error_log /var/log/nginx/app1-error.log;

    location / {
        proxy_pass http://192.168.1.11:3000;
        proxy_http_version 1.1;
        
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # CORS if needed
        add_header 'Access-Control-Allow-Origin' '*' always;
    }
}

# =============================================================================
# Service 3 - app2.itekk.in
# =============================================================================
server {
    listen 80;
    listen [::]:80;
    server_name app2.itekk.in;
    
    access_log /var/log/nginx/app2-access.log;
    error_log /var/log/nginx/app2-error.log;

    location / {
        proxy_pass http://192.168.1.12:8080;
        proxy_http_version 1.1;
        
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# =============================================================================
# Default Server (Catch-all for unknown domains)
# =============================================================================
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;
    
    return 444;  # Close connection without response
}
```

### 4. Enable Subdomain Configuration

```bash
# Enable the subdomain configuration
sudo ln -s /etc/nginx/sites-available/home-services-subdomains /etc/nginx/sites-enabled/

# Remove port-based config if you had it enabled
# sudo rm /etc/nginx/sites-enabled/home-services

# Test configuration
sudo nginx -t

# Reload NGINX
sudo systemctl reload nginx
```

### 5. Configure Local DNS (For VPN-Only Access)

If you want subdomains to work only within VPN (not public internet):

```bash
# Edit hosts file on NGINX server
sudo nano /etc/hosts
```

Add entries:
```
# Local service routing
127.0.0.1   langflow.itekk.in
127.0.0.1   app1.itekk.in
127.0.0.1   app2.itekk.in
```

**OR** use dnsmasq for local DNS:

```bash
# Install dnsmasq
sudo apt install dnsmasq -y

# Configure
sudo nano /etc/dnsmasq.conf
```

Add:
```
# Local DNS entries
address=/langflow.itekk.in/192.168.1.x
address=/app1.itekk.in/192.168.1.x
address=/app2.itekk.in/192.168.1.x
```

```bash
# Restart dnsmasq
sudo systemctl restart dnsmasq

# Configure OpenVPN to push DNS
sudo nano /etc/openvpn/server/server.conf
```

Add:
```
# Push local DNS server to VPN clients
push "dhcp-option DNS 192.168.1.x"
```

---

## SSL/TLS Configuration

### Option 1: Let's Encrypt (Public Domain - Recommended)

**Requirements:**
- Public domain name pointing to your VPN server
- Ports 80 and 443 accessible from internet
- Certbot installed

```bash
# Install certbot
sudo apt install certbot python3-certbot-nginx -y

# Stop NGINX temporarily
sudo systemctl stop nginx

# Get certificates for all subdomains at once
sudo certbot certonly --standalone \
  -d langflow.itekk.in \
  -d app1.itekk.in \
  -d app2.itekk.in \
  --email your-email@example.com \
  --agree-tos

# OR get them individually
sudo certbot certonly --standalone -d langflow.itekk.in
sudo certbot certonly --standalone -d app1.itekk.in
sudo certbot certonly --standalone -d app2.itekk.in

# Start NGINX
sudo systemctl start nginx

# Update NGINX configuration
sudo nano /etc/nginx/sites-available/home-services-subdomains
```

Update each server block to use SSL:

```nginx
# Langflow HTTPS
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name langflow.itekk.in;
    
    # SSL Certificate paths
    ssl_certificate /etc/letsencrypt/live/langflow.itekk.in/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/langflow.itekk.in/privkey.pem;
    
    # SSL Configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # OCSP Stapling
    ssl_stapling on;
    ssl_stapling_verify on;
    ssl_trusted_certificate /etc/letsencrypt/live/langflow.itekk.in/chain.pem;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    access_log /var/log/nginx/langflow-ssl-access.log;
    error_log /var/log/nginx/langflow-ssl-error.log;

    location / {
        proxy_pass http://192.168.1.10:7860;
        proxy_http_version 1.1;
        
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;  # Important: set to https
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # CORS headers
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization' always;
        
        if ($request_method = 'OPTIONS') {
            return 204;
        }
        
        proxy_connect_timeout 600s;
        proxy_send_timeout 600s;
        proxy_read_timeout 600s;
    }
}

# HTTP to HTTPS redirect
server {
    listen 80;
    listen [::]:80;
    server_name langflow.itekk.in;
    
    # Redirect all HTTP to HTTPS
    return 301 https://$server_name$request_uri;
}
```

Repeat for other subdomains.

```bash
# Test configuration
sudo nginx -t

# Reload NGINX
sudo systemctl reload nginx

# Test auto-renewal
sudo certbot renew --dry-run

# Setup auto-renewal cron job (certbot does this automatically)
sudo systemctl status certbot.timer
```

### Option 2: Self-Signed Certificate (VPN-Only Access)

**Best for:** Internal VPN-only access where Let's Encrypt won't work

```bash
# Create directory for certificates
sudo mkdir -p /etc/nginx/ssl

# Generate self-signed certificate (valid for 365 days)
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/nginx/ssl/nginx-selfsigned.key \
  -out /etc/nginx/ssl/nginx-selfsigned.crt \
  -subj "/C=IN/ST=TamilNadu/L=Chennai/O=HomeNetwork/CN=*.itekk.in"

# Generate Diffie-Hellman parameters (takes a few minutes)
sudo openssl dhparam -out /etc/nginx/ssl/dhparam.pem 2048

# Set proper permissions
sudo chmod 600 /etc/nginx/ssl/nginx-selfsigned.key
sudo chmod 644 /etc/nginx/ssl/nginx-selfsigned.crt
```

Create SSL configuration snippet:

```bash
sudo nano /etc/nginx/snippets/self-signed.conf
```

```nginx
ssl_certificate /etc/nginx/ssl/nginx-selfsigned.crt;
ssl_certificate_key /etc/nginx/ssl/nginx-selfsigned.key;
```

```bash
sudo nano /etc/nginx/snippets/ssl-params.conf
```

```nginx
ssl_protocols TLSv1.2 TLSv1.3;
ssl_prefer_server_ciphers on;
ssl_dhparam /etc/nginx/ssl/dhparam.pem;
ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384;
ssl_session_timeout 10m;
ssl_session_cache shared:SSL:10m;
ssl_stapling off;  # Not applicable for self-signed
ssl_stapling_verify off;

# Security headers
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
```

Update server block:

```nginx
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name langflow.itekk.in;
    
    include snippets/self-signed.conf;
    include snippets/ssl-params.conf;
    
    access_log /var/log/nginx/langflow-ssl-access.log;
    error_log /var/log/nginx/langflow-ssl-error.log;

    location / {
        proxy_pass http://192.168.1.10:7860;
        proxy_http_version 1.1;
        
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # CORS
        add_header 'Access-Control-Allow-Origin' '*' always;
    }
}

server {
    listen 80;
    listen [::]:80;
    server_name langflow.itekk.in;
    return 301 https://$server_name$request_uri;
}
```

**Note:** Browsers will show security warnings for self-signed certificates. You'll need to add an exception.

---

## DNS Configuration

### Public DNS (GoDaddy)

If you want services accessible from internet (through VPN):

1. **Login to GoDaddy DNS Management**
2. **Add A Records:**

```
Type    Name        Value                       TTL
----    ----        -----                       ---
A       langflow    <your-public-IP>           600
A       app1        <your-public-IP>           600
A       app2        <your-public-IP>           600
```

Or use wildcard:
```
A       *           <your-public-IP>           600
```

3. **Verify DNS propagation:**

```bash
# Check DNS records
nslookup langflow.itekk.in
dig langflow.itekk.in

# Check from online tools
# https://dnschecker.org
```

### Private DNS (VPN-Only)

For internal-only access without exposing to internet:

#### Method 1: Hosts File on Each Client

On each VPN client device:

**Windows:**
```
# Edit: C:\Windows\System32\drivers\etc\hosts
192.168.1.x    langflow.itekk.in
192.168.1.x    app1.itekk.in
192.168.1.x    app2.itekk.in
```

**Linux/Mac:**
```bash
sudo nano /etc/hosts

# Add:
192.168.1.x    langflow.itekk.in
192.168.1.x    app1.itekk.in
192.168.1.x    app2.itekk.in
```

#### Method 2: Local DNS Server (Better for Multiple Clients)

**Install dnsmasq on NGINX server:**

```bash
sudo apt install dnsmasq -y

# Configure dnsmasq
sudo nano /etc/dnsmasq.conf
```

Add:
```
# Listen on all interfaces
listen-address=127.0.0.1
listen-address=192.168.1.x

# DNS entries
address=/langflow.itekk.in/192.168.1.x
address=/app1.itekk.in/192.168.1.x
address=/app2.itekk.in/192.168.1.x

# Or wildcard
address=/.itekk.in/192.168.1.x

# Upstream DNS
server=8.8.8.8
server=8.8.4.4

# Cache size
cache-size=1000
```

```bash
# Restart dnsmasq
sudo systemctl restart dnsmasq
sudo systemctl enable dnsmasq

# Verify
dig @192.168.1.x langflow.itekk.in
```

**Configure OpenVPN to push DNS:**

```bash
sudo nano /etc/openvpn/server/server.conf
```

Add:
```
# Push DNS server to clients
push "dhcp-option DNS 192.168.1.x"

# Prevent DNS leaks
push "block-outside-dns"
```

```bash
# Restart OpenVPN
sudo systemctl restart openvpn-server@server
```

---

## Firewall Configuration

### UFW (Ubuntu Firewall)

```bash
# Check firewall status
sudo ufw status

# Allow SSH (if not already allowed)
sudo ufw allow 22/tcp

# Allow NGINX HTTP and HTTPS
sudo ufw allow 'Nginx Full'

# Or manually:
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# For port-based routing, allow specific ports
sudo ufw allow 8001/tcp
sudo ufw allow 8002/tcp
sudo ufw allow 8003/tcp

# Allow from VPN subnet only (more secure)
sudo ufw allow from 10.8.0.0/24 to any port 80
sudo ufw allow from 10.8.0.0/24 to any port 443
sudo ufw allow from 10.8.0.0/24 to any port 8001
sudo ufw allow from 10.8.0.0/24 to any port 8002
sudo ufw allow from 10.8.0.0/24 to any port 8003

# Enable firewall if not already enabled
sudo ufw enable

# Reload firewall rules
sudo ufw reload

# Check status
sudo ufw status numbered
```

### IPTables (Alternative)

```bash
# Allow HTTP and HTTPS
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# Allow from VPN subnet only
sudo iptables -A INPUT -s 10.8.0.0/24 -p tcp --dport 80 -j ACCEPT
sudo iptables -A INPUT -s 10.8.0.0/24 -p tcp --dport 443 -j ACCEPT

# Save rules
sudo iptables-save | sudo tee /etc/iptables/rules.v4

# Install persistence
sudo apt install iptables-persistent -y
```

### Service-Level Firewall

Restrict backend services to accept connections only from NGINX:

```bash
# Example: If backend service has its own firewall
# Allow only from NGINX server IP
sudo ufw allow from 192.168.1.x to any port 7860
```

---

## Advanced CORS Handling

### Comprehensive CORS Configuration

For applications with strict CORS requirements:

```bash
# Create CORS configuration snippet
sudo nano /etc/nginx/snippets/cors.conf
```

```nginx
# CORS configuration snippet

# Set allowed origins
set $cors_origin "*";

# For specific origins, use:
# if ($http_origin ~* (https?://langflow\.itekk\.in|https?://app1\.itekk\.in)) {
#     set $cors_origin $http_origin;
# }

# CORS method and header definitions
set $cors_methods "GET, POST, PUT, DELETE, PATCH, OPTIONS";
set $cors_headers "DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization,Accept,Origin,X-Custom-Header";

# Always add CORS headers for all requests
add_header 'Access-Control-Allow-Origin' $cors_origin always;
add_header 'Access-Control-Allow-Methods' $cors_methods always;
add_header 'Access-Control-Allow-Headers' $cors_headers always;
add_header 'Access-Control-Expose-Headers' 'Content-Length,Content-Range,Authorization,X-Custom-Header' always;
add_header 'Access-Control-Allow-Credentials' 'true' always;
add_header 'Access-Control-Max-Age' 1728000 always;

# Handle preflight OPTIONS requests
if ($request_method = 'OPTIONS') {
    add_header 'Access-Control-Allow-Origin' $cors_origin always;
    add_header 'Access-Control-Allow-Methods' $cors_methods always;
    add_header 'Access-Control-Allow-Headers' $cors_headers always;
    add_header 'Access-Control-Max-Age' 1728000 always;
    add_header 'Content-Type' 'text/plain; charset=utf-8' always;
    add_header 'Content-Length' 0 always;
    return 204;
}
```

### Using CORS Snippet

```nginx
server {
    listen 80;
    server_name langflow.itekk.in;

    location / {
        # Include CORS configuration
        include snippets/cors.conf;
        
        proxy_pass http://192.168.1.10:7860;
        proxy_http_version 1.1;
        
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

### Testing CORS

```bash
# Test preflight request
curl -H "Origin: http://example.com" \
     -H "Access-Control-Request-Method: POST" \
     -H "Access-Control-Request-Headers: Content-Type" \
     -X OPTIONS --verbose \
     http://langflow.itekk.in

# Expected headers in response:
# Access-Control-Allow-Origin: *
# Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS
# Access-Control-Allow-Headers: ...
```

---

## Performance Optimization

### 1. Enable Caching

```bash
# Create cache directory
sudo mkdir -p /var/cache/nginx
sudo chown www-data:www-data /var/cache/nginx

# Configure caching
sudo nano /etc/nginx/conf.d/cache.conf
```

```nginx
# Cache configuration
proxy_cache_path /var/cache/nginx/cache 
                 levels=1:2 
                 keys_zone=my_cache:10m 
                 max_size=1g 
                 inactive=60m 
                 use_temp_path=off;

# Cache key configuration
proxy_cache_key "$scheme$request_method$host$request_uri";
```

Use in server block:

```nginx
location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
    proxy_cache my_cache;
    proxy_cache_valid 200 304 60m;
    proxy_cache_valid 404 1m;
    proxy_cache_bypass $http_cache_control;
    add_header X-Cache-Status $upstream_cache_status;
    
    proxy_pass http://192.168.1.10:7860;
}
```

### 2. Enable Compression

```bash
sudo nano /etc/nginx/nginx.conf
```

```nginx
http {
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript 
               application/json application/javascript application/xml+rss 
               application/rss+xml font/truetype font/opentype 
               application/vnd.ms-fontobject image/svg+xml;
    gzip_disable "msie6";
    
    # Other settings...
}
```

### 3. Connection Optimization

```bash
sudo nano /etc/nginx/nginx.conf
```

```nginx
http {
    # Keep-alive connections
    keepalive_timeout 65;
    keepalive_requests 100;
    
    # Buffer sizes
    client_body_buffer_size 128k;
    client_max_body_size 50m;
    client_header_buffer_size 1k;
    large_client_header_buffers 4 16k;
    
    # Timeouts
    client_body_timeout 12;
    client_header_timeout 12;
    send_timeout 10;
    
    # Other settings...
}
```

### 4. Worker Process Optimization

```bash
sudo nano /etc/nginx/nginx.conf
```

```nginx
# Set based on CPU cores
# Check with: nproc
worker_processes auto;

# Maximum file descriptors
worker_rlimit_nofile 65535;

events {
    worker_connections 4096;
    use epoll;
    multi_accept on;
}
```

### 5. Proxy Buffer Optimization

```bash
sudo nano /etc/nginx/conf.d/proxy-buffers.conf
```

```nginx
# Proxy buffer settings
proxy_buffering on;
proxy_buffer_size 128k;
proxy_buffers 4 256k;
proxy_busy_buffers_size 256k;
proxy_max_temp_file_size 2048m;
proxy_temp_file_write_size 128k;

# Hide backend headers
proxy_hide_header X-Powered-By;
proxy_hide_header Server;
```

### 6. Apply Optimizations

```bash
# Test configuration
sudo nginx -t

# Reload NGINX
sudo systemctl reload nginx
```

---

## Testing and Verification

### 1. Basic Connectivity Tests

```bash
# Test from NGINX server itself
curl -I http://localhost:8001
curl -I http://langflow.itekk.in

# Test from another device on LAN
curl -I http://192.168.1.x:8001
curl -I http://langflow.itekk.in

# Test HTTPS
curl -I https://langflow.itekk.in

# Test with verbose output
curl -v http://langflow.itekk.in
```

### 2. Test CORS Headers

```bash
# Test CORS preflight
curl -H "Origin: http://example.com" \
     -H "Access-Control-Request-Method: POST" \
     -H "Access-Control-Request-Headers: Content-Type,Authorization" \
     -X OPTIONS --verbose \
     http://langflow.itekk.in

# Check for these headers in response:
# Access-Control-Allow-Origin
# Access-Control-Allow-Methods
# Access-Control-Allow-Headers
```

### 3. Test WebSocket Connection

```bash
# Install websocat for testing
cargo install websocat

# Or use wscat
npm install -g wscat

# Test WebSocket
wscat -c ws://langflow.itekk.in/ws
```

### 4. Test SSL/TLS Configuration

```bash
# Test SSL configuration
openssl s_client -connect langflow.itekk.in:443 -servername langflow.itekk.in

# Check certificate
openssl s_client -connect langflow.itekk.in:443 -servername langflow.itekk.in | openssl x509 -noout -text

# Test SSL with specific protocol
openssl s_client -connect langflow.itekk.in:443 -tls1_2
openssl s_client -connect langflow.itekk.in:443 -tls1_3

# Online SSL test
# https://www.ssllabs.com/ssltest/
```

### 5. Performance Testing

```bash
# Install Apache Bench
sudo apt install apache2-utils -y

# Simple load test
ab -n 1000 -c 10 http://langflow.itekk.in/

# Test with keep-alive
ab -n 1000 -c 10 -k http://langflow.itekk.in/

# More advanced testing with wrk
sudo apt install wrk -y
wrk -t4 -c100 -d30s http://langflow.itekk.in/
```

### 6. Check NGINX Status

```bash
# Real-time status (if configured)
curl http://192.168.1.x:8000/status

# Check processes
ps aux | grep nginx

# Check listening ports
sudo ss -tlnp | grep nginx

# Check resource usage
top -p $(pgrep nginx | tr '\n' ',' | sed 's/,$//')
```

### 7. End-to-End Test from VPN Client

```bash
# Connect to VPN first
sudo openvpn --config client.ovpn

# Test access
curl http://langflow.itekk.in
curl http://app1.itekk.in
curl http://app2.itekk.in

# Test in browser
# Open: http://langflow.itekk.in
# Open: https://langflow.itekk.in (if SSL configured)
```

---

## Troubleshooting

### 1. 502 Bad Gateway

**Symptoms:** NGINX returns 502 error

**Possible Causes:**
- Backend service is down
- Wrong backend IP/port in configuration
- Firewall blocking connection
- Backend service refusing connections

**Solutions:**

```bash
# Check if backend service is running
curl http://192.168.1.10:7860

# Check NGINX error logs
sudo tail -f /var/log/nginx/error.log

# Check backend service logs
# (depends on your service)

# Test connectivity from NGINX server to backend
telnet 192.168.1.10 7860
nc -zv 192.168.1.10 7860

# Check NGINX configuration
sudo nginx -t

# Verify SELinux (if applicable)
sudo setsebool -P httpd_can_network_connect 1

# Check firewall rules
sudo ufw status
sudo iptables -L -n
```

### 2. 504 Gateway Timeout

**Symptoms:** Request times out, 504 error

**Possible Causes:**
- Backend service too slow
- Insufficient timeout values
- Network connectivity issues

**Solutions:**

```bash
# Increase timeouts in NGINX configuration
sudo nano /etc/nginx/sites-available/home-services
```

```nginx
location / {
    proxy_pass http://backend;
    
    # Increase timeouts
    proxy_connect_timeout 300s;
    proxy_send_timeout 300s;
    proxy_read_timeout 300s;
    fastcgi_send_timeout 300s;
    fastcgi_read_timeout 300s;
}
```

```bash
# Reload NGINX
sudo systemctl reload nginx
```

### 3. CORS Errors Still Occurring

**Symptoms:** Browser console shows CORS errors

**Solutions:**

```bash
# Check if CORS headers are being sent
curl -I -H "Origin: http://example.com" http://langflow.itekk.in

# Ensure CORS headers are in location block, not just server block
# Add 'always' flag to headers
add_header 'Access-Control-Allow-Origin' '*' always;

# Check for duplicate headers
# If backend also sends CORS headers, you might have conflicts

# To override backend CORS headers
proxy_hide_header Access-Control-Allow-Origin;
add_header 'Access-Control-Allow-Origin' '*' always;
```

### 4. WebSocket Connection Failing

**Symptoms:** WebSocket upgrade fails, connection drops

**Solutions:**

```nginx
location / {
    proxy_pass http://backend;
    
    # Essential WebSocket headers
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    
    # Disable buffering for WebSocket
    proxy_buffering off;
    
    # Increase timeouts for long-lived connections
    proxy_read_timeout 86400s;
    proxy_send_timeout 86400s;
}
```

### 5. SSL Certificate Issues

**Symptoms:** Browser shows "Not Secure" or certificate errors

**Solutions:**

```bash
# Check certificate validity
openssl x509 -in /etc/letsencrypt/live/langflow.itekk.in/cert.pem -text -noout

# Check certificate expiration
openssl x509 -in /etc/letsencrypt/live/langflow.itekk.in/cert.pem -noout -dates

# Renew certificate
sudo certbot renew

# For self-signed certificates
# Trust the certificate on client devices

# Check certificate chain
openssl s_client -connect langflow.itekk.in:443 -showcerts
```

### 6. DNS Not Resolving

**Symptoms:** Domain name doesn't resolve to IP

**Solutions:**

```bash
# Test DNS resolution
nslookup langflow.itekk.in
dig langflow.itekk.in

# Check /etc/hosts file
cat /etc/hosts

# Flush DNS cache on client
# Windows:
ipconfig /flushdns

# Linux:
sudo systemd-resolve --flush-caches

# macOS:
sudo dscacheutil -flushcache

# Check VPN DNS settings
cat /etc/resolv.conf

# Verify dnsmasq is running (if using)
sudo systemctl status dnsmasq
```

### 7. Performance Issues / Slow Loading

**Solutions:**

```bash
# Check NGINX resource usage
top
htop

# Check for errors in logs
sudo tail -f /var/log/nginx/error.log

# Enable access log to see request times
sudo tail -f /var/log/nginx/access.log

# Optimize buffer sizes
# See Performance Optimization section

# Check network latency
ping 192.168.1.10

# Check backend service performance
# Access backend directly to isolate issue
curl -w "@curl-format.txt" -o /dev/null -s http://192.168.1.10:7860
```

Create curl timing format file:

```bash
cat > curl-format.txt << 'EOF'
    time_namelookup:  %{time_namelookup}\n
       time_connect:  %{time_connect}\n
    time_appconnect:  %{time_appconnect}\n
   time_pretransfer:  %{time_pretransfer}\n
      time_redirect:  %{time_redirect}\n
 time_starttransfer:  %{time_starttransfer}\n
                    ----------\n
         time_total:  %{time_total}\n
EOF
```

### 8. Configuration Not Taking Effect

**Solutions:**

```bash
# Always test configuration before reloading
sudo nginx -t

# Reload (preferred for config changes)
sudo systemctl reload nginx

# Restart (if reload doesn't work)
sudo systemctl restart nginx

# Check if NGINX is actually running
sudo systemctl status nginx

# View NGINX process details
ps aux | grep nginx

# Check which config files are being used
sudo nginx -T | less
```

### 9. Permission Denied Errors

**Solutions:**

```bash
# Check file permissions
ls -la /etc/nginx/sites-available/
ls -la /etc/nginx/ssl/

# Fix ownership
sudo chown -R root:root /etc/nginx/
sudo chown www-data:www-data /var/log/nginx/
sudo chown www-data:www-data /var/cache/nginx/

# Check SELinux context (if applicable)
ls -Z /etc/nginx/

# Fix SELinux context
sudo restorecon -Rv /etc/nginx/
```

### 10. Port Already in Use

**Symptoms:** NGINX fails to start, port conflict

**Solutions:**

```bash
# Check what's using the port
sudo ss -tlnp | grep :80
sudo lsof -i :80

# Kill the process using the port
sudo kill -9 <PID>

# Or change NGINX port in configuration
listen 8080;  # Instead of 80
```

---

## Monitoring and Logging

### 1. Log Files

```bash
# Access logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/langflow-access.log

# Error logs
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/langflow-error.log

# View logs with filtering
sudo grep "GET" /var/log/nginx/access.log
sudo grep "error" /var/log/nginx/error.log | tail -20

# View logs by date
sudo grep "30/Dec/2025" /var/log/nginx/access.log
```

### 2. Custom Log Format

```bash
sudo nano /etc/nginx/nginx.conf
```

```nginx
http {
    # Custom log format with timing information
    log_format detailed '$remote_addr - $remote_user [$time_local] '
                       '"$request" $status $body_bytes_sent '
                       '"$http_referer" "$http_user_agent" '
                       'rt=$request_time uct="$upstream_connect_time" '
                       'uht="$upstream_header_time" urt="$upstream_response_time"';
    
    # Use custom format
    access_log /var/log/nginx/access.log detailed;
}
```

### 3. Log Rotation

NGINX logs are automatically rotated by logrotate. Check configuration:

```bash
# View logrotate config
cat /etc/logrotate.d/nginx

# Manual log rotation test
sudo logrotate -f /etc/logrotate.d/nginx

# Check rotated logs
ls -lah /var/log/nginx/
```

Customize log rotation:

```bash
sudo nano /etc/logrotate.d/nginx
```

```
/var/log/nginx/*.log {
    daily           # Rotate daily
    missingok       # Don't error if log missing
    rotate 14       # Keep 14 days of logs
    compress        # Compress old logs
    delaycompress   # Compress on next rotation
    notifempty      # Don't rotate empty logs
    create 0640 www-data adm
    sharedscripts
    postrotate
        if [ -f /var/run/nginx.pid ]; then
            kill -USR1 `cat /var/run/nginx.pid`
        fi
    endscript
}
```

### 4. Real-Time Monitoring with GoAccess

```bash
# Install GoAccess
sudo apt install goaccess -y

# Real-time HTML report
sudo goaccess /var/log/nginx/access.log -o /var/www/html/report.html --log-format=COMBINED --real-time-html

# Terminal dashboard
sudo goaccess /var/log/nginx/access.log --log-format=COMBINED

# Access report
# http://192.168.1.x/report.html
```

### 5. Status Module

Enable status module (already configured in port-based example):

```nginx
server {
    listen 8000;
    
    location /status {
        stub_status on;
        access_log off;
        allow 192.168.1.0/24;
        allow 10.8.0.0/24;
        deny all;
    }
}
```

Access status:
```bash
curl http://192.168.1.x:8000/status
```

### 6. Alerting with Logwatch

```bash
# Install logwatch
sudo apt install logwatch -y

# Configure for NGINX
sudo nano /etc/logwatch/conf/services/nginx.conf

# Run manually
sudo logwatch --service nginx --detail high

# Configure daily email reports
sudo nano /etc/cron.daily/00logwatch
```

### 7. Integration with Monitoring Tools

**Prometheus + Grafana:**

```bash
# Install nginx-prometheus-exporter
wget https://github.com/nginxinc/nginx-prometheus-exporter/releases/download/v0.11.0/nginx-prometheus-exporter_0.11.0_linux_amd64.tar.gz
tar -xzf nginx-prometheus-exporter_0.11.0_linux_amd64.tar.gz
sudo mv nginx-prometheus-exporter /usr/local/bin/

# Run exporter
nginx-prometheus-exporter -nginx.scrape-uri=http://localhost:8000/status
```

---

## Security Best Practices

### 1. Limit Request Methods

```nginx
location / {
    # Allow only specific methods
    limit_except GET POST PUT DELETE {
        deny all;
    }
    
    proxy_pass http://backend;
}
```

### 2. Rate Limiting

```nginx
# Define rate limit zone
http {
    limit_req_zone $binary_remote_addr zone=one:10m rate=10r/s;
    limit_conn_zone $binary_remote_addr zone=addr:10m;
}

# Apply in location
location / {
    limit_req zone=one burst=20 nodelay;
    limit_conn addr 10;
    
    proxy_pass http://backend;
}
```

### 3. IP Whitelisting

```nginx
location / {
    # Allow specific IPs or ranges
    allow 192.168.1.0/24;
    allow 10.8.0.0/24;
    deny all;
    
    proxy_pass http://backend;
}
```

### 4. Basic Authentication

```bash
# Install htpasswd utility
sudo apt install apache2-utils -y

# Create password file
sudo htpasswd -c /etc/nginx/.htpasswd admin

# Add more users
sudo htpasswd /etc/nginx/.htpasswd user2
```

```nginx
location / {
    auth_basic "Restricted Access";
    auth_basic_user_file /etc/nginx/.htpasswd;
    
    proxy_pass http://backend;
}
```

### 5. Security Headers

```nginx
# Add to server block
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header Content-Security-Policy "default-src 'self' https: data: 'unsafe-inline' 'unsafe-eval'" always;

# For HTTPS only
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
```

### 6. Hide NGINX Version

```bash
sudo nano /etc/nginx/nginx.conf
```

```nginx
http {
    server_tokens off;
}
```

### 7. Disable Unused HTTP Methods

```nginx
location / {
    if ($request_method !~ ^(GET|POST|HEAD|PUT|DELETE)$) {
        return 405;
    }
    
    proxy_pass http://backend;
}
```

### 8. DDoS Protection

```nginx
# Connection limiting
limit_conn_zone $binary_remote_addr zone=conn_limit_per_ip:10m;
limit_req_zone $binary_remote_addr zone=req_limit_per_ip:10m rate=5r/s;

server {
    limit_conn conn_limit_per_ip 10;
    limit_req zone=req_limit_per_ip burst=10 nodelay;
}
```

### 9. Fail2ban Integration

```bash
# Install Fail2ban
sudo apt install fail2ban -y

# Create NGINX jail
sudo nano /etc/fail2ban/jail.local
```

```ini
[nginx-http-auth]
enabled = true
port = http,https
filter = nginx-http-auth
logpath = /var/log/nginx/error.log
maxretry = 3
bantime = 3600

[nginx-noscript]
enabled = true
port = http,https
filter = nginx-noscript
logpath = /var/log/nginx/access.log
maxretry = 6
bantime = 3600

[nginx-badbots]
enabled = true
port = http,https
filter = nginx-badbots
logpath = /var/log/nginx/access.log
maxretry = 2
bantime = 86400
```

```bash
# Restart Fail2ban
sudo systemctl restart fail2ban

# Check status
sudo fail2ban-client status
sudo fail2ban-client status nginx-http-auth
```

---

## Maintenance

### Daily Tasks

```bash
# Check NGINX status
sudo systemctl status nginx

# Check error logs for issues
sudo tail -20 /var/log/nginx/error.log

# Monitor disk usage
df -h
```

### Weekly Tasks

```bash
# Review access logs
sudo tail -100 /var/log/nginx/access.log

# Check for failed SSL certificates (if using Let's Encrypt)
sudo certbot certificates

# Review security logs
sudo grep "denied" /var/log/nginx/error.log
```

### Monthly Tasks

```bash
# Update system and NGINX
sudo apt update
sudo apt upgrade nginx -y

# Test SSL certificate renewal
sudo certbot renew --dry-run

# Review and rotate logs manually if needed
sudo logrotate -f /etc/logrotate.d/nginx

# Check for NGINX updates
nginx -v
apt-cache policy nginx
```

### Backup Configuration

```bash
# Create backup script
sudo nano /usr/local/bin/backup-nginx.sh
```

```bash
#!/bin/bash
BACKUP_DIR="/backup/nginx"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Backup configurations
tar -czf $BACKUP_DIR/nginx-config-$DATE.tar.gz /etc/nginx/

# Backup SSL certificates
tar -czf $BACKUP_DIR/nginx-ssl-$DATE.tar.gz /etc/letsencrypt/ /etc/nginx/ssl/

# Keep only last 7 backups
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete

echo "Backup completed: $DATE"
```

```bash
# Make executable
sudo chmod +x /usr/local/bin/backup-nginx.sh

# Add to cron
sudo crontab -e

# Add line (run daily at 2 AM)
0 2 * * * /usr/local/bin/backup-nginx.sh
```

### Restore from Backup

```bash
# Stop NGINX
sudo systemctl stop nginx

# Restore configuration
sudo tar -xzf /backup/nginx/nginx-config-YYYYMMDD_HHMMSS.tar.gz -C /

# Restore SSL
sudo tar -xzf /backup/nginx/nginx-ssl-YYYYMMDD_HHMMSS.tar.gz -C /

# Test configuration
sudo nginx -t

# Start NGINX
sudo systemctl start nginx
```

---

## Quick Reference Commands

### Essential Commands

```bash
# Test configuration
sudo nginx -t

# Reload configuration
sudo systemctl reload nginx

# Restart NGINX
sudo systemctl restart nginx

# Check status
sudo systemctl status nginx

# View running config
sudo nginx -T

# Check error logs
sudo tail -f /var/log/nginx/error.log

# Check access logs
sudo tail -f /var/log/nginx/access.log

# Test connectivity
curl -I http://langflow.itekk.in

# Test backend
curl http://192.168.1.10:7860
```

### Troubleshooting Commands

```bash
# Check listening ports
sudo ss -tlnp | grep nginx

# Check processes
ps aux | grep nginx

# Test DNS
nslookup langflow.itekk.in

# Test SSL
openssl s_client -connect langflow.itekk.in:443

# Check firewall
sudo ufw status

# View full configuration
sudo nginx -T | less
```

---

## Complete Example Configurations

### Example 1: Simple Port-Based Setup (HTTP Only)

```nginx
# /etc/nginx/sites-available/simple-home-services

server {
    listen 8001;
    server_name _;

    location / {
        proxy_pass http://192.168.1.10:7860;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        add_header 'Access-Control-Allow-Origin' '*' always;
    }
}
```

### Example 2: Production Subdomain Setup (HTTPS with SSL)

```nginx
# /etc/nginx/sites-available/production-services

server {
    listen 443 ssl http2;
    server_name langflow.itekk.in;
    
    ssl_certificate /etc/letsencrypt/live/langflow.itekk.in/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/langflow.itekk.in/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    
    add_header Strict-Transport-Security "max-age=31536000" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;

    location / {
        proxy_pass http://192.168.1.10:7860;
        proxy_http_version 1.1;
        
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS' always;
        
        if ($request_method = 'OPTIONS') {
            return 204;
        }
    }
}

server {
    listen 80;
    server_name langflow.itekk.in;
    return 301 https://$server_name$request_uri;
}
```

---

## Conclusion

You now have a complete NGINX reverse proxy setup that:

✅ Solves CORS issues  
✅ Provides clean, memorable URLs  
✅ Supports SSL/TLS encryption  
✅ Handles WebSocket connections  
✅ Centralizes access control  
✅ Improves security  
✅ Enables monitoring and logging  

### Next Steps

1. **Deploy**: Choose port-based or subdomain-based routing
2. **Test**: Verify all services are accessible through NGINX
3. **Secure**: Add SSL certificates and security headers
4. **Monitor**: Set up logging and monitoring
5. **Optimize**: Tune performance based on usage patterns
6. **Document**: Keep track of your service URLs and configurations

### Getting Help

- **NGINX Documentation**: https://nginx.org/en/docs/
- **Community Forum**: https://forum.nginx.org/
- **Stack Overflow**: Tag your questions with `nginx`

---

## Additional Resources

### Related Guides in Your Collection

- **OpenVPN Setup**: Your existing OpenVPN configuration
- **Nmap Guide**: Network discovery and security scanning
- **Bettercap Guide**: Advanced network analysis

### Recommended Tools

- **GoAccess**: Real-time web log analyzer
- **Certbot**: Let's Encrypt SSL automation
- **Fail2ban**: Intrusion prevention
- **Prometheus**: Metrics collection
- **Grafana**: Monitoring dashboards

---

**Document Version**: 1.0  
**Last Updated**: December 29, 2025  
**Author**: Network Security Documentation Project  
**License**: Free for personal and educational use
