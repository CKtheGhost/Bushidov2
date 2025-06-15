import { MerkleTree } from 'merkletreejs';
import keccak256 from 'keccak256';
import fs from 'fs';
import path from 'path';

interface KOL {
  address: string;
  tier: 'tier1' | 'tier2' | 'tier3';
  allocation: number;
  twitter?: string;
  notes?: string;
}

class WhitelistManager {
  private whitelist: KOL[] = [];
  private merkleTree: MerkleTree | null = null;
  
  async loadWhitelist() {
    const whitelistPath = path.join(__dirname, 'kol-list.json');
    const data = fs.readFileSync(whitelistPath, 'utf8');
    this.whitelist = JSON.parse(data).kols;
    console.log(`Loaded ${this.whitelist.length} addresses`);
  }
  
  generateMerkleTree() {
    const leaves = this.whitelist.map(kol => 
      keccak256(kol.address.toLowerCase())
    );
    
    this.merkleTree = new MerkleTree(leaves, keccak256, { 
      sortPairs: true 
    });
    
    const root = this.merkleTree.getHexRoot();
    console.log('Merkle Root:', root);
    
    return root;
  }
  
  generateProofs() {
    if (!this.merkleTree) {
      throw new Error('Generate merkle tree first');
    }
    
    const proofs: Record<string, string[]> = {};
    
    this.whitelist.forEach(kol => {
      const leaf = keccak256(kol.address.toLowerCase());
      const proof = this.merkleTree!.getHexProof(leaf);
      proofs[kol.address] = proof;
    });
    
    // Save proofs
    fs.writeFileSync(
      path.join(__dirname, 'merkle-proofs.json'),
      JSON.stringify(proofs, null, 2)
    );
    
    console.log('Generated proofs for all addresses');
    return proofs;
  }
  
  exportForContract() {
    const root = this.merkleTree!.getHexRoot();
    
    const output = {
      root,
      totalWhitelisted: this.whitelist.length,
      breakdown: {
        tier1: this.whitelist.filter(k => k.tier === 'tier1').length,
        tier2: this.whitelist.filter(k => k.tier === 'tier2').length,
        tier3: this.whitelist.filter(k => k.tier === 'tier3').length,
      },
      addresses: this.whitelist.map(k => k.address),
    };
    
    fs.writeFileSync(
      path.join(__dirname, 'whitelist-export.json'),
      JSON.stringify(output, null, 2)
    );
    
    console.log('Exported whitelist data for contract deployment');
  }
}

// Execute
async function main() {
  const manager = new WhitelistManager();
  await manager.loadWhitelist();
  manager.generateMerkleTree();
  manager.generateProofs();
  manager.exportForContract();
}

main().catch(console.error);
