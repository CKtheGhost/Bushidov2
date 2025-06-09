📋 Step-by-Step Transformation Guide
Phase 1: Environment Setup

Initialize New Project Structure

bash# Create new project directory
mkdir bushido-nft && cd bushido-nft

# Initialize monorepo with pnpm
pnpm init
touch pnpm-workspace.yaml

Configure Workspace

yaml# pnpm-workspace.yaml
packages:
  - 'contracts'
  - 'frontend'
  - 'backend'
  - 'scripts'
Phase 2: Smart Contract Development

Install Contract Dependencies

bashcd contracts
pnpm init
pnpm add -D hardhat @nomicfoundation/hardhat-toolbox @openzeppelin/contracts
pnpm add -D typescript @types/node ts-node
npx hardhat init

Create Main NFT Contract

solidity// contracts/BushidoNFT.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./lib/VotingMechanics.sol";

contract BushidoNFT is ERC721Enumerable, Ownable, VotingMechanics {
    using Counters for Counters.Counter;
    
    // Constants
    uint256 public constant MAX_SUPPLY = 1600;
    uint256 public constant MAX_PER_WALLET = 3;
    uint256 public constant MINT_PRICE = 0.08 ether;
    uint256 public constant CLANS_COUNT = 8;
    uint256 public constant TOKENS_PER_CLAN = 200;
    
    // State
    Counters.Counter private _tokenIdCounter;
    mapping(uint256 => uint256) public tokenClan;
    mapping(uint256 => uint256) public tokenRarity;
    mapping(address => uint256) public mintedPerWallet;
    
    bool public mintActive = false;
    string private _baseTokenURI;
    
    // Events
    event MintActivated();
    event TokenMinted(address indexed to, uint256 tokenId, uint256 clan, uint256 rarity);
    
    constructor() ERC721("Bushido", "BUSHIDO") {}
    
    function activateMint() external onlyOwner {
        mintActive = true;
        emit MintActivated();
    }
    
    function mint(uint256 quantity) external payable {
        require(mintActive, "Mint not active");
        require(quantity > 0 && quantity <= MAX_PER_WALLET, "Invalid quantity");
        require(mintedPerWallet[msg.sender] + quantity <= MAX_PER_WALLET, "Exceeds wallet limit");
        require(_tokenIdCounter.current() + quantity <= MAX_SUPPLY, "Exceeds supply");
        require(msg.value >= MINT_PRICE * quantity, "Insufficient payment");
        
        for (uint256 i = 0; i < quantity; i++) {
            _tokenIdCounter.increment();
            uint256 tokenId = _tokenIdCounter.current();
            
            // Assign clan and rarity
            uint256 clan = (tokenId - 1) / TOKENS_PER_CLAN + 1;
            uint256 rarity = _generateRarity(tokenId);
            
            tokenClan[tokenId] = clan;
            tokenRarity[tokenId] = rarity;
            
            _safeMint(msg.sender, tokenId);
            emit TokenMinted(msg.sender, tokenId, clan, rarity);
        }
        
        mintedPerWallet[msg.sender] += quantity;
    }
    
    function _generateRarity(uint256 tokenId) private view returns (uint256) {
        uint256 rand = uint256(keccak256(abi.encodePacked(block.timestamp, tokenId)));
        uint256 normalized = rand % 100;
        
        if (normalized < 1) return 5;      // Legendary (1%)
        if (normalized < 5) return 4;      // Epic (4%)
        if (normalized < 15) return 3;     // Rare (10%)
        if (normalized < 35) return 2;     // Uncommon (20%)
        return 1;                          // Common (65%)
    }
    
    function getVotingPower(uint256 tokenId) public view returns (uint256) {
        uint256 rarity = tokenRarity[tokenId];
        return rarity ** 2; // Exponential voting power
    }
}
Phase 3: Frontend Development

Initialize Next.js Project

bashcd ../frontend
pnpm create next-app@latest . --typescript --tailwind --app --src-dir
pnpm add wagmi viem @rainbow-me/rainbowkit ethers
pnpm add @react-three/fiber @react-three/drei three
pnpm add framer-motion lucide-react
pnpm add @tanstack/react-query axios

Create Core Components

Countdown Timer Component:
tsx// src/components/countdown/CountdownTimer.tsx
import { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';

interface TimeLeft {
  days: number;
  hours: number;
  minutes: number;
  seconds: number;
}

export const CountdownTimer = ({ targetDate }: { targetDate: Date }) => {
  const [timeLeft, setTimeLeft] = useState<TimeLeft>({
    days: 0,
    hours: 0,
    minutes: 0,
    seconds: 0
  });

  useEffect(() => {
    const calculateTimeLeft = () => {
      const difference = +targetDate - +new Date();
      
      if (difference > 0) {
        setTimeLeft({
          days: Math.floor(difference / (1000 * 60 * 60 * 24)),
          hours: Math.floor((difference / (1000 * 60 * 60)) % 24),
          minutes: Math.floor((difference / 1000 / 60) % 60),
          seconds: Math.floor((difference / 1000) % 60)
        });
      }
    };

    const timer = setInterval(calculateTimeLeft, 1000);
    calculateTimeLeft();

    return () => clearInterval(timer);
  }, [targetDate]);

  const timeUnits = [
    { label: 'Days', value: timeLeft.days },
    { label: 'Hours', value: timeLeft.hours },
    { label: 'Minutes', value: timeLeft.minutes },
    { label: 'Seconds', value: timeLeft.seconds }
  ];

  return (
    <div className="flex gap-4 justify-center">
      {timeUnits.map((unit, index) => (
        <motion.div
          key={unit.label}
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: index * 0.1 }}
          className="relative"
        >
          <div className="bg-black/80 backdrop-blur-sm border border-red-500/20 rounded-lg p-6">
            <AnimatePresence mode="wait">
              <motion.div
                key={unit.value}
                initial={{ rotateX: -90 }}
                animate={{ rotateX: 0 }}
                exit={{ rotateX: 90 }}
                transition={{ duration: 0.3 }}
                className="text-4xl font-bold text-red-500"
              >
                {unit.value.toString().padStart(2, '0')}
              </motion.div>
            </AnimatePresence>
            <div className="text-sm text-gray-400 mt-2">{unit.label}</div>
          </div>
        </motion.div>
      ))}
    </div>
  );
};
Voting Panel Component:
tsx// src/components/episodes/VotingPanel.tsx
import { useState } from 'react';
import { motion } from 'framer-motion';
import { useVotingPower } from '@/hooks/useVotingPower';

interface VoteOption {
  id: string;
  text: string;
  votes: number;
}

export const VotingPanel = ({ 
  episodeId, 
  options,
  deadline 
}: {
  episodeId: number;
  options: VoteOption[];
  deadline: Date;
}) => {
  const { votingPower, hasVoted, submitVote } = useVotingPower();
  const [selectedOption, setSelectedOption] = useState<string | null>(null);
  const [isVoting, setIsVoting] = useState(false);

  const totalVotes = options.reduce((sum, opt) => sum + opt.votes, 0);

  const handleVote = async () => {
    if (!selectedOption || hasVoted) return;
    
    setIsVoting(true);
    try {
      await submitVote(episodeId, selectedOption);
    } finally {
      setIsVoting(false);
    }
  };

  return (
    <div className="bg-neutral-900/50 backdrop-blur-sm rounded-xl p-6 border border-red-900/20">
      <div className="flex justify-between items-center mb-6">
        <h3 className="text-2xl font-bold text-white">Shape the Story</h3>
        <div className="text-red-500">
          Voting Power: {votingPower}
        </div>
      </div>

      <div className="space-y-4">
        {options.map((option) => {
          const percentage = totalVotes > 0 
            ? Math.round((option.votes / totalVotes) * 100) 
            : 0;

          return (
            <motion.button
              key={option.id}
              onClick={() => setSelectedOption(option.id)}
              disabled={hasVoted || isVoting}
              className={`
                w-full p-4 rounded-lg text-left transition-all relative overflow-hidden
                ${selectedOption === option.id 
                  ? 'bg-red-900/30 border border-red-500' 
                  : 'bg-neutral-800 hover:bg-neutral-700 border border-transparent'}
                ${hasVoted ? 'opacity-50 cursor-not-allowed' : ''}
              `}
              whileHover={{ scale: hasVoted ? 1 : 1.02 }}
              whileTap={{ scale: hasVoted ? 1 : 0.98 }}
            >
              <div className="relative z-10">
                <div className="text-white mb-2">{option.text}</div>
                <div className="text-sm text-gray-400">
                  {option.votes.toLocaleString()} votes ({percentage}%)
                </div>
              </div>
              
              <motion.div
                className="absolute inset-0 bg-red-500/10"
                initial={{ width: 0 }}
                animate={{ width: `${percentage}%` }}
                transition={{ duration: 0.5 }}
              />
            </motion.button>
          );
        })}
      </div>

      {!hasVoted && (
        <motion.button
          onClick={handleVote}
          disabled={!selectedOption || isVoting}
          className={`
            w-full mt-6 py-3 rounded-lg font-bold transition-all
            ${selectedOption && !isVoting
              ? 'bg-red-600 hover:bg-red-500 text-white' 
              : 'bg-neutral-700 text-gray-400 cursor-not-allowed'}
          `}
          whileHover={{ scale: selectedOption && !isVoting ? 1.02 : 1 }}
          whileTap={{ scale: selectedOption && !isVoting ? 0.98 : 1 }}
        >
          {isVoting ? 'Submitting Vote...' : 'Cast Your Vote'}
        </motion.button>
      )}
    </div>
  );
};
Phase 4: Backend Development

Initialize Backend

bashcd ../backend
pnpm init
pnpm add express cors helmet compression
pnpm add -D typescript @types/express @types/node nodemon ts-node
pnpm add ethers ipfs-http-client redis ioredis
pnpm add drizzle-orm @vercel/postgres

Create Voting Service

typescript// src/services/voting.ts
import { ethers } from 'ethers';
import { redis } from '../db/redis';
import { BushidoNFT__factory } from '../types';

export class VotingService {
  private contract: ethers.Contract;
  private provider: ethers.Provider;

  constructor() {
    this.provider = new ethers.JsonRpcProvider(process.env.RPC_URL);
    this.contract = BushidoNFT__factory.connect(
      process.env.CONTRACT_ADDRESS!,
      this.provider
    );
  }

  async getVotingPower(address: string): Promise<number> {
    const balance = await this.contract.balanceOf(address);
    let totalPower = 0;

    for (let i = 0; i < balance; i++) {
      const tokenId = await this.contract.tokenOfOwnerByIndex(address, i);
      const power = await this.contract.getVotingPower(tokenId);
      totalPower += Number(power);
    }

    return totalPower;
  }

  async recordVote(
    episodeId: number,
    optionId: string,
    address: string,
    votingPower: number
  ): Promise<void> {
    const voteKey = `vote:${episodeId}:${address}`;
    const hasVoted = await redis.exists(voteKey);
    
    if (hasVoted) {
      throw new Error('Already voted');
    }

    // Record vote
    await redis.set(voteKey, optionId, 'EX', 30 * 24 * 60 * 60); // 30 days
    
    // Increment vote count
    const countKey = `votes:${episodeId}:${optionId}`;
    await redis.incrby(countKey, votingPower);
  }

  async getVoteResults(episodeId: number): Promise<Record<string, number>> {
    const pattern = `votes:${episodeId}:*`;
    const keys = await redis.keys(pattern);
    
    const results: Record<string, number> = {};
    
    for (const key of keys) {
      const optionId = key.split(':').pop()!;
      const votes = await redis.get(key);
      results[optionId] = parseInt(votes || '0');
    }
    
    return results;
  }
}
Phase 5: Database Setup

Database Schema

typescript// backend/src/db/schema.ts
import { pgTable, serial, text, timestamp, integer, boolean } from 'drizzle-orm/pg-core';

export const episodes = pgTable('episodes', {
  id: serial('id').primaryKey(),
  title: text('title').notNull(),
  description: text('description'),
  videoUrl: text('video_url').notNull(),
  thumbnailUrl: text('thumbnail_url'),
  releaseDate: timestamp('release_date').notNull(),
  votingDeadline: timestamp('voting_deadline'),
  published: boolean('published').default(false)
});

export const voteOptions = pgTable('vote_options', {
  id: serial('id').primaryKey(),
  episodeId: integer('episode_id').references(() => episodes.id),
  optionText: text('option_text').notNull(),
  description: text('description'),
  order: integer('order').default(0)
});

export const voteResults = pgTable('vote_results', {
  id: serial('id').primaryKey(),
  episodeId: integer('episode_id').references(() => episodes.id),
  optionId: integer('option_id').references(() => voteOptions.id),
  voterAddress: text('voter_address').notNull(),
  votingPower: integer('voting_power').notNull(),
  timestamp: timestamp('timestamp').defaultNow()
});
Phase 6: IPFS Setup

Metadata Generation Script

typescript// scripts/generate-metadata.ts
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
Phase 7: Deployment Configuration

Contract Deployment Script

typescript// scripts/deploy.ts
import { ethers } from 'hardhat';
import { verify } from './verify';

async function main() {
  console.log('Deploying Bushido NFT to Abstract...');
  
  const BushidoNFT = await ethers.getContractFactory('BushidoNFT');
  const contract = await BushidoNFT.deploy();
  await contract.waitForDeployment();
  
  const address = await contract.getAddress();
  console.log(`Contract deployed to: ${address}`);
  
  // Wait for confirmations
  await contract.deploymentTransaction()?.wait(5);
  
  // Verify on explorer
  await verify(address, []);
  
  // Set base URI
  const baseURI = `https://ipfs.io/ipfs/${process.env.METADATA_HASH}/`;
  await contract.setBaseURI(baseURI);
  
  console.log('Deployment complete!');
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});