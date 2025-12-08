#!/bin/bash
# Pocket Network Node Monitor
# Checks node health and sends alerts

POCKET_HOME="/home/tom14cat14/.pocket"
LOG_FILE="/tmp/pocket_monitor.log"
ALERT_FILE="/home/tom14cat14/Pocket_Network/alerts.log"
RPC_URL="http://localhost:26657"

# Telegram alert (optional - set these in .env)
source /home/tom14cat14/Pocket_Network/.env 2>/dev/null
TELEGRAM_BOT_TOKEN="${POCKET_TELEGRAM_BOT_TOKEN:-}"
TELEGRAM_CHAT_ID="${POCKET_TELEGRAM_CHAT_ID:-}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

send_alert() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # Log to alert file
    echo "[$timestamp] ALERT: $message" >> "$ALERT_FILE"

    # Telegram notification (if configured)
    if [ -n "$TELEGRAM_BOT_TOKEN" ] && [ -n "$TELEGRAM_CHAT_ID" ]; then
        curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
            -d chat_id="${TELEGRAM_CHAT_ID}" \
            -d text="🚨 Pocket Node Alert: ${message}" \
            -d parse_mode="HTML" > /dev/null 2>&1
    fi

    # Console output
    echo -e "${RED}[ALERT]${NC} $message"
}

send_info() {
    local message="$1"

    # Telegram notification (if configured)
    if [ -n "$TELEGRAM_BOT_TOKEN" ] && [ -n "$TELEGRAM_CHAT_ID" ]; then
        curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
            -d chat_id="${TELEGRAM_CHAT_ID}" \
            -d text="ℹ️ Pocket Node: ${message}" \
            -d parse_mode="HTML" > /dev/null 2>&1
    fi
}

check_process() {
    if pgrep -f "pocketd start" > /dev/null; then
        return 0
    else
        return 1
    fi
}

check_rpc() {
    local response=$(curl -s --connect-timeout 5 "${RPC_URL}/status" 2>/dev/null)
    if [ -z "$response" ]; then
        return 1
    fi
    echo "$response"
    return 0
}

get_sync_status() {
    local status=$(check_rpc)
    if [ $? -ne 0 ]; then
        echo "RPC_UNAVAILABLE"
        return 1
    fi

    local height=$(echo "$status" | jq -r '.result.sync_info.latest_block_height // "0"')
    local catching_up=$(echo "$status" | jq -r '.result.sync_info.catching_up // "true"')
    local latest_time=$(echo "$status" | jq -r '.result.sync_info.latest_block_time // ""')

    echo "${height}|${catching_up}|${latest_time}"
}

check_block_progress() {
    local current_height="$1"
    local state_file="/tmp/pocket_last_height"

    if [ -f "$state_file" ]; then
        local last_height=$(cat "$state_file")
        local last_check=$(stat -c %Y "$state_file" 2>/dev/null || echo "0")
        local now=$(date +%s)
        local time_diff=$((now - last_check))

        # If more than 5 minutes and no block progress
        if [ "$time_diff" -gt 300 ] && [ "$current_height" -eq "$last_height" ]; then
            return 1  # Stuck
        fi
    fi

    echo "$current_height" > "$state_file"
    return 0
}

monitor() {
    log "Starting Pocket Network node monitor..."

    while true; do
        # Check if process is running
        if ! check_process; then
            send_alert "Pocket node process is NOT running!"
            log "ERROR: Node process not running"

            # Try to restart via systemd
            if systemctl is-enabled pocket-node 2>/dev/null; then
                log "Attempting restart via systemd..."
                sudo systemctl restart pocket-node 2>/dev/null
                sleep 10
                if check_process; then
                    send_info "Node restarted successfully"
                    log "Node restarted successfully"
                fi
            fi
        else
            # Check RPC and sync status
            sync_info=$(get_sync_status)

            if [ "$sync_info" = "RPC_UNAVAILABLE" ]; then
                send_alert "Node RPC is not responding!"
                log "ERROR: RPC not responding"
            else
                IFS='|' read -r height catching_up latest_time <<< "$sync_info"

                # Check if blocks are progressing
                if ! check_block_progress "$height"; then
                    send_alert "Node appears stuck at height $height for >5 minutes!"
                    log "WARNING: Node stuck at height $height"
                fi

                # Log status every check
                if [ "$catching_up" = "true" ]; then
                    log "Syncing: height=$height"
                else
                    log "Synced: height=$height"
                fi
            fi
        fi

        # Check every 60 seconds
        sleep 60
    done
}

status() {
    echo "=== Pocket Node Status ==="
    echo ""

    if check_process; then
        echo -e "Process: ${GREEN}Running${NC}"
        pid=$(pgrep -f "pocketd start" | head -1)
        echo "PID: $pid"
    else
        echo -e "Process: ${RED}NOT Running${NC}"
    fi

    echo ""
    sync_info=$(get_sync_status)

    if [ "$sync_info" = "RPC_UNAVAILABLE" ]; then
        echo -e "RPC: ${RED}Not Available${NC}"
    else
        IFS='|' read -r height catching_up latest_time <<< "$sync_info"
        echo -e "RPC: ${GREEN}Available${NC}"
        echo "Block Height: $height"
        if [ "$catching_up" = "true" ]; then
            echo -e "Status: ${YELLOW}Syncing${NC}"
        else
            echo -e "Status: ${GREEN}Synced${NC}"
        fi
        echo "Latest Block Time: $latest_time"
    fi

    echo ""
    echo "Current Binary: $(/home/tom14cat14/.pocket/cosmovisor/current/bin/pocketd version 2>&1)"

    echo ""
    if [ -f "$ALERT_FILE" ]; then
        echo "=== Recent Alerts ==="
        tail -5 "$ALERT_FILE"
    fi
}

case "$1" in
    start)
        monitor &
        echo "Monitor started in background (PID: $!)"
        ;;
    status)
        status
        ;;
    test-alert)
        send_alert "Test alert from Pocket monitor"
        echo "Test alert sent (check Telegram if configured)"
        ;;
    *)
        echo "Pocket Network Node Monitor"
        echo ""
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  start       - Start monitoring in background"
        echo "  status      - Show current node status"
        echo "  test-alert  - Send a test alert"
        echo ""
        echo "Configure Telegram alerts by adding to .env:"
        echo "  POCKET_TELEGRAM_BOT_TOKEN=your_bot_token"
        echo "  POCKET_TELEGRAM_CHAT_ID=your_chat_id"
        ;;
esac
