bushido-nft/
├── contracts/                    # Smart contracts
│   ├── BushidoNFT.sol           # Main NFT contract with voting
│   ├── interfaces/
│   │   └── IBushidoNFT.sol
│   └── lib/
│       └── VotingMechanics.sol
│
├── frontend/                     # Next.js 14 App
│   ├── src/
│   │   ├── app/
│   │   │   ├── (landing)/       # Stealth launch pages
│   │   │   │   ├── countdown/
│   │   │   │   │   └── page.tsx
│   │   │   │   └── layout.tsx
│   │   │   ├── (main)/          # Post-launch pages
│   │   │   │   ├── mint/
│   │   │   │   │   └── page.tsx
│   │   │   │   ├── collection/
│   │   │   │   │   └── page.tsx
│   │   │   │   ├── episodes/
│   │   │   │   │   ├── page.tsx
│   │   │   │   │   └── [episode]/
│   │   │   │   │       └── page.tsx
│   │   │   │   └── layout.tsx
│   │   │   ├── api/
│   │   │   │   ├── voting/
│   │   │   │   │   └── route.ts
│   │   │   │   └── metadata/
│   │   │   │       └── [tokenId]/
│   │   │   │           └── route.ts
│   │   │   ├── layout.tsx
│   │   │   └── globals.css
│   │   │
│   │   ├── components/
│   │   │   ├── countdown/
│   │   │   │   ├── CountdownTimer.tsx
│   │   │   │   └── StealthReveal.tsx
│   │   │   ├── mint/
│   │   │   │   ├── MintButton.tsx
│   │   │   │   ├── ClanSelector.tsx
│   │   │   │   └── MintProgress.tsx
│   │   │   ├── episodes/
│   │   │   │   ├── VideoPlayer.tsx
│   │   │   │   ├── VotingPanel.tsx
│   │   │   │   └── EpisodeCard.tsx
│   │   │   ├── shared/
│   │   │   │   ├── Navigation.tsx
│   │   │   │   ├── WalletConnect.tsx
│   │   │   │   └── LoadingSpinner.tsx
│   │   │   └── three/
│   │   │       └── SamuraiModel.tsx
│   │   │
│   │   ├── lib/
│   │   │   ├── web3/
│   │   │   │   ├── contract.ts
│   │   │   │   ├── abstract.ts
│   │   │   │   └── wagmi.ts
│   │   │   ├── voting/
│   │   │   │   ├── power.ts
│   │   │   │   └── episodes.ts
│   │   │   └── utils/
│   │   │       ├── constants.ts
│   │   │       └── helpers.ts
│   │   │
│   │   ├── hooks/
│   │   │   ├── useCountdown.ts
│   │   │   ├── useVotingPower.ts
│   │   │   └── useMint.ts
│   │   │
│   │   └── styles/
│   │       └── animations.css
│   │
│   ├── public/
│   │   ├── videos/              # Episode previews
│   │   ├── models/              # 3D samurai models
│   │   └── images/              # Clan images, backgrounds
│   │
│   └── package.json
│
├── backend/                      # Express.js API
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
│   │
│   └── package.json
│
├── scripts/                      # Deployment & management
│   ├── deploy.ts
│   ├── generate-metadata.ts
│   └── upload-to-ipfs.ts
│
├── metadata/                     # NFT metadata templates
│   ├── clans/
│   └── traits/
│
└── docs/
    ├── README.md
    ├── SETUP.md
    └── DEPLOYMENT.md