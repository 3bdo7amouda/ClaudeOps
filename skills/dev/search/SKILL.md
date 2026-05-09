# skill: dev/search
# triggers: search, full-text, typesense, meilisearch, elasticsearch, postgres fts, vector search, semantic search, embedding

## Postgres Full-Text Search (start here)
```sql
-- Add search vector column (auto-updated via trigger)
ALTER TABLE products ADD COLUMN search_vector tsvector
  GENERATED ALWAYS AS (
    to_tsvector('english', coalesce(title, '') || ' ' || coalesce(description, ''))
  ) STORED;

CREATE INDEX idx_products_search ON products USING gin(search_vector);

-- Search query
SELECT *, ts_rank(search_vector, query) AS rank
FROM products, to_tsquery('english', 'laptop & gaming') query
WHERE search_vector @@ query
ORDER BY rank DESC
LIMIT 20;

-- Fuzzy (similarity) search for typos
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX idx_products_trgm ON products USING gin(title gin_trgm_ops);
SELECT * FROM products WHERE similarity(title, 'laptoop') > 0.3 ORDER BY similarity(title, 'laptoop') DESC;
```

## Typesense (hosted search engine — recommended upgrade from FTS)
```typescript
import Typesense from 'typesense'

const client = new Typesense.Client({
  nodes: [{ host: process.env.TYPESENSE_HOST!, port: 443, protocol: 'https' }],
  apiKey: process.env.TYPESENSE_API_KEY!,
  connectionTimeoutSeconds: 5,
})

// Define schema
await client.collections().create({
  name: 'products',
  fields: [
    { name: 'id', type: 'string' },
    { name: 'title', type: 'string' },
    { name: 'description', type: 'string', optional: true },
    { name: 'price', type: 'float', facet: true },
    { name: 'category', type: 'string', facet: true },
    { name: 'in_stock', type: 'bool', facet: true },
    { name: 'created_at', type: 'int64' },
  ],
  default_sorting_field: 'created_at',
})

// Index documents
await client.collections('products').documents().import(products, { action: 'upsert' })

// Search
const results = await client.collections('products').documents().search({
  q: 'gaming laptop',
  query_by: 'title,description',
  filter_by: 'in_stock:true && price:<2000',
  facet_by: 'category,price',
  sort_by: '_text_match:desc,price:asc',
  per_page: 20,
  page: 1,
  typo_tolerance_threshold: 0,  // 0=auto based on word length
})
```

## Sync DB → Search Index
```typescript
// After any DB write, sync to search index
async function syncProduct(productId: string) {
  const product = await db.products.findUnique({ where: { id: productId } })
  if (!product) {
    await client.collections('products').documents(productId).delete()
    return
  }
  await client.collections('products').documents().upsert({
    id: product.id,
    title: product.title,
    description: product.description ?? '',
    price: product.price,
    category: product.category,
    in_stock: product.stock > 0,
    created_at: Math.floor(product.createdAt.getTime() / 1000),
  })
}

// Or bulk sync via queue
await searchSyncQueue.add('sync', { productId }, { delay: 500, jobId: `sync:${productId}` })
```

## Vector / Semantic Search
```typescript
import OpenAI from 'openai'
// (or use Anthropic's claude-3 via: anthropic.embeddings)

// Generate embedding
async function embed(text: string): Promise<number[]> {
  const res = await openai.embeddings.create({ model: 'text-embedding-3-small', input: text })
  return res.data[0].embedding
}

// Store in Postgres with pgvector
// CREATE EXTENSION vector;
// ALTER TABLE documents ADD COLUMN embedding vector(1536);
// CREATE INDEX ON documents USING hnsw (embedding vector_cosine_ops);

await db.$executeRaw`
  UPDATE documents SET embedding = ${JSON.stringify(await embed(doc.content))}::vector
  WHERE id = ${doc.id}
`

// Semantic search
const queryEmbedding = await embed(userQuery)
const results = await db.$queryRaw`
  SELECT id, title, 1 - (embedding <=> ${JSON.stringify(queryEmbedding)}::vector) AS similarity
  FROM documents
  WHERE 1 - (embedding <=> ${JSON.stringify(queryEmbedding)}::vector) > 0.75
  ORDER BY embedding <=> ${JSON.stringify(queryEmbedding)}::vector
  LIMIT 10
`
```

## Search Decision Tree
```
< 50k records, simple queries → Postgres FTS
50k-10M records, facets, typo tolerance → Typesense
> 10M records, complex analytics → Elasticsearch
Semantic/AI search → pgvector + Typesense hybrid
```
