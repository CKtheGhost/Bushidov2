// backend/src/db/schema.ts
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