#!/bin/bash
# ==================================================================================
# 🐕 WATCHDOG v4.0 - Intelligent Service Monitor & Auto-Recovery System
# ==================================================================================
# Universal Linux service monitoring with smart socket-activation support
# 
# Features:
# ✅ Socket-activated service support (snapd, packagekit, etc.)
# ✅ Multi-tier service classification
# ✅ Advanced notification system (Email, Webhook, Telegram)
# ✅ Auto-update from GitHub
# ✅ System health monitoring
# ✅ Intelligent restart policies
# ✅ Multi-language support
# ✅ Comprehensive logging and analytics
#
# Author: Slaweally
# GitHub: https://github.com/slaweally/Watchdog/
# License: MIT
# ==================================================================================

VERSION="4.0.0"
SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_PATH="$SCRIPT_DIR/$SCRIPT_NAME"

# ==================================================================================
# 🔧 CONFIGURATION PATHS
# ==================================================================================
CONFIG_DIR="$HOME/.config/watchdog"
CONFIG_FILE="$CONFIG_DIR/config.conf"
NOTIFICATION_CONFIG="$CONFIG_DIR/notifications.conf"
SERVICE_TYPES_CONFIG="$CONFIG_DIR/service_types.conf"
LOG_FILE="$CONFIG_DIR/watchdog.log"
PID_FILE="$CONFIG_DIR/watchdog.pid"
LANG_DIR="$CONFIG_DIR/lang"
UPDATE_CHECK_FILE="$CONFIG_DIR/.last_update_check"

# ==================================================================================
# 🌐 GITHUB INTEGRATION
# ==================================================================================
GITHUB_REPO="slaweally/Watchdog/"
GITHUB_API="https://api.github.com/repos/$GITHUB_REPO"
GITHUB_RAW="https://raw.githubusercontent.com/$GITHUB_REPO/main"
UPDATE_CHECK_INTERVAL=86400  # 24 hours

# ==================================================================================
# 🎨 COLOR SCHEMES
# ==================================================================================
declare -A COLORS=(
    [RED]='\033[0;31m'
    [GREEN]='\033[0;32m'
    [YELLOW]='\033[1;33m'
    [BLUE]='\033[0;34m'
    [PURPLE]='\033[0;35m'
    [CYAN]='\033[0;36m'
    [WHITE]='\033[1;37m'
    [GRAY]='\033[0;37m'
    [BOLD]='\033[1m'
    [DIM]='\033[2m'
    [NC]='\033[0m'
)

# ==================================================================================
# 📊 SERVICE CLASSIFICATION SYSTEM
# ==================================================================================
declare -A DEFAULT_SERVICE_TYPES=(
    # Critical Services - Must always be running
    ["ssh.service"]="critical"
    ["sshd.service"]="critical"
    ["systemd-networkd.service"]="critical"
    ["systemd-resolved.service"]="critical"
    ["cron.service"]="critical"
    ["crond.service"]="critical"
    ["rsyslog.service"]="critical"
    ["systemd-journald.service"]="critical"
    
    # Socket-Activated Services - Normal to be inactive when idle
    ["snapd.service"]="socket-activated"
    ["packagekit.service"]="socket-activated"
    ["accounts-daemon.service"]="socket-activated"
    ["udisks2.service"]="socket-activated"
    ["polkit.service"]="socket-activated"
    ["systemd-hostnamed.service"]="socket-activated"
    ["systemd-localed.service"]="socket-activated"
    ["systemd-timedated.service"]="socket-activated"
    
    # On-Demand Services - Started when needed
    ["systemd-tmpfiles-clean.service"]="on-demand"
    ["apt-daily.service"]="on-demand"
    ["apt-daily-upgrade.service"]="on-demand"
    ["man-db.service"]="on-demand"
    ["dpkg-db-backup.service"]="on-demand"
    
    # Application Services - User applications
    ["apache2.service"]="application"
    ["nginx.service"]="application"
    ["mysql.service"]="application"
    ["mariadb.service"]="application"
    ["postgresql.service"]="application"
    ["redis.service"]="application"
    ["mongodb.service"]="application"
    ["docker.service"]="application"
    ["containerd.service"]="application"
    
    # Optional Services - Nice to have but not critical
    ["bluetooth.service"]="optional"
    ["cups.service"]="optional"
    ["avahi-daemon.service"]="optional"
    ["NetworkManager.service"]="optional"
)

# ==================================================================================
# 🌍 INTERNATIONALIZATION SYSTEM
# ==================================================================================
declare -A MESSAGES
LANGUAGE="en"

init_i18n() {
    mkdir -p "$LANG_DIR"
    
    # English (Default)
    cat > "$LANG_DIR/en.json" << 'EOF'
{
    "welcome": "Welcome to Watchdog v4.0 Setup",
    "language_select": "Select your language",
    "service_discovery": "Discovering system services",
    "service_classification": "Classifying services by type",
    "found_services": "Found %d services",
    "critical_services": "Critical Services (always monitored)",
    "application_services": "Application Services",
    "socket_services": "Socket-Activated Services",
    "optional_services": "Optional Services",
    "select_services": "Select services to monitor",
    "notification_setup": "Notification Setup",
    "email_prompt": "Email address for notifications",
    "webhook_prompt": "Discord/Slack webhook URL",
    "telegram_setup": "Telegram notification setup",
    "interval_prompt": "Monitoring interval (minutes)",
    "config_saved": "Configuration saved successfully",
    "service_started": "Watchdog service started",
    "service_stopped": "Watchdog service stopped",
    "update_available": "Update available: v%s",
    "update_installing": "Installing update",
    "update_complete": "Update completed successfully",
    "monitoring_active": "Monitoring %d services",
    "service_healthy": "Service %s is healthy",
    "service_restarted": "Service %s restarted",
    "service_failed": "Service %s failed to restart",
    "socket_healthy": "Socket %s is active",
    "socket_restarted": "Socket %s restarted",
    "system_health_ok": "System health: OK",
    "high_load": "High system load detected",
    "high_memory": "High memory usage detected",
    "high_disk": "High disk usage detected"
}
EOF

    # Turkish
    cat > "$LANG_DIR/tr.json" << 'EOF'
{
    "welcome": "Watchdog v4.0 Kurulumuna Hoş Geldiniz",
    "language_select": "Dilinizi seçin",
    "service_discovery": "Sistem servisleri keşfediliyor",
    "service_classification": "Servisler türlerine göre sınıflandırılıyor",
    "found_services": "%d servis bulundu",
    "critical_services": "Kritik Servisler (her zaman izlenir)",
    "application_services": "Uygulama Servisleri",
    "socket_services": "Socket-Aktif Servisler",
    "optional_services": "Opsiyonel Servisler",
    "select_services": "İzlenecek servisleri seçin",
    "notification_setup": "Bildirim Kurulumu",
    "email_prompt": "Bildirimler için e-posta adresi",
    "webhook_prompt": "Discord/Slack webhook URL'si",
    "telegram_setup": "Telegram bildirim kurulumu",
    "interval_prompt": "İzleme aralığı (dakika)",
    "config_saved": "Yapılandırma başarıyla kaydedildi",
    "service_started": "Watchdog servisi başlatıldı",
    "service_stopped": "Watchdog servisi durduruldu",
    "update_available": "Güncelleme mevcut: v%s",
    "update_installing": "Güncelleme yükleniyor",
    "update_complete": "Güncelleme başarıyla tamamlandı",
    "monitoring_active": "%d servis izleniyor",
    "service_healthy": "Servis %s sağlıklı",
    "service_restarted": "Servis %s yeniden başlatıldı",
    "service_failed": "Servis %s yeniden başlatılamadı",
    "socket_healthy": "Socket %s aktif",
    "socket_restarted": "Socket %s yeniden başlatıldı",
    "system_health_ok": "Sistem sağlığı: İYİ",
    "high_load": "Yüksek sistem yükü tespit edildi",
    "high_memory": "Yüksek bellek kullanımı tespit edildi",
    "high_disk": "Yüksek disk kullanımı tespit edildi"
}
EOF

    load_language "$LANGUAGE"
}

load_language() {
    local lang="${1:-en}"
    local lang_file="$LANG_DIR/$lang.json"
    
    MESSAGES=()
    if [[ -f "$lang_file" ]] && command -v jq >/dev/null 2>&1; then
        while IFS='=' read -r key value; do
            MESSAGES["$key"]="$value"
        done < <(jq -r 'to_entries[] | "\(.key)=\(.value)"' "$lang_file" 2>/dev/null)
    fi
}

msg() {
    local key="$1"
    local text="${MESSAGES[$key]:-$key}"
    shift
    printf "$text" "$@"
}

# ==================================================================================
# 🖼️ UI COMPONENTS
# ==================================================================================
show_header() {
    clear
    echo -e "${COLORS[CYAN]}${COLORS[BOLD]}"
    cat << 'EOF'
 ██╗    ██╗ █████╗ ████████╗ ██████╗██╗  ██╗██████╗  ██████╗  ██████╗     ██╗  ██╗ ██████╗ 
 ██║    ██║██╔══██╗╚══██╔══╝██╔════╝██║  ██║██╔══██╗██╔═══██╗██╔════╝     ██║  ██║██╔═████╗
 ██║ █╗ ██║███████║   ██║   ██║     ███████║██║  ██║██║   ██║██║  ███╗    ██║  ██║██║██╔██║
 ██║███╗██║██╔══██║   ██║   ██║     ██╔══██║██║  ██║██║   ██║██║   ██║    ╚██╗██╔╝████╔╝██║
 ╚███╔███╔╝██║  ██║   ██║   ╚██████╗██║  ██║██████╔╝╚██████╔╝╚██████╔╝     ╚███╔╝ ╚██████╔╝
  ╚══╝╚══╝ ╚═╝  ╚═╝   ╚═╝    ╚═════╝╚═╝  ╚═╝╚═════╝  ╚═════╝  ╚═════╝       ╚══╝   ╚═════╝ 
EOF
    echo -e "${COLORS[NC]}"
    echo -e "${COLORS[WHITE]}${COLORS[BOLD]}🐕 Intelligent Service Monitor & Auto-Recovery System v$VERSION${COLORS[NC]}"
    echo -e "${COLORS[BLUE]}═══════════════════════════════════════════════════════════════════════════════════════${COLORS[NC]}"
    echo
}

print_status() {
    local level="$1"
    local message="$2"
    local timestamp="$(date '+%H:%M:%S')"
    
    case "$level" in
        "success") echo -e "${COLORS[GREEN]}✅ [$timestamp] $message${COLORS[NC]}" ;;
        "error")   echo -e "${COLORS[RED]}❌ [$timestamp] $message${COLORS[NC]}" ;;
        "warning") echo -e "${COLORS[YELLOW]}⚠️  [$timestamp] $message${COLORS[NC]}" ;;
        "info")    echo -e "${COLORS[BLUE]}ℹ️  [$timestamp] $message${COLORS[NC]}" ;;
        "debug")   echo -e "${COLORS[GRAY]}🔍 [$timestamp] $message${COLORS[NC]}" ;;
        "update")  echo -e "${COLORS[PURPLE]}🔄 [$timestamp] $message${COLORS[NC]}" ;;
        *)         echo -e "${COLORS[WHITE]}📝 [$timestamp] $message${COLORS[NC]}" ;;
    esac
}

show_progress_bar() {
    local current=$1
    local total=$2
    local width=50
    local percentage=$((current * 100 / total))
    local completed=$((current * width / total))
    
    printf "\r${COLORS[CYAN]}["
    printf "%${completed}s" | tr ' ' '█'
    printf "%$((width - completed))s" | tr ' ' '░'
    printf "] %d%% (%d/%d)${COLORS[NC]}" "$percentage" "$current" "$total"
    
    [[ $current -eq $total ]] && echo
}

# ==================================================================================
# 📝 LOGGING SYSTEM
# ==================================================================================
log_message() {
    local level="$1"
    local message="$2"
    local timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    local pid="$$"
    
    echo "[$timestamp] [$pid] [$level] $message" >> "$LOG_FILE"
    
    # Rotate logs if too large (10MB)
    if [[ -f "$LOG_FILE" ]] && [[ $(stat -c%s "$LOG_FILE" 2>/dev/null) -gt 10485760 ]]; then
        tail -n 1000 "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"
        log_message "INFO" "Log file rotated"
    fi
}

# ==================================================================================
# 🔄 PID MANAGEMENT
# ==================================================================================
create_pid_file() {
    mkdir -p "$(dirname "$PID_FILE")"
    echo $$ > "$PID_FILE"
    log_message "INFO" "Watchdog started with PID: $$"
}

remove_pid_file() {
    [[ -f "$PID_FILE" ]] && rm -f "$PID_FILE"
    log_message "INFO" "Watchdog stopped, PID file removed"
}

is_watchdog_running() {
    if [[ -f "$PID_FILE" ]]; then
        local pid=$(cat "$PID_FILE" 2>/dev/null)
        if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
            return 0
        else
            rm -f "$PID_FILE"
            return 1
        fi
    fi
    return 1
}

# ==================================================================================
# 🔍 SERVICE DISCOVERY & CLASSIFICATION
# ==================================================================================
discover_services() {
    # Get all running services
    local services=()
    mapfile -t services < <(systemctl list-units --type=service --state=running --no-pager --no-legend 2>/dev/null | \
        awk '{print $1}' | grep -E '\.service$' | sort)
    
    # Get enabled but not running services
    local enabled_services=()
    mapfile -t enabled_services < <(systemctl list-unit-files --type=service --state=enabled --no-pager --no-legend 2>/dev/null | \
        awk '{print $1}' | grep -E '\.service$' | sort)
    
    # Combine and deduplicate
    local all_services=()
    for service in "${services[@]}" "${enabled_services[@]}"; do
        if [[ ! " ${all_services[*]} " =~ " ${service} " ]]; then
            all_services+=("$service")
        fi
    done
    
    echo "${all_services[@]}"
}

classify_service() {
    local service="$1"
    
    # Check custom classification first
    if [[ -f "$SERVICE_TYPES_CONFIG" ]]; then
        local custom_type=$(grep "^$service=" "$SERVICE_TYPES_CONFIG" 2>/dev/null | cut -d'=' -f2)
        if [[ -n "$custom_type" ]]; then
            echo "$custom_type"
            return 0
        fi
    fi
    
    # Check default classification
    if [[ -n "${DEFAULT_SERVICE_TYPES[$service]}" ]]; then
        echo "${DEFAULT_SERVICE_TYPES[$service]}"
        return 0
    fi
    
    # Auto-detect service type
    local service_file="/etc/systemd/system/$service"
    [[ ! -f "$service_file" ]] && service_file="/usr/lib/systemd/system/$service"
    [[ ! -f "$service_file" ]] && service_file="/lib/systemd/system/$service"
    
    if [[ -f "$service_file" ]]; then
        # Socket activation detection
        if grep -q "TriggeredBy=.*\.socket" "$service_file" 2>/dev/null || \
           systemctl list-dependencies "$service" 2>/dev/null | grep -q "\.socket"; then
            echo "socket-activated"
            return 0
        fi
        
        # Oneshot detection
        if grep -q "Type=oneshot" "$service_file" 2>/dev/null; then
            echo "on-demand"
            return 0
        fi
        
        # Static services
        local enabled_status=$(systemctl is-enabled "$service" 2>/dev/null)
        if [[ "$enabled_status" == "static" ]]; then
            echo "on-demand"
            return 0
        fi
    fi
    
    # Default classification
    echo "standard"
}

categorize_all_services() {
    local -n services_ref=$1
    declare -A categorized=(
        ["critical"]=""
        ["application"]=""
        ["socket-activated"]=""
        ["on-demand"]=""
        ["optional"]=""
        ["standard"]=""
    )
    
    print_status "info" "$(msg "service_classification")"
    local count=0
    local total=${#services_ref[@]}
    
    for service in "${services_ref[@]}"; do
        local category=$(classify_service "$service")
        categorized["$category"]+="$service "
        ((count++))
        show_progress_bar "$count" "$total"
    done
    
    # Return categorized services
    for category in critical application socket-activated on-demand optional standard; do
        if [[ -n "${categorized[$category]}" ]]; then
            echo "$category:${categorized[$category]}"
        fi
    done
}

# ==================================================================================
# 🔧 SERVICE HEALTH MONITORING
# ==================================================================================
check_critical_service() {
    local service="$1"
    
    if ! systemctl is-active --quiet "$service" 2>/dev/null; then
        log_message "ERROR" "Critical service $service is down"
        print_status "error" "Critical service $service is down, restarting..."
        
        if systemctl start "$service" 2>/dev/null; then
            log_message "INFO" "Critical service $service restarted successfully"
            print_status "success" "$(msg "service_restarted" "$service")"
            send_notification "$service" "restarted" "critical"
            return 0
        else
            log_message "ERROR" "Failed to restart critical service $service"
            print_status "error" "$(msg "service_failed" "$service")"
            send_notification "$service" "failed" "critical"
            return 1
        fi
    fi
    
    log_message "DEBUG" "Critical service $service is healthy"
    return 0
}

check_socket_activated_service() {
    local service="$1"
    local socket_name="${service%.*}.socket"
    local socket_status=$(systemctl is-active "$socket_name" 2>/dev/null)
    local service_status=$(systemctl is-active "$service" 2>/dev/null)
    
    # Check if socket exists
    if ! systemctl list-units --all "$socket_name" &>/dev/null; then
        log_message "DEBUG" "No socket found for $service, treating as standard service"
        check_standard_service "$service"
        return $?
    fi
    
    # Socket should be active
    if [[ "$socket_status" == "active" ]]; then
        if [[ "$service_status" == "inactive" ]]; then
            log_message "DEBUG" "Socket-activated service $service is dormant (normal)"
            return 0
        elif [[ "$service_status" == "active" ]]; then
            log_message "DEBUG" "Socket-activated service $service is currently active"
            return 0
        fi
    else
        log_message "WARNING" "Socket $socket_name is not active for $service"
        print_status "warning" "Socket $socket_name is down, restarting..."
        
        if systemctl start "$socket_name" 2>/dev/null; then
            log_message "INFO" "Socket $socket_name restarted successfully"
            print_status "success" "$(msg "socket_restarted" "$socket_name")"
            send_notification "$socket_name" "socket restarted" "socket"
            return 0
        else
            log_message "ERROR" "Failed to restart socket $socket_name"
            print_status "error" "Failed to restart socket $socket_name"
            send_notification "$socket_name" "socket failed" "socket"
            return 1
        fi
    fi
    
    # Check for abnormal exit status
    local exit_status=$(systemctl show "$service" --property=ExecMainStatus --value 2>/dev/null)
    if [[ -n "$exit_status" && "$exit_status" != "0" && "$exit_status" != "42" ]]; then
        log_message "WARNING" "Socket-activated service $service last exit: $exit_status"
        
        # Check recent errors
        local recent_errors=$(journalctl -u "$service" --since "10 minutes ago" -p err --no-pager -q 2>/dev/null)
        if [[ -n "$recent_errors" ]]; then
            log_message "ERROR" "Recent errors in $service: $recent_errors"
            send_notification "$service" "has errors" "socket"
            return 1
        fi
    fi
    
    return 0
}

check_application_service() {
    local service="$1"
    
    if ! systemctl is-active --quiet "$service" 2>/dev/null; then
        log_message "WARNING" "Application service $service is down"
        print_status "warning" "Application service $service is down, restarting..."
        
        if systemctl start "$service" 2>/dev/null; then
            log_message "INFO" "Application service $service restarted successfully"
            print_status "success" "$(msg "service_restarted" "$service")"
            send_notification "$service" "restarted" "application"
            return 0
        else
            log_message "ERROR" "Failed to restart application service $service"
            print_status "error" "$(msg "service_failed" "$service")"
            send_notification "$service" "failed" "application"
            return 1
        fi
    fi
    
    log_message "DEBUG" "Application service $service is healthy"
    return 0
}

check_on_demand_service() {
    local service="$1"
    local service_status=$(systemctl is-active "$service" 2>/dev/null)
    
    # On-demand services being inactive is normal
    if [[ "$service_status" == "inactive" ]]; then
        local last_exit=$(systemctl show "$service" --property=ExecMainStatus --value 2>/dev/null)
        if [[ "$last_exit" == "0" || -z "$last_exit" ]]; then
            log_message "DEBUG" "On-demand service $service is dormant (normal)"
            return 0
        else
            log_message "WARNING" "On-demand service $service last run failed (exit: $last_exit)"
            return 1
        fi
    elif [[ "$service_status" == "active" ]]; then
        log_message "DEBUG" "On-demand service $service is currently running"
        return 0
    else
        log_message "WARNING" "On-demand service $service status: $service_status"
        return 1
    fi
}

check_optional_service() {
    local service="$1"
    
    # Optional services - only log if they fail, don't restart
    if ! systemctl is-active --quiet "$service" 2>/dev/null; then
        local failed_status=$(systemctl is-failed "$service" 2>/dev/null)
        if [[ "$failed_status" == "failed" ]]; then
            log_message "WARNING" "Optional service $service is in failed state"
            return 1
        else
            log_message "DEBUG" "Optional service $service is inactive (normal)"
            return 0
        fi
    fi
    
    log_message "DEBUG" "Optional service $service is running"
    return 0
}

check_standard_service() {
    local service="$1"
    
    if ! systemctl is-active --quiet "$service" 2>/dev/null; then
        log_message "ERROR" "Standard service $service is down"
        print_status "warning" "Standard service $service is down, restarting..."
        
        if systemctl start "$service" 2>/dev/null; then
            log_message "INFO" "Standard service $service restarted successfully"
            print_status "success" "$(msg "service_restarted" "$service")"
            send_notification "$service" "restarted" "standard"
            return 0
        else
            log_message "ERROR" "Failed to restart standard service $service"
            print_status "error" "$(msg "service_failed" "$service")"
            send_notification "$service" "failed" "standard"
            return 1
        fi
    fi
    
    log_message "DEBUG" "Standard service $service is healthy"
    return 0
}

check_service_health() {
    local service="$1"
    local service_type="$2"
    
    case "$service_type" in
        "critical")
            check_critical_service "$service"
            ;;
        "socket-activated")
            check_socket_activated_service "$service"
            ;;
        "application")
            check_application_service "$service"
            ;;
        "on-demand")
            check_on_demand_service "$service"
            ;;
        "optional")
            check_optional_service "$service"
            ;;
        *)
            check_standard_service "$service"
            ;;
    esac
}

# ==================================================================================
# 📱 NOTIFICATION SYSTEM
# ==================================================================================
send_email_notification() {
    local subject="$1"
    local message="$2"
    local email="$3"
    local priority="$4"
    
    [[ -z "$email" ]] && return 1
    
    # Add priority indicator to subject
    case "$priority" in
        "critical") subject="🚨 CRITICAL: $subject" ;;
        "application") subject="⚠️ APPLICATION: $subject" ;;
        "socket") subject="🔌 SOCKET: $subject" ;;
        *) subject="ℹ️ INFO: $subject" ;;
    esac
    
    if command -v sendmail >/dev/null; then
        local priority_num="3"
        case "$priority" in
            "critical") priority_num="1" ;;
        esac
        {
            echo "To: $email"
            echo "Subject: $subject"
            echo "From: watchdog@$(hostname)"
            echo "X-Priority: $priority_num"
            echo "Content-Type: text/html; charset=UTF-8"
            echo ""
            echo "<h3>$subject</h3>"
            echo "<p><strong>Hostname:</strong> $(hostname)</p>"
            echo "<p><strong>Time:</strong> $(date)</p>"
            echo "<p><strong>Message:</strong> $message</p>"
            echo "<hr>"
            echo "<small>Generated by Watchdog v$VERSION</small>"
        } | sendmail "$email" 2>/dev/null
    elif command -v mail >/dev/null; then
        echo "$message" | mail -s "$subject" "$email" 2>/dev/null
    else
        return 1
    fi
}

send_webhook_notification() {
    local message="$1"
    local webhook_url="$2"
    local priority="$3"
    
    [[ -z "$webhook_url" ]] && return 1
    
    local color=""
    local emoji=""
    case "$priority" in
        "critical") color="15158332"; emoji="🚨" ;;  # Red
        "application") color="16776960"; emoji="⚠️" ;;  # Yellow
        "socket") color="3447003"; emoji="🔌" ;;     # Blue
        *) color="8947848"; emoji="ℹ️" ;;            # Gray
    esac
    
    local payload
    payload=$(cat << EOF
{
    "embeds": [{
        "title": "$emoji Watchdog Alert",
        "description": "$message",
        "color": $color,
        "fields": [
            {
                "name": "Hostname",
                "value": "$(hostname)",
                "inline": true
            },
            {
                "name": "Time",
                "value": "$(date)",
                "inline": true
            },
            {
                "name": "Priority",
                "value": "$priority",
                "inline": true
            }
        ],
        "footer": {
            "text": "Watchdog v$VERSION"
        }
    }]
}
EOF
)
    
    if command -v curl >/dev/null; then
        curl -s -X POST "$webhook_url" \
            -H "Content-Type: application/json" \
            -d "$payload" >/dev/null 2>&1
    fi
}

send_telegram_notification() {
    local message="$1"
    local bot_token="$2"
    local chat_id="$3"
    local priority="$4"
    
    [[ -z "$bot_token" || -z "$chat_id" ]] && return 1
    
    local emoji=""
    case "$priority" in
        "critical") emoji="🚨" ;;
        "application") emoji="⚠️" ;;
        "socket") emoji="🔌" ;;
        *) emoji="ℹ️" ;;
    esac
    
    local formatted_message="$emoji *Watchdog Alert*

*Service:* $message
*Hostname:* $(hostname)
*Time:* $(date)
*Priority:* $priority

_Generated by Watchdog v$VERSION_"
    
    if command -v curl >/dev/null; then
        curl -s -X POST \
            "https://api.telegram.org/bot$bot_token/sendMessage" \
            -d "chat_id=$chat_id" \
            -d "text=$formatted_message" \
            -d "parse_mode=Markdown" \
            >/dev/null 2>&1
    fi
}

send_notification() {
    local service="$1"
    local action="$2"
    local priority="${3:-standard}"
    local timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    local hostname="$(hostname)"
    local message="Service '$service' $action on $hostname at $timestamp"
    
    # Always log
    log_message "ALERT" "$message"
    
    # Load notification config
    [[ -f "$CONFIG_FILE" ]] && source "$CONFIG_FILE"
    [[ -f "$NOTIFICATION_CONFIG" ]] && source "$NOTIFICATION_CONFIG"
    
    # Send notifications based on priority and configuration
    if [[ "$priority" == "critical" || "$NOTIFICATION_LEVEL" == "all" ]]; then
        [[ -n "$EMAIL" ]] && send_email_notification "$service $action" "$message" "$EMAIL" "$priority"
        [[ -n "$WEBHOOK_URL" ]] && send_webhook_notification "$message" "$WEBHOOK_URL" "$priority"
        [[ -n "$TELEGRAM_BOT_TOKEN" && -n "$TELEGRAM_CHAT_ID" ]] && \
            send_telegram_notification "$message" "$TELEGRAM_BOT_TOKEN" "$TELEGRAM_CHAT_ID" "$priority"
    fi
    
    # System journal
    command -v systemd-cat >/dev/null && \
        echo "WATCHDOG_ALERT: $message" | systemd-cat -t watchdog -p warning
}

# ==================================================================================
# 📊 SYSTEM HEALTH MONITORING
# ==================================================================================
check_system_health() {
    local issues=()
    
    # CPU Load Average
    local load_avg=$(uptime | awk -F'load average:' '{print $2}' | cut -d',' -f1 | tr -d ' ')
    if command -v bc >/dev/null && (( $(echo "$load_avg > 10.0" | bc -l 2>/dev/null) )); then
        issues+=("High CPU load: $load_avg")
        log_message "WARNING" "High system load detected: $load_avg"
    fi
    
    # Memory Usage
    local mem_usage=$(free | awk 'NR==2{printf "%.1f", $3*100/$2}')
    if (( $(echo "$mem_usage > 90.0" | bc -l 2>/dev/null || echo 0) )); then
        issues+=("High memory usage: ${mem_usage}%")
        log_message "WARNING" "High memory usage detected: ${mem_usage}%"
    fi
    
    # Disk Usage
    local disk_usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    if [[ "$disk_usage" -gt 90 ]]; then
        issues+=("High disk usage: ${disk_usage}%")
        log_message "WARNING" "High disk usage detected: ${disk_usage}%"
    fi
    
    # Failed systemd units
    local failed_units=$(systemctl list-units --state=failed --no-pager --no-legend 2>/dev/null | wc -l)
    if [[ $failed_units -gt 0 ]]; then
        issues+=("$failed_units failed systemd units")
        log_message "WARNING" "$failed_units systemd units in failed state"
    fi
    
    # Journal size
    if command -v journalctl >/dev/null; then
        local journal_size=$(journalctl --disk-usage 2>/dev/null | awk '{print $7}' | sed 's/[^0-9.]//g')
        if [[ -n "$journal_size" ]] && (( $(echo "$journal_size > 1000" | bc -l 2>/dev/null || echo 0) )); then
            issues+=("Large journal size: ${journal_size}MB")
            log_message "INFO" "Large journal size detected: ${journal_size}MB"
        fi
    fi
    
    # Send alerts for critical issues
    if [[ ${#issues[@]} -gt 0 ]]; then
        for issue in "${issues[@]}"; do
            if [[ "$issue" =~ ^High ]]; then
                send_notification "system" "$issue" "critical"
            fi
        done
        return 1
    fi
    
    log_message "DEBUG" "System health check: OK"
    return 0
}

# ==================================================================================
# 🔄 AUTO-UPDATE SYSTEM
# ==================================================================================
check_for_updates() {
    local force_check="$1"
    local now=$(date +%s)
    local last_check=0
    
    # Check if update check is needed
    if [[ -f "$UPDATE_CHECK_FILE" && "$force_check" != "force" ]]; then
        last_check=$(cat "$UPDATE_CHECK_FILE" 2>/dev/null || echo 0)
        if [[ $((now - last_check)) -lt $UPDATE_CHECK_INTERVAL ]]; then
            return 0
        fi
    fi
    
    print_status "update" "Checking for updates..."
    
    # Get latest version from GitHub
    local latest_version
    if command -v curl >/dev/null; then
        latest_version=$(curl -s "$GITHUB_API/releases/latest" 2>/dev/null | \
            grep '"tag_name"' | cut -d'"' -f4 | sed 's/^v//')
    elif command -v wget >/dev/null; then
        latest_version=$(wget -qO- "$GITHUB_API/releases/latest" 2>/dev/null | \
            grep '"tag_name"' | cut -d'"' -f4 | sed 's/^v//')
    else
        print_status "warning" "curl or wget not found, cannot check for updates"
        return 1
    fi
    
    # Update last check time
    echo "$now" > "$UPDATE_CHECK_FILE"
    
    if [[ -z "$latest_version" ]]; then
        print_status "warning" "Could not retrieve version information from GitHub"
        return 1
    fi
    
    # Version comparison
    if version_gt "$latest_version" "$VERSION"; then
        print_status "update" "$(msg "update_available" "$latest_version")"
        log_message "INFO" "New version available: v$latest_version (current: v$VERSION)"
        
        if [[ "$force_check" == "force" ]]; then
            echo -n "Would you like to update now? [y/N]: "
            read -r update_choice
            if [[ "$update_choice" =~ ^[Yy] ]]; then
                upgrade_watchdog "$latest_version"
            fi
        else
            # Auto-update if enabled
            source "$CONFIG_FILE" 2>/dev/null
            if [[ "$AUTO_UPDATE" == "true" ]]; then
                log_message "INFO" "Auto-updating to v$latest_version"
                upgrade_watchdog "$latest_version"
            fi
        fi
    else
        print_status "success" "Watchdog is up to date (v$VERSION)"
    fi
}

version_gt() {
    # Return success (0) if $1 > $2, otherwise non-zero
    local a="$1" b="$2"
    if [[ "$a" == "$b" ]]; then
        return 1
    fi
    local first
    first=$(printf '%s\n%s\n' "$a" "$b" | sort -V | head -n1)
    if [[ "$first" == "$b" ]]; then
        return 0
    fi
    return 1
}

upgrade_watchdog() {
    local target_version="$1"
    local backup_file="${SCRIPT_PATH}.backup-$(date +%F-%H%M%S)"
    local temp_file="/tmp/watchdog_new_$$.sh"
    
    print_status "update" "$(msg "update_installing")"
    log_message "INFO" "Starting upgrade to v$target_version"
    
    # Stop running service
    local was_running=false
    if is_watchdog_running; then
        print_status "update" "Stopping Watchdog service..."
        if command -v systemctl >/dev/null && systemctl is-active --quiet watchdog 2>/dev/null; then
            sudo systemctl stop watchdog 2>/dev/null
        else
            kill "$(cat "$PID_FILE")" 2>/dev/null
        fi
        was_running=true
        sleep 3
    fi
    
    # Create backup
    cp "$SCRIPT_PATH" "$backup_file" 2>/dev/null || {
        print_status "error" "Failed to create backup"
        return 1
    }
    print_status "update" "Backup created: $backup_file"
    
    # Download new version
    print_status "update" "Downloading v$target_version..."
    if command -v curl >/dev/null; then
        curl -s "$GITHUB_RAW/watchdog.sh" -o "$temp_file"
    elif command -v wget >/dev/null; then
        wget -q "$GITHUB_RAW/watchdog.sh" -O "$temp_file"
    else
        print_status "error" "curl or wget not found"
        return 1
    fi
    
    # Verify download
    if [[ ! -f "$temp_file" || ! -s "$temp_file" ]]; then
        print_status "error" "Failed to download new version"
        return 1
    fi
    
    # Verify it's a valid script
    if ! bash -n "$temp_file" 2>/dev/null; then
        print_status "error" "Downloaded file is not a valid bash script"
        rm -f "$temp_file"
        return 1
    fi
    
    # Replace script
    mv "$temp_file" "$SCRIPT_PATH"
    chmod +x "$SCRIPT_PATH"
    
    # Update systemd service if exists
    if [[ -f "/etc/systemd/system/watchdog.service" ]]; then
        print_status "update" "Updating systemd service..."
        create_systemd_service
        sudo systemctl daemon-reload
    fi
    
    # Download updated language files
    for lang in en tr; do
        if command -v curl >/dev/null; then
            curl -s "$GITHUB_RAW/lang/$lang.json" -o "$LANG_DIR/$lang.json" 2>/dev/null
        elif command -v wget >/dev/null; then
            wget -q "$GITHUB_RAW/lang/$lang.json" -O "$LANG_DIR/$lang.json" 2>/dev/null
        fi
    done
    
    print_status "success" "$(msg "update_complete")"
    log_message "INFO" "Upgrade completed successfully to v$target_version"
    
    # Restart service if it was running
    if [[ "$was_running" == "true" ]]; then
        print_status "update" "Restarting Watchdog service..."
        if command -v systemctl >/dev/null; then
            sudo systemctl start watchdog
        else
            "$SCRIPT_PATH" --daemon &
        fi
    fi
    
    # Show new version
    local new_version=$("$SCRIPT_PATH" --version 2>/dev/null | grep -o 'v[0-9.]*' || echo "v$target_version")
    print_status "success" "Watchdog updated to $new_version"
}

# ==================================================================================
# 🛠️ DEPENDENCY CHECKING
# ==================================================================================
check_dependencies() {
    local missing=()
    local optional_missing=()
    
    # Critical dependencies
    command -v systemctl >/dev/null || missing+=("systemd")
    if ! command -v curl >/dev/null && ! command -v wget >/dev/null; then
        missing+=("curl or wget")
    fi
    
    # Optional dependencies
    command -v bc >/dev/null || optional_missing+=("bc (for calculations)")
    command -v jq >/dev/null || optional_missing+=("jq (for JSON parsing)")
    if ! command -v sendmail >/dev/null && ! command -v mail >/dev/null; then
        optional_missing+=("mail system (sendmail/mailutils)")
    fi
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        print_status "error" "Missing critical dependencies: ${missing[*]}"
        echo "Install with:"
        echo "  Ubuntu/Debian: sudo apt install curl wget systemd"
        echo "  RHEL/CentOS: sudo yum install curl wget systemd"
        exit 1
    fi
    
    if [[ ${#optional_missing[@]} -gt 0 ]]; then
        print_status "warning" "Optional dependencies missing: ${optional_missing[*]}"
        echo "Install with:"
        echo "  Ubuntu/Debian: sudo apt install bc jq mailutils"
        echo "  RHEL/CentOS: sudo yum install bc jq mailx"
        echo
    fi
}

# ==================================================================================
# 📋 SETUP WIZARD
# ==================================================================================
setup_wizard() {
    show_header
    
    # Initialize i18n
    init_i18n
    
    # Language selection
    echo -e "${COLORS[YELLOW]}$(msg "language_select"):${COLORS[NC]}"
    echo "  [1] English"
    echo "  [2] Türkçe"
    echo -n "Choice [1-2]: "
    read -r lang_choice
    
    case "$lang_choice" in
        2) LANGUAGE="tr" ;;
        *) LANGUAGE="en" ;;
    esac
    
    load_language "$LANGUAGE"
    show_header
    
    # Check for updates first
    check_for_updates "force"
    
    # Service discovery
    mapfile -t all_services < <(discover_services)
    print_status "success" "$(msg "found_services" "${#all_services[@]}")"
    
    # Categorize services
    print_status "info" "$(msg "service_classification")"
    declare -A service_categories
    while IFS=':' read -r category services; do
        service_categories["$category"]="$services"
    done < <(categorize_all_services all_services)
    
    echo
    echo -e "${COLORS[CYAN]}${COLORS[BOLD]}📊 Service Categories:${COLORS[NC]}"
    echo -e "${COLORS[BLUE]}────────────────────────────────────────${COLORS[NC]}"
    
    # Show categorized services
    declare -A selected_services
    for category in critical application socket-activated on-demand optional standard; do
        if [[ -n "${service_categories[$category]}" ]]; then
            local services_array=(${service_categories[$category]})
            local count=${#services_array[@]}
            
            case "$category" in
                "critical")
                    echo -e "${COLORS[RED]}🔴 $(msg "critical_services") ($count):${COLORS[NC]}"
                    selected_services["$category"]="${service_categories[$category]}"
                    ;;
                "application")
                    echo -e "${COLORS[GREEN]}🟢 $(msg "application_services") ($count):${COLORS[NC]}"
                    ;;
                "socket-activated")
                    echo -e "${COLORS[BLUE]}🔵 $(msg "socket_services") ($count):${COLORS[NC]}"
                    selected_services["$category"]="${service_categories[$category]}"
                    ;;
                "on-demand")
                    echo -e "${COLORS[YELLOW]}🟡 On-Demand Services ($count):${COLORS[NC]}"
                    ;;
                "optional")
                    echo -e "${COLORS[PURPLE]}🟣 $(msg "optional_services") ($count):${COLORS[NC]}"
                    ;;
                "standard")
                    echo -e "${COLORS[GRAY]}⚪ Standard Services ($count):${COLORS[NC]}"
                    ;;
            esac
            
            # Show first few services
            local display_count=0
            for service in ${services_array[@]}; do
                if [[ $display_count -lt 5 ]]; then
                    echo "    • $service"
                    ((display_count++))
                elif [[ $display_count -eq 5 ]]; then
                    echo "    • ... and $((count - 5)) more"
                    break
                fi
            done
            echo
        fi
    done
    
    # Service selection for non-automatic categories
    for category in application standard; do
        if [[ -n "${service_categories[$category]}" ]]; then
            local services_array=(${service_categories[$category]})
            echo -e "${COLORS[YELLOW]}Select $category services to monitor:${COLORS[NC]}"
            echo "Available services:"
            
            local i=0
            for service in ${services_array[@]}; do
                printf "  [%2d] %s\n" "$i" "$service"
                ((i++))
            done
            
            echo -n "Enter numbers (comma separated) or 'all' for all, 'none' for none: "
            read -r selection
            
            if [[ "$selection" == "all" ]]; then
                selected_services["$category"]="${service_categories[$category]}"
            elif [[ "$selection" != "none" ]]; then
                IFS=',' read -ra indices <<< "$selection"
                local selected=""
                for idx in "${indices[@]}"; do
                    idx=$(echo "$idx" | tr -d ' ')
                    if [[ "$idx" =~ ^[0-9]+$ ]] && [[ $idx -lt ${#services_array[@]} ]]; then
                        selected+="${services_array[$idx]} "
                    fi
                done
                selected_services["$category"]="$selected"
            fi
            echo
        fi
    done
    
    # Email configuration
    echo -e "${COLORS[YELLOW]}$(msg "notification_setup"):${COLORS[NC]}"
    echo -n "$(msg "email_prompt"): "
    read -r EMAIL
    
    # Additional notifications
    local notification_method=""
    echo
    echo "Additional notification methods:"
    echo "  [1] Discord/Slack Webhook"
    echo "  [2] Telegram Bot"
    echo "  [3] Skip"
    echo -n "Choice [1-3]: "
    read -r notification_choice
    
    case "$notification_choice" in
        1)
            echo -n "$(msg "webhook_prompt"): "
            read -r WEBHOOK_URL
            notification_method="webhook"
            ;;
        2)
            echo -n "Telegram Bot Token: "
            read -r TELEGRAM_BOT_TOKEN
            echo -n "Telegram Chat ID: "
            read -r TELEGRAM_CHAT_ID
            notification_method="telegram"
            ;;
    esac
    
    # Monitoring configuration
    echo
    echo -n "$(msg "interval_prompt") [5]: "
    read -r INTERVAL
    [[ "$INTERVAL" =~ ^[0-9]+$ ]] || INTERVAL=5
    
    echo -n "Notification level - all/critical only [critical]: "
    read -r NOTIFICATION_LEVEL
    [[ "$NOTIFICATION_LEVEL" == "all" ]] || NOTIFICATION_LEVEL="critical"
    
    echo -n "Enable auto-updates? [y/N]: "
    read -r auto_update_choice
    AUTO_UPDATE="false"
    [[ "$auto_update_choice" =~ ^[Yy] ]] && AUTO_UPDATE="true"
    
    echo -n "Enable auto-start on boot? [y/N]: "
    read -r autostart_choice
    AUTOSTART="false"
    [[ "$autostart_choice" =~ ^[Yy] ]] && AUTOSTART="true"
    
    # Save configuration
    mkdir -p "$CONFIG_DIR"
    
    # Main config
    {
        echo "# Watchdog v$VERSION Configuration"
        echo "# Generated on $(date)"
        echo
        echo "VERSION=\"$VERSION\""
        echo "LANGUAGE=\"$LANGUAGE\""
        echo "INTERVAL=\"$INTERVAL\""
        echo "NOTIFICATION_LEVEL=\"$NOTIFICATION_LEVEL\""
        echo "AUTO_UPDATE=\"$AUTO_UPDATE\""
        echo "AUTOSTART=\"$AUTOSTART\""
        echo "EMAIL=\"$EMAIL\""
        echo
        echo "# Service Configuration"
        for category in critical application socket-activated on-demand optional standard; do
            if [[ -n "${selected_services[$category]}" ]]; then
                var_suffix=$(echo "$category" | tr '[:lower:]-' '[:upper:]_')
                echo "SERVICES_${var_suffix}=(${selected_services[$category]})"
            fi
        done
    } > "$CONFIG_FILE"
    
    # Notification config
    {
        echo "# Notification Configuration"
        echo "WEBHOOK_URL=\"$WEBHOOK_URL\""
        echo "TELEGRAM_BOT_TOKEN=\"$TELEGRAM_BOT_TOKEN\""
        echo "TELEGRAM_CHAT_ID=\"$TELEGRAM_CHAT_ID\""
    } > "$NOTIFICATION_CONFIG"
    
    # Service types config (for custom overrides)
    {
        echo "# Custom Service Type Overrides"
        echo "# Format: service.service=type"
        echo "# Types: critical, application, socket-activated, on-demand, optional, standard"
    } > "$SERVICE_TYPES_CONFIG"
    
    # Create systemd service
    create_systemd_service
    
    print_status "success" "$(msg "config_saved")"
    
    echo
    echo -e "${COLORS[CYAN]}${COLORS[BOLD]}📋 Configuration Summary:${COLORS[NC]}"
    echo -e "${COLORS[BLUE]}──────────────────────────────────────────${COLORS[NC]}"
    
    local total_services=0
    for category in critical application socket-activated; do
        if [[ -n "${selected_services[$category]}" ]]; then
            local services_array=(${selected_services[$category]})
            local count=${#services_array[@]}
            total_services=$((total_services + count))
            echo "  📦 ${category^} services: $count"
        fi
    done
    
    echo "  📧 Email: ${EMAIL:-"Not configured"}"
    echo "  🔔 Notifications: $notification_method"
    echo "  ⏱️  Interval: $INTERVAL minutes"
    echo "  🔄 Auto-update: $AUTO_UPDATE"
    echo "  🚀 Auto-start: $AUTOSTART"
    echo "  📁 Config: $CONFIG_DIR/"
    echo
    
    if [[ "$AUTOSTART" == "true" ]]; then
        sudo systemctl enable watchdog.service 2>/dev/null
        print_status "success" "Auto-start enabled"
    fi
    
    echo -e "${COLORS[GREEN]}${COLORS[BOLD]}🎉 Setup Complete!${COLORS[NC]}"
    echo
    echo -e "${COLORS[WHITE]}Quick Start Commands:${COLORS[NC]}"
    echo "  🟢 Start monitoring: ${COLORS[GREEN]}sudo systemctl start watchdog${COLORS[NC]}"
    echo "  📊 Check status: ${COLORS[BLUE]}$SCRIPT_PATH --status${COLORS[NC]}"
    echo "  📄 View logs: ${COLORS[YELLOW]}tail -f $LOG_FILE${COLORS[NC]}"
    echo "  🧪 Test notifications: ${COLORS[PURPLE]}$SCRIPT_PATH --test${COLORS[NC]}"
    echo "  🔄 Check for updates: ${COLORS[CYAN]}$SCRIPT_PATH --update${COLORS[NC]}"
}

# ==================================================================================
# 🎛️ MONITORING DAEMON
# ==================================================================================
monitor_services() {
    # Load configuration
    if [[ ! -f "$CONFIG_FILE" ]]; then
        print_status "error" "Configuration not found. Run setup first."
        exit 1
    fi
    
    source "$CONFIG_FILE"
    load_language "$LANGUAGE"
    
    # Create PID file
    create_pid_file
    
    # Setup signal handlers
    trap 'remove_pid_file; exit 0' EXIT INT TERM
    
    log_message "INFO" "Watchdog v$VERSION daemon started"
    
    # Collect all services to monitor
    declare -a all_monitored_services
    declare -A service_type_map
    
    for category in critical application socket-activated standard; do
        local var_suffix
        var_suffix=$(echo "$category" | tr '[:lower:]-' '[:upper:]_')
        local var_name="SERVICES_${var_suffix}"
        local services_var="${!var_name}"
        if [[ -n "$services_var" ]]; then
            for service in $services_var; do
                all_monitored_services+=("$service")
                service_type_map["$service"]="$category"
            done
        fi
    done
    
    log_message "INFO" "Monitoring ${#all_monitored_services[@]} services: ${all_monitored_services[*]}"
    print_status "success" "$(msg "monitoring_active" ${#all_monitored_services[@]})"
    
    local check_counter=0
    local update_check_counter=0
    local health_check_counter=0
    
    # Main monitoring loop
    while true; do
        local start_time=$(date +%s)
        
        # Monitor services
        for service in "${all_monitored_services[@]}"; do
            local service_type="${service_type_map[$service]}"
            check_service_health "$service" "$service_type"
        done
        
        # System health check every 5 cycles
        ((health_check_counter++))
        if [[ $((health_check_counter % 5)) -eq 0 ]]; then
            check_system_health
            health_check_counter=0
        fi
        
        # Update check (daily)
        ((update_check_counter++))
        local checks_per_day=$((1440 / INTERVAL))
        if [[ $update_check_counter -ge $checks_per_day ]] && [[ "$AUTO_UPDATE" == "true" ]]; then
            check_for_updates
            update_check_counter=0
        fi
        
        # Log periodic status
        ((check_counter++))
        if [[ $((check_counter % 12)) -eq 0 ]]; then  # Every hour (if interval=5min)
            log_message "INFO" "Monitoring cycle #$check_counter completed - ${#all_monitored_services[@]} services checked"
            print_status "debug" "Monitoring cycle #$check_counter - all services checked"
        fi
        
        # Sleep for interval
        local end_time=$(date +%s)
        local elapsed=$((end_time - start_time))
        local sleep_time=$((INTERVAL * 60 - elapsed))
        
        if [[ $sleep_time -gt 0 ]]; then
            sleep "$sleep_time"
        fi
    done
}

# ==================================================================================
# 🏗️ SYSTEMD SERVICE CREATION
# ==================================================================================
create_systemd_service() {
    local service_content="[Unit]
Description=Watchdog Service Monitor v$VERSION
Documentation=https://github.com/$GITHUB_REPO
After=network-online.target multi-user.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=$SCRIPT_PATH --daemon
ExecReload=/bin/kill -HUP \$MAINPID
KillMode=process
Restart=always
RestartSec=30
User=$USER
Group=$(id -gn)
Environment=HOME=$HOME
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
WorkingDirectory=$SCRIPT_DIR
PIDFile=$PID_FILE
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target"
    
    echo "$service_content" | sudo tee /etc/systemd/system/watchdog.service >/dev/null
    sudo systemctl daemon-reload
    log_message "INFO" "Systemd service created/updated"
}

# ==================================================================================
# 🧪 TEST FUNCTIONS
# ==================================================================================
test_notifications() {
    print_status "info" "Testing notification systems..."
    
    [[ -f "$CONFIG_FILE" ]] && source "$CONFIG_FILE"
    [[ -f "$NOTIFICATION_CONFIG" ]] && source "$NOTIFICATION_CONFIG"
    load_language "$LANGUAGE"
    
    send_notification "test-service" "notification test completed" "application"
    print_status "success" "Test notifications sent! Check your configured channels."
}

test_service_classification() {
    print_status "info" "Testing service classification..."
    
    local services=("ssh.service" "snapd.service" "packagekit.service" "nginx.service" "cron.service")
    
    for service in "${services[@]}"; do
        local classification=$(classify_service "$service")
        print_status "info" "$service -> $classification"
    done
}

# ==================================================================================
# 📊 STATUS AND ANALYTICS
# ==================================================================================
show_status() {
    show_header
    
    if is_watchdog_running; then
        local pid=$(cat "$PID_FILE")
        print_status "success" "Watchdog is running (PID: $pid)"
        
        if [[ -f "$CONFIG_FILE" ]]; then
            source "$CONFIG_FILE"
            load_language "$LANGUAGE"
            
            echo
            echo -e "${COLORS[CYAN]}${COLORS[BOLD]}📊 Current Configuration:${COLORS[NC]}"
            echo -e "${COLORS[BLUE]}────────────────────────────────${COLORS[NC]}"
            
            # Count monitored services
            local total_services=0
            for category in critical application socket-activated standard; do
                local var_suffix
                var_suffix=$(echo "$category" | tr '[:lower:]-' '[:upper:]_')
                local var_name="SERVICES_${var_suffix}"
                local services_var="${!var_name}"
                if [[ -n "$services_var" ]]; then
                    local services_array=($services_var)
                    local count=${#services_array[@]}
                    total_services=$((total_services + count))
                    echo "  📦 ${category^}: $count services"
                fi
            done
            
            echo "  📧 Email: ${EMAIL:-"Not configured"}"
            echo "  ⏱️  Interval: $INTERVAL minutes"
            echo "  🌐 Language: $LANGUAGE"
            echo "  🔄 Auto-update: $AUTO_UPDATE"
            echo "  📄 Log file: $LOG_FILE"
            
            # System health
            echo
            echo -e "${COLORS[CYAN]}${COLORS[BOLD]}🖥️ System Health:${COLORS[NC]}"
            echo -e "${COLORS[BLUE]}─────────────────${COLORS[NC]}"
            
            local load_avg=$(uptime | awk -F'load average:' '{print $2}' | cut -d',' -f1 | tr -d ' ')
            local disk_usage=$(df / | awk 'NR==2 {print $5}')
            local mem_usage=$(free | awk 'NR==2{printf "%.1f%%", $3*100/$2}')
            local uptime_info=$(uptime -p 2>/dev/null || uptime | awk -F'up ' '{print $2}' | awk -F',' '{print $1}')
            
            echo "  📈 Load Average: $load_avg"
            echo "  💾 Disk Usage: $disk_usage"
            echo "  🧠 Memory Usage: $mem_usage"
            echo "  ⏰ System Uptime: $uptime_info"
            
            # Recent activity
            if [[ -f "$LOG_FILE" ]]; then
                echo
                echo -e "${COLORS[CYAN]}${COLORS[BOLD]}📜 Recent Activity (last 5 entries):${COLORS[NC]}"
                echo -e "${COLORS[BLUE]}──────────────────────────────────────────${COLORS[NC]}"
                tail -n 5 "$LOG_FILE" 2>/dev/null | while read -r line; do
                    echo "  ${COLORS[GRAY]}$line${COLORS[NC]}"
                done
            fi
        fi
    else
        print_status "error" "Watchdog is not running"
        echo
        echo -e "${COLORS[YELLOW]}Start with:${COLORS[NC]}"
        echo "  ${COLORS[GREEN]}sudo systemctl start watchdog${COLORS[NC]}"
        echo "  ${COLORS[BLUE]}$SCRIPT_PATH --daemon${COLORS[NC]}"
    fi
}

# ==================================================================================
# 📈 LOG ANALYTICS
# ==================================================================================
analyze_logs() {
    if [[ ! -f "$LOG_FILE" ]]; then
        print_status "error" "Log file not found: $LOG_FILE"
        return 1
    fi
    
    show_header
    echo -e "${COLORS[CYAN]}${COLORS[BOLD]}📊 Watchdog Log Analytics${COLORS[NC]}"
    echo -e "${COLORS[BLUE]}═══════════════════════════════════════════${COLORS[NC]}"
    
    # Basic statistics
    local total_lines=$(wc -l < "$LOG_FILE" 2>/dev/null || echo 0)
    local today=$(date +%Y-%m-%d)
    local today_lines=$(grep "^$today" "$LOG_FILE" 2>/dev/null | wc -l || echo 0)
    
    echo -e "\n${COLORS[WHITE]}📋 General Statistics:${COLORS[NC]}"
    echo "  📄 Total log entries: $total_lines"
    echo "  📅 Today's entries: $today_lines"
    echo "  📁 Log file size: $(du -h "$LOG_FILE" 2>/dev/null | cut -f1 || echo "0B")"
    
    # Service restart statistics
    echo -e "\n${COLORS[WHITE]}🔄 Service Restart Statistics:${COLORS[NC]}"
    local total_restarts=$(grep -c "restarted successfully\|Service.*restart" "$LOG_FILE" 2>/dev/null || echo 0)
    local failed_restarts=$(grep -c "Failed to restart\|failed to restart" "$LOG_FILE" 2>/dev/null || echo 0)
    
    echo "  ✅ Successful restarts: $total_restarts"
    echo "  ❌ Failed restarts: $failed_restarts"
    
    if [[ $total_restarts -gt 0 ]]; then
        echo -e "\n${COLORS[WHITE]}🏆 Most Restarted Services:${COLORS[NC]}"
        grep "restarted successfully\|Service.*restart" "$LOG_FILE" 2>/dev/null | \
            sed -n 's/.*Service \([^ ]*\) restart.*/\1/p' | \
            sort | uniq -c | sort -nr | head -5 | \
            while read -r count service; do
                echo "  🔄 $service: $count times"
            done
    fi
    
    # Error analysis
    echo -e "\n${COLORS[WHITE]}⚠️ Error Analysis:${COLORS[NC]}"
    local error_count=$(grep -c "\[ERROR\]\|\[WARNING\]" "$LOG_FILE" 2>/dev/null || echo 0)
    local critical_count=$(grep -c "\[ALERT\].*critical" "$LOG_FILE" 2>/dev/null || echo 0)
    
    echo "  ⚠️  Total warnings/errors: $error_count"
    echo "  🚨 Critical alerts: $critical_count"
    
    # System health alerts
    echo -e "\n${COLORS[WHITE]}🖥️ System Health Alerts:${COLORS[NC]}"
    local load_alerts=$(grep -c "High.*load\|high load" "$LOG_FILE" 2>/dev/null || echo 0)
    local memory_alerts=$(grep -c "High.*memory\|high memory" "$LOG_FILE" 2>/dev/null || echo 0)
    local disk_alerts=$(grep -c "High.*disk\|high disk" "$LOG_FILE" 2>/dev/null || echo 0)
    
    echo "  📈 High load alerts: $load_alerts"
    echo "  🧠 High memory alerts: $memory_alerts"
    echo "  💾 High disk alerts: $disk_alerts"
    
    # Recent activity timeline
    echo -e "\n${COLORS[WHITE]}⏰ Recent Activity (Last 24 Hours):${COLORS[NC]}"
    local yesterday=$(date -d "yesterday" +%Y-%m-%d 2>/dev/null || date -v-1d +%Y-%m-%d 2>/dev/null)
    
    grep -E "($yesterday|$today)" "$LOG_FILE" 2>/dev/null | tail -10 | \
        while read -r line; do
            if [[ "$line" =~ ERROR|ALERT ]]; then
                echo "  ${COLORS[RED]}$line${COLORS[NC]}"
            elif [[ "$line" =~ WARNING ]]; then
                echo "  ${COLORS[YELLOW]}$line${COLORS[NC]}"
            else
                echo "  ${COLORS[GRAY]}$line${COLORS[NC]}"
            fi
        done
    
    # Performance metrics
    echo -e "\n${COLORS[WHITE]}⚡ Performance Metrics:${COLORS[NC]}"
    if command -v awk >/dev/null; then
        local avg_cycle_time=$(grep "Monitoring cycle" "$LOG_FILE" 2>/dev/null | \
            awk '{print $1}' | xargs -I {} date -d {} +%s 2>/dev/null | \
            awk 'NR>1{sum+=$1-prev} {prev=$1} END{if(NR>1) print int(sum/(NR-1)); else print 0}')
        
        if [[ -n "$avg_cycle_time" && "$avg_cycle_time" -gt 0 ]]; then
            echo "  ⏱️  Average cycle time: ${avg_cycle_time}s"
        fi
    fi
    
    # Suggestions
    echo -e "\n${COLORS[WHITE]}💡 Suggestions:${COLORS[NC]}"
    
    if [[ $failed_restarts -gt 5 ]]; then
        echo "  ⚠️  Consider investigating services with frequent restart failures"
    fi
    
    if [[ $total_restarts -gt 20 ]]; then
        echo "  🔍 High restart frequency detected - check system stability"
    fi
    
    if [[ $error_count -gt 50 ]]; then
        echo "  📝 Consider log rotation or investigating recurring errors"
    fi
    
    if [[ $critical_count -eq 0 && $total_restarts -eq 0 ]]; then
        echo "  ✅ System appears stable - no critical issues detected"
    fi
}

# ==================================================================================
# 🔧 MANAGEMENT FUNCTIONS
# ==================================================================================
backup_configuration() {
    local backup_dir="$HOME/.watchdog_backup_$(date +%F-%H%M%S)"
    mkdir -p "$backup_dir"
    
    # Copy configuration files
    [[ -f "$CONFIG_FILE" ]] && cp "$CONFIG_FILE" "$backup_dir/"
    [[ -f "$NOTIFICATION_CONFIG" ]] && cp "$NOTIFICATION_CONFIG" "$backup_dir/"
    [[ -f "$SERVICE_TYPES_CONFIG" ]] && cp "$SERVICE_TYPES_CONFIG" "$backup_dir/"
    [[ -f "$LOG_FILE" ]] && cp "$LOG_FILE" "$backup_dir/"
    [[ -d "$LANG_DIR" ]] && cp -r "$LANG_DIR" "$backup_dir/"
    
    # Copy systemd service
    [[ -f "/etc/systemd/system/watchdog.service" ]] && \
        sudo cp "/etc/systemd/system/watchdog.service" "$backup_dir/" 2>/dev/null
    
    print_status "success" "Configuration backed up to: $backup_dir"
    echo "  📦 Files backed up:"
    find "$backup_dir" -type f -exec basename {} \; | sed 's/^/    • /'
}

restore_configuration() {
    local backup_dir="$1"
    
    if [[ ! -d "$backup_dir" ]]; then
        print_status "error" "Backup directory not found: $backup_dir"
        return 1
    fi
    
    print_status "info" "Restoring configuration from: $backup_dir"
    
    # Stop service if running
    local was_running=false
    if is_watchdog_running; then
        print_status "info" "Stopping Watchdog service..."
        sudo systemctl stop watchdog 2>/dev/null || kill "$(cat "$PID_FILE")" 2>/dev/null
        was_running=true
    fi
    
    # Restore files
    mkdir -p "$CONFIG_DIR"
    [[ -f "$backup_dir/$(basename "$CONFIG_FILE")" ]] && cp "$backup_dir/$(basename "$CONFIG_FILE")" "$CONFIG_FILE"
    [[ -f "$backup_dir/$(basename "$NOTIFICATION_CONFIG")" ]] && cp "$backup_dir/$(basename "$NOTIFICATION_CONFIG")" "$NOTIFICATION_CONFIG"
    [[ -f "$backup_dir/$(basename "$SERVICE_TYPES_CONFIG")" ]] && cp "$backup_dir/$(basename "$SERVICE_TYPES_CONFIG")" "$SERVICE_TYPES_CONFIG"
    [[ -f "$backup_dir/$(basename "$LOG_FILE")" ]] && cp "$backup_dir/$(basename "$LOG_FILE")" "$LOG_FILE"
    [[ -d "$backup_dir/lang" ]] && cp -r "$backup_dir/lang" "$CONFIG_DIR/"
    
    # Restore systemd service
    [[ -f "$backup_dir/watchdog.service" ]] && \
        sudo cp "$backup_dir/watchdog.service" "/etc/systemd/system/" 2>/dev/null && \
        sudo systemctl daemon-reload
    
    print_status "success" "Configuration restored successfully"
    
    # Restart service if it was running
    if [[ "$was_running" == "true" ]]; then
        print_status "info" "Restarting Watchdog service..."
        sudo systemctl start watchdog
    fi
}

uninstall_watchdog() {
    print_status "warning" "Starting Watchdog uninstallation..."
    
    echo -n "Are you sure you want to completely remove Watchdog? [y/N]: "
    read -r confirm
    if [[ ! "$confirm" =~ ^[Yy] ]]; then
        print_status "info" "Uninstallation cancelled"
        return 0
    fi
    
    # Stop and disable service
    if systemctl is-active --quiet watchdog 2>/dev/null; then
        print_status "info" "Stopping Watchdog service..."
        sudo systemctl stop watchdog
    fi
    
    if systemctl is-enabled --quiet watchdog 2>/dev/null; then
        print_status "info" "Disabling Watchdog service..."
        sudo systemctl disable watchdog
    fi
    
    # Remove systemd service
    if [[ -f "/etc/systemd/system/watchdog.service" ]]; then
        sudo rm -f "/etc/systemd/system/watchdog.service"
        sudo systemctl daemon-reload
        print_status "success" "Systemd service removed"
    fi
    
    # Create backup before removing
    backup_configuration
    
    # Remove configuration
    if [[ -d "$CONFIG_DIR" ]]; then
        rm -rf "$CONFIG_DIR"
        print_status "success" "Configuration directory removed"
    fi
    
    print_status "success" "Watchdog uninstalled successfully"
    echo
    echo "Note: The script file ($SCRIPT_PATH) was not removed."
    echo "Remove it manually if no longer needed."
}

# ==================================================================================
# 📋 HELP SYSTEM
# ==================================================================================
show_help() {
    show_header
    
    echo -e "${COLORS[WHITE]}${COLORS[BOLD]}🐕 WATCHDOG v$VERSION - Usage Guide${COLORS[NC]}"
    echo -e "${COLORS[BLUE]}════════════════════════════════════════════════${COLORS[NC]}"
    echo
    echo -e "${COLORS[YELLOW]}BASIC USAGE:${COLORS[NC]}"
    echo "  $SCRIPT_NAME                    Run interactive setup wizard"
    echo "  $SCRIPT_NAME --daemon           Start monitoring daemon"
    echo "  $SCRIPT_NAME --status           Show current status"
    echo "  $SCRIPT_NAME --stop             Stop running daemon"
    echo
    echo -e "${COLORS[YELLOW]}TESTING & DIAGNOSTICS:${COLORS[NC]}"
    echo "  $SCRIPT_NAME --test             Test notification systems"
    echo "  $SCRIPT_NAME --test-classify    Test service classification"
    echo "  $SCRIPT_NAME --logs             Analyze log files"
    echo "  $SCRIPT_NAME --health           Show system health"
    echo
    echo -e "${COLORS[YELLOW]}UPDATES & MAINTENANCE:${COLORS[NC]}"
    echo "  $SCRIPT_NAME --update           Check for and install updates"
    echo "  $SCRIPT_NAME --backup           Backup configuration"
    echo "  $SCRIPT_NAME --restore DIR      Restore from backup"
    echo "  $SCRIPT_NAME --uninstall        Complete removal"
    echo
    echo -e "${COLORS[YELLOW]}SYSTEMD INTEGRATION:${COLORS[NC]}"
    echo "  sudo systemctl start watchdog   Start service"
    echo "  sudo systemctl stop watchdog    Stop service"
    echo "  sudo systemctl enable watchdog  Enable auto-start"
    echo "  sudo systemctl status watchdog  Show service status"
    echo
    echo -e "${COLORS[YELLOW]}INFORMATION:${COLORS[NC]}"
    echo "  $SCRIPT_NAME --version          Show version"
    echo "  $SCRIPT_NAME --help             Show this help"
    echo
    echo -e "${COLORS[CYAN]}${COLORS[BOLD]}🌟 FEATURES:${COLORS[NC]}"
    echo "  ✅ Intelligent service classification"
    echo "  ✅ Socket-activated service support"
    echo "  ✅ Multi-channel notifications"
    echo "  ✅ Auto-update system"
    echo "  ✅ System health monitoring"
    echo "  ✅ Comprehensive logging"
    echo "  ✅ Multi-language support"
    echo
    echo -e "${COLORS[WHITE]}Configuration files:${COLORS[NC]}"
    echo "  📁 $CONFIG_DIR/"
    echo "  📄 Log file: $LOG_FILE"
    echo
    echo -e "${COLORS[GRAY]}For more information, visit: https://github.com/$GITHUB_REPO${COLORS[NC]}"
}

# ==================================================================================
# 🚀 MAIN PROGRAM ENTRY POINT
# ==================================================================================
main() {
    # Create config directory
    mkdir -p "$CONFIG_DIR"
    
    case "${1:-}" in
        "--daemon"|"-d")
            monitor_services
            ;;
        "--test"|"-t")
            test_notifications
            ;;
        "--test-classify")
            test_service_classification
            ;;
        "--status"|"-s")
            show_status
            ;;
        "--update"|"-u"|"--upgrade")
            check_for_updates "force"
            ;;
        "--logs"|"-l")
            analyze_logs
            ;;
        "--health")
            check_system_health
            if [[ $? -eq 0 ]]; then
                print_status "success" "$(msg "system_health_ok")"
            else
                print_status "warning" "System health issues detected"
            fi
            ;;
        "--backup")
            backup_configuration
            ;;
        "--restore")
            restore_configuration "$2"
            ;;
        "--uninstall")
            uninstall_watchdog
            ;;
        "--stop")
            if is_watchdog_running; then
                local pid=$(cat "$PID_FILE")
                kill "$pid" 2>/dev/null
                remove_pid_file
                print_status "success" "$(msg "service_stopped")"
                
                # Also stop systemd service if running
                if systemctl is-active --quiet watchdog 2>/dev/null; then
                    sudo systemctl stop watchdog
                fi
            else
                print_status "info" "Watchdog is not running"
            fi
            ;;
        "--version"|"-v")
            echo "Watchdog v$VERSION"
            echo "GitHub: https://github.com/$GITHUB_REPO"
            ;;
        "--help"|"-h"|"help")
            show_help
            ;;
        *)
            # Setup wizard mode
            check_dependencies
            
            if is_watchdog_running; then
                show_status
                echo
                print_status "warning" "Watchdog is already running."
                echo "  🛑 Stop with: ${COLORS[YELLOW]}$SCRIPT_PATH --stop${COLORS[NC]}"
                echo "  📊 Status: ${COLORS[BLUE]}$SCRIPT_PATH --status${COLORS[NC]}"
                echo "  ⚙️  Reconfigure: ${COLORS[GREEN]}$SCRIPT_PATH --stop && $SCRIPT_PATH${COLORS[NC]}"
                exit 1
            fi
            
            setup_wizard
            ;;
    esac
}

# ==================================================================================
# 🎬 SCRIPT EXECUTION
# ==================================================================================
# Initialize and run
main "$@"
