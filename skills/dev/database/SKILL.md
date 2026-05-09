# skill: dev/database
# triggers: database, sql, postgres, migration, schema, query, orm, prisma, drizzle

## Postgres — Production Config
```sql
-- Always use transactions for multi-step ops
BEGIN;
  INSERT INTO users (id, email) VALUES (gen_random_uuid(), $1);
  INSERT INTO profiles (user_id) VALUES (lastval());
COMMIT;

-- Index strategy
CREATE INDEX CONCURRENTLY idx_users_email ON users(email);
CREATE INDEX idx_orders_user_created ON orders(user_id, created_at DESC);

-- Partial index for common filter
CREATE INDEX idx_orders_pending ON orders(created_at) WHERE status = 'pending';
```

## Migrations (pattern — use any tool)
```
migrations/
├── 001_initial_schema.sql
├── 002_add_users_email_index.sql
└── 003_add_orders_table.sql
```
- Never edit existing migrations
- Always reversible (UP/DOWN or separate rollback)
- Run in CI before deploy
- Use `CREATE INDEX CONCURRENTLY` (non-blocking)

## Prisma Schema Pattern
```prisma
model User {
  id        String   @id @default(cuid())
  email     String   @unique
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
  orders    Order[]
  @@index([email])
}

model Order {
  id        String   @id @default(cuid())
  userId    String
  status    OrderStatus @default(PENDING)
  user      User     @relation(fields: [userId], references: [id])
  @@index([userId, createdAt(sort: Desc)])
}
```

## Query Rules
- Use parameterized queries always (never string concat)
- Paginate with cursor, not OFFSET for large tables
- Use `EXPLAIN ANALYZE` before shipping complex queries
- Connection pool: max 10-20 per service instance

## EXPLAIN ANALYZE Pattern
```sql
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT u.*, COUNT(o.id) as order_count
FROM users u
LEFT JOIN orders o ON o.user_id = u.id
WHERE u.created_at > NOW() - INTERVAL '30 days'
GROUP BY u.id
ORDER BY order_count DESC
LIMIT 100;
-- Look for: Seq Scan on large tables, high actual_rows vs estimated_rows
```

## Connection Pool (Node)
```javascript
import { Pool } from 'pg'
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  max: 10,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
})
```

## Advanced Query Patterns
```sql
-- Top-N per group (window function)
SELECT * FROM (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY org_id ORDER BY created_at DESC) AS rn
  FROM events
) t WHERE rn <= 5;

-- Running totals
SELECT date, amount,
  SUM(amount) OVER (ORDER BY date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total
FROM transactions;

-- UPSERT (Postgres)
INSERT INTO settings (key, value, updated_at) VALUES ('theme', 'dark', NOW())
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value, updated_at = EXCLUDED.updated_at;

-- Soft delete pattern
ALTER TABLE records ADD COLUMN deleted_at TIMESTAMPTZ;
CREATE INDEX idx_records_active ON records (org_id, created_at) WHERE deleted_at IS NULL;
-- Query: WHERE deleted_at IS NULL

-- JSON aggregation
SELECT u.id, u.email,
  json_agg(json_build_object('id', o.id, 'total', o.total)) FILTER (WHERE o.id IS NOT NULL) AS orders
FROM users u LEFT JOIN orders o ON o.user_id = u.id
GROUP BY u.id;
```

## Drizzle ORM Pattern (modern alternative to Prisma)
```typescript
import { pgTable, text, timestamp, uuid } from 'drizzle-orm/pg-core'
import { drizzle } from 'drizzle-orm/node-postgres'
import { eq, desc, and, gt } from 'drizzle-orm'

export const users = pgTable('users', {
  id:        uuid('id').defaultRandom().primaryKey(),
  email:     text('email').notNull().unique(),
  orgId:     uuid('org_id').notNull().references(() => orgs.id),
  createdAt: timestamp('created_at').defaultNow().notNull(),
})

// Type-safe queries
const recentUsers = await db.select()
  .from(users)
  .where(and(eq(users.orgId, orgId), gt(users.createdAt, cutoff)))
  .orderBy(desc(users.createdAt))
  .limit(20)
```
