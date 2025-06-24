#!/bin/bash

echo "🔧 Watchdog sistem güncellemesi başlatılıyor..."

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$BASE_DIR"

# Yedek al
echo "📦 Mevcut dosyalar yedekleniyor..."
cp -r "$BASE_DIR" "${BASE_DIR}-backup-$(date +%F-%H%M%S)"

# Güncelle
echo "⬇️ GitHub'dan son sürüm çekiliyor..."
git reset --hard HEAD
git pull origin main

# İzinler
echo "🛡️ Dosya izinleri güncelleniyor..."
chmod +x watchdog.sh
chmod +x modules/*.sh

# Servis yeniden başlatılıyor
echo "🚀 Watchdog servisi yeniden başlatılıyor..."
sudo systemctl restart watchdog

echo "✅ Güncelleme tamamlandı. Versiyon kontrolü için:"
echo "   bash update.sh"
