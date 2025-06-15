# Bushido-Complete-Update.ps1
# PowerShell 7.5 script for implementing all Bushido NFT project updates
# Includes smart contract updates, metadata system, whitelist management, and frontend components

#Requires -Version 7.5

param(
    [Parameter(HelpMessage="Path to the Bushido project root directory")]
    [string]$ProjectPath = (Get-Location).Path,
    
    [Parameter(HelpMessage="Install npm dependencies after file updates")]
    [switch]$InstallDependencies,
    
    [Parameter(HelpMessage="Create backup before making changes")]
    [switch]$CreateBackup,
    
    [Parameter(HelpMessage="Run in dry-run mode (no actual changes)")]
    [switch]$DryRun
)

# Script configuration
$script:Config = @{
    Version = "1.0.0"
    UpdateDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    MintPrice = "0.03"
    OldMintPrice = "0.08"
    TotalSupply = 1600
    RequiredDirectories = @(
        "contracts/contracts",
        "contracts/interfaces",
        "contracts/libraries",
        "contracts/scripts",
        "contracts/test",
        "frontend/src/components",
        "frontend/src/hooks",
        "backend/src/routes",
        "scripts/metadata",
        "scripts/whitelist",
        "metadata/json",
        "whitelist/snapshots"
    )
}

# Initialize logging
$script:LogPath = Join-Path $ProjectPath "bushido-update-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
$script:UpdatedFiles = @()
$script:CreatedFiles = @()
$script:Errors = @()

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('Info', 'Success', 'Warning', 'Error')]
        [string]$Level = 'Info'
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Write to log file
    if (-not $DryRun) {
        Add-Content -Path $script:LogPath -Value $logEntry -ErrorAction SilentlyContinue
    }
    
    # Console output with colors
    $colors = @{
        'Info' = 'Cyan'
        'Success' = 'Green'
        'Warning' = 'Yellow'
        'Error' = 'Red'
    }
    
    Write-Host $logEntry -ForegroundColor $colors[$Level]
}

function Test-ProjectStructure {
    Write-Log "Validating project structure..." "Info"
    
    $requiredPaths = @(
        "contracts",
        "frontend",
        "backend",
        "scripts"
    )
    
    $missingPaths = @()
    foreach ($path in $requiredPaths) {
        $fullPath = Join-Path $ProjectPath $path
        if (-not (Test-Path $fullPath)) {
            $missingPaths += $path
        }
    }
    
    if ($missingPaths.Count -gt 0) {
        Write-Log "Missing required directories: $($missingPaths -join ', ')" "Error"
        return $false
    }
    
    Write-Log "Project structure validated successfully" "Success"
    return $true
}

function New-BackupArchive {
    if (-not $CreateBackup) { return }
    
    Write-Log "Creating backup archive..." "Info"
    
    $backupName = "bushido-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss').zip"
    $backupPath = Join-Path $ProjectPath $backupName
    
    try {
        $filesToBackup = @(
            "contracts/contracts/*.sol",
            "frontend/src/components/*.jsx",
            "frontend/src/components/*.js",
            "package.json",
            "README.md",
            ".env.example"
        )
        
        if (-not $DryRun) {
            Compress-Archive -Path $filesToBackup -DestinationPath $backupPath -ErrorAction Stop
            Write-Log "Backup created: $backupName" "Success"
        } else {
            Write-Log "[DRY RUN] Would create backup: $backupName" "Info"
        }
    } catch {
        Write-Log "Failed to create backup: $_" "Error"
        $script:Errors += "Backup creation failed"
    }
}

function Update-SmartContracts {
    Write-Log "`nUpdating smart contracts..." "Info"
    
    # Update main BushidoNFT contract
    $contractPath = Join-Path $ProjectPath "contracts/contracts/BushidoNFT.sol"
    
    if (Test-Path $contractPath) {
        try {
            $content = Get-Content $contractPath -Raw
            
            # Update mint price from 0.08 to 0.03
            $updatedContent = $content -replace 'MINT_PRICE = 0\.08 ether', 'MINT_PRICE = 0.03 ether'
            
            # Add whitelist functionality if not present
            if ($updatedContent -notmatch 'MerkleProof') {
                $updatedContent = $updatedContent -replace '(import.*?;)', '$1`nimport "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";'
            }
            
            if ($content -ne $updatedContent) {
                if (-not $DryRun) {
                    Set-Content -Path $contractPath -Value $updatedContent -Encoding UTF8
                }
                $script:UpdatedFiles += $contractPath
                Write-Log "Updated BushidoNFT.sol with new mint price (0.03 ETH)" "Success"
            } else {
                Write-Log "BushidoNFT.sol already up to date" "Info"
            }
        } catch {
            Write-Log "Failed to update BushidoNFT.sol: $_" "Error"
            $script:Errors += "Smart contract update failed"
        }
    }
    
    # Create enhanced contract with full implementation
    $enhancedContractContent = @'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./interfaces/IBushidoNFT.sol";
import "./libraries/VotingPower.sol";

contract BushidoNFT is ERC721Enumerable, Ownable, ReentrancyGuard, IBushidoNFT {
    using Counters for Counters.Counter;
    using VotingPower for uint256;
    
    uint256 public constant MAX_SUPPLY = 1600;
    uint256 public constant MAX_PER_WALLET = 3;
    uint256 public constant MINT_PRICE = 0.03 ether;
    uint256 public constant CLANS_COUNT = 8;
    uint256 public constant WARRIORS_PER_CLAN = 200;
    
    Counters.Counter private _tokenIdCounter;
    
    enum MintPhase { CLOSED, WHITELIST, PUBLIC }
    MintPhase public currentPhase = MintPhase.CLOSED;
    
    bytes32 public merkleRoot;
    mapping(address => uint256) public whitelistMinted;
    uint256 public constant MAX_WHITELIST_MINT = 2;
    
    mapping(uint256 => uint256) public tokenClan;
    mapping(uint256 => uint256) public tokenRarity;
    mapping(address => uint256) public publicMinted;
    
    mapping(uint256 => mapping(uint256 => bool)) public hasVoted;
    mapping(uint256 => mapping(string => uint256)) public episodeVotes;
    mapping(uint256 => bool) public episodeActive;
    uint256 public currentEpisode;
    
    string private _baseTokenURI;
    
    event PhaseChanged(MintPhase newPhase);
    event MerkleRootUpdated(bytes32 newRoot);
    event TokenMinted(address indexed to, uint256 tokenId, uint256 clan, uint256 rarity);
    event VoteCast(uint256 indexed episodeId, uint256 indexed tokenId, string choice, uint256 votingPower);
    event EpisodeCreated(uint256 indexed episodeId);
    event EpisodeEnded(uint256 indexed episodeId);
    
    constructor() ERC721("Bushido", "BUSHIDO") Ownable(msg.sender) {}
    
    function setMintPhase(MintPhase _phase) external onlyOwner {
        currentPhase = _phase;
        emit PhaseChanged(_phase);
    }
    
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
        emit MerkleRootUpdated(_merkleRoot);
    }
    
    function whitelistMint(uint256 quantity, bytes32[] calldata merkleProof) 
        external 
        payable 
        nonReentrant 
    {
        require(currentPhase == MintPhase.WHITELIST, "Whitelist mint not active");
        require(quantity > 0 && quantity <= MAX_WHITELIST_MINT, "Invalid quantity");
        require(whitelistMinted[msg.sender] + quantity <= MAX_WHITELIST_MINT, "Exceeds whitelist limit");
        require(_tokenIdCounter.current() + quantity <= MAX_SUPPLY, "Exceeds supply");
        require(msg.value >= MINT_PRICE * quantity, "Insufficient payment");
        
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(merkleProof, merkleRoot, leaf), "Invalid proof");
        
        _mintTokens(msg.sender, quantity);
        whitelistMinted[msg.sender] += quantity;
    }
    
    function mint(uint256 quantity) 
        external 
        payable 
        nonReentrant 
    {
        require(currentPhase == MintPhase.PUBLIC, "Public mint not active");
        require(quantity > 0 && quantity <= MAX_PER_WALLET, "Invalid quantity");
        require(publicMinted[msg.sender] + quantity <= MAX_PER_WALLET, "Exceeds wallet limit");
        require(_tokenIdCounter.current() + quantity <= MAX_SUPPLY, "Exceeds supply");
        require(msg.value >= MINT_PRICE * quantity, "Insufficient payment");
        
        _mintTokens(msg.sender, quantity);
        publicMinted[msg.sender] += quantity;
    }
    
    function _mintTokens(address to, uint256 quantity) private {
        for (uint256 i = 0; i < quantity; i++) {
            _tokenIdCounter.increment();
            uint256 tokenId = _tokenIdCounter.current();
            
            uint256 clan = ((tokenId - 1) / WARRIORS_PER_CLAN);
            uint256 rarity = _determineRarity(tokenId);
            
            tokenClan[tokenId] = clan;
            tokenRarity[tokenId] = rarity;
            
            _safeMint(to, tokenId);
            emit TokenMinted(to, tokenId, clan, rarity);
        }
    }
    
    function vote(uint256 tokenId, uint256 episodeId, string memory choice) external {
        require(ownerOf(tokenId) == msg.sender, "Not token owner");
        require(episodeActive[episodeId], "Episode not active");
        require(!hasVoted[tokenId][episodeId], "Already voted");
        
        uint256 votingPower = getVotingPower(tokenId);
        hasVoted[tokenId][episodeId] = true;
        episodeVotes[episodeId][choice] += votingPower;
        
        emit VoteCast(episodeId, tokenId, choice, votingPower);
    }
    
    function getVotingPower(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Token does not exist");
        return tokenRarity[tokenId].calculateVotingPower();
    }
    
    function _determineRarity(uint256 tokenId) private view returns (uint256) {
        uint256 rand = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, tokenId))) % 1000;
        
        if (rand < 25) return 4;
        if (rand < 100) return 3;
        if (rand < 250) return 2;
        if (rand < 500) return 1;
        return 0;
    }
    
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }
    
    function totalMinted() external view returns (uint256) {
        return _tokenIdCounter.current();
    }
    
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Withdrawal failed");
    }
}
'@
    
    $enhancedContractPath = Join-Path $ProjectPath "contracts/contracts/BushidoNFTEnhanced.sol"
    
    if (-not $DryRun) {
        Set-Content -Path $enhancedContractPath -Value $enhancedContractContent -Encoding UTF8
    }
    $script:CreatedFiles += $enhancedContractPath
    Write-Log "Created enhanced BushidoNFT contract with whitelist support" "Success"
}

function Update-FrontendComponents {
    Write-Log "`nUpdating frontend components..." "Info"
    
    # Update any existing components that reference the mint price
    $componentsPath = Join-Path $ProjectPath "frontend/src/components"
    
    if (Test-Path $componentsPath) {
        $jsxFiles = Get-ChildItem -Path $componentsPath -Filter "*.jsx" -Recurse
        $jsFiles = Get-ChildItem -Path $componentsPath -Filter "*.js" -Recurse
        $allFiles = $jsxFiles + $jsFiles
        
        foreach ($file in $allFiles) {
            try {
                $content = Get-Content $file.FullName -Raw
                $originalContent = $content
                
                # Update mint price references
                $content = $content -replace '0\.08\s*ETH', '0.03 ETH'
                $content = $content -replace 'MINT_PRICE\s*=\s*0\.08', 'MINT_PRICE = 0.03'
                $content = $content -replace 'mintPrice:\s*"0\.08"', 'mintPrice: "0.03"'
                $content = $content -replace 'price.*?0\.08', 'price: 0.03'
                
                if ($content -ne $originalContent) {
                    if (-not $DryRun) {
                        Set-Content -Path $file.FullName -Value $content -Encoding UTF8
                    }
                    $script:UpdatedFiles += $file.FullName
                    Write-Log "Updated $($file.Name) with new mint price" "Success"
                }
            } catch {
                Write-Log "Failed to update $($file.Name): $_" "Error"
                $script:Errors += "Frontend component update failed: $($file.Name)"
            }
        }
    }
    
    # Create new MintButton component
    $mintButtonContent = @'
import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { useAccount, useContractWrite, useWaitForTransaction } from 'wagmi';
import { parseEther } from 'viem';
import { Loader2, Wallet, Check, Shield, Sword, ChevronDown } from 'lucide-react';

const MINT_PRICE = 0.03;
const MAX_PER_WALLET = 3;
const CONTRACT_ADDRESS = process.env.NEXT_PUBLIC_CONTRACT_ADDRESS;

const MintButton = ({ totalSupply = 1600, totalMinted = 0, userMints = 0 }) => {
  const { address, isConnected } = useAccount();
  const [quantity, setQuantity] = useState(1);
  const [showDetails, setShowDetails] = useState(false);
  
  const remainingSupply = totalSupply - totalMinted;
  const userRemainingMints = MAX_PER_WALLET - userMints;
  const maxMintable = Math.min(userRemainingMints, remainingSupply);
  
  const { write: mint, data: mintData, isLoading: isMinting } = useContractWrite({
    address: CONTRACT_ADDRESS,
    abi: [{
      name: 'mint',
      type: 'function',
      stateMutability: 'payable',
      inputs: [{ name: 'quantity', type: 'uint256' }],
      outputs: []
    }],
    functionName: 'mint',
    value: parseEther((MINT_PRICE * quantity).toString()),
    args: [BigInt(quantity)]
  });

  const { isLoading: isConfirming, isSuccess } = useWaitForTransaction({
    hash: mintData?.hash,
  });

  const handleQuantityChange = (newQuantity) => {
    if (newQuantity >= 1 && newQuantity <= maxMintable) {
      setQuantity(newQuantity);
    }
  };

  const handleMint = () => {
    if (!isConnected || maxMintable === 0) return;
    mint?.();
  };

  return (
    <div className="w-full max-w-md mx-auto">
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="bg-gradient-to-b from-neutral-900/90 to-black/90 backdrop-blur-sm rounded-2xl border border-red-900/20 overflow-hidden shadow-2xl"
      >
        <div className="bg-red-900/10 p-6 border-b border-red-900/20">
          <div className="flex items-center justify-between mb-2">
            <h3 className="text-2xl font-bold text-white">Mint Your Warrior</h3>
            <Shield className="w-6 h-6 text-red-500" />
          </div>
          <p className="text-gray-400">Join the legendary Bushido collection</p>
        </div>

        <div className="p-6 border-b border-red-900/20">
          <div className="flex items-center justify-between mb-4">
            <span className="text-gray-400">Price per NFT</span>
            <span className="text-2xl font-bold text-white">{MINT_PRICE} ETH</span>
          </div>
          
          <div className="space-y-2">
            <div className="flex justify-between text-sm">
              <span className="text-gray-400">Minted</span>
              <span className="text-white">{totalMinted} / {totalSupply}</span>
            </div>
            <div className="w-full bg-neutral-800 rounded-full h-2 overflow-hidden">
              <motion.div
                className="h-full bg-gradient-to-r from-red-600 to-red-500"
                initial={{ width: 0 }}
                animate={{ width: `${(totalMinted / totalSupply) * 100}%` }}
                transition={{ duration: 1 }}
              />
            </div>
          </div>
        </div>

        <div className="p-6">
          {!isConnected ? (
            <button
              className="w-full py-4 px-6 bg-gradient-to-r from-red-600 to-red-500 hover:from-red-500 hover:to-red-400 text-white font-bold rounded-xl transition-all duration-300 transform hover:scale-[1.02] flex items-center justify-center gap-2"
            >
              <Wallet className="w-5 h-5" />
              Connect Wallet to Mint
            </button>
          ) : (
            <button
              onClick={handleMint}
              disabled={isMinting || isConfirming}
              className="w-full py-4 px-6 bg-gradient-to-r from-red-600 to-red-500 hover:from-red-500 hover:to-red-400 disabled:from-gray-600 disabled:to-gray-500 text-white font-bold rounded-xl transition-all duration-300 transform hover:scale-[1.02] disabled:scale-100 flex items-center justify-center gap-2"
            >
              {isMinting || isConfirming ? (
                <Loader2 className="w-5 h-5 animate-spin" />
              ) : (
                <Sword className="w-5 h-5" />
              )}
              {isMinting ? 'Minting...' : isConfirming ? 'Confirming...' : `Mint ${quantity} Warrior${quantity > 1 ? 's' : ''}`}
            </button>
          )}
        </div>
      </motion.div>
    </div>
  );
};

export default MintButton;
'@
    
    $mintButtonPath = Join-Path $ProjectPath "frontend/src/components/MintButton.jsx"
    
    if (-not $DryRun) {
        Set-Content -Path $mintButtonPath -Value $mintButtonContent -Encoding UTF8
    }
    $script:CreatedFiles += $mintButtonPath
    Write-Log "Created MintButton component with 0.03 ETH price" "Success"
}

function Create-MetadataSystem {
    Write-Log "`nCreating metadata generation system..." "Info"
    
    $metadataScript = @'
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
'@
    
    $metadataPath = Join-Path $ProjectPath "scripts/metadata/metadata-generator.js"
    $metadataDir = Split-Path $metadataPath -Parent
    
    if (-not (Test-Path $metadataDir)) {
        if (-not $DryRun) {
            New-Item -ItemType Directory -Path $metadataDir -Force | Out-Null
        }
    }
    
    if (-not $DryRun) {
        Set-Content -Path $metadataPath -Value $metadataScript -Encoding UTF8
    }
    $script:CreatedFiles += $metadataPath
    Write-Log "Created metadata generation system" "Success"
}

function Create-WhitelistSystem {
    Write-Log "`nCreating whitelist management system..." "Info"
    
    $whitelistScript = @'
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
'@
    
    $whitelistPath = Join-Path $ProjectPath "scripts/whitelist/whitelist-generator.js"
    $whitelistDir = Split-Path $whitelistPath -Parent
    
    if (-not (Test-Path $whitelistDir)) {
        if (-not $DryRun) {
            New-Item -ItemType Directory -Path $whitelistDir -Force | Out-Null
        }
    }
    
    if (-not $DryRun) {
        Set-Content -Path $whitelistPath -Value $whitelistScript -Encoding UTF8
    }
    $script:CreatedFiles += $whitelistPath
    Write-Log "Created whitelist management system" "Success"
}

function Update-ConfigurationFiles {
    Write-Log "`nUpdating configuration files..." "Info"
    
    # Update .env.example
    $envPath = Join-Path $ProjectPath ".env.example"
    
    if (Test-Path $envPath) {
        try {
            $content = Get-Content $envPath -Raw
            $originalContent = $content
            
            # Add or update mint price
            if ($content -notmatch 'NEXT_PUBLIC_MINT_PRICE') {
                $content += "`nNEXT_PUBLIC_MINT_PRICE=0.03"
            } else {
                $content = $content -replace 'NEXT_PUBLIC_MINT_PRICE=.*', 'NEXT_PUBLIC_MINT_PRICE=0.03'
            }
            
            # Add or update collection configuration
            if ($content -notmatch 'MINT_PRICE_ETH') {
                $content += "`nMINT_PRICE_ETH=0.03`nMAX_PER_WALLET=3`nTOTAL_SUPPLY=1600"
            }
            
            if ($content -ne $originalContent) {
                if (-not $DryRun) {
                    Set-Content -Path $envPath -Value $content -Encoding UTF8
                }
                $script:UpdatedFiles += $envPath
                Write-Log "Updated .env.example with new configuration" "Success"
            }
        } catch {
            Write-Log "Failed to update .env.example: $_" "Error"
            $script:Errors += "Environment configuration update failed"
        }
    }
    
    # Update README.md
    $readmePath = Join-Path $ProjectPath "README.md"
    
    if (Test-Path $readmePath) {
        try {
            $content = Get-Content $readmePath -Raw
            $originalContent = $content
            
            # Update mint price references
            $content = $content -replace '0\.08\s*ETH', '0.03 ETH'
            $content = $content -replace 'Mint Price[:\s]+0\.08', 'Mint Price: 0.03'
            $content = $content -replace '"mintPrice"[:\s]+"0\.08"', '"mintPrice": "0.03"'
            
            if ($content -ne $originalContent) {
                if (-not $DryRun) {
                    Set-Content -Path $readmePath -Value $content -Encoding UTF8
                }
                $script:UpdatedFiles += $readmePath
                Write-Log "Updated README.md with new mint price" "Success"
            }
        } catch {
            Write-Log "Failed to update README.md: $_" "Error"
            $script:Errors += "README update failed"
        }
    }
    
    # Update stealth-config.json if it exists
    $stealthConfigPath = Join-Path $ProjectPath "stealth-config.json"
    
    if (Test-Path $stealthConfigPath) {
        try {
            $config = Get-Content $stealthConfigPath -Raw | ConvertFrom-Json
            
            if ($config.collection.mintPrice -ne "0.03") {
                $config.collection.mintPrice = "0.03"
                
                if (-not $DryRun) {
                    $config | ConvertTo-Json -Depth 10 | Set-Content $stealthConfigPath -Encoding UTF8
                }
                $script:UpdatedFiles += $stealthConfigPath
                Write-Log "Updated stealth-config.json with new mint price" "Success"
            }
        } catch {
            Write-Log "Failed to update stealth-config.json: $_" "Error"
            $script:Errors += "Stealth config update failed"
        }
    }
}

function Install-Dependencies {
    if (-not $InstallDependencies) { return }
    
    Write-Log "`nInstalling dependencies..." "Info"
    
    # Add required dependencies to package.json files
    $packagesToUpdate = @(
        @{
            Path = "frontend/package.json"
            Dependencies = @{
                "framer-motion" = "^10.18.0"
                "wagmi" = "^2.0.0"
                "viem" = "^2.0.0"
                "@rainbow-me/rainbowkit" = "^2.0.0"
                "lucide-react" = "^0.300.0"
            }
        },
        @{
            Path = "scripts/package.json"
            Dependencies = @{
                "@pinata/sdk" = "^2.1.0"
                "merkletreejs" = "^0.3.11"
                "keccak256" = "^1.0.6"
            }
        }
    )
    
    foreach ($package in $packagesToUpdate) {
        $packagePath = Join-Path $ProjectPath $package.Path
        
        if (Test-Path $packagePath) {
            try {
                $packageJson = Get-Content $packagePath -Raw | ConvertFrom-Json
                
                if (-not $packageJson.dependencies) {
                    $packageJson | Add-Member -NotePropertyName dependencies -NotePropertyValue @{} -Force
                }
                
                foreach ($dep in $package.Dependencies.GetEnumerator()) {
                    $packageJson.dependencies | Add-Member -NotePropertyName $dep.Key -NotePropertyValue $dep.Value -Force
                }
                
                if (-not $DryRun) {
                    $packageJson | ConvertTo-Json -Depth 10 | Set-Content $packagePath -Encoding UTF8
                }
                
                Write-Log "Updated dependencies in $($package.Path)" "Success"
            } catch {
                Write-Log "Failed to update dependencies in $($package.Path): $_" "Error"
            }
        }
    }
    
    # Run pnpm install
    if (-not $DryRun) {
        Write-Log "Running pnpm install..." "Info"
        
        try {
            $installProcess = Start-Process -FilePath "pnpm" -ArgumentList "install" -WorkingDirectory $ProjectPath -NoNewWindow -Wait -PassThru
            
            if ($installProcess.ExitCode -eq 0) {
                Write-Log "Dependencies installed successfully" "Success"
            } else {
                Write-Log "Dependency installation completed with exit code: $($installProcess.ExitCode)" "Warning"
            }
        } catch {
            Write-Log "Failed to run pnpm install: $_" "Error"
            $script:Errors += "Dependency installation failed"
        }
    }
}

function Show-Summary {
    Write-Log "`n════════════════════════════════════════════════════════════════" "Info"
    Write-Log "Update Summary" "Info"
    Write-Log "════════════════════════════════════════════════════════════════" "Info"
    
    Write-Log "`nProject Path: $ProjectPath" "Info"
    Write-Log "Update Date: $($script:Config.UpdateDate)" "Info"
    Write-Log "Script Version: $($script:Config.Version)" "Info"
    
    if ($DryRun) {
        Write-Log "`n[DRY RUN MODE] No actual changes were made" "Warning"
    }
    
    Write-Log "`nFiles Updated: $($script:UpdatedFiles.Count)" "Info"
    if ($script:UpdatedFiles.Count -gt 0) {
        $script:UpdatedFiles | ForEach-Object {
            Write-Log "  - $(Split-Path $_ -Leaf)" "Success"
        }
    }
    
    Write-Log "`nFiles Created: $($script:CreatedFiles.Count)" "Info"
    if ($script:CreatedFiles.Count -gt 0) {
        $script:CreatedFiles | ForEach-Object {
            Write-Log "  - $(Split-Path $_ -Leaf)" "Success"
        }
    }
    
    if ($script:Errors.Count -gt 0) {
        Write-Log "`nErrors Encountered: $($script:Errors.Count)" "Error"
        $script:Errors | ForEach-Object {
            Write-Log "  - $_" "Error"
        }
    }
    
    Write-Log "`nKey Changes Applied:" "Info"
    Write-Log "  - Smart contract mint price updated to 0.03 ETH" "Success"
    Write-Log "  - Enhanced contract with whitelist functionality created" "Success"
    Write-Log "  - Frontend components updated with new pricing" "Success"
    Write-Log "  - Metadata generation system implemented" "Success"
    Write-Log "  - KOL whitelist management system created" "Success"
    Write-Log "  - Configuration files updated" "Success"
    
    Write-Log "`nNext Steps:" "Info"
    Write-Log "  1. Review the update log: $script:LogPath" "Info"
    Write-Log "  2. Test smart contract deployment on testnet" "Info"
    Write-Log "  3. Configure Pinata API keys in .env file" "Info"
    Write-Log "  4. Generate KOL whitelist merkle tree" "Info"
    Write-Log "  5. Upload artwork files when received from artist" "Info"
}

# Main execution
function Start-BushidoUpdate {
    Write-Log "════════════════════════════════════════════════════════════════" "Info"
    Write-Log "Bushido NFT Complete Update Script v$($script:Config.Version)" "Info"
    Write-Log "════════════════════════════════════════════════════════════════" "Info"
    
    if ($DryRun) {
        Write-Log "[DRY RUN MODE] No changes will be made to files" "Warning"
    }
    
    # Validate project structure
    if (-not (Test-ProjectStructure)) {
        Write-Log "Project structure validation failed. Ensure you're in the correct directory." "Error"
        return
    }
    
    # Create backup if requested
    if ($CreateBackup) {
        New-BackupArchive
    }
    
    # Ensure required directories exist
    Write-Log "`nCreating required directories..." "Info"
    foreach ($dir in $script:Config.RequiredDirectories) {
        $fullPath = Join-Path $ProjectPath $dir
        if (-not (Test-Path $fullPath)) {
            if (-not $DryRun) {
                New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
            }
            Write-Log "Created directory: $dir" "Success"
        }
    }
    
    # Execute updates
    Update-SmartContracts
    Update-FrontendComponents
    Create-MetadataSystem
    Create-WhitelistSystem
    Update-ConfigurationFiles
    Install-Dependencies
    
    # Show summary
    Show-Summary
}

# Execute the update
Start-BushidoUpdate