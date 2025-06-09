// src/services/voting.ts
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