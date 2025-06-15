const fs = require('fs').promises;
const path = require('path');
const pinataSDK = require('@pinata/sdk');

class BushidoMetadataGenerator {
  constructor(config) {
    this.config = {
      totalSupply: 1600,
      clansCount: 8,
      warriorsPerClan: 200,
      pinataApiKey: config.pinataApiKey,
      pinataSecretKey: config.pinataSecretKey,
      imageBaseUri: config.imageBaseUri || '',
      ...config
    };
    
    this.pinata = pinataSDK(this.config.pinataApiKey, this.config.pinataSecretKey);
    
    this.clans = [
      { id: 0, name: 'Dragon', virtue: 'Courage', color: '#DC2626', kanji: '龍' },
      { id: 1, name: 'Phoenix', virtue: 'Rebirth', color: '#EA580C', kanji: '鳳' },
      { id: 2, name: 'Tiger', virtue: 'Strength', color: '#F59E0B', kanji: '虎' },
      { id: 3, name: 'Serpent', virtue: 'Wisdom', color: '#10B981', kanji: '蛇' },
      { id: 4, name: 'Eagle', virtue: 'Vision', color: '#3B82F6', kanji: '鷲' },
      { id: 5, name: 'Wolf', virtue: 'Loyalty', color: '#6366F1', kanji: '狼' },
      { id: 6, name: 'Bear', virtue: 'Protection', color: '#8B5CF6', kanji: '熊' },
      { id: 7, name: 'Lion', virtue: 'Leadership', color: '#EC4899', kanji: '獅' }
    ];
    
    this.rarities = [
      { name: 'Common', weight: 50, votingPower: 1 },
      { name: 'Uncommon', weight: 25, votingPower: 4 },
      { name: 'Rare', weight: 15, votingPower: 9 },
      { name: 'Epic', weight: 7.5, votingPower: 16 },
      { name: 'Legendary', weight: 2.5, votingPower: 25 }
    ];
  }
  
  generateTokenMetadata(tokenId) {
    const clanIndex = Math.floor((tokenId - 1) / this.config.warriorsPerClan);
    const clan = this.clans[clanIndex];
    const warriorNumber = ((tokenId - 1) % this.config.warriorsPerClan) + 1;
    const rarity = this.determineRarity(tokenId);
    
    const metadata = {
      name: `Bushido Warrior #${tokenId}`,
      description: `A ${rarity.name.toLowerCase()} warrior of the ${clan.name} clan, embodying the virtue of ${clan.virtue.toLowerCase()}.`,
      image: `${this.config.imageBaseUri}/${tokenId}.png`,
      external_url: `https://bushido.art/warrior/${tokenId}`,
      attributes: [
        { trait_type: 'Clan', value: clan.name },
        { trait_type: 'Virtue', value: clan.virtue },
        { trait_type: 'Rarity', value: rarity.name },
        { trait_type: 'Warrior Number', value: warriorNumber, display_type: 'number' },
        { trait_type: 'Voting Power', value: rarity.votingPower, display_type: 'number' }
      ]
    };
    
    return metadata;
  }
  
  determineRarity(tokenId) {
    const hash = require('crypto').createHash('sha256').update(tokenId.toString()).digest('hex');
    const rand = (parseInt(hash.substr(0, 8), 16) % 1000) / 10;
    
    let cumulativeWeight = 0;
    for (const rarity of this.rarities) {
      cumulativeWeight += rarity.weight;
      if (rand <= cumulativeWeight) {
        return rarity;
      }
    }
    
    return this.rarities[0];
  }
  
  async generateAllMetadata() {
    console.log('Generating metadata for', this.config.totalSupply, 'warriors...');
    
    const metadataDir = path.join(process.cwd(), 'metadata', 'json');
    await fs.mkdir(metadataDir, { recursive: true });
    
    const allMetadata = [];
    
    for (let tokenId = 1; tokenId <= this.config.totalSupply; tokenId++) {
      const metadata = this.generateTokenMetadata(tokenId);
      allMetadata.push(metadata);
      
      const filePath = path.join(metadataDir, `${tokenId}.json`);
      await fs.writeFile(filePath, JSON.stringify(metadata, null, 2));
      
      if (tokenId % 100 === 0) {
        console.log(`Generated metadata for ${tokenId}/${this.config.totalSupply} warriors`);
      }
    }
    
    await fs.writeFile(
      path.join(metadataDir, '_collection.json'),
      JSON.stringify(allMetadata, null, 2)
    );
    
    console.log('Metadata generation complete!');
    return allMetadata;
  }
}

module.exports = BushidoMetadataGenerator;
