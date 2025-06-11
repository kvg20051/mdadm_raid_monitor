# MDADM RAID Monitor with Telegram Notifications

A simple bash script that monitors your MDADM RAID arrays and sends notifications via Telegram when issues are detected, such as drive failures or array status changes.

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

2. Create a configuration file:
   ```bash
   cp raid_monitor.conf.example raid_monitor.conf
   ```

3. Edit the configuration file with your Telegram settings:
   ```bash
   nano raid_monitor.conf
   ```
   Add your Telegram bot token and chat ID:
   ```bash
   TELEGRAM_BOT_TOKEN="your_bot_token_here"
   TELEGRAM_CHAT_ID="your_chat_id_here"
   ```

4. Make the script executable:
   ```bash
   chmod +x raid_monitor.sh
   ```

5. Test the script:
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

The script uses a configuration file (`raid_monitor.conf`) for sensitive settings. This file should be kept secure and not committed to version control.

### Configuration Options

- `TELEGRAM_BOT_TOKEN`: Your Telegram bot token
- `TELEGRAM_CHAT_ID`: Your Telegram chat ID
- `LOG_FILE`: (Optional) Custom log file location
- `STATE_FILE`: (Optional) Custom state file location

### Security

- The configuration file should be readable only by the root user:
  ```bash
  sudo chown root:root raid_monitor.conf
  sudo chmod 600 raid_monitor.conf
  ```

## Setting up Cron Job

There are two ways to set up the cron job:

### Method 1: Using /etc/cron.d/ (Recommended)

This method is more secure and follows system administration best practices:

1. Create a new cron file:
   ```bash
   # Get the absolute path to the script
   readlink -f raid_monitor.sh
   
   # Create the cron file (replace with your actual script path)
   echo "*/5 * * * * /path/to/raid_monitor.sh" | sudo tee /etc/cron.d/raid_monitor
   
   # Set proper permissions
   sudo chmod 644 /etc/cron.d/raid_monitor
   ```

2. Verify the cron job is set up:
   ```bash
   sudo crontab -l | cat
   ```

### Method 2: Using crontab -e

Alternatively, you can use the traditional crontab method:

1. Edit the root crontab:
   ```bash
   sudo crontab -e
   ```

2. Add the following line (replace with your actual script path):
   ```
   */5 * * * * /path/to/raid_monitor.sh
   ```

### Verifying the Cron Job

1. Check if the cron daemon is running:
   ```bash
   systemctl status cron
   ```

2. Monitor the log file to see if the script is running:
   ```bash
   sudo tail -f /var/log/raid_monitor.log
   ```

3. You should see entries every 5 minutes like:
   ```
   2025-06-11 16:35:00 - [INFO] - === RAID Monitor Started ===
   2025-06-11 16:35:00 - [INFO] - Starting RAID status check
   ...
   2025-06-11 16:35:00 - [INFO] - === RAID Monitor Completed ===
   ```

### Troubleshooting Cron

If the script isn't running via cron:

1. Check cron logs:
   ```bash
   sudo grep CRON /var/log/syslog
   ```

2. Verify script permissions:
   ```bash
   ls -l raid_monitor.sh
   sudo chmod +x raid_monitor.sh  # Make sure it's executable
   ```

3. Verify config file permissions:
   ```bash
   ls -l raid_monitor.conf
   # Should show: -rw------- 1 root root
   ```

4. Test the script manually:
   ```bash
   sudo ./raid_monitor.sh
   ```

5. Check if the script path in cron is absolute:
   ```bash
   # Use this to get the absolute path
   readlink -f raid_monitor.sh
   ```

## Logging

The script logs all activities to `/var/log/raid_monitor.log` by default. The log includes:
- Script start and completion
- RAID array status
- Health information
- Telegram notifications
- Errors and warnings

## Troubleshooting

1. Check if the script has execute permissions:
   ```bash
   ls -l raid_monitor.sh
   ```

2. Verify the configuration file exists and has correct permissions:
   ```bash
   ls -l raid_monitor.conf
   ```

3. Check the log file for errors:
   ```bash
   sudo tail -f /var/log/raid_monitor.log
   ```

4. Test Telegram connectivity:
   ```bash
   curl -s "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getMe"
   ```

## License

This project is licensed under the MIT License - see the LICENSE file for details. 
