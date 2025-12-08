# Migration Plan: LAVA → POKT

## Current Assets
| Asset | Amount | Value |
|-------|--------|-------|
| LAVA (Lava mainnet) | ~456 LAVA | ~$68 |
| SOL (to add) | ? | You decide |

## Target
- **15,001 POKT** = ~$210 USD
- Gap to fill: ~$142 more (about 0.6 SOL)

---

## STEP 1: Bridge LAVA → Arbitrum (You Do)

1. Go to: https://app.squidrouter.com
2. Connect Keplr (your Lava wallet)
3. FROM: Lava → LAVA token
4. TO: Arbitrum → USDC (or LAVA)
5. Destination: `0x02F126BD97a576C7d2f301f4fe9fc562c0d299A2` (your Arbitrum wallet)
6. Bridge all ~456 LAVA

**Result**: ~$68 USDC on Arbitrum

---

## STEP 2: Add More SOL (You Do)

Send **0.7 SOL** (~$155) to your Solana wallet:
```
GnoaerhKLQkqZd3xsBxg7hpCWfqEj3S3wFCbgCoiNKzq
```

**Result**: ~$155 SOL ready to bridge

---

## STEP 3: Bridge SOL → Ethereum (You Do)

1. Go to: https://app.debridge.finance
2. FROM: Solana → SOL
3. TO: Ethereum → ETH (or USDC)
4. Destination: `0x02F126BD97a576C7d2f301f4fe9fc562c0d299A2`

**Result**: ~$155 ETH/USDC on Ethereum

---

## STEP 4: Swap to POKT on Uniswap (You Do)

1. Import Arbitrum wallet to MetaMask:
   - Private Key: `0x3de0033f58fd42c392270d228cbe1d3c714c149f545b0babaf217542236bead0`
2. Bridge USDC from Arbitrum → Ethereum if needed
3. Go to: https://app.uniswap.org (Ethereum mainnet)
4. Swap USDC/ETH → POKT
5. POKT contract: `0x67F4C72a50f8Df6487720261E188F2abE83F57D7`

**Result**: ~15,000+ POKT on Ethereum

---

## STEP 5: Transfer POKT to POKT Mainnet (Claude Does)

Once you have POKT on Ethereum, I'll help you:
1. Create a POKT mainnet wallet
2. Bridge POKT from Ethereum → POKT mainnet
3. Stake 15,001 POKT
4. Configure node with your Helius/QuickNode endpoints
5. Start earning 80-150% APY

---

## Summary of What You Do

| Step | Action | Where |
|------|--------|-------|
| 1 | Bridge LAVA → Arbitrum | Squid Router |
| 2 | Send 0.7 SOL to wallet | Your exchange |
| 3 | Bridge SOL → Ethereum | deBridge |
| 4 | Swap all to POKT | Uniswap |
| 5 | Tell Claude you're ready | Here |

## Wallet Addresses
- **Solana**: `GnoaerhKLQkqZd3xsBxg7hpCWfqEj3S3wFCbgCoiNKzq`
- **Arbitrum/ETH**: `0x02F126BD97a576C7d2f301f4fe9fc562c0d299A2`
- **Private Key**: `0x3de0033f58fd42c392270d228cbe1d3c714c149f545b0babaf217542236bead0`

## Estimated Costs
- Bridge fees: ~$5-10 total
- Gas fees: ~$10-20 on Ethereum
- Total investment: ~$220-230 for 15,001 POKT

## Expected Returns
- APY: 80-150%
- Monthly: ~$15-25 in POKT rewards
- Breakeven: 6-12 months
