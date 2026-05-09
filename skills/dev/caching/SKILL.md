# skill: dev/caching
# triggers: cache, redis, caching, invalidation, ttl, memcached, in-memory, stale

## From: redis/redis-development (official Redis skill)

## Redis Client Setup
```typescript
import { Redis } from 'ioredis'

export const redis = new Redis({
  host: process.env.REDIS_HOST!,
  port: 6379,
  password: process.env.REDIS_PASSWORD,
  tls: process.env.NODE_ENV === 'production' ? {} : undefined,
  maxRetriesPerRequest: 3,
  retryStrategy: (times) => Math.min(times * 200, 3000),
  lazyConnect: true,
})
```

## Cache Patterns

### Cache-Aside (read-through)
```typescript
async function getUser(id: string): Promise<User> {
  const cached = await redis.get(`user:${id}`)
  if (cached) return JSON.parse(cached)

  const user = await db.users.findUnique({ where: { id } })
  if (user) await redis.setex(`user:${id}`, 300, JSON.stringify(user))  // 5 min TTL
  return user
}

// Invalidate on update
async function updateUser(id: string, data: Partial<User>) {
  const user = await db.users.update({ where: { id }, data })
  await redis.del(`user:${id}`)    // invalidate cache
  return user
}
```

### Write-Through
```typescript
async function updateUserWT(id: string, data: Partial<User>) {
  const [user] = await Promise.all([
    db.users.update({ where: { id }, data }),
    redis.setex(`user:${id}`, 300, JSON.stringify({ ...existingUser, ...data })),
  ])
  return user
}
```

### Data Structures — Choose Right One
```typescript
// Strings — simple values, counters, sessions
await redis.setex(`session:${token}`, 86400, userId)
await redis.incr(`page_views:${date}`)

// Hashes — objects (avoid JSON.stringify for frequently updated fields)
await redis.hset(`user:${id}`, { name, email, plan })
await redis.hget(`user:${id}`, 'plan')

// Sets — unique members, tags, permissions
await redis.sadd(`org:${orgId}:members`, userId)
await redis.smembers(`org:${orgId}:members`)

// Sorted Sets — leaderboards, rate limiting, delayed jobs
await redis.zadd('leaderboard', score, userId)
await redis.zrange('leaderboard', 0, 9, 'REV', 'WITHSCORES')  // top 10

// Lists — queues (prefer BullMQ), activity feeds
await redis.lpush(`feed:${userId}`, JSON.stringify(event))
await redis.lrange(`feed:${userId}`, 0, 19)  // last 20 events
```

## Rate Limiting
```typescript
export async function rateLimit(key: string, max: number, windowSec: number): Promise<boolean> {
  const current = await redis.incr(key)
  if (current === 1) await redis.expire(key, windowSec)
  return current <= max
}

// Usage: 5 requests per minute per IP
const allowed = await rateLimit(`rl:${ip}:login`, 5, 60)
if (!allowed) res.status(429).json({ error: 'Too many requests' })
```

## Session Store
```typescript
import session from 'express-session'
import RedisStore from 'connect-redis'

app.use(session({
  store: new RedisStore({ client: redis, prefix: 'sess:' }),
  secret: process.env.SESSION_SECRET!,
  resave: false,
  saveUninitialized: false,
  cookie: { secure: true, httpOnly: true, maxAge: 86400 * 1000, sameSite: 'strict' },
}))
```

## Cache Invalidation Strategies
```typescript
// Tag-based invalidation
await redis.sadd(`tag:user:${userId}`, `user:${userId}`, `feed:${userId}`, `stats:${userId}`)
// Invalidate all user-related keys
const keys = await redis.smembers(`tag:user:${userId}`)
await redis.del(...keys, `tag:user:${userId}`)

// Versioned cache (avoids stale reads after deploys)
const v = process.env.CACHE_VERSION ?? '1'
const key = `${v}:user:${id}`
```

## Rules (from official Redis skill)
- Always set TTL on cache keys — `SETEX` never `SET` alone
- Avoid `KEYS *` in production — use `SCAN` for iteration
- Connection pooling: one client per service, not per request
- Monitor: `redis-cli INFO memory` — alert if `used_memory > maxmemory * 0.8`
- Use `HSET` for objects you partially update (not full JSON replace)
- Pipeline bulk operations: `redis.pipeline().set().set().exec()`
