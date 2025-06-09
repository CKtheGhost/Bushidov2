// scripts/generate-metadata.ts
import { create } from 'ipfs-http-client';
import fs from 'fs/promises';
import path from 'path';

const IPFS_GATEWAY = 'https://ipfs.io/ipfs/';
const ipfs = create({ url: 'https://api.pinata.cloud' });

interface Metadata {
  name: string;
  description: string;
  image: string;
  attributes: Array<{
    trait_type: string;
    value: string | number;
  }>;
}

const CLANS = [
  'Dragon', 'Phoenix', 'Tiger', 'Wolf', 
  'Eagle', 'Serpent', 'Bear', 'Lion'
];

const RARITIES = ['Common', 'Uncommon', 'Rare', 'Epic', 'Legendary'];

async function generateMetadata() {
  const metadataList: Metadata[] = [];
  
  for (let tokenId = 1; tokenId <= 1600; tokenId++) {
    const clanIndex = Math.floor((tokenId - 1) / 200);
    const clan = CLANS[clanIndex];
    const rarityIndex = getRarityIndex(tokenId);
    const rarity = RARITIES[rarityIndex];
    
    const metadata: Metadata = {
      name: `Bushido Samurai #${tokenId}`,
      description: `A legendary warrior of the ${clan} Clan, embodying the virtues of Bushido.`,
      image: `${IPFS_GATEWAY}${await uploadImage(tokenId, clan, rarity)}`,
      attributes: [
        {
          trait_type: 'Clan',
          value: clan
        },
        {
          trait_type: 'Rarity',
          value: rarity
        },
        {
          trait_type: 'Voting Power',
          value: (rarityIndex + 1) ** 2
        },
        {
          trait_type: 'Episode 1 Eligible',
          value: true
        }
      ]
    };
    
    metadataList.push(metadata);
    
    // Save individual metadata
    const metadataPath = path.join('metadata', `${tokenId}.json`);
    await fs.writeFile(metadataPath, JSON.stringify(metadata, null, 2));
  }
  
  // Upload all metadata to IPFS
  const metadataHash = await uploadDirectory('metadata');
  console.log(`Metadata uploaded to IPFS: ${IPFS_GATEWAY}${metadataHash}`);
}

function getRarityIndex(tokenId: number): number {
  const rand = parseInt(
    require('crypto')
      .createHash('sha256')
      .update(tokenId.toString())
      .digest('hex')
      .slice(0, 8),
    16
  );
  
  const normalized = rand % 100;
  if (normalized < 1) return 4;   // Legendary
  if (normalized < 5) return 3;   // Epic
  if (normalized < 15) return 2;  // Rare
  if (normalized < 35) return 1;  // Uncommon
  return 0;                       // Common
}