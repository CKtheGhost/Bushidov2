import { Server } from 'socket.io';
import { createServer } from 'http';
import express from 'express';
import { ethers } from 'ethers';
import Redis from 'redis';

const app = express();
const httpServer = createServer(app);
const io = new Server(httpServer, {
  cors: {
    origin: process.env.FRONTEND_URL,
    credentials: true
  }
});

const redis = Redis.createClient({
  url: process.env.REDIS_URL
});

// Real-time voting aggregation
interface Vote {
  tokenId: number;
  episodeId: number;
  choice: string;
  votingPower: number;
  timestamp: number;
}

class VotingAggregator {
  private votes: Map<string, Vote[]> = new Map();
  
  async recordVote(vote: Vote): Promise<void> {
    const key = `episode:${vote.episodeId}`;
    
    // Store in memory
    if (!this.votes.has(key)) {
      this.votes.set(key, []);
    }
    this.votes.get(key)!.push(vote);
    
    // Store in Redis
    await redis.hIncrBy(
      `votes:${vote.episodeId}`,
      vote.choice,
      vote.votingPower
    );
    
    // Emit real-time update
    io.emit('voteUpdate', {
      episodeId: vote.episodeId,
      totals: await this.getVoteTotals(vote.episodeId)
    });
  }
  
  async getVoteTotals(episodeId: number): Promise<Record<string, number>> {
    const totals = await redis.hGetAll(`votes:${episodeId}`);
    return Object.fromEntries(
      Object.entries(totals).map(([k, v]) => [k, parseInt(v)])
    );
  }
  
  async getVoteBreakdown(episodeId: number): Promise<any> {
    const votes = this.votes.get(`episode:${episodeId}`) || [];
    
    // Aggregate by clan
    const clanVotes: Record<number, Record<string, number>> = {};
    
    for (const vote of votes) {
      const clan = Math.floor((vote.tokenId - 1) / 200);
      if (!clanVotes[clan]) {
        clanVotes[clan] = {};
      }
      clanVotes[clan][vote.choice] = (clanVotes[clan][vote.choice] || 0) + vote.votingPower;
    }
    
    return {
      total: await this.getVoteTotals(episodeId),
      byClan: clanVotes,
      voteCount: votes.length
    };
  }
}

const aggregator = new VotingAggregator();

// WebSocket handlers
io.on('connection', (socket) => {
  console.log('Client connected:', socket.id);
  
  socket.on('vote', async (data) => {
    try {
      // Verify vote signature
      const { tokenId, episodeId, choice, signature } = data;
      
      // Record vote
      await aggregator.recordVote({
        tokenId,
        episodeId,
        choice,
        votingPower: calculateVotingPower(tokenId),
        timestamp: Date.now()
      });
      
      socket.emit('voteConfirmed', { success: true });
    } catch (error) {
      socket.emit('voteError', { error: error.message });
    }
  });
  
  socket.on('getResults', async (episodeId) => {
    const results = await aggregator.getVoteBreakdown(episodeId);
    socket.emit('results', results);
  });
});

function calculateVotingPower(tokenId: number): number {
  // This would fetch from contract or cache
  // Placeholder implementation
  return 1;
}

export { httpServer, aggregator };
