import { Router } from 'express';

export const metadataRouter = Router();

metadataRouter.get('/:tokenId', (req, res) => {
  const { tokenId } = req.params;
  res.json({ tokenId, name: `Bushido Samurai #${tokenId}` });
});
