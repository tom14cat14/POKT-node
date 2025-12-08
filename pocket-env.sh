#!/bin/bash
# Pocket Network Node Environment Variables
# Source this file: source /home/tom14cat14/Pocket_Network/pocket-env.sh

export DAEMON_NAME="pocketd"
export DAEMON_HOME="/home/tom14cat14/.pocket"
export DAEMON_RESTART_AFTER_UPGRADE="true"
export DAEMON_ALLOW_DOWNLOAD_BINARIES="true"
export UNSAFE_SKIP_BACKUP="true"

# Add to PATH
export PATH="/home/tom14cat14/.local/bin:/home/tom14cat14/Pocket_Network:$PATH"

# Aliases for convenience
alias pocket-status='/home/tom14cat14/Pocket_Network/v0.1.1_bin/pocketd status --home=/home/tom14cat14/.pocket'
alias pocket-logs='journalctl -u pocket-node -f'
alias pocket-sync='pocket-status | jq ".sync_info"'

echo "Pocket Network environment loaded!"
echo "Commands: pocket-status, pocket-logs, pocket-sync"
