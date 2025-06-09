import { Router } from 'express';
import { VotingService } from '../services/voting';

const service = new VotingService();
export const votingRouter = Router();

votingRouter.post('/', async (req, res) => {
  const { episodeId, optionId, address } = req.body;
  const power = await service.getVotingPower(address);
  await service.recordVote(episodeId, optionId, address, power);
  res.json({ ok: true });
});

votingRouter.get('/:episodeId', async (req, res) => {
  const results = await service.getVoteResults(parseInt(req.params.episodeId));
  res.json(results);
});
