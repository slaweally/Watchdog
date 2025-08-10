# Watchdog v4 — Intelligent Service Monitor & Auto‑Recovery

### What it is
Watchdog monitors selected systemd services, restarts them if they stop, and can notify you (email/webhook/Telegram). It also performs lightweight system health checks (CPU, RAM, disk).

### Requirements
- Linux with systemd, bash, and curl or wget
- Optional: mailutils/sendmail (email), jq, bc

### Install & Setup (clean install)
```bash
# Download latest
curl -fsSL https://raw.githubusercontent.com/slaweally/watchdog/main/watchdog.sh -o watchdog.sh
chmod +x watchdog.sh

# Run setup wizard (choose services, notifications, interval, autostart)
./watchdog.sh

# Enable + start as a systemd service
sudo systemctl enable watchdog
sudo systemctl start watchdog

# Optional: install global command so you can run 'watchdog' from anywhere
sudo install -m 0755 watchdog.sh /usr/local/bin/watchdog
```

### Daily use
```bash
watchdog --status     # Show monitored services & system health
watchdog --test       # Send test notifications
watchdog --logs       # Analyze recent logs
watchdog --health     # One‑off system health check

# Systemd
sudo systemctl start watchdog
sudo systemctl stop watchdog
sudo systemctl status watchdog | cat
```

Notes
- The check interval (INTERVAL in minutes) applies to all monitored services.
- Categories: critical/application/standard are restarted when down; optional/on‑demand are logged only.

If you didn’t install the global command, run the same flags with the local script from its directory, e.g. `./watchdog.sh --status`.

### Update to latest
Preferred:
```bash
watchdog --update
```
Manual (in place):
```bash
sudo systemctl stop watchdog || true
curl -fsSL https://raw.githubusercontent.com/slaweally/watchdog/main/watchdog.sh -o watchdog.sh
chmod +x watchdog.sh
sudo systemctl start watchdog
```
If you encounter issues after a major upgrade, re‑run the wizard:
```bash
sudo systemctl stop watchdog
watchdog || ./watchdog.sh
sudo systemctl start watchdog
```

### Uninstall (clean removal)
```bash
# Stop & disable service
sudo systemctl stop watchdog || true
sudo systemctl disable watchdog || true

# Remove service unit
sudo rm -f /etc/systemd/system/watchdog.service
sudo systemctl daemon-reload

# Remove configuration and logs
rm -rf ~/.config/watchdog

# Remove script if placed globally
sudo rm -f /usr/local/bin/watchdog || true
```

### File locations
- Config: `~/.config/watchdog/config.conf`
- Notifications: `~/.config/watchdog/notifications.conf`
- Service type overrides: `~/.config/watchdog/service_types.conf`
- Log: `~/.config/watchdog/watchdog.log`

### Troubleshooting (quick)
- Service not restarting: ensure it’s listed under `SERVICES_APPLICATION` or `SERVICES_STANDARD` in `config.conf`.
- Too noisy logs: remove services from config or increase `INTERVAL`.
- Status loop/old config: stop service, remove `~/.config/watchdog/config.conf`, re‑run `./watchdog.sh` to regenerate.

MIT Licensed. Repo: https://github.com/slaweally/watchdog
