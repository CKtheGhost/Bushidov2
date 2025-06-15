import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import dotenv from 'dotenv';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 4000;

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());

// Health check
app.get('/health', (req, res) => {
  res.json({ 
    status: 'healthy',
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});

// Metadata endpoint
app.get('/api/metadata/:tokenId', async (req, res) => {
  const { tokenId } = req.params;
  
  // Calculate clan and warrior number
  const clan = Math.floor((parseInt(tokenId) - 1) / 200);
  const warriorInClan = ((parseInt(tokenId) - 1) % 200) + 1;
  
  const clans = [
    'Dragon', 'Phoenix', 'Tiger', 'Serpent',
    'Eagle', 'Wolf', 'Bear', 'Lion'
  ];
  
  const metadata = {
    name: `Bushido Warrior #${tokenId}`,
    description: `A legendary warrior of the ${clans[clan]} clan.`,
    image: `ipfs://QmXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX/${tokenId}.png`,
    attributes: [
      {
        trait_type: 'Clan',
        value: clans[clan]
      },
      {
        trait_type: 'Warrior Number',
        value: warriorInClan
      }
    ]
  };
  
  res.json(metadata);
});

// Voting endpoints
app.get('/api/episodes/:episodeId/votes', async (req, res) => {
  // Return current vote tallies
  res.json({
    episodeId: req.params.episodeId,
    options: [],
    totalVotes: 0
  });
});

app.post('/api/episodes/:episodeId/vote', async (req, res) => {
  // Process vote
  res.json({ success: true });
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 Server running on http://localhost:${PORT}`);
});
