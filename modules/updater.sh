#!/bin/bash

# Versiyon dosyasının bulunduğu URL
REMOTE_VERSION_URL="https://raw.githubusercontent.com/slaweally/Watchdog/main/version"
REMOTE_SCRIPT_URL="https://raw.githubusercontent.com/slaweally/Watchdog/main/watchdog.sh"
LOCAL_SCRIPT_PATH="$(realpath "$(dirname "$0")/../watchdog.sh")"
LOCAL_VERSION=$(grep VERSION= "$LOCAL_SCRIPT_PATH" | cut -d '"' -f2)

# Geçerli e-posta (konfigürasyonun son satırında)
EMAIL=$(tail -n1 "$HOME/.watchdog.conf" 2>/dev/null)

REMOTE_VERSION=$(curl -fsSL "$REMOTE_VERSION_URL")

if [[ "$REMOTE_VERSION" != "$LOCAL_VERSION" ]]; then
  echo "[Watchdog] New version available: $REMOTE_VERSION (current: $LOCAL_VERSION)"

  # Yedek al
  cp "$LOCAL_SCRIPT_PATH" "${LOCAL_SCRIPT_PATH}.bak"

  # Yeni dosyayı indir
  curl -fsSL "$REMOTE_SCRIPT_URL" -o "$LOCAL_SCRIPT_PATH"
  chmod +x "$LOCAL_SCRIPT_PATH"

  # Mail bildirimi
  echo "Watchdog updated to version $REMOTE_VERSION from $LOCAL_VERSION" | \
    mail -s "[Watchdog] Auto-Update Performed" "$EMAIL"

  # Servisi yeniden başlat
  systemctl restart watchdog
else
  echo "[Watchdog] Version is current ($LOCAL_VERSION)"
fi
