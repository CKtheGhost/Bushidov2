// whitelist-generator.js
// KOL Whitelist Management System for Bushido NFT

const { MerkleTree } = require('merkletreejs');
const keccak256 = require('keccak256');
const fs = require('fs').promises;
const path = require('path');

/**
 * Whitelist Generator for KOL Distribution
 * Manages early access for influencers and strategic partners
 */
class BushidoWhitelistManager {
  constructor() {
    this.whitelistPath = path.join(process.cwd(), 'whitelist');
    this.kolCategories = {
      tier1: {
        name: 'Elite KOLs',
        allocation: 2,
        description: 'Top-tier influencers with 100k+ engaged followers'
      },
      tier2: {
        name: 'Core KOLs',
        allocation: 2,
        description: 'Mid-tier influencers with 25k-100k followers'
      },
      tier3: {
        name: 'Rising Stars',
        allocation: 1,
        description: 'Emerging influencers with high engagement'
      },
      partner: {
        name: 'Strategic Partners',
        allocation: 2,
        description: 'Collaborators and ecosystem partners'
      },
      community: {
        name: 'Community Leaders',
        allocation: 1,
        description: 'Active community moderators and contributors'
      }
    };
  }

  /**
   * Initialize whitelist directory structure
   */
  async initialize() {
    await fs.mkdir(this.whitelistPath, { recursive: true });
    await fs.mkdir(path.join(this.whitelistPath, 'snapshots'), { recursive: true });
    console.log('✅ Whitelist directory initialized');
  }

  /**
   * Add KOL to whitelist
   */
  async addKOL(address, tier, details = {}) {
    const kolData = {
      address: address.toLowerCase(),
      tier,
      allocation: this.kolCategories[tier]?.allocation || 1,
      addedDate: new Date().toISOString(),
      ...details
    };

    // Load existing whitelist
    const whitelist = await this.loadWhitelist();
    
    // Check if already exists
    const existingIndex = whitelist.findIndex(k => k.address === kolData.address);
    if (existingIndex >= 0) {
      whitelist[existingIndex] = kolData;
      console.log(`📝 Updated existing KOL: ${address}`);
    } else {
      whitelist.push(kolData);
      console.log(`✅ Added new KOL: ${address} (${tier})`);
    }

    // Save updated whitelist
    await this.saveWhitelist(whitelist);
    return kolData;
  }

  /**
   * Add multiple KOLs from CSV or array
   */
  async addBulkKOLs(kolList) {
    console.log(`📋 Adding ${kolList.length} KOLs to whitelist...`);
    
    for (const kol of kolList) {
      await this.addKOL(kol.address, kol.tier, {
        name: kol.name,
        twitter: kol.twitter,
        discord: kol.discord,
        notes: kol.notes
      });
    }
    
    console.log('✅ Bulk addition complete');
  }

  /**
   * Generate Merkle tree for on-chain verification
   */
  async generateMerkleTree() {
    const whitelist = await this.loadWhitelist();
    
    // Create leaves from addresses
    const leaves = whitelist.map(kol => 
      keccak256(kol.address)
    );
    
    // Generate tree
    const tree = new MerkleTree(leaves, keccak256, { sortPairs: true });
    const root = tree.getHexRoot();
    
    // Generate proofs for each address
    const proofs = {};
    whitelist.forEach((kol, index) => {
      const proof = tree.getHexProof(leaves[index]);
      proofs[kol.address] = {
        proof,
        allocation: kol.allocation,
        tier: kol.tier
      };
    });
    
    // Save merkle data
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
    
    console.log('🌳 Merkle tree generated');
    console.log('📍 Root:', root);
    console.log('📊 Total addresses:', whitelist.length);
    
    return merkleData;
  }

  /**
   * Generate proof for specific address
   */
  async getProof(address) {
    const merkleData = await this.loadMerkleData();
    const normalizedAddress = address.toLowerCase();
    
    if (!merkleData.proofs[normalizedAddress]) {
      throw new Error(`Address ${address} not found in whitelist`);
    }
    
    return merkleData.proofs[normalizedAddress];
  }

  /**
   * Create snapshot of current whitelist
   */
  async createSnapshot(name = null) {
    const whitelist = await this.loadWhitelist();
    const snapshotName = name || `snapshot-${Date.now()}`;
    
    const snapshot = {
      name: snapshotName,
      timestamp: new Date().toISOString(),
      totalAddresses: whitelist.length,
      breakdown: this.getWhitelistBreakdown(whitelist),
      addresses: whitelist
    };
    
    await fs.writeFile(
      path.join(this.whitelistPath, 'snapshots', `${snapshotName}.json`),
      JSON.stringify(snapshot, null, 2)
    );
    
    console.log(`📸 Snapshot created: ${snapshotName}`);
    return snapshot;
  }

  /**
   * Generate whitelist report
   */
  async generateReport() {
    const whitelist = await this.loadWhitelist();
    const breakdown = this.getWhitelistBreakdown(whitelist);
    
    const report = {
      summary: {
        totalAddresses: whitelist.length,
        totalAllocation: whitelist.reduce((sum, kol) => sum + kol.allocation, 0),
        generatedAt: new Date().toISOString()
      },
      breakdown,
      recentAdditions: whitelist
        .sort((a, b) => new Date(b.addedDate) - new Date(a.addedDate))
        .slice(0, 10)
    };
    
    await fs.writeFile(
      path.join(this.whitelistPath, 'whitelist-report.json'),
      JSON.stringify(report, null, 2)
    );
    
    // Generate human-readable report
    const readableReport = this.formatReadableReport(report);
    await fs.writeFile(
      path.join(this.whitelistPath, 'whitelist-report.md'),
      readableReport
    );
    
    console.log('📊 Report generated');
    return report;
  }

  /**
   * Verify whitelist integrity
   */
  async verifyWhitelist() {
    const whitelist = await this.loadWhitelist();
    const issues = [];
    const seen = new Set();
    
    for (const kol of whitelist) {
      // Check for duplicates
      if (seen.has(kol.address)) {
        issues.push(`Duplicate address: ${kol.address}`);
      }
      seen.add(kol.address);
      
      // Validate address format
      if (!/^0x[a-fA-F0-9]{40}$/.test(kol.address)) {
        issues.push(`Invalid address format: ${kol.address}`);
      }
      
      // Check tier validity
      if (!this.kolCategories[kol.tier]) {
        issues.push(`Invalid tier for ${kol.address}: ${kol.tier}`);
      }
    }
    
    if (issues.length > 0) {
      console.log('⚠️  Whitelist issues found:');
      issues.forEach(issue => console.log(`   - ${issue}`));
    } else {
      console.log('✅ Whitelist verification passed');
    }
    
    return { valid: issues.length === 0, issues };
  }

  /**
   * Export whitelist for distribution
   */
  async exportForDistribution() {
    const whitelist = await this.loadWhitelist();
    const merkleData = await this.loadMerkleData();
    
    // Create distribution package
    const distribution = {
      merkleRoot: merkleData.root,
      totalEligible: whitelist.length,
      addresses: whitelist.map(kol => ({
        address: kol.address,
        allocation: kol.allocation,
        proof: merkleData.proofs[kol.address].proof
      }))
    };
    
    // Save for frontend integration
    await fs.writeFile(
      path.join(this.whitelistPath, 'distribution.json'),
      JSON.stringify(distribution, null, 2)
    );
    
    // Create simple address list for contract deployment
    const addressList = whitelist.map(kol => kol.address);
    await fs.writeFile(
      path.join(this.whitelistPath, 'addresses.json'),
      JSON.stringify(addressList, null, 2)
    );
    
    console.log('📦 Distribution package exported');
    return distribution;
  }

  // Helper functions
  
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

  async loadMerkleData() {
    const data = await fs.readFile(
      path.join(this.whitelistPath, 'merkle-tree.json'),
      'utf8'
    );
    return JSON.parse(data);
  }

  getWhitelistBreakdown(whitelist) {
    const breakdown = {};
    
    Object.keys(this.kolCategories).forEach(tier => {
      breakdown[tier] = {
        name: this.kolCategories[tier].name,
        count: whitelist.filter(kol => kol.tier === tier).length,
        allocation: whitelist
          .filter(kol => kol.tier === tier)
          .reduce((sum, kol) => sum + kol.allocation, 0)
      };
    });
    
    return breakdown;
  }

  formatReadableReport(report) {
    let content = '# Bushido NFT Whitelist Report\n\n';
    content += `Generated: ${report.summary.generatedAt}\n\n`;
    content += '## Summary\n\n';
    content += `- Total Addresses: ${report.summary.totalAddresses}\n`;
    content += `- Total Allocation: ${report.summary.totalAllocation} NFTs\n\n`;
    content += '## Breakdown by Tier\n\n';
    
    Object.entries(report.breakdown).forEach(([tier, data]) => {
      content += `### ${data.name}\n`;
      content += `- Count: ${data.count}\n`;
      content += `- Total Allocation: ${data.allocation} NFTs\n\n`;
    });
    
    content += '## Recent Additions\n\n';
    report.recentAdditions.forEach(kol => {
      content += `- ${kol.address} (${kol.tier}) - ${kol.addedDate}\n`;
    });
    
    return content;
  }
}

// CLI Interface
if (require.main === module) {
  const manager = new BushidoWhitelistManager();
  
  const commands = {
    init: async () => {
      await manager.initialize();
    },
    
    add: async (address, tier) => {
      if (!address || !tier) {
        console.error('Usage: node whitelist-generator.js add <address> <tier>');
        return;
      }
      await manager.addKOL(address, tier);
    },
    
    generate: async () => {
      await manager.generateMerkleTree();
    },
    
    verify: async () => {
      await manager.verifyWhitelist();
    },
    
    report: async () => {
      await manager.generateReport();
    },
    
    export: async () => {
      await manager.exportForDistribution();
    },
    
    snapshot: async (name) => {
      await manager.createSnapshot(name);
    },
    
    proof: async (address) => {
      if (!address) {
        console.error('Usage: node whitelist-generator.js proof <address>');
        return;
      }
      const proof = await manager.getProof(address);
      console.log('Proof for', address);
      console.log(JSON.stringify(proof, null, 2));
    }
  };
  
  const [,, command, ...args] = process.argv;
  
  if (commands[command]) {
    commands[command](...args).catch(console.error);
  } else {
    console.log('Available commands:');
    console.log('  init       - Initialize whitelist directory');
    console.log('  add        - Add KOL to whitelist');
    console.log('  generate   - Generate Merkle tree');
    console.log('  verify     - Verify whitelist integrity');
    console.log('  report     - Generate whitelist report');
    console.log('  export     - Export for distribution');
    console.log('  snapshot   - Create whitelist snapshot');
    console.log('  proof      - Get proof for address');
  }
}

module.exports = BushidoWhitelistManager;