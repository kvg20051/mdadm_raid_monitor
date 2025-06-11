#!/bin/bash

# RAID Monitor Script with Telegram Notifications
# Designed to run from cron (e.g., */5 * * * * /path/to/raid_monitor.sh)

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Default configuration file location
CONFIG_FILE="${SCRIPT_DIR}/raid_monitor.conf"

# Try to load from config file first
if [ -f "$CONFIG_FILE" ]; then
    if ! source "$CONFIG_FILE"; then
        echo "Error: Failed to load configuration file"
        exit 1
    fi
fi

# If variables are not set from config file, try environment variables
if [ -z "$TELEGRAM_BOT_TOKEN" ] || [ -z "$TELEGRAM_CHAT_ID" ]; then
    # Try to source .bashrc to get environment variables
    if [ -f "$HOME/.bashrc" ]; then
        # Only source the specific variables we need
        TELEGRAM_BOT_TOKEN=$(grep "^export TELEGRAM_BOT_TOKEN=" "$HOME/.bashrc" | cut -d'"' -f2)
        TELEGRAM_CHAT_ID=$(grep "^export TELEGRAM_CHAT_ID=" "$HOME/.bashrc" | cut -d'"' -f2)
    fi
fi

# Validate required configuration
if [ -z "$TELEGRAM_BOT_TOKEN" ] || [ -z "$TELEGRAM_CHAT_ID" ]; then
    echo "Error: TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID must be set in either:"
    echo "1. $CONFIG_FILE"
    echo "2. Environment variables (e.g., in .bashrc)"
    exit 1
fi

# Get hostname
HOSTNAME=$(hostname -s)

# Color codes for console output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Color mapping for log levels
declare -A LOG_COLORS
LOG_COLORS=(
    ["INFO"]="${GREEN}"
    ["WARNING"]="${YELLOW}"
    ["ERROR"]="${RED}"
    ["ALERT"]="${MAGENTA}"
)

# Log file
LOG_FILE="/var/log/raid_monitor.log"
STATE_FILE="/var/run/raid_monitor.state"

# Ensure log directory exists and is writable
if [ ! -w "$(dirname "$LOG_FILE")" ]; then
    # Fallback to user's home directory if /var/log is not writable
    LOG_FILE="$HOME/raid_monitor.log"
    log "WARNING" "Warning: /var/log not writable, using fallback log location: $LOG_FILE"
fi

# Log function with timestamp and log level
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Write to log file (plain text)
    echo "$timestamp - [$level] - $message" >> "$LOG_FILE"
    
    # Print to console with colors if running interactively
    if [ -t 1 ]; then
        local color="${LOG_COLORS[$level]:-${NC}}"
        echo -e "${BLUE}$timestamp${NC} - ${color}[$level]${NC} - $message"
    fi
}

# Send Telegram message
send_telegram() {
    local message="$1"
    local urgent="$2"
    
    # Add hostname and urgency indicator
    if [ "$urgent" = "true" ]; then
        message="🚨 *${HOSTNAME}* RAID Alert: $message"
        log "ALERT" "Sending urgent Telegram alert"
    else
        message="ℹ️ *${HOSTNAME}* RAID: $message"
        log "INFO" "Sending Telegram status update"
    fi
    
    # URL encode the message
    message=$(echo "$message" | sed 's/ /%20/g; s/\n/%0A/g; s/\*/%2A/g; s/_/%5F/g; s/\[/%5B/g; s/\]/%5D/g')
    
    # Send to Telegram
    if curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
         -d "chat_id=${TELEGRAM_CHAT_ID}" \
         -d "text=${message}" \
         -d "parse_mode=Markdown" > /dev/null; then
        log "INFO" "Telegram message sent successfully"
    else
        log "ERROR" "Failed to send Telegram message"
    fi
}

# Get RAID status
get_raid_status() {
    log "INFO" "Starting RAID status check"
    
    if [ ! -f "/proc/mdstat" ]; then
        log "ERROR" "/proc/mdstat not found - RAID subsystem may not be available"
        return 1
    fi
    
    # Read current RAID status
    local mdstat=$(cat /proc/mdstat)
    
    # Check if any arrays are present (look for actual md devices, not just personalities)
    if ! echo "$mdstat" | grep -q "^md[0-9]"; then
        log "INFO" "No RAID arrays configured in system (only personalities: $(echo "$mdstat" | grep "Personalities" | sed 's/Personalities : //'))"
        send_telegram "No arrays found" "true"
        return 0
    fi
    
    log "INFO" "Found RAID arrays in /proc/mdstat"
    
    # Process each array
    local array_count=0
    # Use process substitution instead of pipe to avoid subshell
    while IFS= read -r line; do
        # Check for array definition line (must start with md followed by a number)
        if [[ $line =~ ^(md[0-9]+)[[:space:]]*:[[:space:]]*([^[:space:]]+)[[:space:]]+([^[:space:]]+)[[:space:]]+(.+)$ ]]; then
            local array_name="${BASH_REMATCH[1]}"
            local status="${BASH_REMATCH[2]}"
            local raid_type="${BASH_REMATCH[3]}"
            local devices_info="${BASH_REMATCH[4]}"
            
            array_count=$((array_count + 1))
            log "INFO" "Processing array: $array_name (Type: $raid_type, Status: $status)"
            
            # Get health status
            local health_status=$(echo "$mdstat" | grep -A1 "^$array_name" | grep -o '\[[0-9/]*\] \[[U_]*\]' | head -1)
            local failed_drives=$(echo "$health_status" | grep -o '_' | wc -l)
            local total_drives=$(echo "$health_status" | grep -o '[U_]' | wc -l)
            
            log "INFO" "Array $array_name health: $health_status (Failed: $failed_drives/$total_drives)"
            
            # Get device list
            local devices=$(echo "$devices_info" | grep -o '[a-z]\+[0-9]\+' | tr '\n' ' ')
            log "INFO" "Array $array_name devices: $devices"
            
            # Check for failed devices
            local failed_devices=$(echo "$devices_info" | grep -o '[a-z]\+[0-9]\+\(F\)' | sed 's/(F)//' | tr '\n' ' ')
            if [ -n "$failed_devices" ]; then
                log "WARNING" "Array $array_name has failed devices: $failed_devices"
            fi
            
            # Save current state
            echo "$array_name|$status|$raid_type|$health_status|$failed_drives|$total_drives|$devices|$failed_devices" >> "$STATE_FILE.tmp"
        fi
    done < <(echo "$mdstat" | grep "^md[0-9]")
    
    if [ $array_count -eq 0 ]; then
        log "INFO" "No active RAID arrays found in /proc/mdstat"
    else
        log "INFO" "Successfully processed $array_count RAID array(s)"
    fi
    
    # Compare with previous state
    if [ -f "$STATE_FILE" ]; then
        log "INFO" "Comparing with previous state"
        while IFS='|' read -r array_name status raid_type health_status failed_drives total_drives devices failed_devices; do
            # Read previous state for this array
            local prev_state=$(grep "^$array_name|" "$STATE_FILE" || echo "")
            
            if [ -z "$prev_state" ]; then
                # New array detected
                log "INFO" "New array detected: $array_name"
                send_telegram "\`$array_name\` ($raid_type) new: $status $health_status" "false"
            else
                # Compare with previous state
                IFS='|' read -r _ prev_status _ prev_health_status prev_failed_drives _ _ _ <<< "$prev_state"
                
                # Check for status changes
                if [ "$status" != "$prev_status" ]; then
                    log "WARNING" "Array $array_name status changed from $prev_status to $status"
                    if [ "$status" = "active" ]; then
                        send_telegram "\`$array_name\` active" "false"
                    else
                        send_telegram "\`$array_name\` $status" "true"
                    fi
                fi
                
                # Check for drive failures
                if [ "$failed_drives" -gt "$prev_failed_drives" ]; then
                    log "ALERT" "Drive failure detected in array $array_name: $failed_drives failed drives"
                    send_telegram "\`$array_name\` ($raid_type) $failed_drives/$total_drives failed: $failed_devices" "true"
                elif [ "$failed_drives" -lt "$prev_failed_drives" ]; then
                    log "INFO" "Drive recovery in array $array_name: $failed_drives failed drives"
                    send_telegram "\`$array_name\` recovered ($failed_drives/$total_drives)" "false"
                fi
            fi
        done < "$STATE_FILE.tmp"
        
        # Check for removed arrays
        while IFS='|' read -r array_name _; do
            if ! grep -q "^$array_name|" "$STATE_FILE.tmp"; then
                log "ALERT" "Array $array_name is no longer detected"
                send_telegram "\`$array_name\` removed" "true"
            fi
        done < "$STATE_FILE"
    else
        # First run - send initial status
        log "INFO" "First run detected, sending initial status"
        while IFS='|' read -r array_name status raid_type health_status failed_drives total_drives devices failed_devices; do
            send_telegram "\`$array_name\` ($raid_type) $status $health_status" "false"
        done < "$STATE_FILE.tmp"
    fi
    
    # Update state file
    if mv "$STATE_FILE.tmp" "$STATE_FILE" 2>/dev/null; then
        log "INFO" "State file updated successfully"
    else
        log "ERROR" "Failed to update state file"
    fi
}

# Main execution
log "INFO" "=== RAID Monitor Started ==="

# Ensure we're running as root
if [ "$(id -u)" -ne 0 ]; then
    log "ERROR" "This script must be run as root"
    exit 1
fi

# Check for required commands
if ! command -v curl &> /dev/null; then
    log "ERROR" "curl is required but not installed"
    exit 1
fi

# Run the check
get_raid_status

log "INFO" "=== RAID Monitor Completed ==="

exit 0 