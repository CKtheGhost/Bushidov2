// metadata-generator.js
// Complete metadata generation system for Bushido NFT collection

const fs = require('fs').promises;
const path = require('path');
const { create } = require('ipfs-http-client');
const pinataSDK = require('@pinata/sdk');

/**
 * Bushido NFT Metadata Generator
 * Handles metadata creation and IPFS upload for the entire collection
 */
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
    
    // Initialize Pinata
    this.pinata = pinataSDK(this.config.pinataApiKey, this.config.pinataSecretKey);
    
    // Clan definitions
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
    
    // Rarity definitions
    this.rarities = [
      { name: 'Common', weight: 50, votingPower: 1, traits: 3 },
      { name: 'Uncommon', weight: 25, votingPower: 4, traits: 4 },
      { name: 'Rare', weight: 15, votingPower: 9, traits: 5 },
      { name: 'Epic', weight: 7.5, votingPower: 16, traits: 6 },
      { name: 'Legendary', weight: 2.5, votingPower: 25, traits: 7 }
    ];
    
    // Trait categories with variations
    this.traitCategories = {
      weapon: {
        common: ['Katana', 'Naginata', 'Yari'],
        uncommon: ['Kusarigama', 'Kama', 'Tonfa'],
        rare: ['Tessen', 'Kyoketsu-shoge', 'Manriki'],
        epic: ['Legendary Katana', 'Dragon Spear', 'Phoenix Blade'],
        legendary: ['Celestial Sword', 'Divine Naginata', 'Mythic Kusarigama']
      },
      armor: {
        common: ['Standard Do', 'Basic Yoroi', 'Simple Haramaki'],
        uncommon: ['Reinforced Do', 'Battle Yoroi', 'War Haramaki'],
        rare: ['Master\'s Do', 'Elite Yoroi', 'Commander Haramaki'],
        epic: ['Dragon Scale Armor', 'Phoenix Feather Plate', 'Tiger Hide Armor'],
        legendary: ['Celestial Armor', 'Divine Protection', 'Invincible Yoroi']
      },
      helmet: {
        common: ['Basic Kabuto', 'Simple Jingasa', 'Standard Hachigane'],
        uncommon: ['Horned Kabuto', 'Battle Jingasa', 'Reinforced Hachigane'],
        rare: ['Master Kabuto', 'War Jingasa', 'Elite Hachigane'],
        epic: ['Dragon Helm', 'Phoenix Crown', 'Tiger Mask'],
        legendary: ['Celestial Kabuto', 'Divine Crown', 'Mythic Helm']
      },
      background: {
        common: ['Bamboo Forest', 'Mountain Path', 'Village Gate'],
        uncommon: ['Temple Grounds', 'Castle Wall', 'Cherry Blossoms'],
        rare: ['Shrine Steps', 'Waterfall', 'Ancient Bridge'],
        epic: ['Dragon\'s Lair', 'Phoenix Nest', 'Sacred Mountain'],
        legendary: ['Celestial Palace', 'Divine Realm', 'Mythic Battlefield']
      },
      special: {
        common: ['Battle Scar', 'War Paint', 'Clan Banner'],
        uncommon: ['Honor Mark', 'Victory Emblem', 'Battle Trophy'],
        rare: ['Master\'s Seal', 'Elite Badge', 'Champion Mark'],
        epic: ['Dragon\'s Blessing', 'Phoenix Feather', 'Tiger\'s Eye'],
        legendary: ['Divine Aura', 'Celestial Mark', 'Mythic Power']
      }
    };
  }
  
  /**
   * Generate metadata for a single token
   */
  generateTokenMetadata(tokenId) {
    const clanIndex = Math.floor((tokenId - 1) / this.config.warriorsPerClan);
    const clan = this.clans[clanIndex];
    const warriorNumber = ((tokenId - 1) % this.config.warriorsPerClan) + 1;
    const rarity = this.determineRarity(tokenId);
    
    // Generate traits based on rarity
    const traits = this.generateTraits(rarity, clan);
    
    // Base metadata structure
    const metadata = {
      name: `Bushido Warrior #${tokenId}`,
      description: `A ${rarity.name.toLowerCase()} warrior of the ${clan.name} clan, embodying the virtue of ${clan.virtue.toLowerCase()}. This warrior carries the honor of ancient samurai traditions into the digital realm.`,
      image: `${this.config.imageBaseUri}/${tokenId}.png`,
      external_url: `https://bushido.art/warrior/${tokenId}`,
      attributes: [
        {
          trait_type: 'Clan',
          value: clan.name
        },
        {
          trait_type: 'Virtue',
          value: clan.virtue
        },
        {
          trait_type: 'Rarity',
          value: rarity.name
        },
        {
          trait_type: 'Warrior Number',
          value: warriorNumber,
          display_type: 'number'
        },
        {
          trait_type: 'Voting Power',
          value: rarity.votingPower,
          display_type: 'number'
        },
        {
          trait_type: 'Clan Kanji',
          value: clan.kanji
        },
        ...traits
      ],
      properties: {
        clan: {
          name: clan.name,
          id: clanIndex,
          color: clan.color
        },
        rarity: {
          tier: rarity.name,
          voting_power: rarity.votingPower
        },
        files: [
          {
            uri: `${this.config.imageBaseUri}/${tokenId}.png`,
            type: 'image/png'
          }
        ],
        category: 'image'
      }
    };
    
    return metadata;
  }
  
  /**
   * Determine rarity for a token
   */
  determineRarity(tokenId) {
    // Use deterministic randomness based on tokenId
    const hash = this.hashTokenId(tokenId);
    const rand = (parseInt(hash.substr(0, 8), 16) % 1000) / 10;
    
    let cumulativeWeight = 0;
    for (const rarity of this.rarities) {
      cumulativeWeight += rarity.weight;
      if (rand <= cumulativeWeight) {
        return rarity;
      }
    }
    
    return this.rarities[0]; // Default to common
  }
  
  /**
   * Generate traits based on rarity
   */
  generateTraits(rarity, clan) {
    const traits = [];
    const rarityLevel = rarity.name.toLowerCase();
    
    // Select traits from each category
    Object.entries(this.traitCategories).forEach(([category, options]) => {
      const availableTraits = options[rarityLevel] || options.common;
      const selectedTrait = availableTraits[
        this.seededRandom(clan.id + category) % availableTraits.length
      ];
      
      traits.push({
        trait_type: this.capitalizeFirst(category),
        value: selectedTrait
      });
    });
    
    // Add bonus traits for higher rarities
    if (rarity.traits > 5) {
      traits.push({
        trait_type: 'Legendary Status',
        value: 'True'
      });
    }
    
    return traits;
  }
  
  /**
   * Generate all metadata files
   */
  async generateAllMetadata() {
    console.log('🎨 Starting metadata generation for', this.config.totalSupply, 'warriors...');
    
    const metadataDir = path.join(process.cwd(), 'metadata', 'json');
    await fs.mkdir(metadataDir, { recursive: true });
    
    const allMetadata = [];
    
    for (let tokenId = 1; tokenId <= this.config.totalSupply; tokenId++) {
      const metadata = this.generateTokenMetadata(tokenId);
      allMetadata.push(metadata);
      
      // Save individual metadata file
      const filePath = path.join(metadataDir, `${tokenId}.json`);
      await fs.writeFile(filePath, JSON.stringify(metadata, null, 2));
      
      if (tokenId % 100 === 0) {
        console.log(`✓ Generated metadata for ${tokenId}/${this.config.totalSupply} warriors`);
      }
    }
    
    // Save complete metadata collection
    const collectionPath = path.join(metadataDir, '_collection.json');
    await fs.writeFile(collectionPath, JSON.stringify(allMetadata, null, 2));
    
    console.log('✅ Metadata generation complete!');
    return allMetadata;
  }
  
  /**
   * Upload metadata to IPFS via Pinata
   */
  async uploadToPinata(metadata) {
    console.log('📤 Uploading metadata to IPFS via Pinata...');
    
    try {
      // Upload individual metadata files
      const uploads = [];
      
      for (let i = 0; i < metadata.length; i++) {
        const tokenId = i + 1;
        const result = await this.pinata.pinJSONToIPFS(metadata[i], {
          pinataMetadata: {
            name: `Bushido Warrior #${tokenId}`,
            keyvalues: {
              clan: metadata[i].attributes[0].value,
              rarity: metadata[i].attributes[2].value
            }
          }
        });
        
        uploads.push({
          tokenId,
          ipfsHash: result.IpfsHash,
          pinSize: result.PinSize,
          timestamp: result.Timestamp
        });
        
        if (tokenId % 50 === 0) {
          console.log(`✓ Uploaded ${tokenId}/${this.config.totalSupply} to IPFS`);
        }
      }
      
      // Upload collection metadata
      const collectionResult = await this.pinata.pinJSONToIPFS(
        { 
          name: 'Bushido NFT Collection',
          description: 'Interactive NFT collection with episodic anime storytelling',
          tokens: uploads
        },
        {
          pinataMetadata: {
            name: 'Bushido Collection Metadata'
          }
        }
      );
      
      console.log('✅ Upload complete!');
      console.log('📍 Collection IPFS Hash:', collectionResult.IpfsHash);
      
      // Save upload results
      const resultsPath = path.join(process.cwd(), 'metadata', 'ipfs-uploads.json');
      await fs.writeFile(resultsPath, JSON.stringify({
        collectionHash: collectionResult.IpfsHash,
        baseUri: `ipfs://${collectionResult.IpfsHash}`,
        uploads,
        timestamp: new Date().toISOString()
      }, null, 2));
      
      return {
        collectionHash: collectionResult.IpfsHash,
        uploads
      };
    } catch (error) {
      console.error('❌ Upload failed:', error);
      throw error;
    }
  }
  
  /**
   * Verify artwork files exist
   */
  async verifyArtwork() {
    console.log('🔍 Verifying artwork files...');
    
    const artworkDir = path.join(process.cwd(), 'artwork');
    const missing = [];
    
    for (let tokenId = 1; tokenId <= this.config.totalSupply; tokenId++) {
      const imagePath = path.join(artworkDir, `${tokenId}.png`);
      try {
        await fs.access(imagePath);
      } catch {
        missing.push(tokenId);
      }
    }
    
    if (missing.length > 0) {
      console.log(`⚠️  Missing ${missing.length} artwork files:`, missing.slice(0, 10), '...');
      return false;
    }
    
    console.log('✅ All artwork files verified!');
    return true;
  }
  
  /**
   * Upload images to IPFS
   */
  async uploadImages() {
    console.log('📤 Uploading images to IPFS...');
    
    const artworkDir = path.join(process.cwd(), 'artwork');
    const imageUploads = [];
    
    for (let tokenId = 1; tokenId <= this.config.totalSupply; tokenId++) {
      const imagePath = path.join(artworkDir, `${tokenId}.png`);
      const readableStreamForFile = await fs.readFile(imagePath);
      
      const result = await this.pinata.pinFileToIPFS(readableStreamForFile, {
        pinataMetadata: {
          name: `Bushido Warrior #${tokenId}.png`
        }
      });
      
      imageUploads.push({
        tokenId,
        ipfsHash: result.IpfsHash,
        uri: `ipfs://${result.IpfsHash}`
      });
      
      if (tokenId % 50 === 0) {
        console.log(`✓ Uploaded ${tokenId}/${this.config.totalSupply} images`);
      }
    }
    
    // Save image upload results
    const resultsPath = path.join(process.cwd(), 'metadata', 'image-uploads.json');
    await fs.writeFile(resultsPath, JSON.stringify(imageUploads, null, 2));
    
    console.log('✅ Image upload complete!');
    return imageUploads;
  }
  
  // Utility functions
  hashTokenId(tokenId) {
    const crypto = require('crypto');
    return crypto.createHash('sha256').update(tokenId.toString()).digest('hex');
  }
  
  seededRandom(seed) {
    const x = Math.sin(seed) * 10000;
    return Math.floor((x - Math.floor(x)) * 1000);
  }
  
  capitalizeFirst(str) {
    return str.charAt(0).toUpperCase() + str.slice(1);
  }
}

// CLI Usage
if (require.main === module) {
  const generator = new BushidoMetadataGenerator({
    pinataApiKey: process.env.PINATA_API_KEY,
    pinataSecretKey: process.env.PINATA_SECRET_KEY,
    imageBaseUri: process.env.IPFS_IMAGE_BASE_URI || ''
  });
  
  async function run() {
    try {
      // Generate metadata
      const metadata = await generator.generateAllMetadata();
      
      // Verify artwork exists
      const artworkExists = await generator.verifyArtwork();
      
      if (artworkExists && process.argv.includes('--upload')) {
        // Upload images first
        const imageUploads = await generator.uploadImages();
        
        // Update metadata with IPFS image URIs
        metadata.forEach((token, index) => {
          token.image = imageUploads[index].uri;
        });
        
        // Upload metadata
        await generator.uploadToPinata(metadata);
      }
      
      console.log('🎉 Process complete!');
    } catch (error) {
      console.error('❌ Error:', error);
      process.exit(1);
    }
  }
  
  run();
}

module.exports = BushidoMetadataGenerator;