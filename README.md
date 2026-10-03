# Consent-Based Financial Data Sharing Platform

A blockchain-backed consent and audit-log layer for financial data sharing. Users keep their real
data off-chain; the chain only ever stores identity hashes, issuer attestations, consent records,
and an append-only access log.
## Prerequisites

- Node.js (v20+) and npm
- Python 3 with `web3` and `eth-account` installed, if you're running the off-chain `LocalStorage`
  module (`pip install web3 eth-account`)

## Install

```bash
npm install
```

## Compile

```bash
npx hardhat compile
```

## Run the tests

```bash
npx hardhat test solidity
```

Runs the Foundry-style Solidity unit tests (`*.t.sol`) for every contract: `IdentityRegistry`,
`Token`, `ConsentManager`.

## Run it locally (deploy + interact)

Two terminals, the node has to stay running while you interact with it.

**Terminal 1** — start a persistent local chain:
```bash
npx hardhat node
```
Leave this running. It prints 20 funded test accounts; `Ctrl+C` stops it and wipes all state.

**Terminal 2** — deploy the contracts, then run the demo interaction:
```bash
npx hardhat run scripts/deploy.js --network localhost
npx hardhat run scripts/interact.js --network localhost
```
`deploy.js` deploys `IdentityRegistry` → `Token` → `ConsentManager` → transfers `Token` ownership to
`ConsentManager` → deploys `DataSharing`, in that order. `interact.js` then simulates a user
granting consent, receiving a reward token, and a requester successfully requesting access.

**Important:** don't re-run `deploy.js` against a node that's already had contracts deployed to
it the resulting addresses will shift, and `interact.js`'s addresses (currently hardcoded) will
go stale. Either restart the node (`Ctrl+C` in Terminal 1, then `npx hardhat node` again) before
redeploying, or redeploy and update the addresses in `interact.js` to match.

## Project structure

```
contracts/            Solidity contracts (*.sol) and their unit tests (*.t.sol)
contracts/LocalStorage.py   Off-chain module: local data storage, hashing, ticket verification
docs/                  Design document, diagrams, references
ignition/modules/      Hardhat Ignition deployment modules
scripts/               deploy.js, interact.js — manual deployment/simulation scripts
```
