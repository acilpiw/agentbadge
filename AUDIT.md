# AgentBadge — pre-deploy review (advice only)

Date: 2026-11-18. Reviewer: agent self-review + forge tests on BSC mainnet fork.
Scope: `src/AgentBadge.sol` (Solady ERC721 + Ownable). This is a PRE-DEPLOY review:
there is no on-chain address yet, so the bsc-contract-audit skill's on-chain probes
(Sourcify exact_match, selector scan, holder reconstruction) cannot run until after
deploy. Full on-chain audit to be re-run against the deployed address.

## Rubric mapping (MINT track, bsc-contract-audit v3.2.0)

### Security
- No proxy, no upgrade path. No pause, no blacklist, no trading gate.
- Hidden mint: NO. `claim()` is bounded by `MAX_SUPPLY = 10000`, one claim per
  address (`hasClaimed`), and requires Agent ID `balanceOf > 0`. Owner cannot mint
  for free beyond the same single claim any holder gets (owner address holds an
  Agent ID, so max 1 badge like anyone else).
- Live owner: YES, but minimal and disclosed — `withdraw()` only, recovers BNB
  accidentally sent to the contract. Contract takes no payments by design, so
  there are no user funds to drain. No `setBaseURI`, no mint, no freeze.
- Source will be verified on BscScan after deploy (required by hackathon rules).

### Investor protection
- No mint fee (free claim, gas only) — proceeds-drain risk does not apply.
- Resale: standard ERC721 `transferFrom`, never paused, no royalty function
  (marketplace default 0). Not soulbound.
- Reveal: metadata is FULLY ON-CHAIN (base64 SVG in `tokenURI`). There is no
  baseURI to mutate — strictly stronger than frozen IPFS.
- Refund: N/A — nothing is paid.

### Anti-manipulation
- No team allocation, no allowlist, no sale windows, no discretionary timing.
  Claim is open until `MAX_SUPPLY` is reached.
- Reentrancy: checks-effects-interactions holds — state (`hasClaimed`,
  `totalClaimed`, tagline) is written BEFORE `_mint` (which can call
  `onERC721Received` on contract recipients). The only external call before
  state writes is the view-only `AGENT_ID.balanceOf`.

### Transparency
- Claims = code (see README: free, 1/wallet, Agent ID gate, 10k cap).
- Team: acilpiw.ai (Binance Agent ID holder, public GitHub @acilpiw).
- Tests: 8/8 pass on BSC mainnet fork (`forge test`), incl. holder / non-holder /
  double-claim / tagline validation / tokenURI prefix.

### Market viability
- N/A pre-deploy. Free badge, no floor, no liquidity. Value is the hackathon
  + the badge itself, not a resale market. Never present as cash.

## Verdict (pre-deploy): GO with one disclosed note
Note: `owner()` is live with `withdraw()` only. It cannot move user funds
(contract holds none by design) — only accidentally sent BNB. Acceptable and
disclosed in README + contract NatSpec.

Re-run full on-chain audit after deploy + BscScan verification.
Reference only, not investment advice.
