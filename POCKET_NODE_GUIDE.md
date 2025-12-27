# Pocket Network Shannon Mainnet Node Guide

## Overview

This guide covers the setup and operation of a Pocket Network Shannon mainnet Supplier node.

**Chain ID**: `pocket`
**Genesis Time**: March 28, 2025
**Network**: Shannon Mainnet
**Supplier Address**: `pokt1azdnnltewxtwfuv2etzhe8n0857xeyyvvhqlrk`

## Current Status (Dec 10, 2025)

| Component | Status |
|-----------|--------|
| Full Node | Running, Fully Synced |
| RelayMiner | Running |
| Staked Amount | 71,080 POKT |
| Liquid Balance | ~500 POKT |
| Services | Solana, BSC, opBNB |
| Endpoint | https://pokt-rpc.sol-pulse.com |

## Quick Reference Commands

```bash
# Check node sync status
curl -s localhost:26657/status | jq '.result.sync_info'

# Check wallet balance
/home/tom14cat14/Pocket_Network/pocketd query bank balances pokt1azdnnltewxtwfuv2etzhe8n0857xeyyvvhqlrk --node tcp://127.0.0.1:26657

# Check supplier status
/home/tom14cat14/Pocket_Network/pocketd query supplier show-supplier pokt1azdnnltewxtwfuv2etzhe8n0857xeyyvvhqlrk --node tcp://127.0.0.1:26657

# Check for claims/earnings
/home/tom14cat14/Pocket_Network/pocketd query proof list-claims --supplier-operator-address pokt1azdnnltewxtwfuv2etzhe8n0857xeyyvvhqlrk --node tcp://127.0.0.1:26657

# Check session params
/home/tom14cat14/Pocket_Network/pocketd query session params --node tcp://127.0.0.1:26657

# Check supplier params (minimum stake)
/home/tom14cat14/Pocket_Network/pocketd query supplier params --node tcp://127.0.0.1:26657

# List gateways on network
/home/tom14cat14/Pocket_Network/pocketd query gateway list-gateway --node tcp://127.0.0.1:26657

# Check if supplier is in a specific session
/home/tom14cat14/Pocket_Network/pocketd query session get-session <app_address> <service_id> <block_height> --node tcp://127.0.0.1:26657
```

## Directory Structure

```
/home/tom14cat14/Pocket_Network/
├── pocketd                        # Main binary (v0.1.30)
├── relayminer/
│   └── relayminer_config.yaml     # RelayMiner configuration
├── supplier_stake_config.yaml      # Supplier staking config
├── pocket-ctl.sh                   # Management script
├── pocket-env.sh                   # Environment variables
├── pocket-node.service             # Full node systemd service
├── pocket-relayminer.service       # RelayMiner systemd service
└── POCKET_NODE_GUIDE.md            # This file

/home/tom14cat14/.pocket/
├── config/
│   ├── config.toml                 # Node configuration
│   ├── app.toml                    # Application configuration
│   └── genesis.json                # Genesis file
├── data/                           # Blockchain data
├── smt/                            # SMT store for RelayMiner
│   └── sessions_metadata/          # Session data (DO NOT DELETE)
└── cosmovisor/
    └── upgrades/v0.1.30/bin/pocketd
```

## Architecture

```
                    Internet
                       |
                       v
              +----------------+
              |  Cloudflare    |
              |    Tunnel      |
              +----------------+
                       |
                       v
              pokt-rpc.sol-pulse.com
                       |
                       v
              +----------------+
              |  RelayMiner    |  (port 8545)
              |  All services  |
              +----------------+
                    |  |  |
         +----------+  |  +----------+
         v             v             v
    +---------+  +---------+  +---------+
    | Solana  |  |   BSC   |  |  opBNB  |
    | Backend |  | Backend |  | Backend |
    +---------+  +---------+  +---------+
```

## Network Parameters

| Parameter | Value |
|-----------|-------|
| Minimum Stake | 59,500-60,000 POKT |
| Blocks per Session | 60 (~1 hour) |
| Suppliers per Session | 50 |
| Unbonding Period | 1008 sessions (~42 days) |
| Compute Units (Solana) | 5,033 per relay |
| Compute Units (BSC) | 5,000 per relay |

## Session Selection Algorithm

POKT Shannon uses **deterministic probabilistic selection**:

1. Sessions rotate every 60 blocks (~1 hour)
2. Each session includes up to 50 suppliers per service
3. Selection is based on a hash of (app_address + service_id + session_number)
4. **Higher stake = Higher selection probability**
5. Quality metrics (response time, accuracy) affect future selection

### Why You Might Not Be in Sessions

- **Probability**: With 100+ suppliers for popular services like Solana, each supplier has ~25-50% chance per session
- **Stake Weight**: Higher stakers get selected more often
- **QoS History**: Poor response quality can reduce selection probability
- **New Suppliers**: Need time to build reputation in the network

## RelayMiner Configuration

**IMPORTANT**: All services MUST use the same `listen_url` for proper routing!

```yaml
# /home/tom14cat14/Pocket_Network/relayminer/relayminer_config.yaml
default_signing_key_names:
  - supplier-wallet
smt_store_path: /home/tom14cat14/.pocket/smt
pocket_node:
  query_node_rpc_url: tcp://127.0.0.1:26657
  query_node_grpc_url: tcp://127.0.0.1:9090
  tx_node_rpc_url: tcp://127.0.0.1:26657
suppliers:
  - service_id: "solana"
    service_config:
      backend_url: "https://dian-8gkewt-fast-mainnet.helius-rpc.com"
    listen_url: "http://0.0.0.0:8545"

  - service_id: "bsc"
    service_config:
      backend_url: "https://bsc-dataseed1.binance.org"
    listen_url: "http://0.0.0.0:8545"

  - service_id: "opbnb"
    service_config:
      backend_url: "https://opbnb-mainnet-rpc.bnbchain.org"
    listen_url: "http://0.0.0.0:8545"
```

### Starting RelayMiner

```bash
# Via systemd (recommended)
sudo systemctl start pocket-relayminer
sudo systemctl status pocket-relayminer

# Manual start
/home/tom14cat14/Pocket_Network/pocketd relayminer start \
  --config /home/tom14cat14/Pocket_Network/relayminer/relayminer_config.yaml \
  --keyring-backend test \
  --network main \
  --node tcp://127.0.0.1:26657 \
  --grpc-addr tcp://127.0.0.1:9090 \
  --grpc-insecure
```

### Common RelayMiner Issues

**"error opening the store - resource temporarily unavailable"**
- Another process has the SMT store locked
- Solution: Kill stale pocketd processes, then restart

```bash
# Find and kill stale processes
lsof +D /home/tom14cat14/.pocket/smt/
kill <PID>
```

**"failed to unmarshal relay request"**
- Normal! This happens when non-POKT requests hit the endpoint
- POKT relay requests have a specific format that only gateways send

## Cloudflare Tunnel Configuration

```yaml
# ~/.cloudflared/config.yml
tunnel: abd74874-dfe2-45f4-b1ca-abfe0bc03842
credentials-file: /home/tom14cat14/.cloudflared/abd74874-dfe2-45f4-b1ca-abfe0bc03842.json

ingress:
  # POKT Network Supplier (Shannon) - All services on port 8545
  - hostname: pokt-rpc.sol-pulse.com
    service: http://localhost:8545
  # ... other services
```

## Supplier Staking

### Current Stake Configuration

```yaml
# /home/tom14cat14/Pocket_Network/supplier_stake_config.yaml
owner_address: pokt1azdnnltewxtwfuv2etzhe8n0857xeyyvvhqlrk
operator_address: pokt1azdnnltewxtwfuv2etzhe8n0857xeyyvvhqlrk
stake_amount: 71080000000upokt
default_rev_share_percent:
  pokt1azdnnltewxtwfuv2etzhe8n0857xeyyvvhqlrk: 100
services:
  - service_id: solana
    endpoints:
      - publicly_exposed_url: https://pokt-rpc.sol-pulse.com
        rpc_type: JSON_RPC
  - service_id: bsc
    endpoints:
      - publicly_exposed_url: https://pokt-rpc.sol-pulse.com
        rpc_type: JSON_RPC
  - service_id: opbnb
    endpoints:
      - publicly_exposed_url: https://pokt-rpc.sol-pulse.com
        rpc_type: JSON_RPC
```

### Re-staking (to update services or stake amount)

```bash
/home/tom14cat14/Pocket_Network/pocketd tx supplier stake-supplier \
  --config /home/tom14cat14/Pocket_Network/supplier_stake_config.yaml \
  --from supplier-wallet \
  --keyring-backend test \
  --network main \
  --node tcp://127.0.0.1:26657 \
  --gas auto \
  --gas-adjustment 1.5 \
  --yes
```

## Earnings & Rewards

### How Earnings Work

1. **Session Selection**: Supplier gets selected for a session (probabilistic)
2. **Serve Relays**: Gateway routes app requests to your supplier
3. **Create Claims**: RelayMiner automatically creates claims for served relays
4. **Submit Proofs**: Proofs are submitted within the proof window
5. **Receive Rewards**: POKT is minted and distributed based on compute units served

### Estimated Earnings

Based on network data (from POKT docs):
- ~0.0000078125 POKT per compute unit
- Solana: 5,033 CU/relay = ~0.039 POKT/relay
- At 5M relays/day = ~195 POKT/day (~$30-60/day at current prices)

**Note**: Actual earnings depend on session selection and relay volume.

### Monitoring Earnings

```bash
# Check for pending claims
/home/tom14cat14/Pocket_Network/pocketd query proof list-claims \
  --supplier-operator-address pokt1azdnnltewxtwfuv2etzhe8n0857xeyyvvhqlrk \
  --node tcp://127.0.0.1:26657

# Check balance changes
/home/tom14cat14/Pocket_Network/pocketd query bank balances pokt1azdnnltewxtwfuv2etzhe8n0857xeyyvvhqlrk \
  --node tcp://127.0.0.1:26657
```

## Troubleshooting

### Not Getting Sessions

1. **Check stake**: Must be >= 59,500 POKT
2. **Check services**: Verify services are registered correctly
3. **Check endpoint**: Must be publicly accessible
4. **Wait**: New suppliers need time to be selected (probabilistic)
5. **Increase stake**: Higher stake = higher selection probability

### RelayMiner Not Starting

```bash
# Check for port conflicts
ss -tlnp | grep 8545

# Check for stale locks
lsof +D /home/tom14cat14/.pocket/smt/

# Check logs
journalctl -u pocket-relayminer -f
tail -f /tmp/relayminer.log
```

### Full Node Issues

```bash
# Check sync status
curl -s localhost:26657/status | jq '.result.sync_info.catching_up'

# Check peer count
curl -s localhost:26657/net_info | jq '.result.n_peers'

# View node logs
journalctl -u pocket-node -f
```

## Important Links & Resources

### Official Documentation
- **POKT Docs**: https://docs.pokt.network
- **Shannon Upgrade Guide**: https://docs.pokt.network/pokt-protocol/the-shannon-upgrade
- **Supplier Docs**: https://docs.pokt.network/pokt-protocol/the-shannon-upgrade/shannon-actors/suppliers
- **Tokenomics**: https://docs.pokt.network/pokt-protocol/the-shannon-upgrade/proposed-tokenomics

### Developer Resources
- **Poktroll Dev Docs**: https://dev.poktroll.com/
- **Supplier Cheat Sheet**: https://dev.poktroll.com/operate/quickstart/supplier_cheatsheet
- **GitHub - Poktroll**: https://github.com/pokt-network/poktroll
- **GitHub - Releases**: https://github.com/pokt-network/poktroll/releases

### Setup Guides
- **Official Node Setup**: https://pocket.network/pokt-node-shannon/
- **Shannon Developer Guide**: https://pocket.network/pocket-developer-guide/

### Community & Support
- **Discord**: https://discord.gg/poktnetwork
- **Forum**: https://forum.pokt.network
- **Economics Discussion**: https://forum.pokt.network/t/protocol-economics-parameters-for-the-shannon-upgrade/5490

### Explorers & Tools
- **Block Explorer**: https://shannon.poktscan.com
- **Supported Chains**: https://docs.pokt.network/reference/supported-chains

## Maintenance Checklist

### Daily
- [ ] Check RelayMiner is running: `pgrep -a relayminer`
- [ ] Check for claims: `pocketd query proof list-claims ...`
- [ ] Monitor balance for earnings

### Weekly
- [ ] Check disk space: `df -h`
- [ ] Review logs for errors
- [ ] Check for new releases: https://github.com/pokt-network/poktroll/releases

### Monthly
- [ ] Backup wallet keys
- [ ] Review stake amount vs network average
- [ ] Check service performance metrics

## Wallet Information

**Address**: `pokt1azdnnltewxtwfuv2etzhe8n0857xeyyvvhqlrk`
**Keyring Backend**: test
**Wallet Name**: supplier-wallet

### Key Backup Location
Keys are stored in: `/home/tom14cat14/.pocket/keyring-test/`

**IMPORTANT**: Back up wallet keys securely! Loss of keys = loss of staked POKT.

---

**Last Updated**: December 10, 2025
**Node Status**: Fully synced, RelayMiner running
**Binary Version**: v0.1.30
**Staked**: 71,080 POKT on Solana, BSC, opBNB services
