#!/bin/bash
# Pocket Network Node Management Script
# Usage: ./pocket-ctl.sh [command]

POCKET_HOME="/home/tom14cat14/.pocket"
POCKET_BIN="/home/tom14cat14/Pocket_Network/v0.1.1_bin/pocketd"
COSMOVISOR="/home/tom14cat14/.local/bin/cosmovisor"
SERVICE_NAME="pocket-node"
LOG_FILE="/tmp/pocketd_v0.1.1_sync.log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

case "$1" in
    start)
        print_status "Starting Pocket Network node..."
        if systemctl is-active --quiet $SERVICE_NAME 2>/dev/null; then
            print_warning "Service already running. Use 'restart' to restart."
        else
            # Check if manual process is running
            if pgrep -f "pocketd start" > /dev/null; then
                print_warning "Manual pocketd process detected. Stopping it first..."
                pkill -f "pocketd start"
                sleep 2
            fi
            sudo systemctl start $SERVICE_NAME 2>/dev/null || {
                print_warning "Systemd not available, starting manually..."
                nohup $POCKET_BIN start --home=$POCKET_HOME > $LOG_FILE 2>&1 &
                echo "Started with PID $!"
            }
        fi
        ;;

    stop)
        print_status "Stopping Pocket Network node..."
        sudo systemctl stop $SERVICE_NAME 2>/dev/null || {
            pkill -f "pocketd start"
        }
        ;;

    restart)
        print_status "Restarting Pocket Network node..."
        $0 stop
        sleep 3
        $0 start
        ;;

    status)
        echo "=== Node Status ==="
        $POCKET_BIN status --home=$POCKET_HOME 2>&1 | jq '.' 2>/dev/null || \
            $POCKET_BIN status --home=$POCKET_HOME 2>&1

        echo ""
        echo "=== Process Status ==="
        if pgrep -f "pocketd start" > /dev/null; then
            echo -e "${GREEN}Node process is running${NC}"
            pgrep -af "pocketd start"
        else
            echo -e "${RED}Node process is NOT running${NC}"
        fi

        echo ""
        echo "=== Systemd Status ==="
        systemctl is-active $SERVICE_NAME 2>/dev/null && echo "Service: active" || echo "Service: inactive/not installed"
        ;;

    sync)
        echo "=== Sync Status ==="
        $POCKET_BIN status --home=$POCKET_HOME 2>&1 | jq '.sync_info' 2>/dev/null
        ;;

    logs)
        if [ -f $LOG_FILE ]; then
            tail -f $LOG_FILE
        else
            journalctl -u $SERVICE_NAME -f 2>/dev/null || echo "No logs found"
        fi
        ;;

    logs-last)
        if [ -f $LOG_FILE ]; then
            tail -100 $LOG_FILE
        else
            journalctl -u $SERVICE_NAME -n 100 2>/dev/null || echo "No logs found"
        fi
        ;;

    reset)
        print_warning "This will reset all blockchain data!"
        read -p "Are you sure? (y/N): " confirm
        if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
            $0 stop
            sleep 2
            $POCKET_BIN tendermint unsafe-reset-all --home=$POCKET_HOME
            print_status "Node data reset. Use 'start' to begin syncing again."
        else
            print_status "Reset cancelled."
        fi
        ;;

    install-service)
        print_status "Installing systemd service..."
        sudo cp /home/tom14cat14/Pocket_Network/pocket-node.service /etc/systemd/system/
        sudo systemctl daemon-reload
        sudo systemctl enable $SERVICE_NAME
        print_status "Service installed and enabled."
        print_status "Use 'sudo systemctl start $SERVICE_NAME' to start."
        ;;

    version)
        echo "=== Binary Versions ==="
        echo "Genesis (v0.1.1): $($POCKET_HOME/cosmovisor/genesis/bin/pocketd version 2>&1)"
        echo "Upgrade v0.1.30: $($POCKET_HOME/cosmovisor/upgrades/v0.1.30/bin/pocketd version 2>&1)"
        echo "Current: $($POCKET_BIN version 2>&1)"
        ;;

    peers)
        echo "=== Connected Peers ==="
        $POCKET_BIN status --home=$POCKET_HOME 2>&1 | jq '.node_info.network, .sync_info.latest_block_height' 2>/dev/null
        curl -s localhost:26657/net_info 2>/dev/null | jq '.result.n_peers, .result.peers[].node_info.moniker' 2>/dev/null || echo "RPC not available"
        ;;

    *)
        echo "Pocket Network Node Management"
        echo ""
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  start           - Start the node"
        echo "  stop            - Stop the node"
        echo "  restart         - Restart the node"
        echo "  status          - Show node status"
        echo "  sync            - Show sync status"
        echo "  logs            - Follow live logs"
        echo "  logs-last       - Show last 100 log lines"
        echo "  reset           - Reset blockchain data (dangerous!)"
        echo "  install-service - Install systemd service"
        echo "  version         - Show binary versions"
        echo "  peers           - Show connected peers"
        echo ""
        ;;
esac
