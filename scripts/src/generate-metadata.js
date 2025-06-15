import fs from 'fs';
import path from 'path';

const clans = [
  { name: 'Dragon', virtue: 'Courage', color: '#DC2626' },
  { name: 'Phoenix', virtue: 'Rebirth', color: '#EA580C' },
  { name: 'Tiger', virtue: 'Strength', color: '#F59E0B' },
  { name: 'Serpent', virtue: 'Wisdom', color: '#10B981' },
  { name: 'Eagle', virtue: 'Vision', color: '#3B82F6' },
  { name: 'Wolf', virtue: 'Loyalty', color: '#6366F1' },
  { name: 'Bear', virtue: 'Protection', color: '#8B5CF6' },
  { name: 'Lion', virtue: 'Leadership', color: '#EC4899' }
];

const rarities = [
  { name: 'Common', weight: 50 },
  { name: 'Uncommon', weight: 25 },
  { name: 'Rare', weight: 15 },
  { name: 'Epic', weight: 7.5 },
  { name: 'Legendary', weight: 2.5 }
];

function generateMetadata(tokenId) {
  const clanIndex = Math.floor((tokenId - 1) / 200);
  const clan = clans[clanIndex];
  const warriorNumber = ((tokenId - 1) % 200) + 1;
  
  // Determine rarity
  const rand = Math.random() * 100;
  let cumulativeWeight = 0;
  let rarity = 'Common';
  
  for (const r of rarities) {
    cumulativeWeight += r.weight;
    if (rand <= cumulativeWeight) {
      rarity = r.name;
      break;
    }
  }
  
  return {
    name: `Bushido Warrior #${tokenId}`,
    description: `A ${rarity.toLowerCase()} warrior of the ${clan.name} clan, embodying the virtue of ${clan.virtue.toLowerCase()}.`,
    image: `ipfs://QmXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX/${tokenId}.png`,
    attributes: [
      { trait_type: 'Clan', value: clan.name },
      { trait_type: 'Virtue', value: clan.virtue },
      { trait_type: 'Rarity', value: rarity },
      { trait_type: 'Warrior Number', value: warriorNumber }
    ]
  };
}

// Generate all metadata
console.log('Generating metadata for 1600 warriors...');

for (let i = 1; i <= 1600; i++) {
  const metadata = generateMetadata(i);
  const outputPath = path.join('metadata', `${i}.json`);
  
  fs.writeFileSync(outputPath, JSON.stringify(metadata, null, 2));
  
  if (i % 100 === 0) {
    console.log(`Generated ${i}/1600...`);
  }
}

console.log('Metadata generation complete!');
