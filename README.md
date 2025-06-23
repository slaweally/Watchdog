## 🐾 Watchdog

**Linux Servis İzleyicisi** — panel bağımsız, hafif ve akıllı otomasyon betiği.  
Belirlediğiniz servisleri düzenli aralıklarla kontrol eder, kapananları otomatik başlatır ve yöneticiyi e-posta ile bilgilendirir.

> 📡 Uptime sağlama artık sistem yöneticisinin kâbusu olmaktan çıkıyor.

---

### 🚀 Özellikler

- 🎛️ Kurulum sırasında etkileşimli servis seçimi
- ✉️ Mail bildirimi (örn. `mailutils`)
- 🔁 Kapanan servisi otomatik başlatma
- 📅 Zamanlanmış izleme (varsayılan: 15 dakika)
- 🧠 Panel bağımsız: CloudPanel, Plesk, cPanel, aaPanel uyumlu
- 🔐 Kendi kendini başlatan `systemd` servisi

---

### 🧑‍💻 Kurulum

> Bash 5+ ve `mail` komutu için `mailutils` önerilir.

```bash
git clone https://github.com/slaweally/Watchdog.git
cd Watchdog
chmod +x watchdog.sh
./watchdog.sh
```

İlk çalıştırmada:
- Çalışan servisleri listeler
- İzlenecekleri seçmenizi ister
- E-posta adresinizi alır
- Ayarları kaydeder, `systemd` servisini oluşturur

---

### ⚙️ Servisi Yönetme

```bash
sudo systemctl start watchdog
sudo systemctl status watchdog
sudo journalctl -u watchdog -f
```

---

### 🪵 Loglar ve Ayarlar

- İzleme logları: `/var/log/watchdog.log`
- Konfigürasyon: `~/.watchdog.conf`
- Servis dosyası: `/etc/systemd/system/watchdog.service`

---

### 📬 E-posta Bildirimi

> Betik kapanan bir servis tespit ettiğinde `mail` ile sizi uyarır.

Kurulum (Debian/Ubuntu):
```bash
sudo apt install mailutils
```

---

### 📢 Katkı ve Geliştirme

PR’lar, yeni özellik önerileri ve yıldızlar ✨ her zaman hoş karşılanır!  
Gelecek sürümlerde:
- Webhook/Discord entegrasyonu
- Çökme sayacı ve analizleri
- GUI betik yönetimi (opsiyonel)

---

### 🛡️ Lisans

MIT — özgürce kullan, dağıt, geliştir.  
Sisteminizi koruyun, hizmetiniz durmasın 
