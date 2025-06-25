#!/bin/bash
# === Watchdog v3.1 - Complete System with Auto-Update ===
# Universal Linux Service Monitor & Auto-Recovery System
# Author: Enhanced by AI
# License: MIT

VERSION="3.1"
SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_PATH="$SCRIPT_DIR/$SCRIPT_NAME"

# === Dosya Yolları ===
CONFIG_FILE="$HOME/.watchdog.conf"
NOTIFICATION_CONFIG="$HOME/.watchdog_notifications.conf"
LOG_FILE="$HOME/watchdog.log"
PID_FILE="$HOME/.watchdog.pid"
LANG_DIR="$SCRIPT_DIR/lang"
UPDATE_CHECK_FILE="$HOME/.watchdog_last_update_check"

# === Update Ayarları ===
GITHUB_REPO="slaweally/Watchdog"
GITHUB_API="https://api.github.com/repos/$GITHUB_REPO"
GITHUB_RAW="https://raw.githubusercontent.com/$GITHUB_REPO/main"

# === Varsayılan Ayarlar ===
LANGUAGE="en"
DEFAULT_INTERVAL=15
DEFAULT_EMAIL=""
AUTO_UPDATE_CHECK=true

# === Renkli Çıktı ===
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# === Logo ve Başlık ===
show_header() {
    clear
    echo -e "${CYAN}"
    echo "██╗    ██╗ █████╗ ████████╗ ██████╗██╗  ██╗██████╗  ██████╗  ██████╗ "
    echo "██║    ██║██╔══██╗╚══██╔══╝██╔════╝██║  ██║██╔══██╗██╔═══██╗██╔════╝ "
    echo "██║ █╗ ██║███████║   ██║   ██║     ███████║██║  ██║██║   ██║██║  ███╗"
    echo "██║███╗██║██╔══██║   ██║   ██║     ██╔══██║██║  ██║██║   ██║██║   ██║"
    echo "╚███╔███╔╝██║  ██║   ██║   ╚██████╗██║  ██║██████╔╝╚██████╔╝╚██████╔╝"
    echo " ╚══╝╚══╝ ╚═╝  ╚═╝   ╚═╝    ╚═════╝╚═╝  ╚═╝╚═════╝  ╚═════╝  ╚═════╝ "
    echo -e "${NC}"
    echo -e "${WHITE}🐾 Universal Linux Service Monitor v$VERSION${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════${NC}"
    echo
}

# === Utility Fonksiyonları ===
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $*" >> "$LOG_FILE"
}

print_status() {
    local status="$1"
    local message="$2"
    case "$status" in
        "success") echo -e "${GREEN}✅ $message${NC}" ;;
        "error") echo -e "${RED}❌ $message${NC}" ;;
        "warning") echo -e "${YELLOW}⚠️  $message${NC}" ;;
        "info") echo -e "${BLUE}ℹ️  $message${NC}" ;;
        "update") echo -e "${PURPLE}🔄 $message${NC}" ;;
        *) echo -e "${WHITE}$message${NC}" ;;
    esac
}

# === PID Yönetimi ===
create_pid_file() {
    echo $$ > "$PID_FILE"
    log_message "Watchdog started with PID: $$"
}

remove_pid_file() {
    [[ -f "$PID_FILE" ]] && rm -f "$PID_FILE"
    log_message "Watchdog stopped, PID file removed"
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

# === Güncelleme Sistemi ===
check_for_updates() {
    local force_check="$1"
    local now=$(date +%s)
    local last_check=0
    
    # Son kontrol zamanını oku
    if [[ -f "$UPDATE_CHECK_FILE" ]] && [[ "$force_check" != "force" ]]; then
        last_check=$(cat "$UPDATE_CHECK_FILE" 2>/dev/null || echo 0)
        # 24 saat = 86400 saniye
        if [[ $((now - last_check)) -lt 86400 ]]; then
            return 0
        fi
    fi
    
    print_status "update" "Yeni sürüm kontrolü yapılıyor..."
    
    # GitHub API'den son sürümü al
    local latest_version
    if command -v curl >/dev/null; then
        latest_version=$(curl -s "$GITHUB_API/releases/latest" | \
            grep '"tag_name"' | cut -d'"' -f4 2>/dev/null)
    elif command -v wget >/dev/null; then
        latest_version=$(wget -qO- "$GITHUB_API/releases/latest" | \
            grep '"tag_name"' | cut -d'"' -f4 2>/dev/null)
    else
        print_status "warning" "curl veya wget bulunamadı, güncelleme kontrolü yapılamıyor"
        return 1
    fi
    
    # Son kontrol zamanını kaydet
    echo "$now" > "$UPDATE_CHECK_FILE"
    
    if [[ -z "$latest_version" ]]; then
        print_status "warning" "GitHub'dan sürüm bilgisi alınamadı"
        return 1
    fi
    
    # Sürüm karşılaştırması
    if [[ "$latest_version" != "v$VERSION" ]]; then
        print_status "update" "Yeni sürüm mevcut: $latest_version (Mevcut: v$VERSION)"
        log_message "New version available: $latest_version"
        
        echo -n "Şimdi güncellemek ister misiniz? [y/N]: "
        read -r update_choice
        if [[ "$update_choice" =~ ^[Yy] ]]; then
            upgrade_watchdog "$latest_version"
        else
            print_status "info" "Güncelleme atlandı. Manuel güncelleme: $SCRIPT_PATH --upgrade"
        fi
    else
        print_status "success" "Watchdog güncel (v$VERSION)"
    fi
}

upgrade_watchdog() {
    local target_version="$1"
    local backup_dir="${SCRIPT_DIR}-backup-$(date +%F-%H%M%S)"
    
    print_status "update" "Watchdog güncelleme başlatılıyor..."
    
    # Çalışan servisi durdur
    local was_running=false
    if is_watchdog_running; then
        print_status "update" "Watchdog servisi durduruluyor..."
        sudo systemctl stop watchdog 2>/dev/null || kill $(cat "$PID_FILE") 2>/dev/null
        was_running=true
        sleep 2
    fi
    
    # Yedek al
    print_status "update" "Mevcut dosyalar yedekleniyor: $backup_dir"
    cp -r "$SCRIPT_DIR" "$backup_dir" 2>/dev/null || {
        # Tek dosya yedeklemesi
        cp "$SCRIPT_PATH" "${SCRIPT_PATH}.backup-$(date +%F-%H%M%S)"
    }
    
    # Yeni sürümü indir
    print_status "update" "Yeni sürüm indiriliyor..."
    local temp_file="/tmp/watchdog_new.sh"
    
    if command -v curl >/dev/null; then
        curl -s "$GITHUB_RAW/watchdog.sh" -o "$temp_file"
    elif command -v wget >/dev/null; then
        wget -q "$GITHUB_RAW/watchdog.sh" -O "$temp_file"
    else
        print_status "error" "curl veya wget bulunamadı"
        return 1
    fi
    
    # İndirilen dosyayı kontrol et
    if [[ ! -f "$temp_file" ]] || [[ ! -s "$temp_file" ]]; then
        print_status "error" "Yeni sürüm indirilemedi"
        return 1
    fi
    
    # Dosyayı değiştir
    mv "$temp_file" "$SCRIPT_PATH"
    chmod +x "$SCRIPT_PATH"
    
    # Dil dosyalarını güncelle (varsa)
    if [[ -d "$LANG_DIR" ]]; then
        for lang in en tr; do
            if command -v curl >/dev/null; then
                curl -s "$GITHUB_RAW/lang/$lang.lang" -o "$LANG_DIR/$lang.lang" 2>/dev/null
            elif command -v wget >/dev/null; then
                wget -q "$GITHUB_RAW/lang/$lang.lang" -O "$LANG_DIR/$lang.lang" 2>/dev/null
            fi
        done
    fi
    
    print_status "success" "Güncelleme tamamlandı!"
    
    # Systemd servisini güncelle
    if [[ -f "/etc/systemd/system/watchdog.service" ]]; then
        print_status "update" "Systemd servisi güncelleniyor..."
        create_systemd_service
        sudo systemctl daemon-reload
    fi
    
    # Servisi yeniden başlat
    if [[ "$was_running" == "true" ]]; then
        print_status "update" "Watchdog servisi başlatılıyor..."
        sudo systemctl start watchdog
    fi
    
    # Yeni sürümü göster
    local new_version=$("$SCRIPT_PATH" --version 2>/dev/null | grep -o 'v[0-9.]*' || echo "updated")
    print_status "success" "Watchdog güncellendi: $new_version"
    log_message "Watchdog upgraded to: $new_version"
}

# === Bağımlılık Kontrolü ===
check_dependencies() {
    local missing=()
    local optional_missing=()
    
    # Temel bağımlılıklar
    command -v systemctl >/dev/null || missing+=("systemctl")
    command -v curl >/dev/null && command -v wget >/dev/null || missing+=("curl or wget")
    
    # Mail için gerekli
    if ! command -v sendmail >/dev/null && ! command -v mail >/dev/null; then
        optional_missing+=("mail system (install: sudo apt install postfix/sendmail)")
    fi
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        print_status "error" "Missing critical dependencies: ${missing[*]}"
        echo "Install with: sudo apt install curl wget"
        exit 1
    fi
    
    if [[ ${#optional_missing[@]} -gt 0 ]]; then
        print_status "warning" "Optional dependencies missing: ${optional_missing[*]}"
    fi
}

# === Dil Sistemi ===
declare -A MSG
init_language_system() {
    mkdir -p "$LANG_DIR"
    
    # İngilizce dil dosyası
    cat > "$LANG_DIR/en.lang" <<'EOF'
welcome=Welcome to Watchdog Setup Wizard
language_select=Please select your language
found_services=Found running services
select_all=Select All Services
select_services=Select services to monitor (comma separated, 'all' for all)
extra_services=Add additional services (optional, comma separated)
email_setup=Email Configuration
email_prompt=Enter email address for notifications (optional)
notification_setup=Additional Notification Methods
autostart_prompt=Enable auto-start on system boot?
interval_prompt=Monitoring interval in minutes
config_saved=Configuration saved successfully
monitoring_started=Monitoring started
service_ready=Watchdog service is ready
test_notification=Test notification sent
update_available=New version available
update_prompt=Would you like to update now?
EOF

    # Türkçe dil dosyası
    cat > "$LANG_DIR/tr.lang" <<'EOF'
welcome=Watchdog Kurulum Sihirbazına Hoş Geldiniz
language_select=Lütfen dilinizi seçin
found_services=Bulunan çalışan servisler
select_all=Tüm Servisleri Seç
select_services=İzlenecek servisleri seçin (virgülle ayrılmış, tümü için 'all')
extra_services=Ek servisler ekleyin (opsiyonel, virgülle ayrılmış)
email_setup=E-posta Yapılandırması
email_prompt=Bildirimler için e-posta adresi (opsiyonel)
notification_setup=Ek Bildirim Yöntemleri
autostart_prompt=Sistem başlangıcında otomatik başlatılsın mı?
interval_prompt=İzleme aralığı (dakika)
config_saved=Yapılandırma başarıyla kaydedildi
monitoring_started=İzleme başlatıldı
service_ready=Watchdog servisi hazır
test_notification=Test bildirimi gönderildi
update_available=Yeni sürüm mevcut
update_prompt=Şimdi güncellemek ister misiniz?
EOF
}

load_language() {
    local lang_file="$LANG_DIR/$LANGUAGE.lang"
    
    if [[ -f "$lang_file" ]]; then
        while IFS='=' read -r key value; do
            [[ $key =~ ^#.*$ || -z "$key" ]] && continue
            MSG[$key]="$value"
        done < "$lang_file"
    fi
}

get_msg() {
    echo "${MSG[$1]:-$1}"
}

# === Bildirim Sistemi ===
setup_mail_system() {
    # Basit sendmail kontrolü
    if command -v sendmail >/dev/null; then
        return 0
    elif command -v mail >/dev/null; then
        return 0
    else
        print_status "warning" "No mail system found. Installing basic mail support..."
        if command -v apt >/dev/null; then
            sudo apt update && sudo apt install -y mailutils
        elif command -v yum >/dev/null; then
            sudo yum install -y mailx
        else
            print_status "error" "Cannot install mail system automatically"
            return 1
        fi
    fi
}

send_email_notification() {
    local subject="$1"
    local message="$2"
    local email="$3"
    
    [[ -z "$email" ]] && return 1
    
    if command -v sendmail >/dev/null; then
        {
            echo "To: $email"
            echo "Subject: $subject"
            echo "From: watchdog@$(hostname)"
            echo ""
            echo "$message"
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
    
    [[ -z "$webhook_url" ]] && return 1
    
    if command -v curl >/dev/null; then
        curl -s -X POST "$webhook_url" \
            -H "Content-Type: application/json" \
            -d "{\"content\": \"🚨 **Watchdog Alert**\n$message\n$(date)\"}" \
            >/dev/null 2>&1
    fi
}

send_telegram_notification() {
    local message="$1"
    local bot_token="$2"
    local chat_id="$3"
    
    [[ -z "$bot_token" || -z "$chat_id" ]] && return 1
    
    if command -v curl >/dev/null; then
        curl -s -X POST \
            "https://api.telegram.org/bot$bot_token/sendMessage" \
            -d "chat_id=$chat_id" \
            -d "text=🚨 Watchdog Alert: $message" \
            >/dev/null 2>&1
    fi
}

send_notification() {
    local service="$1"
    local action="$2"
    local timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    local hostname="$(hostname)"
    local message="Service '$service' $action on $hostname at $timestamp"
    
    # Log'a her zaman yaz
    log_message "ALERT: $message"
    
    # Konfigürasyonları yükle
    [[ -f "$CONFIG_FILE" ]] && source "$CONFIG_FILE"
    [[ -f "$NOTIFICATION_CONFIG" ]] && source "$NOTIFICATION_CONFIG"
    
    # E-posta bildirimi
    [[ -n "$EMAIL" ]] && send_email_notification "[Watchdog] $service $action" "$message" "$EMAIL"
    
    # Webhook bildirimi
    [[ -n "$WEBHOOK_URL" ]] && send_webhook_notification "$message" "$WEBHOOK_URL"
    
    # Telegram bildirimi
    [[ -n "$TELEGRAM_BOT_TOKEN" && -n "$TELEGRAM_CHAT_ID" ]] && \
        send_telegram_notification "$message" "$TELEGRAM_BOT_TOKEN" "$TELEGRAM_CHAT_ID"
    
    # Systemd journal
    command -v systemd-cat >/dev/null && \
        echo "WATCHDOG_ALERT: $message" | systemd-cat -t watchdog -p err
    
    print_status "info" "$message"
}

# === Servis Yönetimi ===
get_running_services() {
    systemctl list-units --type=service --state=running --no-pager --no-legend | \
        awk '{print $1}' | grep -E '\.service$' | sort
}

# === Ana İzleme Sistemi ===
monitor_services() {
    # Konfigürasyonu yükle
    if [[ ! -f "$CONFIG_FILE" ]]; then
        print_status "error" "Configuration file not found: $CONFIG_FILE"
        exit 1
    fi
    
    source "$CONFIG_FILE"
    load_language
    
    # PID dosyası oluştur
    create_pid_file
    
    # Temizlik için signal handler
    trap 'remove_pid_file; exit 0' EXIT INT TERM
    
    print_status "success" "$(get_msg "monitoring_started") (PID: $$)"
    log_message "Watchdog v$VERSION started - Monitoring ${#SERVICES[@]} services"
    log_message "Services: ${SERVICES[*]}"
    log_message "Interval: $INTERVAL minutes"
    
    # İlk güncelleme kontrolü
    if [[ "$AUTO_UPDATE_CHECK" == "true" ]]; then
        check_for_updates
    fi
    
    local update_check_counter=0
    
    # Ana izleme döngüsü
    while true; do
        for service in "${SERVICES[@]}"; do
            if ! systemctl is-active --quiet "$service" 2>/dev/null; then
                log_message "Service $service is down, attempting restart..."
                print_status "warning" "Service $service is down, restarting..."
                
                if systemctl start "$service" 2>/dev/null; then
                    log_message "Service $service restarted successfully"
                    print_status "success" "Service $service restarted"
                    send_notification "$service" "restarted"
                else
                    log_message "Failed to restart service $service"
                    print_status "error" "Failed to restart $service"
                    send_notification "$service" "failed to restart"
                fi
            fi
        done
        
        # Sistem durumu kontrolleri
        check_system_health
        
        # Günde bir kez güncelleme kontrolü (24 * 60 / INTERVAL)
        update_check_counter=$((update_check_counter + 1))
        local checks_per_day=$((1440 / INTERVAL))
        if [[ $update_check_counter -ge $checks_per_day ]] && [[ "$AUTO_UPDATE_CHECK" == "true" ]]; then
            check_for_updates
            update_check_counter=0
        fi
        
        sleep "$((INTERVAL * 60))"
    done
}

check_system_health() {
    # CPU yükü kontrolü
    local load_avg=$(uptime | awk -F'load average:' '{print $2}' | cut -d',' -f1 | tr -d ' ')
    if command -v bc >/dev/null && (( $(echo "$load_avg > 10.0" | bc -l) )); then
        log_message "High system load detected: $load_avg"
        send_notification "system" "high load detected ($load_avg)"
    fi
    
    # Disk kullanımı kontrolü
    local disk_usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    if [[ "$disk_usage" -gt 90 ]]; then
        log_message "High disk usage detected: ${disk_usage}%"
        send_notification "system" "high disk usage (${disk_usage}%)"
    fi
    
    # Memory kontrolü
    local mem_usage=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
    if [[ "$mem_usage" -gt 90 ]]; then
        log_message "High memory usage detected: ${mem_usage}%"
        send_notification "system" "high memory usage (${mem_usage}%)"
    fi
}

# === Kurulum Sihirbazı ===
setup_wizard() {
    show_header
    
    # Dil seçimi
    echo -e "${YELLOW}$(get_msg "language_select"):${NC}"
    echo "  [1] English"
    echo "  [2] Türkçe"
    echo -n "Choice [1-2]: "
    read -r lang_choice
    
    case "$lang_choice" in
        2) LANGUAGE="tr" ;;
        *) LANGUAGE="en" ;;
    esac
    
    load_language
    show_header
    
    # Güncelleme kontrolü
    check_for_updates "force"
    
    # Çalışan servisleri listele
    print_status "info" "$(get_msg "found_services")..."
    mapfile -t SERVICES < <(get_running_services)
    
    if [[ ${#SERVICES[@]} -eq 0 ]]; then
        print_status "error" "No running services found!"
        exit 1
    fi
    
    echo
    echo -e "${CYAN}┌──────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│                    Available Services                   │${NC}"
    echo -e "${CYAN}├──────────────────────────────────────────────────────────┤${NC}"
    
    for i in "${!SERVICES[@]}"; do 
        printf "${CYAN}│${NC} [%2d] %-50s ${CYAN}│${NC}\n" "$i" "${SERVICES[$i]}"
    done
    
    echo -e "${CYAN}│${NC} [${GREEN}all${NC}] $(get_msg "select_all")                                     ${CYAN}│${NC}"
    echo -e "${CYAN}└──────────────────────────────────────────────────────────┘${NC}"
    
    echo
    echo -n "$(get_msg "select_services"): "
    read -r input
    
    # Servis seçimi
    SELECTED=()
    if [[ "$input" == "all" ]]; then
        SELECTED=("${SERVICES[@]}")
        print_status "success" "All ${#SERVICES[@]} services selected"
    else
        IFS=',' read -ra IDX <<< "$input"
        for i in "${IDX[@]}"; do 
            i=$(echo "$i" | tr -d ' ')
            if [[ "$i" =~ ^[0-9]+$ ]] && [[ $i -lt ${#SERVICES[@]} ]]; then
                SELECTED+=("${SERVICES[$i]}")
            fi
        done
        print_status "success" "${#SELECTED[@]} services selected"
    fi
    
    # Ekstra servisler
    echo
    echo -n "$(get_msg "extra_services"): "
    read -r extra_input
    if [[ -n "$extra_input" ]]; then
        IFS=',' read -ra EXTRA_SERVICES <<< "$extra_input"
        for service in "${EXTRA_SERVICES[@]}"; do
            service=$(echo "$service" | tr -d ' ')
            [[ -n "$service" ]] && SELECTED+=("$service")
        done
    fi
    
    if [[ ${#SELECTED[@]} -eq 0 ]]; then
        print_status "error" "No services selected!"
        exit 1
    fi
    
    # E-posta kurulumu
    echo
    echo -e "${YELLOW}$(get_msg "email_setup"):${NC}"
    setup_mail_system
    echo -n "$(get_msg "email_prompt"): "
    read -r EMAIL
    
    # Ek bildirim yöntemleri
    echo
    echo -e "${YELLOW}$(get_msg "notification_setup"):${NC}"
    echo "  [1] Discord/Slack Webhook"
    echo "  [2] Telegram Bot"
    echo "  [3] Skip additional notifications"
    echo -n "Choice [1-3]: "
    read -r notification_choice
    
    case "$notification_choice" in
        1)
            echo -n "Discord/Slack Webhook URL: "
            read -r webhook_url
            echo "WEBHOOK_URL=\"$webhook_url\"" > "$NOTIFICATION_CONFIG"
            ;;
        2)
            echo -n "Telegram Bot Token: "
            read -r bot_token
            echo -n "Telegram Chat ID: "
            read -r chat_id
            {
                echo "TELEGRAM_BOT_TOKEN=\"$bot_token\""
                echo "TELEGRAM_CHAT_ID=\"$chat_id\""
            } > "$NOTIFICATION_CONFIG"
            ;;
        *)
            echo "# No additional notifications" > "$NOTIFICATION_CONFIG"
            ;;
    esac
    
    # Otomatik başlatma
    echo
    echo -n "$(get_msg "autostart_prompt") [y/N]: "
    read -r autostart_choice
    AUTOSTART="false"
    [[ "$autostart_choice" =~ ^[Yy] ]] && AUTOSTART="true"
    
    # İzleme aralığı
    echo
    echo -n "$(get_msg "interval_prompt") [$DEFAULT_INTERVAL]: "
    read -r INTERVAL
    [[ "$INTERVAL" =~ ^[0-9]+$ ]] || INTERVAL=$DEFAULT_INTERVAL
    
    # Konfigürasyonu kaydet
    {
        echo "# Watchdog Configuration v$VERSION"
        echo "SERVICES=(${SELECTED[*]})"
        echo "EMAIL=\"$EMAIL\""
        echo "INTERVAL=\"$INTERVAL\""
        echo "LANGUAGE=\"$LANGUAGE\""
        echo "AUTOSTART=\"$AUTOSTART\""
        echo "AUTO_UPDATE_CHECK=\"true\""
        echo "CREATED=\"$(date)\""
    } > "$CONFIG_FILE"
    
    # Systemd servisi oluştur
    create_systemd_service
    
    echo
    print_status "success" "$(get_msg "config_saved")"
    echo
    echo -e "${CYAN}📋 Configuration Summary:${NC}"
    echo "  📦 Services: ${#SELECTED[@]} selected"
    echo "  📧 Email: ${EMAIL:-"Not configured"}"
    echo "  ⏱️  Interval: $INTERVAL minutes"
    echo "  🚀 Auto-start: $AUTOSTART"
    echo "  🔄 Auto-update: enabled"
    echo "  📁 Config: $CONFIG_FILE"
    echo "  📄 Logs: $LOG_FILE"
    
    if [[ "$AUTOSTART" == "true" ]]; then
        sudo systemctl enable watchdog.service
        print_status "success" "Auto-start enabled"
    fi
    
    echo
    echo -e "${GREEN}$(get_msg "service_ready")${NC}"
    echo "  🟢 Start: sudo systemctl start watchdog"
    echo "  📊 Status: sudo systemctl status watchdog"
    echo "  📄 Logs: tail -f $LOG_FILE"
    echo "  🧪 Test: $SCRIPT_PATH --test"
    echo "  🔄 Update: $SCRIPT_PATH --upgrade"
}

create_systemd_service() {
    local service_content="[Unit]
Description=Watchdog Service Monitor v$VERSION
Documentation=https://github.com/$GITHUB_REPO
After=network.target multi-user.target
Wants=network.target

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

[Install]
WantedBy=multi-user.target"
    
    echo "$service_content" | sudo tee /etc/systemd/system/watchdog.service >/dev/null
    sudo systemctl daemon-reload
}

# === Test Sistemi ===
test_notifications() {
    print_status "info" "Testing notification systems..."
    
    [[ -f "$CONFIG_FILE" ]] && source "$CONFIG_FILE"
    [[ -f "$NOTIFICATION_CONFIG" ]] && source "$NOTIFICATION_CONFIG"
    
    send_notification "test-service" "test notification - $(get_msg "test_notification")"
    print_status "success" "Test completed! Check your configured notification channels."
}

# === Durum Kontrolü ===
show_status() {
    show_header
    
    if is_watchdog_running; then
        local pid=$(cat "$PID_FILE")
        print_status "success" "Watchdog is running (PID: $pid)"
        
        if [[ -f "$CONFIG_FILE" ]]; then
            source "$CONFIG_FILE"
            echo
            echo -e "${CYAN}📊 Current Configuration:${NC}"
            echo "  📦 Services: ${#SERVICES[@]} monitored"
            echo "  ⏱️  Interval: $INTERVAL minutes"
            echo "  📧 Email: ${EMAIL:-"Not configured"}"
            echo "  🌐 Language: $LANGUAGE"
            echo "  🔄 Auto-update: ${AUTO_UPDATE_CHECK:-"enabled"}"
            echo "  📄 Log file: $LOG_FILE"
            
            # Son birkaç log girişini göster
            if [[ -f "$LOG_FILE" ]]; then
                echo
                echo -e "${CYAN}📜 Recent Log Entries:${NC}"
                tail -n 5 "$LOG_FILE" | while read -r line; do
                    echo "  $line"
                done
            fi
            
            # Sistem durumu
            echo
            echo -e "${CYAN}🖥️ System Health:${NC}"
            local load_avg=$(uptime | awk -F'load average:' '{print $2}' | cut -d',' -f1 | tr -d ' ')
            local disk_usage=$(df / | awk 'NR==2 {print $5}')
            local mem_usage=$(free | awk 'NR==2{printf "%.0f%%", $3*100/$2}')
            echo "  📈 Load Average: $load_avg"
            echo "  💾 Disk Usage: $disk_usage"
            echo "  🧠 Memory Usage: $mem_usage"
        fi
    else
        print_status "error" "Watchdog is not running"
        echo "  Start with: sudo systemctl start watchdog"
    fi
}

# === Backup ve Restore ===
backup_config() {
    local backup_dir="$HOME/.watchdog_backup_$(date +%F-%H%M%S)"
    mkdir -p "$backup_dir"
    
    [[ -f "$CONFIG_FILE" ]] && cp "$CONFIG_FILE" "$backup_dir/"
    [[ -f "$NOTIFICATION_CONFIG" ]] && cp "$NOTIFICATION_CONFIG" "$backup_dir/"
    [[ -f "$LOG_FILE" ]] && cp "$LOG_FILE" "$backup_dir/"
    
    print_status "success" "Configuration backed up to: $backup_dir"
}

restore_config() {
    local backup_dir="$1"
    
    if [[ ! -d "$backup_dir" ]]; then
        print_status "error" "Backup directory not found: $backup_dir"
        return 1
    fi
    
    [[ -f "$backup_dir/$(basename "$CONFIG_FILE")" ]] && cp "$backup_dir/$(basename "$CONFIG_FILE")" "$CONFIG_FILE"
    [[ -f "$backup_dir/$(basename "$NOTIFICATION_CONFIG")" ]] && cp "$backup_dir/$(basename "$NOTIFICATION_CONFIG")" "$NOTIFICATION_CONFIG"
    
    print_status "success" "Configuration restored from: $backup_dir"
}

# === Detaylı Log Analizi ===
analyze_logs() {
    if [[ ! -f "$LOG_FILE" ]]; then
        print_status "error" "Log file not found: $LOG_FILE"
        return 1
    fi
    
    show_header
    echo -e "${CYAN}📊 Watchdog Log Analysis${NC}"
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
    
    # Toplam restart sayısı
    local total_restarts=$(grep -c "restarted successfully" "$LOG_FILE" 2>/dev/null || echo 0)
    echo -e "${GREEN}✅ Total successful restarts: $total_restarts${NC}"
    
    # Başarısız restart sayısı
    local failed_restarts=$(grep -c "Failed to restart" "$LOG_FILE" 2>/dev/null || echo 0)
    echo -e "${RED}❌ Failed restarts: $failed_restarts${NC}"
    
    # En çok restart edilen servisler
    echo -e "\n${CYAN}🔄 Most restarted services:${NC}"
    grep "restarted successfully" "$LOG_FILE" 2>/dev/null | \
        awk '{print $6}' | sort | uniq -c | sort -nr | head -5 | \
        while read -r count service; do
            echo "  $service: $count times"
        done
    
    # Son 24 saatteki aktivite
    echo -e "\n${CYAN}📅 Last 24 hours activity:${NC}"
    local yesterday=$(date -d "yesterday" +%Y-%m-%d)
    local today=$(date +%Y-%m-%d)
    grep -E "($yesterday|$today)" "$LOG_FILE" 2>/dev/null | tail -10 | \
        while read -r line; do
            echo "  $line"
        done
    
    # Sistem uyarıları
    echo -e "\n${CYAN}⚠️ System alerts:${NC}"
    grep -E "(high load|high disk|high memory)" "$LOG_FILE" 2>/dev/null | tail -5 | \
        while read -r line; do
            echo "  $line"
        done
}

# === Ana Program ===
main() {
    case "${1:-}" in
        "--daemon"|"-d")
            monitor_services
            ;;
        "--test"|"-t")
            test_notifications
            ;;
        "--status"|"-s")
            show_status
            ;;
        "--upgrade"|"-u")
            check_for_updates "force"
            ;;
        "--backup")
            backup_config
            ;;
        "--restore")
            restore_config "$2"
            ;;
        "--logs"|"-l")
            analyze_logs
            ;;
        "--stop")
            if is_watchdog_running; then
                local pid=$(cat "$PID_FILE")
                kill "$pid" 2>/dev/null
                remove_pid_file
                print_status "success" "Watchdog stopped"
            else
                print_status "info" "Watchdog is not running"
            fi
            ;;
        "--version"|"-v")
            echo "Watchdog v$VERSION"
            ;;
        "--help"|"-h")
            show_header
            echo "Usage: $SCRIPT_NAME [OPTION]"
            echo ""
            echo "Options:"
            echo "  (no args)     Run setup wizard"
            echo "  -d, --daemon  Run as daemon (monitoring mode)"
            echo "  -t, --test    Test notifications"
            echo "  -s, --status  Show current status"
            echo "  -u, --upgrade Check for updates and upgrade"
            echo "  -l, --logs    Analyze logs"
            echo "  --backup      Backup configuration"
            echo "  --restore DIR Restore configuration from backup"
            echo "  --stop        Stop running watchdog"
            echo "  -v, --version Show version"
            echo "  -h, --help    Show this help"
            echo ""
            echo "SystemD Commands:"
            echo "  sudo systemctl start watchdog    Start service"
            echo "  sudo systemctl stop watchdog     Stop service"
            echo "  sudo systemctl status watchdog   Show status"
            echo "  sudo systemctl enable watchdog   Enable auto-start"
            echo ""
            echo "Features:"
            echo "  🔄 Auto-update system"
            echo "  📧 Multiple notification methods"
            echo "  🖥️ System health monitoring"
            echo "  📊 Log analysis"
            echo "  💾 Configuration backup/restore"
            ;;
        *)
            # Kurulum modu
            check_dependencies
            init_language_system
            
            if is_watchdog_running; then
                show_status
                echo
                print_status "warning" "Watchdog is already running. Stop it first if you want to reconfigure."
                echo "  Stop with: sudo systemctl stop watchdog"
                exit 1
            fi
            
            setup_wizard
            ;;
    esac
}

# Script'i çalıştır
main "$@"
