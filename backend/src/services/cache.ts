import { redis } from '../db/redis'

export class CacheService {
  async get<T>(key: string): Promise<T | null> {
    const value = await redis.get(key)
    return value ? (JSON.parse(value) as T) : null
  }

  async set(key: string, value: unknown, ttlSeconds = 3600): Promise<void> {
    await redis.set(key, JSON.stringify(value), { EX: ttlSeconds })
  }
}
