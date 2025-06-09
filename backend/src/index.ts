import express from 'express';
import cors from 'cors';
import { metadataRouter } from './routes/metadata';
import { episodesRouter } from './routes/episodes';
import { votingRouter } from './routes/voting';

const app = express();
const PORT = process.env.PORT || 3001;

app.use(cors());
app.use(express.json());

app.use('/metadata', metadataRouter);
app.use('/episodes', episodesRouter);
app.use('/voting', votingRouter);

app.get('/', (_req, res) => {
  res.send('Bushido API');
});

app.listen(PORT, () => {
  console.log(`API server listening on port ${PORT}`);
});
