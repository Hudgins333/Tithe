# Tithe

An ERC-20 token with built-in tithing, deployed on **Arc Testnet** — Circle's stablecoin-native L1.

Every transfer automatically routes a configurable percentage of the transferred amount to a designated tithe recipient. The remainder goes to the intended recipient. Transparent, on-chain, no oracles, no upgrade keys, no surprises.

> "Bring the full tithe into the storehouse." — Malachi 3:10

## Live on Arc Testnet

- **Contract:** [`0x7eB4b1Abb96d6ed089c48219dC3df18d2B7aEf4F`](https://testnet.arcscan.app/address/0x7eB4b1Abb96d6ed089c48219dC3df18d2B7aEf4F)
- **Deployment tx:** [`0x86d2edce06075e0ea89bae6a8abee847307c0cecba46380d2065952aaa718026`](https://testnet.arcscan.app/tx/0x86d2edce06075e0ea89bae6a8abee847307c0cecba46380d2065952aaa718026)
- **Network:** Arc Testnet (chain ID 5042002)
- **Symbol:** TITHE
- **Decimals:** 18
- **Initial supply:** 1,000,000 TITHE
- **Tithe rate:** 10% (1000 bps)

## Why this exists

Tithing is one of the oldest economic disciplines in scripture. It's also one of the few financial practices most people fail at — not because they don't want to, but because they forget, the math is annoying, or the friction is real.

Onchain stablecoin payments are now fast, cheap, and final. There's no reason the discipline of "first fruits" shouldn't be the easiest part of moving money.

This contract is the first piece of that: a token where the tithe is not a ledger entry you maintain, it's a protocol-level invariant.

## Design tenets

1. **Transparent.** Every tithe emits a `TitheRouted` event with the gross amount, the tithe amount, and the net amount. Anyone can audit the flow.
2. **Configurable but bounded.** The owner can change the tithe rate, but it's hard-capped at 50% to prevent runaway routing.
3. **No double-tithe.** Transfers TO or FROM the tithe recipient skip the auto-routing logic — the recipient gets what was sent, no recursive skim, no infinite loop.
4. **No upgradability.** What you deploy is what runs. The owner can change the recipient, rate, and active flag — that's the entire admin surface.
5. **Pausable, not killable.** The owner can disable auto-tithing without breaking the token.

## How it works

```solidity
// When someone calls transfer(to, 1000 TITHE):
//   - 100 TITHE routes to titheRecipient (10% tithe)
//   - 900 TITHE routes to the intended recipient
//   - Both transfers emit standard ERC-20 Transfer events
//   - A TitheRouted event emits with full breakdown
//   - totalTithed and titheCount stats update
```

Transfers to or from the tithe recipient skip the routing logic to prevent infinite loops.

## Prerequisites

- [Foundry](https://getfoundry.sh/) (`curl -L https://foundry.paradigm.xyz | bash && foundryup`)
- A funded Arc Testnet wallet — USDC for gas, from [faucet.circle.com](https://faucet.circle.com)

## Quickstart

```bash
git clone https://github.com/YOUR_USERNAME/tithe.git
cd tithe
forge install
cp .env.example .env
# Edit .env with your PRIVATE_KEY and TITHE_RECIPIENT
source .env
forge test -vv
```

## Deploy to Arc Testnet

```bash
forge script script/DeployTithe.s.sol:DeployTithe \
  --rpc-url $ARC_TESTNET_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast
```

## Interact

```bash
# Preview a tithe split for any amount
cast call $TITHE_ADDRESS "previewTithe(uint256)(uint256,uint256)" \
  1000000000000000000000 --rpc-url $ARC_TESTNET_RPC_URL

# Send a transfer (auto-routes the tithe)
cast send $TITHE_ADDRESS "transfer(address,uint256)" \
  $RECIPIENT 1000000000000000000000 \
  --rpc-url $ARC_TESTNET_RPC_URL --private-key $PRIVATE_KEY

# Check cumulative tithed amount
cast call $TITHE_ADDRESS "totalTithed()(uint256)" --rpc-url $ARC_TESTNET_RPC_URL
```

## Roadmap

- **v1 (this):** ERC-20 with auto-tithe on transfer. Live on Arc Testnet.
- **v2:** Standalone Tithe agent — watches a wallet's inbound native USDC on Arc, auto-tithes a configurable % to a designated address. Works on real USDC, no custom token required.
- **v3:** Multi-recipient splits (church + missions + benevolence with configurable weights).
- **v4:** Integration with Circle's USYC for yield-bearing tithe reserves — tithes sit in a tokenized money market until disbursed.

## Built with

- [Foundry](https://getfoundry.sh/) — Solidity development toolkit
- [Arc Testnet](https://www.arc.network/) — Circle's stablecoin-native L1
- Solidity 0.8.30, no external dependencies

## License

MIT. Use this for anything good.

---

*Christ the King.*
