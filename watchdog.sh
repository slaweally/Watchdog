#!/bin/bash

CONFIG_FILE="$HOME/.watchdog.conf"
LOG_FILE="/var/log/watchdog.log"

init_config() {
  echo -e "\n🔍 Sistemde çalışan servisler aranıyor..."
  mapfile -t SERVICES < <(systemctl list-units --type=service --state=running | awk '{print $1}' | grep .service | sort)

  echo -e "\n🔧 İzlenecek servisleri seç:"
  for i in "${!SERVICES[@]}"; do
    echo " [$i] ${SERVICES[$i]}"
  done

  echo -ne "\n📥 Virgülle ayırarak servis numaralarını gir (örnek: 1,5,7): "
  read -r SELECTED
  SELECTED_SERVICES=()
  IFS=',' read -ra IDX <<< "$SELECTED"
  for index in "${IDX[@]}"; do
    SELECTED_SERVICES+=("${SERVICES[$index]}")
  done

  echo -ne "\n➕ Eklemek istediğin ekstra servis var mı (örn: nginx.service)? Yoksa ENTER: "
  read -r EXTRA
  if [ -n "$EXTRA" ]; then
    SELECTED_SERVICES+=("$EXTRA")
  fi

  echo -ne "\n📧 Bildirimlerin gideceği e-posta adresini gir: "
  read -r EMAIL

  INTERVAL=15
  echo -ne "\n⏱️ Kontrol sıklığı kaç dakika olsun? (Varsayılan: 15): "
  read -r CUSTOM
  [[ "$CUSTOM" =~ ^[0-9]+$ ]] && INTERVAL="$CUSTOM"

  mkdir -p "$(dirname "$CONFIG_FILE")"
  echo "${SELECTED_SERVICES[*]}" > "$CONFIG_FILE"
  echo "$EMAIL" >> "$CONFIG_FILE"
  echo "$INTERVAL" >> "$CONFIG_FILE"
  echo -e "\n✅ Ayarlar kaydedildi. İzleme başlıyor..."
}

start_watchdog() {
  mapfile -t LINES < "$CONFIG_FILE"
  IFS=' ' read -ra SERVICES <<< "${LINES[0]}"
  EMAIL="${LINES[1]}"
  INTERVAL="${LINES[2]}"

  while true; do
    for SERVICE in "${SERVICES[@]}"; do
      systemctl is-active --quiet "$SERVICE"
      if [ $? -ne 0 ]; then
        systemctl start "$SERVICE"
        MSG="[$(date)] 🚨 $SERVICE kapalıydı, yeniden başlatıldı."
        echo "$MSG" | tee -a "$LOG_FILE" | mail -s "[Watchdog] $SERVICE yeniden başlatıldı" "$EMAIL"
      fi
    done
    sleep "$((INTERVAL * 60))"
  done
}

create_service() {
  SERVICE_PATH="/etc/systemd/system/watchdog.service"
  cat <<EOF | sudo tee "$SERVICE_PATH" > /dev/null
[Unit]
Description=Linux Watchdog Servis Takibi
After=network.target

[Service]
ExecStart=$(realpath "$0") --run
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

  sudo systemctl daemon-reload
  sudo systemctl enable watchdog
  echo -e "\n📌 'watchdog.service' aktif edildi. Artık her açılışta çalışacak."
}

# Main
case "$1" in
  --run)
    start_watchdog
    ;;
  *)
    echo "🧙 İlk kurulum başlatılıyor..."
    init_config
    create_service
    echo -e "\n🚀 Betik çalışmaya hazır. Servisi başlatmak için:"
    echo "   sudo systemctl start watchdog"
    ;;
esac
