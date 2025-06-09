# Bushido NFT

![Bushido Logo](Bushido-Logo-RED.jpg)

Bushido NFT is an experimental storytelling project where a limited collection of on-chain samurai grants holders the ability to steer an animated series. Votes are weighted by rarity, letting the community decide how the saga unfolds.

## Lore Snapshot

*Excerpt from the project lore:* An ambitious entrepreneur uncovers an artifact that maps a hidden valley. Activating it flings him into 16th‑century Japan, where eight clans embodying the virtues of Bushido battle a malevolent doppelgänger seeking to corrupt them.【0b5429†L1-L23】

## Repository Guide

- **[Architecture](Architecture.md)** – directory breakdown of contracts, backend and frontend.
- **[Complete Tech Stack](CompleteTechStack.md)** – frameworks and infrastructure used.
- **[Lore Overview](docs/Lore.md)** – summary of the anime narrative.

## Quick Start

1. Clone the repository
2. Install dependencies with `pnpm install`
3. Copy `.env.example` to `.env` and fill in RPC_URL, CONTRACT_ADDRESS, and other values
4. Deploy contracts via `pnpm deploy`
5. Start the backend API with `pnpm --filter backend dev`
6. Launch the frontend with `pnpm --filter frontend dev`

## Voting Mechanics

Rarity determines a holder's voting power:

- Common: 1 vote
- Uncommon: 4 votes
- Rare: 9 votes
- Epic: 16 votes
- Legendary: 25 votes

## Sample Characters

Below are a few samurai NFTs that can serve as story protagonists:

![Samurai #78](78.jpg)
![Samurai #139](139.jpg)
![Samurai #188](188.jpg)

## Episode Schedule

Episodes release weekly with a 48‑hour voting window for key decisions.

## Connect

- Website: [bushido.xyz]
- Twitter: [@BushidoNFT]
- Discord: [Join our community]

