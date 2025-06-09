import { Router } from 'express';

export const episodesRouter = Router();

episodesRouter.get('/', (_req, res) => {
  res.json([]);
});
