import { createClient } from 'redis';

const client = createClient({ url: process.env.REDIS_URL });
client.on('error', (err) => console.error('Redis error', err));
client.connect().catch(console.error);

export const redis = client;
