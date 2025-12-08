#!/bin/bash
cd /home/tom14cat14/Pocket_Network

# Wait for node to sync
echo "Waiting for POKT node to sync..."
while true; do
    CATCHING_UP=$(curl -s localhost:26657/status 2>/dev/null | jq -r '.result.sync_info.catching_up' 2>/dev/null)
    if [ "$CATCHING_UP" = "false" ]; then
        echo "Node synced! Starting RelayMiner..."
        break
    fi
    echo "Still syncing... (catching_up=$CATCHING_UP)"
    sleep 60
done

# Start RelayMiner
./pocketd relayminer start \
  --config /home/tom14cat14/Pocket_Network/relayminer/relayminer_config.yaml \
  --keyring-backend test
