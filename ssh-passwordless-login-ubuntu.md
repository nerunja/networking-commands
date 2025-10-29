# Enable Password‑less SSH Login to Ubuntu (GFM Guide)
_Last updated: 2025-10-29_

This guide shows how to enable password‑less SSH login from your **client** (macOS/Linux/Windows with OpenSSH) to an **Ubuntu server** using SSH keys.

---

## ✅ Quick Checklist
- [ ] Generate an SSH key on the **client**
- [ ] Install your **public key** on the **server**
- [ ] Test key‑based login
- [ ] (Optional) Set up `ssh-agent`
- [ ] (Recommended) Disable password auth on the server **after** keys work
- [ ] (If needed) Open the firewall for SSH

---

## 1) Generate a key on the **client**
Use Ed25519 unless you specifically need RSA for legacy systems.

```bash
# macOS / Linux / WSL / Windows PowerShell (OpenSSH)
ssh-keygen -t ed25519 -C "$USER@$(hostname) $(date -I)"
```

> **Passphrase?**> • Leave empty for truly no prompts (less secure), **or**> • Set a passphrase and use `ssh-agent` so you only type it once per session (recommended).

---

## 2) Copy the public key to the **server**
### Option A — Easiest (has `ssh-copy-id`)
```bash
ssh-copy-id -i ~/.ssh/id_ed25519.pub username@server_or_ip
```

### Option B — Without `ssh-copy-id`
**Windows PowerShell:**
```powershell
type $env:USERPROFILE\.ssh\id_ed25519.pub | ssh username@server_or_ip "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys"
```

**Linux/macOS:**
```bash
cat ~/.ssh/id_ed25519.pub | ssh username@server_or_ip "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys"
```

---

## 3) Test key login
```bash
ssh -i ~/.ssh/id_ed25519 username@server_or_ip
```

If you set a passphrase, you’ll be asked for it once.

---

## 4) Use an SSH agent (quality of life)
Add your key to the agent so you don’t retype the passphrase.

**Linux/macOS:**
```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

**Windows PowerShell:**
```powershell
Start-Service ssh-agent
Get-Service ssh-agent  # confirm it's running
ssh-add $env:USERPROFILE\.ssh\id_ed25519
```

---

## 5) (Recommended) Disable password auth on the server
Do this **only after** key login works. Keep your existing SSH session open while making changes.

Edit `/etc/ssh/sshd_config`:
```bash
sudo nano /etc/ssh/sshd_config
```

Ensure these lines (uncomment or add):
```conf
PubkeyAuthentication yes
PasswordAuthentication no
KbdInteractiveAuthentication no
ChallengeResponseAuthentication no
PermitRootLogin no           # or 'prohibit-password' if you need root with a key
# Optional hardening:
# AllowUsers yourusername
```

Reload SSH:
```bash
sudo systemctl reload ssh   # (Ubuntu service name is 'ssh')
```

---

## 6) Firewall (UFW)
```bash
sudo ufw allow OpenSSH
sudo ufw status
```

---

## 7) Troubleshooting
**Permissions (very common):**
```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
chown -R $USER:$USER ~/.ssh
chmod go-w ~
```

**Client‑side debug:**
```bash
ssh -vvv username@server_or_ip
```

**Server logs (Ubuntu):**
```bash
sudo journalctl -u ssh -e
```

If you see *“Permission denied (publickey)”*, double‑check ownership and modes above and verify the right public key is in `~/.ssh/authorized_keys`.

---

## 8) Optional: Client convenience config
Create `~/.ssh/config` on your **client**:
```sshconfig
Host mybox
  HostName server_or_ip
  User username
  IdentityFile ~/.ssh/id_ed25519
  IdentitiesOnly yes
```

Then connect with:
```bash
ssh mybox
```

---

## Notes
- **Key type:** Ed25519 is modern and compact. Use RSA only for legacy systems that lack Ed25519 support.
- **Passphrase:** Improves security. Pair with `ssh-agent` for convenience.
- **Multiple keys:** You can have several keys; use per‑host `IdentityFile` entries in `~/.ssh/config`.
- **Windows tip:** Newer Windows 10/11 include OpenSSH client and agent by default.

---

## Copy‑Paste Summary
```bash
# 1) Generate a key
ssh-keygen -t ed25519 -C "$USER@$(hostname) $(date -I)"

# 2) Install public key on server (Linux/macOS)
cat ~/.ssh/id_ed25519.pub | ssh username@server_or_ip "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys"

# 3) Test
ssh -i ~/.ssh/id_ed25519 username@server_or_ip

# 4) Agent (optional)
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

---

**That’s it!** You now have password‑less (key‑based) SSH into your Ubuntu server.
