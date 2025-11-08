# 🧩 Ubuntu ↔ Mac Port Connectivity Testing Cheat-Sheet

This guide helps you **listen on a port** from an Ubuntu server and **test the connection** from a Mac (or another host).

---

## 🖥️ On Ubuntu Server (Listener Side)

### ✅ Using `nc` (Netcat)
```bash
sudo nc -lvnp 8080
```

**Options explained:**
- `-l` — listen mode  
- `-v` — verbose output  
- `-n` — numeric IPs only (no DNS lookup)  
- `-p 8080` — specify port number  

> Example:  
> Listen on TCP port **8080** waiting for connections.

---

### 🧰 Using `socat` (Alternative)
```bash
sudo socat TCP-LISTEN:8080,fork STDOUT
```

**Explanation:**
- `TCP-LISTEN:8080` — opens TCP port 8080 for listening  
- `fork` — handles multiple connections  
- `STDOUT` — prints received data to terminal

---

## 🍏 On Mac (Client Side)

### 🔍 Check if port is reachable
```bash
nc -vz <ubuntu-ip> 8080
```

**Example:**
```bash
nc -vz 192.168.1.10 8080
```

**Output examples:**
- ✅ `Connection to 192.168.1.10 8080 port [tcp/*] succeeded!`
- ❌ `Connection refused` or `Operation timed out`

---

### 📡 Alternative (if `telnet` is available)
```bash
telnet <ubuntu-ip> 8080
```

- Successful connection ⇒ port open  
- Connection refused / timeout ⇒ port closed or blocked

---

## 💬 Optional: Simple Chat Mode

### On Ubuntu:
```bash
sudo nc -lvnp 8080
```

### On Mac:
```bash
nc <ubuntu-ip> 8080
```

Now type messages on either side — they’ll appear on the other host.  
Press `Ctrl + C` to exit.

---

## 🧠 Notes
- Ensure the port is **not blocked by firewall** (e.g., `ufw`, `iptables`).
- Run with `sudo` if binding to ports < 1024.
- Use `ss -tuln` or `netstat -tuln` to verify listening ports.

---

### 🔍 Quick Commands Summary

| Action | Command | Description |
|--------|----------|-------------|
| Start listener | `sudo nc -lvnp 8080` | Listen on TCP port 8080 |
| Check from Mac | `nc -vz <ip> 8080` | Test connectivity |
| Chat mode | `nc <ip> 8080` | Bidirectional data exchange |
| Check open ports | `ss -tuln` | Show all listening sockets |
| Using socat | `sudo socat TCP-LISTEN:8080,fork STDOUT` | Advanced listener |

---

**Test complete ✅**
