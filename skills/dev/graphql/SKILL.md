# skill: dev/graphql
# triggers: graphql, gql, apollo, pothos, graphql-yoga, schema, resolver, query, mutation, subscription, federation

## When GraphQL > REST
```
Use GraphQL when:
  ✓ Multiple clients need different shapes of same data (web/mobile)
  ✓ Heavy relational data with many join patterns
  ✓ Real-time subscriptions alongside queries

Stick with REST when:
  ✓ Simple CRUD with uniform client needs
  ✓ File uploads (REST handles better)
  ✓ Public API (REST easier to document/consume)
  ✓ Caching at CDN level is critical
```

## Schema-First (TypeScript) with Pothos
```typescript
import SchemaBuilder from '@pothos/core'
import PrismaPlugin from '@pothos/plugin-prisma'

const builder = new SchemaBuilder<{ PrismaTypes: PrismaTypes }>({
  plugins: [PrismaPlugin],
  prisma: { client: db },
})

builder.prismaObject('User', {
  fields: (t) => ({
    id:    t.exposeID('id'),
    email: t.exposeString('email'),
    posts: t.relation('posts'),
  }),
})

builder.queryField('user', (t) =>
  t.prismaField({
    type: 'User',
    args: { id: t.arg.id({ required: true }) },
    resolve: (query, _root, args) =>
      db.user.findUniqueOrThrow({ ...query, where: { id: String(args.id) } }),
  })
)

builder.mutationField('createPost', (t) =>
  t.prismaField({
    type: 'Post',
    args: {
      title:   t.arg.string({ required: true }),
      content: t.arg.string({ required: true }),
    },
    resolve: (_query, _root, args, ctx) =>
      db.post.create({ data: { ...args, authorId: ctx.userId } }),
  })
)
```

## Server Setup (graphql-yoga)
```typescript
import { createYoga } from 'graphql-yoga'
import { schema } from './schema'

const yoga = createYoga({
  schema,
  context: async ({ request }) => ({
    userId: await getUserFromRequest(request),
    db,
  }),
})

// Next.js App Router
export const { handleRequest: GET, handleRequest: POST } = yoga
```

## Apollo Server (Express)
```typescript
import { ApolloServer } from '@apollo/server'
import { expressMiddleware } from '@apollo/server/express4'

const server = new ApolloServer({ typeDefs, resolvers })
await server.start()
app.use('/graphql', expressMiddleware(server, {
  context: async ({ req }) => ({ userId: req.user?.id, db }),
}))
```

## DataLoader (N+1 prevention — mandatory)
```typescript
import DataLoader from 'dataloader'

// Create per-request (in context factory)
const userLoader = new DataLoader<string, User>(async (ids) => {
  const users = await db.users.findMany({ where: { id: { in: [...ids] } } })
  return ids.map(id => users.find(u => u.id === id) ?? new Error(`User ${id} not found`))
})

// Use in resolver instead of db.users.findUnique
const user = await ctx.loaders.user.load(post.authorId)
```

## Subscriptions (real-time)
```typescript
builder.subscriptionField('postAdded', (t) =>
  t.field({
    type: 'Post',
    subscribe: () => pubsub.subscribe('POST_ADDED'),
    resolve: (payload) => payload,
  })
)

// Publish from mutation
await pubsub.publish('POST_ADDED', newPost)
```

## Fragments & Pagination Pattern
```graphql
# Cursor-based (relay spec)
type PostConnection {
  edges: [PostEdge!]!
  pageInfo: PageInfo!
}
type PostEdge { node: Post!; cursor: String! }
type PageInfo { hasNextPage: Boolean!; endCursor: String }

query {
  posts(first: 20, after: "cursor") {
    edges { node { id title } cursor }
    pageInfo { hasNextPage endCursor }
  }
}
```

## Rules
- Always use DataLoader — never query inside a resolver loop
- Auth in context, not in resolvers (check `ctx.userId` at resolver entry)
- Use `depth-limit` to block deeply nested query attacks
- Disable introspection in production
- Persisted queries for performance (hash → query map)
