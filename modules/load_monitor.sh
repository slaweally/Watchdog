#!/bin/bash

# Argümanlar: servis1 servis2 ... email@example.com
EMAIL="${@: -1}" # Son argüman mail
SERVICES=("${@:1:$#-1}")

for svc in "${SERVICES[@]}"; do
  svc_name=$(basename "$svc" .service)
  pid=$(pgrep -f "$svc_name")
  [[ -z "$pid" ]] && continue
  cpu=$(ps -p "$pid" -o %cpu= | awk '{sum+=$1} END {printf("%.1f",sum)}')
  mem=$(ps -p "$pid" -o %mem= | awk '{sum+=$1} END {printf("%.1f",sum)}')

  if (( $(echo "$cpu > 80" | bc -l) )); then
    echo "$(date) - $svc CPU usage high: $cpu%" >> /var/log/watchdog.log
    echo "$svc is using $cpu% CPU." | mail -s "[Watchdog] High CPU load" "$EMAIL"
  fi

  if (( $(echo "$mem > 70" | bc -l) )); then
    echo "$(date) - $svc Memory usage high: $mem%" >> /var/log/watchdog.log
    echo "$svc is using $mem% Memory." | mail -s "[Watchdog] High memory load" "$EMAIL"
  fi
done
