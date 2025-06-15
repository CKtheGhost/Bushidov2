const { MerkleTree } = require('merkletreejs');
const keccak256 = require('keccak256');
const fs = require('fs').promises;
const path = require('path');

class BushidoWhitelistManager {
  constructor() {
    this.whitelistPath = path.join(process.cwd(), 'whitelist');
    this.kolCategories = {
      tier1: { name: 'Elite KOLs', allocation: 2 },
      tier2: { name: 'Core KOLs', allocation: 2 },
      tier3: { name: 'Rising Stars', allocation: 1 },
      partner: { name: 'Strategic Partners', allocation: 2 },
      community: { name: 'Community Leaders', allocation: 1 }
    };
  }

  async initialize() {
    await fs.mkdir(this.whitelistPath, { recursive: true });
    await fs.mkdir(path.join(this.whitelistPath, 'snapshots'), { recursive: true });
  }

  async addKOL(address, tier, details = {}) {
    const kolData = {
      address: address.toLowerCase(),
      tier,
      allocation: this.kolCategories[tier]?.allocation || 1,
      addedDate: new Date().toISOString(),
      ...details
    };

    const whitelist = await this.loadWhitelist();
    const existingIndex = whitelist.findIndex(k => k.address === kolData.address);
    
    if (existingIndex >= 0) {
      whitelist[existingIndex] = kolData;
    } else {
      whitelist.push(kolData);
    }

    await this.saveWhitelist(whitelist);
    return kolData;
  }

  async generateMerkleTree() {
    const whitelist = await this.loadWhitelist();
    const leaves = whitelist.map(kol => keccak256(kol.address));
    const tree = new MerkleTree(leaves, keccak256, { sortPairs: true });
    const root = tree.getHexRoot();
    
    const proofs = {};
    whitelist.forEach((kol, index) => {
      const proof = tree.getHexProof(leaves[index]);
      proofs[kol.address] = {
        proof,
        allocation: kol.allocation,
        tier: kol.tier
      };
    });
    
    const merkleData = {
      root,
      totalAddresses: whitelist.length,
      generatedAt: new Date().toISOString(),
      proofs
    };
    
    await fs.writeFile(
      path.join(this.whitelistPath, 'merkle-tree.json'),
      JSON.stringify(merkleData, null, 2)
    );
    
    return merkleData;
  }

  async loadWhitelist() {
    try {
      const data = await fs.readFile(
        path.join(this.whitelistPath, 'whitelist.json'),
        'utf8'
      );
      return JSON.parse(data);
    } catch {
      return [];
    }
  }

  async saveWhitelist(whitelist) {
    await fs.writeFile(
      path.join(this.whitelistPath, 'whitelist.json'),
      JSON.stringify(whitelist, null, 2)
    );
  }
}

module.exports = BushidoWhitelistManager;
