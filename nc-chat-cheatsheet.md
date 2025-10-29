# Chat between two Ubuntu hosts using `nc` (netcat) — GFM Cheat‑Sheet

_Last updated: 2025‑10‑29_

> This sheet assumes **netcat-openbsd** (the default on modern Ubuntu). Some flags differ on **netcat-traditional**.

---

## Quick start (one-to-one)

Pick a port (e.g., `5000`). **Host A** listens, **Host B** connects.

| Purpose | Host A (listener) | Host B (connector) |
|---|---|---|
| TCP chat | ```bash
nc -l 5000
``` | ```bash
nc <HOST_A_IP> 5000
``` |
| UDP chat | ```bash
nc -u -l 5000
``` | ```bash
nc -u <HOST_A_IP> 5000
``` |
| Keep accepting sequential clients | ```bash
nc -lk 5000
``` | _same as above_ |
| Prefer IPv6 | add `-6` | add `-6` |

Type in either terminal; text appears on the other side. **Ctrl+C** to quit.  
On OpenBSD nc, `-N` makes nc close the socket after stdin hits EOF (useful with pipes).

---

## What you’ll likely need

- **Find the server’s IP** (Host A):  
  ```bash
  hostname -I        # quick, IPv4/IPv6
  ip -4 a | grep -w inet  # detailed IPv4
  ```
- **Firewall (UFW)** on Host A:  
  ```bash
  sudo ufw allow 5000/tcp   # for TCP chat
  sudo ufw allow 5000/udp   # for UDP chat
  ```
- **Verify it’s listening** (Host A):  
  ```bash
  ss -tulpn | grep 5000
  ```

---

## Handy patterns

### 1) Quit cleanly after a line (OpenBSD nc)
Sender closes connection after sending:
```bash
printf 'bye\n' | nc -N <HOST_A_IP> 5000
```

### 2) Avoid local echo / combine read & write
If you want both **sending** and **seeing** your own lines in one window:
```bash
# on either side
mkfifo /tmp/f; cat /tmp/f | nc <PEER_IP> 5000 | tee -a chat.log > /tmp/f
# type in the same terminal; Ctrl+C to stop; rm the fifo afterwards:
rm -f /tmp/f
```

### 3) Bind a specific source address/interface
```bash
# If Host A has multiple IPs and you want nc to use one of them
nc -s <SOURCE_IP> -l 5000
```

---

## Minimal encryption (optional)

> Plain `nc` is **unencrypted**. For quick encrypted pipes use SSH or **ncat** (from Nmap).

**SSH wrapper (simple):**
```bash
# Host A (server): keep a listener bound to localhost only
nc -l 127.0.0.1 5000

# Host B (client): create a tunnel to Host A and connect locally
ssh -L 5000:127.0.0.1:5000 user@<HOST_A_IP>
# in another terminal on Host B:
nc 127.0.0.1 5000
```

**Using ncat with TLS (if installed):**
```bash
# Host A
ncat --ssl -l 5000
# Host B
ncat --ssl <HOST_A_IP> 5000
```

---

## netcat variants (Ubuntu)

- **netcat-openbsd** (default): supports `-N`, `-k`, `-u`, `-6`, etc.  
- **netcat-traditional**: some flags differ; often requires `-p` with `-l` (e.g., `nc -l -p 5000`).  
  You can switch with:
  ```bash
  sudo update-alternatives --config nc
  ```

---

## Troubleshooting checklist

- Same LAN? Can you **ping** Host A from Host B? `ping <HOST_A_IP>`
- Is the right protocol open? `tcp` vs `udp`
- Is **UFW** or another firewall blocking the port?
- Are you using the correct binary/flags for your **nc** variant?
- Try a **different port** (e.g., `5001`) to avoid conflicts.
- For UDP, remember there’s no connection state; packets can drop silently.

---

## Safety notes

- No authentication; anyone on the LAN who can reach the port can join. Prefer a random high port and close when done.
- Avoid sending secrets over plain `nc`. Use SSH tunneling or TLS (ncat) if privacy matters.

---

### Quick copy/paste (TCP)
```bash
# Host A
nc -l 5000

# Host B
nc <HOST_A_IP> 5000
```

Happy chatting! :)
