# Watchdog || Universal Linux Service Monitor
**Watchdog** is a comprehensive Linux service monitoring and auto-recovery system that monitors system services, restarts them if they crash, and provides multiple notification methods including email, webhooks, and real-time alerts.

[![License: MIT]

##  Features

### 🔧 **Core Monitoring**
- ✅ **Service Monitoring**: Monitors selected system services and auto-restarts on failure
- ✅ **"Select All" Option**: Quick selection of all running services during setup
- ✅ **System Health**: CPU load, RAM usage, and disk space monitoring
- ✅ **Smart Recovery**: Intelligent restart mechanisms with failure tracking

###  **Multi-Channel Notifications**
- ✅ **Email**: Built-in mail system with auto-setup (sendmail/mailutils)
- ✅ **Discord/Slack**: Webhook notifications
- ✅ **Telegram**: Bot-based instant messaging
- ✅ **System Logs**: Integration with systemd journal

###  **Advanced Features**
- ✅ **Auto-Update**: Self-updating from GitHub with version checking
- ✅ **PID Management**: Single-instance protection with proper PID handling
- ✅ **Backup/Restore**: Configuration backup and restore capabilities
- ✅ **Log Analysis**: Detailed log analysis and reporting
- ✅ **Multilingual**: English and Turkish language support
- ✅ **Auto-Start**: Optional system boot integration

### **Enterprise Ready**
- ✅ **Single File**: No external dependencies, portable
- ✅ **Systemd Integration**: Full systemd service support
- ✅ **Security**: Safe restart mechanisms and error handling
- ✅ **Lightweight**: Minimal resource usage

##  Quick Installation

```bash
# Download the latest version
curl -O https://raw.githubusercontent.com/slaweally/Watchdog/main/watchdog.sh
chmod +x watchdog.sh

# Run setup wizard
./watchdog.sh
```

**Alternative (Git clone):**
```bash
git clone https://github.com/slaweally/Watchdog.git
cd Watchdog
chmod +x watchdog.sh
./watchdog.sh
```

##  Setup Wizard

During the interactive setup, you'll configure:

1. ** Language Selection**: English or Turkish
2. ** Service Selection**: 
   - Individual services: `1,2,5,8`
   - All services: `all`
   - Custom services: Add manually
3. ** Email Configuration**: Automatic mail system setup
4. ** Additional Notifications**: Discord, Slack, Telegram
5. ** Auto-Start**: Enable automatic startup on boot
6. ** Monitoring Interval**: Check frequency in minutes

##  Usage Commands

### **Basic Operations**
```bash
./watchdog.sh              # Run setup wizard
./watchdog.sh --status     # Show current status
./watchdog.sh --test       # Test notifications
./watchdog.sh --upgrade    # Check for updates
```

### **Service Management**
```bash
sudo systemctl start watchdog    # Start monitoring
sudo systemctl stop watchdog     # Stop monitoring  
sudo systemctl status watchdog   # Check status
sudo systemctl enable watchdog   # Enable auto-start
```

### **Advanced Features**
```bash
./watchdog.sh --logs       # Analyze logs and statistics
./watchdog.sh --backup     # Backup configuration
./watchdog.sh --restore    # Restore from backup
./watchdog.sh --help       # Show all options
```

### **Log Monitoring**
```bash
tail -f ~/watchdog.log            # Live log monitoring
journalctl -u watchdog -f         # Systemd logs
```

##  Sample Configuration

After setup, your configuration will include:

```bash
# ~/.watchdog.conf
SERVICES=(nginx.service mysql.service ssh.service)
EMAIL="admin@example.com"
INTERVAL="15"
LANGUAGE="en"
AUTOSTART="true"
AUTO_UPDATE_CHECK="true"
```

##  Notification Setup Examples

### **Discord/Slack Webhook**
1. Create a webhook in your Discord server or Slack workspace
2. Copy the webhook URL
3. Enter during setup or configure manually

### **Telegram Bot**
1. Create a bot via [@BotFather](https://t.me/botfather)
2. Get your Chat ID: `https://api.telegram.org/bot<TOKEN>/getUpdates`
3. Enter bot token and chat ID during setup

### **Email Configuration**
- **Ubuntu/Debian**: `sudo apt install mailutils postfix`
- **CentOS/RHEL**: `sudo yum install mailx postfix`
- The script will auto-configure basic mail functionality

##  Monitoring Capabilities

### **Service Monitoring**
- Automatic restart of failed services
- Configurable check intervals
- Failure tracking and reporting

### **System Health Monitoring**
- **CPU Load**: Alerts when load > 10.0
- **Memory Usage**: Alerts when RAM > 90%
- **Disk Space**: Alerts when disk > 90%

### **Log Analysis**
- Total restart statistics
- Most problematic services
- 24-hour activity reports
- System alert history

##  File Structure

```
~/.watchdog.conf              # Main configuration
~/.watchdog_notifications.conf # Notification settings
~/watchdog.log               # Activity logs
~/.watchdog.pid              # Process ID file
~/.watchdog_last_update_check # Update tracking
```

##  System Requirements

- **OS**: Linux (any distribution)
- **Shell**: Bash 5+
- **Tools**: `systemctl`, `curl` or `wget`
- **Optional**: `mailutils` for email support

### **Installation on Different Systems**

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install curl mailutils
```

**CentOS/RHEL:**
```bash
sudo yum install curl mailx
```

**Arch Linux:**
```bash
sudo pacman -S curl mailutils
```

##  Auto-Update System

Watchdog includes an intelligent auto-update system:

- **Daily Checks**: Automatically checks for new versions
- **GitHub Integration**: Downloads updates directly from repository
- **Safe Updates**: Creates backups before updating
- **Service Continuity**: Maintains monitoring during updates

Force update check:
```bash
./watchdog.sh --upgrade
```

##  Security Features

- **PID Protection**: Prevents multiple instances
- **Safe Restarts**: Controlled service restart mechanisms  
- **Log Rotation**: Automatic log management
- **Permission Handling**: Proper user/group permissions
- **Signal Handling**: Graceful shutdown on system signals

##  Beautiful Interface

Watchdog features a modern, colorful terminal interface with:
- **ASCII Art Logo**: Professional branding
- **Color-Coded Status**: Easy visual feedback
- **Progress Indicators**: Clear setup progress
- **Formatted Tables**: Organized service listings

##  Advanced Configuration

### **Custom Service Addition**
```bash
# Add custom services during setup
Extra services: custom-app.service, docker.service, custom-daemon
```

### **Notification Customization**
```bash
# Manual notification configuration
echo 'WEBHOOK_URL="https://discord.com/api/webhooks/..."' >> ~/.watchdog_notifications.conf
```

### **Monitoring Interval Tuning**
- **High-Critical**: 5-10 minutes
- **Standard**: 15-30 minutes  
- **Low-Priority**: 60+ minutes

##  Log Analysis Features

The built-in log analyzer provides:

- ** Restart Statistics**: Total successful/failed restarts
- ** Service Rankings**: Most problematic services
- ** Activity Timeline**: Recent 24-hour activity
- ** System Alerts**: Health monitoring alerts
- ** Detailed Reports**: Comprehensive system overview

##  Contributing

We welcome contributions! Here's how you can help:

-  **Bug Reports**: Submit issues with detailed descriptions
-  **Feature Requests**: Suggest new capabilities
-  **Pull Requests**: Submit code improvements
-  **Documentation**: Help improve guides and examples
-  **Star the Project**: Show your support

##  License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

##  Support

- **GitHub Issues**: [Report bugs or request features](https://github.com/slaweally/Watchdog/issues)
- **Discussions**: [Community discussions and help](https://github.com/slaweally/Watchdog/discussions)
- **Documentation**: Check this README and inline help (`--help`)

##  Acknowledgments

- Built for system administrators and DevOps engineers
- Inspired by the need for reliable service monitoring
- Designed for simplicity and effectiveness

---

⭐ **If you find Watchdog helpful, please consider starring the repository!**

[![GitHub stars](https://img.shields.io/github/stars/slaweally/Watchdog?style=social)](https://github.com/slaweally/Watchdog/stargazers)
