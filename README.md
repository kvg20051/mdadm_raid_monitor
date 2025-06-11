# MDADM RAID Monitor with Telegram Notifications

A simple bash script that monitors your MDADM RAID arrays and sends notifications via Telegram when issues are detected, such as drive failures or array status changes.

## System Requirements

- Linux system with software RAID (mdadm)
- Bash shell
- `curl` for Telegram API communication
- Root access (for monitoring RAID status)
- Telegram bot token and chat ID
- System with cron daemon installed

### Required Commands
The script requires these commands to be available:
```bash
mdadm    # For RAID management
curl     # For Telegram notifications
grep     # For text processing
awk      # For text processing
sed      # For text processing
```

## Features

- Monitors RAID array status and health
- Sends Telegram notifications for:
  - Drive failures
  - Array status changes
  - New arrays detected
  - Arrays no longer detected
- Lightweight bash implementation (no Python required)
- Designed to run from cron
- Persistent state tracking to avoid duplicate notifications

## Requirements

- Root privileges (required to read `/proc/mdstat`)
- `curl` command-line tool (for sending Telegram messages)
- Write access to either `/var/log` or user's home directory (for logging)

## Installation

1. Download the script:
   ```bash
   wget https://raw.githubusercontent.com/yourusername/raid-monitor/main/raid_monitor.sh
   ```

2. Make the script executable:
   ```bash
   chmod +x raid_monitor.sh
   ```

3. Test the script (requires root):
   ```bash
   sudo ./raid_monitor.sh
   ```

4. Set up a cron job to run the script periodically (e.g., every 5 minutes).

   You have two options:

   a. Using root's crontab (recommended):
   ```bash
   sudo crontab -e
   ```
   Add this line:
   ```
   */5 * * * * /full/path/to/raid_monitor.sh
   ```

   b. Using user's crontab with sudo (less secure):
   ```bash
   crontab -e
   ```
   Add this line:
   ```
   */5 * * * * sudo /full/path/to/raid_monitor.sh
   ```

   Note: The first option (root's crontab) is recommended because:
   - It's more secure (no need to configure sudo permissions)
   - It's cleaner (no sudo prompts or password requirements)
   - It's the proper way to run system monitoring tasks

## Configuration

If you need to change these, edit the script and update the values at the top:
```bash
TELEGRAM_BOT_TOKEN="your_bot_token"
TELEGRAM_CHAT_ID="your_chat_id"
```

## Logging

The script logs its activity to:
- `/var/log/raid_monitor.log` (if writable)
- `$HOME/raid_monitor.log` (fallback)

You can monitor the logs with:
```bash
sudo tail -f /var/log/raid_monitor.log
# or if using the fallback location
tail -f ~/raid_monitor.log
```

## State Tracking

The script maintains its state in:
- `/var/run/raid_monitor.state`

This file is used to track changes and avoid sending duplicate notifications.

## Notifications

The monitor sends the following types of notifications:

- **Urgent Alerts** (🚨):
  - Drive failures
  - Array status changes to non-active
  - Arrays no longer detected

- **Status Updates** (ℹ️):
  - New arrays detected
  - Drive recovery
  - Array status changes to active
  - Initial status when the monitor starts

## Troubleshooting

If you're not receiving notifications:

1. Check if the script is running:
   ```bash
   sudo ps aux | grep raid_monitor.sh
   ```

2. Check the logs:
   ```bash
   sudo cat /var/log/raid_monitor.log
   # or if using the fallback location
   cat ~/raid_monitor.log
   ```

3. Verify the cron job is active:
   ```bash
   # If using root's crontab
   sudo crontab -l
   # If using user's crontab
   crontab -l
   ```

4. Test the script manually:
   ```bash
   sudo ./raid_monitor.sh
   ```

5. Ensure the bot token and chat ID are correct in the script.

6. Check if you have the required permissions:
   ```bash
   # Check if you can read /proc/mdstat
   sudo cat /proc/mdstat
   
   # Check if you can write to the log location
   sudo touch /var/log/raid_monitor.log
   # or
   touch ~/raid_monitor.log
   ```

## Uninstallation

To remove the RAID monitor:

1. Remove the cron job:
   ```bash
   # If using root's crontab
   sudo crontab -e
   # If using user's crontab
   crontab -e
   ```
   (Delete the line that runs raid_monitor.sh)

2. Remove the script and state file:
   ```bash
   sudo rm /path/to/raid_monitor.sh
   sudo rm /var/run/raid_monitor.state
   ```

# RAID Monitor with Telegram Notifications

A bash script that monitors RAID arrays and sends notifications via Telegram when issues are detected.

## System Requirements

- Linux system with software RAID (mdadm)
- Bash shell
- `curl` for Telegram API communication
- Root access (for monitoring RAID status)
- Telegram bot token and chat ID
- System with cron daemon installed

### Required Commands
The script requires these commands to be available:
```bash
mdadm    # For RAID management
curl     # For Telegram notifications
grep     # For text processing
awk      # For text processing
sed      # For text processing
```

## Features

- Monitors all RAID arrays in the system
- Sends Telegram notifications for:
  - Array status changes
  - Drive failures
  - Array recovery
  - New arrays detected
  - Removed arrays
- Detailed logging with timestamps
- Color-coded console output
- State tracking to avoid duplicate notifications

## Installation

1. Clone this repository or download the script:
   ```bash
   git clone https://github.com/yourusername/raid-monitor.git
   cd raid-monitor
   ```

2. Install required packages (if not already installed):
   ```bash
   # For Debian/Ubuntu
   sudo apt-get update
   sudo apt-get install mdadm curl

   # For RHEL/CentOS
   sudo yum install mdadm curl
   ```

3. Create a configuration file in one of these locations:
   ```bash
   # Option 1: Same directory as script
   sudo cp raid_monitor.conf.example raid_monitor.conf
   
   # Option 2: System-wide config
   sudo cp raid_monitor.conf.example /opt/raid_monitor.conf
   
   # Option 3: System config directory
   sudo cp raid_monitor.conf.example /etc/raid_monitor.conf
   ```

4. Edit the configuration file with your Telegram settings:
   ```bash
   # If using local config
   sudo nano raid_monitor.conf
   
   # If using system-wide config
   sudo nano /opt/raid_monitor.conf
   
   # If using system config
   sudo nano /etc/raid_monitor.conf
   ```
   
   Add your Telegram bot token and chat ID:
   ```bash
   TELEGRAM_BOT_TOKEN="your_bot_token_here"
   TELEGRAM_CHAT_ID="your_chat_id_here"
   ```

5. Set proper permissions:
   ```bash
   # For local config
   sudo chown root:root raid_monitor.conf
   sudo chmod 600 raid_monitor.conf
   
   # For system-wide config
   sudo chown root:root /opt/raid_monitor.conf
   sudo chmod 600 /opt/raid_monitor.conf
   
   # For system config
   sudo chown root:root /etc/raid_monitor.conf
   sudo chmod 600 /etc/raid_monitor.conf
   ```

6. Make the script executable:
   ```bash
   sudo chmod +x raid_monitor.sh
   ```

7. Test the script:
   ```bash
   sudo ./raid_monitor.sh
   ```

## Setting up Telegram Bot

1. Create a new bot using [@BotFather](https://t.me/botfather) on Telegram
2. Get your chat ID by:
   - Starting a chat with your bot
   - Sending a message to the bot
   - Visiting: `https://api.telegram.org/bot<YourBOTToken>/getUpdates`
   - Look for the "chat" object in the response, which contains your "id"

## Configuration

The script uses a configuration file for settings. The script will look for the config file in these locations (in order):
1. Same directory as the script (`raid_monitor.conf`)
2. System-wide config (`/opt/raid_monitor.conf`)
3. System config directory (`/etc/raid_monitor.conf`)

### Configuration Options

- `TELEGRAM_BOT_TOKEN`: Your Telegram bot token
- `TELEGRAM_CHAT_ID`: Your Telegram chat ID
- `LOG_FILE`: (Optional) Custom log file location
- `STATE_FILE`: (Optional) Custom state file location

### Security

- The configuration file should be readable only by the root user (600 permissions)
- The script should be executable by root (755 permissions)
- The log file should be writable by root (644 permissions)
- The state file should be readable/writable by root (600 permissions)

## Setting up Cron Job

1. Set up a cron job to run the script periodically (e.g., every 5 minutes).

   You have two options:

   a. Using root's crontab (recommended):
   ```bash
   sudo crontab -e
   ```
   Add this line:
   ```
   */5 * * * * /full/path/to/raid_monitor.sh
   ```

   b. Using user's crontab with sudo (less secure):
   ```bash
   crontab -e
   ```
   Add this line:
   ```
   */5 * * * * sudo /full/path/to/raid_monitor.sh
   ```

   Note: The first option (root's crontab) is recommended because:
   - It's more secure (no need to configure sudo permissions)
   - It's cleaner (no sudo prompts or password requirements)
   - It's the proper way to run system monitoring tasks

## Backup and Maintenance

### Backup Recommendations

1. Backup your configuration:
   ```bash
   # Create a backup directory
   sudo mkdir -p /etc/raid-monitor/backup
   
   # Backup config and script
   sudo cp /opt/raid_monitor.conf /etc/raid-monitor/backup/
   sudo cp /opt/raid_monitor.sh /etc/raid-monitor/backup/
   ```

2. Backup your state file (if modified):
   ```bash
   sudo cp /var/lib/raid_monitor/state /etc/raid-monitor/backup/
   ```

3. Backup your log file (optional):
   ```bash
   sudo cp /var/log/raid_monitor.log /etc/raid-monitor/backup/
   ```

### Log Rotation

To prevent log files from growing too large, set up log rotation:

1. Create a logrotate configuration:
   ```bash
   sudo nano /etc/logrotate.d/raid_monitor
   ```

2. Add the following configuration:
   ```
   /var/log/raid_monitor.log {
       daily
       rotate 7
       compress
       delaycompress
       missingok
       notifempty
       create 644 root root
   }
   ```

### Regular Maintenance

1. Check script status:
   ```bash
   # Verify cron job is running
   sudo systemctl status cron
   
   # Check recent logs
   sudo tail -n 50 /var/log/raid_monitor.log
   
   # Verify Telegram notifications
   # Send a test message to your bot
   ```

2. Monitor disk space:
   ```bash
   # Check log file size
   du -h /var/log/raid_monitor.log
   
   # Check state file size
   du -h /var/lib/raid_monitor/state
   ```

3. Update script (if needed):
   ```bash
   # Backup current version
   sudo cp raid_monitor.sh raid_monitor.sh.bak
   
   # Update script
   # (Copy new version or git pull)
   
   # Test new version
   sudo ./raid_monitor.sh
   ```

## Security Considerations

1. File Permissions:
   - Config file should be root-owned and 600 permissions
   - Script should be root-owned and 755 permissions
   - Log file should be root-owned and 644 permissions
   - State file should be root-owned and 600 permissions

2. Telegram Security:
   - Keep your bot token secure
   - Regularly rotate your bot token if possible
   - Use a dedicated bot for monitoring
   - Consider using a private Telegram channel for notifications

3. System Security:
   - Run the script as root (required for RAID monitoring)
   - Keep your system and mdadm updated
   - Regularly audit log files for suspicious activity
   - Use a dedicated system user for the bot if possible

## Troubleshooting

### Common Issues and Solutions

1. Script not running:
   - Check cron daemon: `systemctl status cron`
   - Verify script permissions: `ls -l raid_monitor.sh`
   - Check cron logs: `sudo grep CRON /var/log/syslog`
   - Test script manually: `sudo ./raid_monitor.sh`

2. No Telegram notifications:
   - Verify config file exists and has correct permissions
   - Check config file location (script looks in multiple places)
   - Verify bot token: `curl -s "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getMe"`
   - Check chat ID: Send a message to your bot and check getUpdates
   - Verify internet connectivity: `ping api.telegram.org`
   - Check script logs for Telegram errors

## Support

If you encounter any issues:
1. Check the troubleshooting section
2. Review the logs: `sudo tail -f /var/log/raid_monitor.log`
3. Verify your RAID configuration: `cat /proc/mdstat`
4. Test Telegram connectivity: `curl -s "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getMe"`

## License

This project is licensed under the MIT License - see the LICENSE file for details. 