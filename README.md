# Dunk Poge — Smart Contracts

> Three immutable contracts powering the Dunk Poge NFT ecosystem on Ethereum.  
> No admin. No pause. No upgrades. No trust required.

## Deployed Contracts

| Contract | Address | Etherscan |
|----------|---------|-----------|
| DunkPoge NFT | `0x...` | [View →](https://etherscan.io/address/0xdE912cCB0c7F437A317D7A2Fd206E5C4D61f2B9B#code) |
| Pogecoin (POGE) | `0x...` | [View →](https://etherscan.io/address/0x9CE5C3B543269008fE4522f8bF2eb595C5BeE4E1#code) |
| DunkPogeStaking | `0x...` | [View →](https://etherscan.io/address/0x9C2ec41B477DeD75579Cb096A4Cf55201C164d0e#code) |

## Overview

### DunkPoge NFT (`dunkpogenft.sol`)
- ERC721A — gas-optimized batch minting
- 10,000 fixed supply
- **Price:** 0.005 ETH
- **Max per wallet:** 10
- **Royalty:** 5% (ERC2981)
- Fully on-chain SVG generation — no IPFS, no servers
- Traits derived deterministically from on-chain seed at mint time
- ~2 billion possible combinations
- Owner can toggle sale and withdraw mint funds — cannot modify metadata or traits

### Pogecoin (`pogecoin.sol`)
- Standard ERC20
- 1,000,000,000 (1B) fixed supply minted at deployment
- No mint, burn, or pause functions post-deployment
- Transferred entirely to staking contract at launch

### DunkPogeStaking (`dunkpogestaking.sol`)
- Zero admin functions — fully immutable after deployment
- Emission decays from ~10 POGE/day → ~1 POGE/day per NFT over 730 days
- Loyalty multiplier: 1x → 2x over 180 days of continuous staking
- Achievements: Early Adopter, Diamond Paws, Collector, Poge Whale
- Graceful pool degradation — partial payments on low balance, no reverts
- `emergencyWithdraw()` always returns NFTs regardless of pool state

## Security Patterns

- `ReentrancyGuard` on all state-changing functions
- `SafeERC20` prevents silent transfer failures
- `ERC721A` battle-tested batch minting library
- Checks-Effects-Interactions pattern throughout
- No external calls beyond ERC20/721 transfers
- No proxy patterns — contracts are immutable

## Trustlessness

These contracts pass the **Walkaway Test**: if the team disappears, all contracts continue functioning indefinitely. Users can always unstake NFTs and claim rewards without any team involvement.

See: [The Trustless Manifesto](https://trustlessness.eth.limo/general/2025/11/11/the-trustless-manifesto.html)

## Trait System

Traits are generated on-chain at mint time using:

```solidity
baseSeed = keccak256(block.prevrandao, block.timestamp, startTokenId, minter, tx.gasprice)
tokenSeed[tokenId] = keccak256(baseSeed, tokenId, index)
```

Rarity is **emergent** — determined by actual mint distribution, not predetermined weights. Attempting to snipe specific traits makes them more common, creating natural manipulation resistance.

## Emission Math

```solidity
// Quadratic decay over 730 days
baseReward = duration × BASE_EMISSION
bonusReward = INITIAL_BONUS × (t1² - t2²) / (2 × DECAY_PERIOD)

// Loyalty multiplier (linear over 180 days)
multiplier = 1.0x + (1.0x × stakeDuration / 180 days)

finalReward = (baseReward + bonusReward) × multiplier
```

Example timeline per NFT (no multiplier):
- Day 1: ~10 POGE/day
- Day 180: ~6.25 POGE/day
- Day 365: ~3.75 POGE/day
- Day 730: ~1 POGE/day

## Supply Planning

| Scenario | POGE Used | Buffer |
|----------|-----------|--------|
| Worst case (10K NFTs, max multipliers) | ~724M | 276M (27.6%) |
| Realistic (70% participation) | ~400M | 600M (60%) |

## Frontend

[github.com/dunkpoge/frontend](https://github.com/dunkpoge/frontend)

## Links

- [Live Site](https://dunkpoge.com)
- [Manifesto](https://trustlessness.eth.limo/general/2025/11/11/the-trustless-manifesto.html)
- [Discord](https://discord.gg/7PsZwC3TZX)
- [Twitter](https://twitter.com/dunkpoge)
- [OpenSea](https://opensea.io/collection/dunk-poge)

## License

MIT
