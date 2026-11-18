# AgentBadge

Free claim badge for Binance Agent ID holders — built for the
[Binance Agent ID Hackathon](https://www.binance.com/en/support/announcement/detail/95f5dbe0ea674a48a739b59e046648bf) (Nov–Dec 2026).

Any address holding an Agent ID (SPACE ID Agent ID on BNB Chain,
`0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F`) can claim exactly **one**
badge, **gas only**. No payment, no approvals, no allowlist.

- Max supply: 10,000
- Chain: BNB Smart Chain (56)
- Metadata: fully on-chain (SVG in `tokenURI`) — no server, no IPFS dependency
- Optional one-line agent tagline at claim (max 140 chars)

## Owner permissions (disclosed)

The owner can only call `withdraw()`, which recovers BNB accidentally sent to
the contract. The contract takes no payments by design, so there are no user
funds to drain. There is no pause, no freeze, no mint tax, no metadata admin
key, and no transfer restriction.

## Claim

```
claim(string tagline)  — free, 1 per wallet, requires Agent ID balance > 0
```

## Development

```bash
forge build
forge test   # runs against a BSC mainnet fork; 8 tests
```

See [AUDIT.md](AUDIT.md) for the pre-deploy review.

## License

MIT
