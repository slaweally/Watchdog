#!/bin/bash

# Argümanlar: email@example.com
EMAIL="$1"
LOG="/var/log/watchdog.log"

# === NGINX Trafik İzleme ===
nginx_check() {
  active=$(netstat -an | grep ':80\|:443' | grep ESTABLISHED | wc -l)
  threshold=100 # eşik

  if [ "$active" -gt "$threshold" ]; then
    echo "$(date) - ⚠️ Nginx bağlantı sayısı yüksek: $active aktif bağlantı" >> "$LOG"
    echo "Nginx active connections exceeded threshold ($active > $threshold)." | \
      mail -s "[Watchdog] High Nginx Connections" "$EMAIL"
  fi
}

# === PHP-FPM İşlem Yükü Kontrolü ===
phpfpm_check() {
  for version in 8.0 8.1 8.2 8.3 8.4; do
    service="php$version-fpm"
    count=$(pgrep -f "$service" | wc -l)
    if [ "$count" -gt 30 ]; then
      echo "$(date) - ⚠️ $service işlem sayısı yüksek: $count" >> "$LOG"
      echo "$service process count high: $count" | \
        mail -s "[Watchdog] PHP-FPM Load Warning ($service)" "$EMAIL"
    fi
  done
}

# === Çalıştır ===
nginx_check
phpfpm_check
