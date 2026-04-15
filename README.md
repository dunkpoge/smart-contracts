# Dunk Poge

> 10,000 fully on-chain generative NFTs on Ethereum. Stake to earn $POGE tokens.

**Contract Addresses**

| Contract | Address |
|---|---|
| DunkPoge NFT (ERC-721A) | `0xdE912cCB0c7F437A317D7A2Fd206E5C4D61f2B9B` |
| Pogecoin — $POGE (ERC-20) | `0x9CE5C3B543269008fE4522f8bF2eb595C5BeE4E1` |
| Staking Contract | `0x9C2ec41B477DeD75579Cb096A4Cf55201C164d0e` |

**Links:** [Website](https://dunkpoge.com) · [OpenSea](https://opensea.io/collection/dunk-poge) · [X / Twitter](https://x.com/dunkpoge) · [Discord](https://discord.gg/7PsZwC3TZX)

---

## Philosophy

Dunk Poge is built around one principle: **if the team disappears tomorrow, nothing changes**.

- NFT artwork, metadata, and staking logic are stored entirely in the smart contracts
- No IPFS. No external servers. No admin key. No upgrade proxy.
- Every user authorizes their own actions — nobody mints, stakes, or claims on your behalf
- Emission rates, decay curves, and multipliers are public constants — no hidden mechanics
- `emergencyWithdraw()` always returns your NFTs even if rewards are forfeited

This is what the walkaway test looks like in practice: the contracts continue functioning regardless of the team, the website, or any infrastructure.

---

## Contracts

### DunkPoge NFT — ERC-721A

| Parameter | Value |
|---|---|
| Standard | ERC-721A (batch minting) |
| Max Supply | 10,000 |
| Mint Price | 0.005 ETH |
| Max Per Wallet | 10 |
| Royalty | 5% |
| Metadata | 100% on-chain SVG |
| Combinations | ~2 billion |

Art and metadata are generated and stored entirely within the contract. Each token's SVG is produced at mint time using on-chain entropy (block hash, timestamp, token ID). No tokenURI points to an external server.

### Pogecoin — $POGE (ERC-20)

| Parameter | Value |
|---|---|
| Standard | ERC-20 |
| Total Supply | 1,000,000,000 POGE (fixed) |
| Allocation | 100% to staking rewards |
| Admin Functions | None |
| Mint Function | None after deployment |

POGE was never sold. It is earned exclusively through staking Dunk Poge NFTs. There was no public sale, private sale, seed round, or team allocation.

### Staking Contract

| Parameter | Value |
|---|---|
| Type | Immutable vault |
| Admin Functions | Zero |
| Pause Function | None |
| Upgrade Function | None |
| Emission Duration | 264 years |
| Loyalty Multiplier | 1x → 2x over 180 days |
| Lock-up | None — unstake anytime |

---

## Staking Mechanics

### Emission Decay

Rewards decay quadratically over time. Early stakers earn significantly more.

| Day | Base Rate (per NFT) | With 2x Multiplier |
|---|---|---|
| Day 1 | ~10 POGE/day | ~10 POGE/day |
| Day 180 | ~6.25 POGE/day | ~9.375 POGE/day |
| Day 365 | ~3.75 POGE/day | ~7.5 POGE/day |
| Day 730 | ~1 POGE/day | ~2 POGE/day |

### Loyalty Multiplier

The longer you stake continuously, the more you earn. The multiplier grows from 1x to 2x over 180 days of continuous staking. Claiming rewards does **not** reset the multiplier — only unstaking does.

### Achievements

| Achievement | Requirement |
|---|---|
| Early Adopter | Stake within the first 30 days |
| Diamond Paws | Stake continuously for 180+ days |
| Collector | Hold 10+ NFTs staked for 7+ days at peak |
| Poge Whale | Earn 10,000+ POGE total |

---

## NFT Trait Layers

| Layer | Options | Notes |
|---|---|---|
| Skin | 10 | — |
| Eye Color | 7 | — |
| Lip Color | 7 | — |
| Hair Style | 18 | 80% have styled hair |
| Hair Color | 15 | — |
| Eyewear | 11 | 60% have eyewear |
| Headwear | 10 | 60% have headwear |
| Accessory Layer 1 | 8 | Weighted distribution |
| Accessory Layer 2 | 4 | 85% none |
| Accessory Layer 3 | 5 | 70% none |

Rarity is emergent from mint distribution. Attempting to game specific traits makes them more common, not rarer.

---

## Security

### Patterns Used

- `ReentrancyGuard` on all state-changing functions
- `SafeERC20` prevents silent transfer failures
- `ERC721A` battle-tested batch minting
- Checks-Effects-Interactions pattern throughout
- No external calls except standard ERC-20/721 transfers
- Stack depth optimized for gas savings

### What This Means For Users

- Your NFTs are always withdrawable — pool depletion results in partial payment, not reverts
- No admin can prevent unstaking or claiming rewards
- Anyone can verify rarity, pending rewards, and emission rates directly from contract code
- The staking contract has zero admin functions — it cannot be paused, upgraded, or modified

---

## On-Chain SVG Generation

Each NFT is a resolution-independent SVG generated and stored entirely on-chain. SVG was chosen because:

- Resolution-independent — scales infinitely without quality loss
- Smaller than base64 image data
- Native browser and marketplace support
- Allows dynamic on-chain styling

The artwork lives as long as Ethereum does.

---

## Privacy

The frontend is a static React app with no backend, no database, and no analytics. We architecturally cannot collect data. See [dunkpoge.com/#/privacy](https://dunkpoge.com/#/privacy) for the full privacy policy.

**We don't know:** who you are, where you are, what browser you use, whether you've minted or staked, or anything else about you.

**What is public:** your wallet address, transaction history, NFT ownership, and POGE balance — because that's inherent to Ethereum, not something we collect.

---

## Contact

- Email: hello@dunkpoge.com
- X / Twitter: [@dunkpoge](https://x.com/dunkpoge)
- Discord: [discord.gg/7PsZwC3TZX](https://discord.gg/7PsZwC3TZX)

---

*Much permanent · Very immutable · Wow*
