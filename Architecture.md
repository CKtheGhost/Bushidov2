## Project Architecture

This document describes the **target** system architecture for Bushido NFT.
While the repository is currently a monorepo skeleton, the goal is to build the
following components working together. The directory layout below mirrors the
packages that will power the final product:

```text
bushido-nft/
├── contracts/                    # Smart contracts
│   ├── BushidoNFT.sol            # Main NFT contract with voting
│   ├── interfaces/
│   │   └── IBushidoNFT.sol
│   └── lib/
│       └── VotingMechanics.sol
│
├── frontend/                     # Next.js 14 app (placeholder)
│   └── src/                      # React components, pages and hooks
│
├── backend/                      # Express API
│   ├── src/
│   │   ├── routes/
│   │   │   ├── voting.ts
│   │   │   ├── metadata.ts
│   │   │   └── episodes.ts
│   │   ├── services/
│   │   │   ├── ipfs.ts
│   │   │   ├── voting.ts
│   │   │   └── cache.ts
│   │   ├── db/
│   │   │   └── schema.ts
│   │   └── index.ts
│   └── package.json
│
├── scripts/                      # Deployment & metadata generation
│   ├── deploy.ts
│   ├── generate-metadata.ts
│   └── upload-to-ipfs.ts
│
├── metadata/                     # NFT trait templates
│   ├── clans/
│   └── traits/
└── docs/ (this directory)        # Additional documentation
```

This layout keeps the blockchain code isolated from application logic while allowing shared tooling and scripts.

### Service Overview

The final platform consists of three main services working together:

1. **Smart Contracts** – Deployed on the Abstract L2 network. The primary
   contract, `BushidoNFT.sol`, manages minting and stores voting power
   calculations. Contracts emit events consumed by off-chain services.
2. **Backend API** – A Node.js (Express) server responsible for serving metadata,
   persisting vote counts in PostgreSQL, caching hot data in Redis and
   interacting with IPFS via Pinata. It also provides authentication endpoints
   for verifying NFT ownership.
3. **Frontend** – A Next.js 14 application that allows users to mint characters,
   watch episodes and participate in voting. It communicates with the backend via
   REST/GraphQL and connects directly to the contracts using Wagmi and Viem.

### Data Flow

1. Users connect their wallet on the frontend and mint NFTs via the smart
   contract.
2. The backend listens to contract events and updates its database records
   accordingly.
3. Episode media and NFT traits are stored on IPFS. Metadata URLs served from the
   backend reference these IPFS hashes.
4. During voting periods the frontend fetches current vote tallies from the
   backend and submits signed votes to be recorded on-chain.

### Deployment Targets

- **Contracts:** Abstract mainnet
- **Frontend:** Vercel
- **Backend:** Railway or Render
- **Storage:** IPFS via Pinata
- **Monitoring:** Sentry and Datadog

These sections collectively represent the architecture we plan to deliver for
the Bushido NFT project.
