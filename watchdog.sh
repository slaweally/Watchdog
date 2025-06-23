#!/bin/bash

# === Versiyon & Temel Ayarlar ===
VERSION="2.0"
LANG_DIR="./lang"
CONFIG_FILE="$HOME/.watchdog.conf"
LOG_FILE="/var/log/watchdog.log"
LANGUAGE="en" # default

# === Dil Fonksiyonları ===
declare -A MSG
load_language() {
  local lang_file="$LANG_DIR/$LANGUAGE.lang"
  [ ! -f "$lang_file" ] && echo "Language file not found: $lang_file" && exit 1
  while IFS='=' read -r key value; do
    [[ $key =~ ^#.*$ || -z "$key" ]] && continue
    MSG[$key]="$value"
  done < "$lang_file"
}
get_msg() {
  echo "${MSG[$1]}"
}

# === Kullanıcı Etkileşimi ===
setup_wizard() {
  echo "============================================="
  echo "   🐾  $(get_msg "welcome_message")"
  echo "============================================="

  mapfile -t SERVICES < <(systemctl list-units --type=service --state=running | awk '{print $1}' | grep .service)
  echo -e "\n🔍 $(get_msg "found_services")"
  for i in "${!SERVICES[@]}"; do echo " [$i] ${SERVICES[$i]}"; done
  echo -ne "\n📥 $(get_msg "select_services") "
  read -r input
  IFS=',' read -ra IDX <<< "$input"
  SELECTED=()
  for i in "${IDX[@]}"; do SELECTED+=("${SERVICES[$i]}"); done
  echo -ne "\n➕ $(get_msg "extra_services") "
  read -r EXTRA
  [[ -n "$EXTRA" ]] && SELECTED+=("$EXTRA")

  echo -ne "\n📧 $(get_msg "email_prompt") "
  read -r EMAIL

  echo -ne "\n⏱️ $(get_msg "interval_prompt") "
  read -r INTERVAL
  [[ "$INTERVAL" =~ ^[0-9]+$ ]] || INTERVAL=15

  echo "${SELECTED[*]}" > "$CONFIG_FILE"
  echo "$EMAIL" >> "$CONFIG_FILE"
  echo "$INTERVAL" >> "$CONFIG_FILE"
  echo "$LANGUAGE" >> "$CONFIG_FILE"
  echo "$(get_msg "config_saved")"
}

# === Ana İzleme Döngüsü ===
start_monitoring() {
  mapfile -t LINES < "$CONFIG_FILE"
  IFS=' ' read -ra SERVICES <<< "${LINES[0]}"
  EMAIL="${LINES[1]}"
  INTERVAL="${LINES[2]}"
  LANGUAGE="${LINES[3]}"
  load_language
  echo "$(get_msg "monitoring_started")"

  while true; do
    for service in "${SERVICES[@]}"; do
      systemctl is-active --quiet "$service" || {
        systemctl start "$service"
        echo "$(date) - $service restarted" >> "$LOG_FILE"
        echo "$service has restarted" | mail -s "[Watchdog] $service" "$EMAIL"
      }
    done
    bash ./modules/load_monitor.sh "${SERVICES[@]}" "$EMAIL"
    sleep "$((INTERVAL * 60))"
  done
}

# === Başlangıç ===
if [[ "$1" == "--run" ]]; then
  LANGUAGE=$(tail -n1 "$CONFIG_FILE" 2>/dev/null || echo "en")
  load_language
  start_monitoring
else
  echo -e "🌐 Please select language:\n [1] English\n [2] Türkçe"
  read -r LANG_CHOICE
  case "$LANG_CHOICE" in
    2) LANGUAGE="tr" ;;
    *) LANGUAGE="en" ;;
  esac
  load_language
  setup_wizard

  # Servisi oluştur
  sudo tee /etc/systemd/system/watchdog.service >/dev/null <<EOF
[Unit]
Description=Watchdog Monitoring Service
After=network.target

[Service]
ExecStart=$(realpath "$0") --run
Restart=always

[Install]
WantedBy=multi-user.target
EOF

  sudo systemctl daemon-reload
  sudo systemctl enable watchdog
  echo -e "\n🚀 $(get_msg "service_ready")"
  echo "   sudo systemctl start watchdog"
fi
