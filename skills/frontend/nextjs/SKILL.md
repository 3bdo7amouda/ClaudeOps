# skill: frontend/nextjs
# triggers: nextjs, next.js, app router, server component, rsc, server action, ssr, isr, static generation, next config, middleware

## Project Structure (App Router)
```
src/
├── app/
│   ├── layout.tsx          # root layout (server component)
│   ├── page.tsx            # /
│   ├── (auth)/             # route group — no URL segment
│   │   ├── login/page.tsx
│   │   └── layout.tsx
│   ├── dashboard/
│   │   ├── page.tsx        # server component by default
│   │   └── _components/    # private to this route
│   └── api/
│       └── webhooks/route.ts
├── components/             # shared UI
├── lib/                    # utilities, db client, auth
└── middleware.ts            # auth gates, redirects
```

## Server vs Client Components
```typescript
// Server Component (default) — runs on server, no hooks, no browser APIs
// Access DB, secrets, filesystem directly
export default async function Page() {
  const data = await db.posts.findMany()   // direct DB call — no API needed
  return <PostList posts={data} />
}

// Client Component — add 'use client' directive
'use client'
import { useState } from 'react'
export function Counter() {
  const [n, setN] = useState(0)
  return <button onClick={() => setN(n+1)}>{n}</button>
}
```

## Server Actions (form mutations)
```typescript
// app/actions.ts
'use server'
import { revalidatePath } from 'next/cache'
import { z } from 'zod'

const schema = z.object({ name: z.string().min(1) })

export async function createPost(formData: FormData) {
  const parsed = schema.safeParse({ name: formData.get('name') })
  if (!parsed.success) return { error: parsed.error.flatten() }

  await db.posts.create({ data: parsed.data })
  revalidatePath('/dashboard')
  return { success: true }
}

// In component
import { createPost } from './actions'
<form action={createPost}>
  <input name="name" />
  <button type="submit">Create</button>
</form>
```

## Data Fetching Patterns
```typescript
// Static (build time) — default for server components with no dynamic data
export default async function Page() {
  const data = await fetch('https://api.example.com/data', {
    next: { revalidate: 3600 }   // ISR: revalidate every hour
  })
  return <>{data}</>
}

// Dynamic — per request
export const dynamic = 'force-dynamic'   // or use cookies()/headers() which auto-opts in

// Parallel data fetching
export default async function Page() {
  const [user, posts] = await Promise.all([getUser(), getPosts()])
  return <>...</>
}
```

## Middleware (auth gates)
```typescript
// middleware.ts — runs on edge, before page renders
import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

export function middleware(req: NextRequest) {
  const token = req.cookies.get('auth-token')?.value
  const isAuthPage = req.nextUrl.pathname.startsWith('/login')

  if (!token && !isAuthPage) {
    return NextResponse.redirect(new URL('/login', req.url))
  }
  if (token && isAuthPage) {
    return NextResponse.redirect(new URL('/dashboard', req.url))
  }
  return NextResponse.next()
}

export const config = {
  matcher: ['/((?!api|_next/static|_next/image|favicon.ico).*)']
}
```

## Route Handlers (API)
```typescript
// app/api/users/[id]/route.ts
import { NextRequest, NextResponse } from 'next/server'

export async function GET(req: NextRequest, { params }: { params: { id: string } }) {
  const user = await db.users.findUnique({ where: { id: params.id } })
  if (!user) return NextResponse.json({ error: 'NOT_FOUND' }, { status: 404 })
  return NextResponse.json({ data: user })
}

export async function PATCH(req: NextRequest, { params }: { params: { id: string } }) {
  const body = await req.json()
  const updated = await db.users.update({ where: { id: params.id }, data: body })
  return NextResponse.json({ data: updated })
}
```

## Metadata & SEO
```typescript
// app/layout.tsx
export const metadata: Metadata = {
  title: { template: '%s | MyApp', default: 'MyApp' },
  description: '...',
  openGraph: { type: 'website', url: 'https://myapp.com' },
}

// app/blog/[slug]/page.tsx — dynamic metadata
export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const post = await getPost(params.slug)
  return { title: post.title, description: post.excerpt }
}
```

## next.config.ts — Production Setup
```typescript
const nextConfig = {
  images: {
    remotePatterns: [{ hostname: 'cdn.example.com' }],
  },
  experimental: { serverActions: { allowedOrigins: ['myapp.com'] } },
  headers: async () => [
    { source: '/(.*)', headers: [
      { key: 'X-Frame-Options', value: 'DENY' },
      { key: 'X-Content-Type-Options', value: 'nosniff' },
    ]}
  ],
}
export default nextConfig
```

## Rules
- Server Components are the default — only add `'use client'` when needed
- Server Actions > API routes for form mutations
- Colocate `_components/` inside route dirs for route-specific components
- Use `loading.tsx` + `error.tsx` for every major route segment
- `revalidatePath()` / `revalidateTag()` for cache invalidation after mutations
