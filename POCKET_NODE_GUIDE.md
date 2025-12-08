# Pocket Network Shannon Mainnet Node Guide

## Overview

This guide covers the setup and operation of a Pocket Network Shannon mainnet full node.

**Chain ID**: `pocket`
**Genesis Time**: March 28, 2025
**Network**: Shannon Mainnet (pre-Morse migration)

## Quick Start Commands

```bash
# Check node status
./pocket-ctl.sh status

# Check sync progress
./pocket-ctl.sh sync

# View logs
./pocket-ctl.sh logs

# Start/stop/restart
./pocket-ctl.sh start
./pocket-ctl.sh stop
./pocket-ctl.sh restart
```

## Directory Structure

```
/home/tom14cat14/Pocket_Network/
├── v0.1.1_bin/
│   └── pocketd           # Genesis binary (v0.1.1) - REQUIRED for initial sync
├── pocketd               # Latest binary (v0.1.30)
├── pocket-ctl.sh         # Management script
├── pocket-env.sh         # Environment variables
├── pocket-node.service   # Systemd service file
└── POCKET_NODE_GUIDE.md  # This file

/home/tom14cat14/.pocket/
├── config/
│   ├── config.toml       # Node configuration
│   ├── app.toml          # Application configuration
│   ├── genesis.json      # Genesis file
│   ├── node_key.json     # Node identity key
│   └── priv_validator_key.json  # Validator key (if validating)
├── data/                 # Blockchain data
└── cosmovisor/
    ├── genesis/bin/pocketd      # v0.1.1 (genesis version)
    └── upgrades/v0.1.30/bin/pocketd  # Upgrade binary
```

## Critical Information

### Binary Version Mismatch Issue (SOLVED)

**Problem**: `pocketd v0.1.30` causes AppHash mismatch errors when syncing from genesis.

**Error message**:
```
wrong Block.Header.AppHash. Expected 042890DF... got 8FDB9B50...
```

**Solution**: Use `pocketd v0.1.1` (the genesis version) for initial sync. The binary version MUST match the `app_version` in genesis.json.

**Root Cause**: Newer binary versions (v0.1.2+) include state computation changes that are incompatible with genesis replay.

### Sync Process

1. **Genesis sync** uses v0.1.1 binary
2. **Automatic upgrades** are handled by Cosmovisor
3. When the chain reaches upgrade heights, Cosmovisor switches binaries automatically

## Installation

### 1. Install Systemd Service (Production)

```bash
# Install service
./pocket-ctl.sh install-service

# Start the service
sudo systemctl start pocket-node

# Enable auto-start on boot
sudo systemctl enable pocket-node

# Check status
sudo systemctl status pocket-node
```

### 2. Manual Operation (Development)

```bash
# Start manually
nohup ./v0.1.1_bin/pocketd start --home=/home/tom14cat14/.pocket > /tmp/pocket.log 2>&1 &

# Or use the management script
./pocket-ctl.sh start
```

## Monitoring

### Check Sync Status

```bash
# Via management script
./pocket-ctl.sh sync

# Via RPC
curl -s localhost:26657/status | jq '.result.sync_info'

# Via pocketd
./v0.1.1_bin/pocketd status --home=/home/tom14cat14/.pocket | jq '.sync_info'
```

### Key Metrics

- `latest_block_height`: Current synced block
- `catching_up`: `true` = still syncing, `false` = fully synced
- `latest_block_time`: Timestamp of latest block

### View Logs

```bash
# Live logs (manual mode)
tail -f /tmp/pocketd_v0.1.1_sync.log

# Live logs (systemd)
journalctl -u pocket-node -f

# Last 100 lines
./pocket-ctl.sh logs-last
```

## Configuration

### Key Config Files

**config.toml** (`~/.pocket/config/config.toml`):
- P2P settings (seeds, peers)
- RPC settings
- Consensus parameters

**app.toml** (`~/.pocket/config/app.toml`):
- Application settings
- Pruning configuration
- API endpoints

### Seeds

Current mainnet seeds:
```
06edc8bbbc7a3c9c7a6a1d9c7492fb5c3b262f1e@seed1.shannon-mainnet.us.nodefleet.net:26680
3ea9161a71a3a86823002bed5b0caa20431ca377@seed1.shannon-mainnet.eu.nodefleet.net:26670
```

## Troubleshooting

### AppHash Mismatch Error

**Cause**: Wrong binary version
**Solution**: Use v0.1.1 for genesis sync

```bash
# Stop current node
pkill -f pocketd

# Reset data
./v0.1.1_bin/pocketd tendermint unsafe-reset-all --home=/home/tom14cat14/.pocket

# Start with v0.1.1
./pocket-ctl.sh start
```

### Slow Sync

Check peer connections:
```bash
curl -s localhost:26657/net_info | jq '.result.n_peers'
```

Add more persistent peers in `config.toml`.

### Node Crashes

Check logs for errors:
```bash
./pocket-ctl.sh logs-last | grep -i error
```

Common causes:
- Disk full
- Memory exhaustion
- Network issues

### Reset Node

⚠️ **WARNING**: This deletes all blockchain data!

```bash
./pocket-ctl.sh reset
```

## Cosmovisor

Cosmovisor handles automatic binary upgrades.

### Directory Structure

```
~/.pocket/cosmovisor/
├── genesis/bin/pocketd    # Initial binary (v0.1.1)
├── current -> genesis     # Symlink to current binary
└── upgrades/
    └── v0.1.30/bin/pocketd  # Upgrade binary
```

### How It Works

1. Node starts with `genesis/bin/pocketd`
2. When upgrade height is reached, Cosmovisor:
   - Stops the node
   - Switches to the upgrade binary
   - Restarts the node

### Adding New Upgrades

When a new upgrade is announced:

```bash
# Download new binary
wget https://github.com/pokt-network/poktroll/releases/download/vX.Y.Z/pocket_linux_amd64.tar.gz

# Create upgrade directory (name must match upgrade proposal)
mkdir -p ~/.pocket/cosmovisor/upgrades/vX.Y.Z/bin

# Extract binary
tar -xzf pocket_linux_amd64.tar.gz -C ~/.pocket/cosmovisor/upgrades/vX.Y.Z/bin/

# Verify
~/.pocket/cosmovisor/upgrades/vX.Y.Z/bin/pocketd version
```

## Environment Variables

Source the environment file for convenience:

```bash
source /home/tom14cat14/Pocket_Network/pocket-env.sh
```

Or add to `~/.bashrc`:
```bash
echo 'source /home/tom14cat14/Pocket_Network/pocket-env.sh' >> ~/.bashrc
```

## Useful Links

- **Pocket Network Docs**: https://docs.pokt.network
- **GitHub**: https://github.com/pokt-network/poktroll
- **Genesis Repo**: https://github.com/pokt-network/pocket-network-genesis
- **Discord**: https://discord.gg/poktnetwork

## Maintenance

### Regular Tasks

1. **Monitor disk space** - Blockchain data grows over time
2. **Check logs** - Watch for errors or warnings
3. **Stay updated** - Follow announcements for upgrades
4. **Backup keys** - Keep `priv_validator_key.json` and `node_key.json` safe

### Backup Important Files

```bash
cp ~/.pocket/config/priv_validator_key.json ~/backup/
cp ~/.pocket/config/node_key.json ~/backup/
```

---

**Last Updated**: December 7, 2025
**Node Status**: Syncing from genesis with v0.1.1
**Binary Versions**: v0.1.1 (genesis), v0.1.30 (upgrade ready)
