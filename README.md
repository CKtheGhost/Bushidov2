# 🏯 Bushido NFT Collection

> **Interactive NFT project blending digital collectibles with episodic anime storytelling**

## Project Overview

Bushido introduces a pioneering approach to NFT collections where holders directly shape an evolving anime narrative through on-chain voting. The collection features 1,600 unique samurai NFTs distributed across eight clans, each embodying a virtue of the Bushido code.

### Core Innovation
NFT ownership drives story evolution, character development, and clan dynamics—creating the first truly interactive narrative-based NFT ecosystem.

## 🎯 Stealth Launch Strategy

### Phase 1: Stealth Drop
- **Platform**: Abstract L2 (optimized for low gas fees)
- **Website**: Minimalist landing with countdown timer and cryptic clan symbols
- **Marketing**: 10-15 KOL early access without paid promotion

### Phase 2: Post-Mint Reveal
- Full Bushido lore and clan descriptions
- Voting mechanics and evolution system
- Community Discord with clan-based channels

### Phase 3: Series Launch
- Episode 1 premiere (1 week post-sellout)
- Weekly episodes with integrated voting
- NFT evolution based on community decisions

## 🏗️ Technical Architecture

### Project Structure
```
bushido-nft/
├── contracts/              # Smart contracts (ERC-721 + voting mechanics)
│   ├── contracts/         # Solidity contracts
│   ├── scripts/          # Deployment scripts
│   └── test/            # Contract tests
├── frontend/             # Next.js stealth launch site
│   ├── src/
│   │   ├── app/         # App router pages
│   │   ├── components/  # React components
│   │   └── hooks/       # Custom hooks
│   └── public/          # Static assets
├── backend/             # Express.js API server
│   └── src/
│       ├── routes/      # API endpoints
│       └── services/    # Business logic
├── scripts/             # Utility scripts
│   └── metadata/        # NFT metadata generation
└── docs/               # Documentation

```

### Tech Stack
- **Blockchain**: Abstract L2
- **Smart Contracts**: Solidity + Hardhat
- **Frontend**: Next.js 14 + RainbowKit + Wagmi
- **Backend**: Express.js + Redis caching
- **Storage**: IPFS (via Pinata)
- **Deployment**: Vercel (frontend) + Railway (backend)

## 📦 Collection Details

### Distribution
- **Total Supply**: 1,600 NFTs
- **Per Clan**: 200 warriors
- **Mint Price**: 0.03 ETH
- **Max per Wallet**: 3 NFTs

### The Eight Clans
| Clan | Virtue | Color | ID Range |
|------|--------|-------|----------|
| 🐲 Dragon | Courage | #DC2626 | 1-200 |
| 🔥 Phoenix | Rebirth | #EA580C | 201-400 |
| 🐯 Tiger | Strength | #F59E0B | 401-600 |
| 🐍 Serpent | Wisdom | #10B981 | 601-800 |
| 🦅 Eagle | Vision | #3B82F6 | 801-1000 |
| 🐺 Wolf | Loyalty | #6366F1 | 1001-1200 |
| 🐻 Bear | Protection | #8B5CF6 | 1201-1400 |
| 🦁 Lion | Leadership | #EC4899 | 1401-1600 |

### Rarity Tiers
- **Common** (50%): Base voting power
- **Uncommon** (25%): 4x voting power
- **Rare** (15%): 9x voting power
- **Epic** (7.5%): 16x voting power
- **Legendary** (2.5%): 25x voting power

## 🚀 Quick Start

### Prerequisites
- Node.js 18+
- pnpm 8+
- Git

### Installation
```bash
# Clone repository
git clone https://github.com/your-org/bushido-nft.git
cd bushido-nft

# Install dependencies
pnpm install

# Configure environment
cp .env.example .env
# Edit .env with your values
```

### Development
```bash
# Start all services
pnpm dev

# Or run individually:
cd frontend && pnpm dev  # Frontend at http://localhost:3000
cd backend && pnpm dev   # Backend at http://localhost:4000
```

### Deployment
```bash
# Deploy smart contracts
pnpm deploy:testnet  # Abstract testnet
pnpm deploy:mainnet  # Abstract mainnet

# Deploy frontend (stealth mode)
cd frontend && vercel --prod

# Deploy backend
cd backend && railway up
```

## 🎨 Current Status

### ✅ Completed
- Project structure and monorepo setup
- Smart contract architecture
- Frontend stealth launch framework
- Backend API structure
- Deployment scripts

### 🚧 In Progress
- Waiting for artist to upload artwork to Pinata
- Smart contract testing and auditing
- KOL outreach list compilation

### 📋 Next Steps
1. **Artwork Integration** (Pending)
   - Receive IPFS hashes from artist
   - Update metadata generation scripts
   - Configure Pinata gateway

2. **Smart Contract Finalization**
   - Complete unit tests
   - Run security audit
   - Deploy to testnet

3. **Frontend Polish**
   - Implement countdown timer
   - Add subtle animations
   - Optimize for mobile

4. **Launch Preparation**
   - Finalize KOL list
   - Set launch date/time
   - Prepare reveal content

## 🔧 Key Scripts

### Development
```bash
./dev.ps1              # Start development environment
./run.ps1              # Run specific services
```

### Deployment
```bash
./deploy.ps1 testnet   # Deploy to testnet
./deploy.ps1 mainnet   # Deploy to mainnet
./launch-stealth.ps1   # Deploy stealth site
```

### Utilities
```bash
cd scripts
pnpm generate-metadata # Generate NFT metadata
pnpm upload-ipfs      # Upload to IPFS (when ready)
```

## 🔐 Environment Variables

Create a `.env` file based on `.env.example`:

```env
# Network Configuration
ABSTRACT_RPC=https://api.abs.xyz
ABSTRACT_TESTNET_RPC=https://api.testnet.abs.xyz
PRIVATE_KEY=your_wallet_private_key

# Contract Addresses (after deployment)
CONTRACT_ADDRESS=
IPFS_BASE_URI=

# Frontend
NEXT_PUBLIC_NETWORK=abstract
NEXT_PUBLIC_CONTRACT_ADDRESS=
NEXT_PUBLIC_CHAIN_ID=11124
NEXT_PUBLIC_LAUNCH_TIME=2025-01-XX-00:00:00Z

# Backend
PORT=4000
REDIS_URL=redis://localhost:6379

# IPFS/Pinata
PINATA_API_KEY=
PINATA_SECRET_KEY=
```

## 📊 Launch Metrics

### Target Goals
- **Mint Out**: 72 hours
- **Floor Price**: 0.3 ETH (6 months)
- **Voting Participation**: >80% per episode
- **Holder Retention**: >90% (12 months)

### Revenue Projections
- **Year 1**: $500K (mint + royalties)
- **Year 2**: $9M (+ streaming + merch)
- **Year 3**: $17M (expanded ecosystem)

## 🤝 Contributing

This project is currently in stealth mode. Contributing guidelines will be published post-launch.

## 📜 License

All rights reserved. Details to be announced post-launch.

---

<div align="center">

**"Where art meets anime. Where ownership meets narrative. Where legends are born."**

*Bushido NFT - Launching Soon on Abstract*

</div>