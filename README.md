# Watchdog

**Watchdog** is a lightweight Linux monitoring tool that checks the status of selected system services, restarts them if they crash, and notifies the administrator via email.

## Features

- Monitors selected services and restarts if needed  
- Detects high CPU/RAM usage and alerts  
- Watches for sudden Nginx/PHP traffic spikes  
- Sends email notifications  
- Auto-updates from GitHub  
- Multilingual support (English & Turkish)  
- Lightweight and panel-agnostic  

## Installation

```bash
git clone https://github.com/slaweally/Watchdog.git
cd Watchdog
chmod +x watchdog.sh
./watchdog.sh
```

During initial setup:

- Choose language (English/Turkish)  
- Select running services to monitor  
- Add optional custom services  
- Provide an email address for alerts  
- Set monitoring interval (in minutes)

## Starting the Watchdog Service

```bash
sudo systemctl start watchdog
sudo systemctl status watchdog
```

## Self-Updating

Watchdog can check for the latest version online and update itself automatically if a newer release is found.

## Files and Configuration

- `~/.watchdog.conf` : User configuration (services, email, interval)
- `/var/log/watchdog.log` : Log file with status messages
- `/etc/systemd/system/watchdog.service` : Systemd unit definition

## Requirements

- Bash 5+
- `mailutils` package (for email support)

Install on Debian/Ubuntu:

```bash
sudo apt install mailutils
```

## Contributing

Suggestions, bug reports, and pull requests are welcome.  
If you find this project helpful, please consider starring it.

## License

MIT License.
---
# Watchdog

**Watchdog**, Linux sunucularda çalışan sistem servislerini izlemek, kapanmaları durumunda yeniden başlatmak ve yöneticiyi e-posta ile bilgilendirmek üzere tasarlanmış hafif bir servis denetim aracıdır.  

## Özellikler

- Seçilen servisleri izler ve yeniden başlatır  
- Kaynak tüketimi (CPU/RAM) yüksek servisleri algılar  
- Nginx ve PHP gibi yaygın servislerde trafik artışını tespit eder  
- Mail ile uyarı bildirimi gönderir  
- GitHub üzerinden kendi kendini güncelleyebilir  
- Çoklu dil desteği (Türkçe ve İngilizce)  
- Tek dosyalık kurulum, panel bağımsız yapı  

## Kurulum

```bash
git clone https://github.com/slaweally/Watchdog.git
cd Watchdog
chmod +x watchdog.sh
./watchdog.sh
```

İlk çalıştırmada sistem size:

- Dil seçimi (Türkçe/İngilizce)
- İzlenecek servisleri seçme
- Ekstra servis ekleme
- E-posta adresi girme
- Kontrol sıklığı belirleme

gibi seçenekleri sunarak yapılandırmayı tamamlar.

## Servisi Başlatma

```bash
sudo systemctl start watchdog
sudo systemctl status watchdog
```

## Güncelleme

Watchdog kendisini otomatik olarak güncelleyebilir. Yeni bir sürüm tespit ettiğinde GitHub’dan indirerek betiği yeniler, servisle birlikte devam eder.

## Yapılandırma Dosyaları

- `~/.watchdog.conf` : Betik ayarları (servis listesi, e-posta, dil)
- `/var/log/watchdog.log` : Servis geçmişi ve uyarı kayıtları
- `/etc/systemd/system/watchdog.service` : Systemd servis tanımı  

## Gereksinimler

- Bash 5+
- `mail` komutu için `mailutils` paketi (Debian/Ubuntu'da)
  
```bash
sudo apt install mailutils
```

## Katkı ve Destek

Yeni özellik önerilerinizi, hata bildirimlerinizi ve katkılarınızı GitHub üzerinden paylaşabilirsiniz.  
Projeyi faydalı bulduysanız yıldız vermeyi unutmayın.

## Lisans

MIT Lisansı.
