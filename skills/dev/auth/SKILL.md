# skill: dev/auth
# triggers: auth, authentication, jwt, oauth, oidc, login, session, password, mfa, 2fa, better-auth, nextauth, lucia

## Stack Decision
```
Better Auth  → new full-stack TS apps (best DX, built-in orgs/2FA/OAuth)
Auth.js      → Next.js / SvelteKit (ecosystem fit)
Lucia        → custom control, any framework
Auth0/Clerk  → managed, fast to ship, higher cost at scale
Roll your own → only if you have specific compliance/IP needs
```

## Better Auth — Quickstart
```typescript
// lib/auth.ts
import { betterAuth } from "better-auth"
import { twoFactor, organization } from "better-auth/plugins"
import { prismaAdapter } from "better-auth/adapters/prisma"

export const auth = betterAuth({
  database: prismaAdapter(prisma, { provider: "postgresql" }),
  emailAndPassword: { enabled: true },
  socialProviders: {
    google: { clientId: process.env.GOOGLE_CLIENT_ID!, clientSecret: process.env.GOOGLE_CLIENT_SECRET! },
    github: { clientId: process.env.GITHUB_CLIENT_ID!, clientSecret: process.env.GITHUB_CLIENT_SECRET! },
  },
  plugins: [twoFactor(), organization()],
})

// app/api/auth/[...all]/route.ts
import { auth } from "@/lib/auth"
import { toNextJsHandler } from "better-auth/next-js"
export const { GET, POST } = toNextJsHandler(auth)
```

## JWT — Production Pattern
```typescript
import jwt from 'jsonwebtoken'

const ACCESS_TTL  = '15m'
const REFRESH_TTL = '7d'

export const signAccess  = (payload: object) =>
  jwt.sign(payload, process.env.JWT_ACCESS_SECRET!, { expiresIn: ACCESS_TTL })
export const signRefresh = (userId: string) =>
  jwt.sign({ sub: userId }, process.env.JWT_REFRESH_SECRET!, { expiresIn: REFRESH_TTL })

export const verifyAccess = (token: string) =>
  jwt.verify(token, process.env.JWT_ACCESS_SECRET!) as jwt.JwtPayload

// Refresh flow
export async function refresh(refreshToken: string) {
  const payload = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET!) as jwt.JwtPayload
  const stored = await db.refreshTokens.findUnique({ where: { token: refreshToken } })
  if (!stored || stored.revoked) throw new Error('Invalid refresh token')
  await db.refreshTokens.update({ where: { token: refreshToken }, data: { revoked: true } })
  const user = await db.users.findUnique({ where: { id: payload.sub } })
  return { access: signAccess({ sub: user.id, role: user.role }), refresh: signRefresh(user.id) }
}
```

## Auth Middleware (Express)
```typescript
export async function requireAuth(req: Request, res: Response, next: NextFunction) {
  const token = req.headers.authorization?.split(' ')[1]
  if (!token) return res.status(401).json({ error: 'UNAUTHORIZED' })
  try {
    req.user = verifyAccess(token)
    next()
  } catch {
    res.status(401).json({ error: 'TOKEN_EXPIRED' })
  }
}

export const requireRole = (role: string) => (req: Request, res: Response, next: NextFunction) => {
  if (req.user?.role !== role) return res.status(403).json({ error: 'FORBIDDEN' })
  next()
}
```

## Password Hashing
```typescript
import { hash, verify } from '@node-rs/argon2'  // faster than bcrypt

const HASH_OPTIONS = { memoryCost: 19456, timeCost: 2, outputLen: 32, parallelism: 1 }
export const hashPassword   = (pwd: string) => hash(pwd, HASH_OPTIONS)
export const verifyPassword = (hash: string, pwd: string) => verify(hash, pwd, HASH_OPTIONS)
```

## TOTP / 2FA
```typescript
import { TOTP } from 'otpauth'

export function generateTOTP(secret: string) {
  const totp = new TOTP({ secret, digits: 6, period: 30 })
  return { token: totp.generate(), uri: totp.toString() }
}
export function verifyTOTP(secret: string, token: string) {
  const totp = new TOTP({ secret, digits: 6, period: 30 })
  return totp.validate({ token, window: 1 }) !== null
}
```

## OAuth2 Flow (manual)
```typescript
// 1. Redirect to provider
const state = crypto.randomUUID()
await redis.set(`oauth:${state}`, userId, { ex: 600 })
res.redirect(`https://accounts.google.com/o/oauth2/v2/auth?${new URLSearchParams({
  client_id: process.env.GOOGLE_CLIENT_ID!,
  redirect_uri: `${process.env.APP_URL}/auth/callback/google`,
  response_type: 'code', scope: 'openid email profile', state,
})}`)

// 2. Handle callback
const { code, state } = req.query
const storedUserId = await redis.get(`oauth:${state}`)
if (!storedUserId) throw new Error('Invalid state')
const tokens = await exchangeCode(code as string)
const profile = await getGoogleProfile(tokens.access_token)
```

## Security Checklist
```
✓ Passwords: argon2id, never bcrypt MD5
✓ Tokens: short-lived access (15m) + refresh rotation
✓ Refresh tokens: single-use, stored hashed
✓ CSRF: SameSite=Strict cookies or CSRF tokens
✓ Rate limit: /login (5/min), /register (3/min)
✓ Timing-safe comparison for tokens: crypto.timingSafeEqual()
✓ No user enumeration: same error for bad email + bad password
✓ Logout: revoke refresh token server-side
```

## FORBIDDEN
```
FORBIDDEN: Storing JWT secrets in client-accessible storage (localStorage for sensitive apps).
FORBIDDEN: Long-lived access tokens (>1 hour) without refresh rotation.
FORBIDDEN: Returning different errors for "user not found" vs "wrong password."
FORBIDDEN: Logging raw passwords or tokens anywhere.
```

## Gotchas

1. **JWT "stateless" is a lie in practice.** You still need server-side refresh token storage to support logout and revocation. Pure stateless JWT = can't revoke a compromised token until it expires.

2. **`SameSite=Strict` breaks OAuth redirects.** OAuth returns to your callback URL from the provider's domain — the browser won't send `SameSite=Strict` cookies. Use `SameSite=Lax` for auth cookies.

3. **argon2id parameters are tunable.** The defaults in most libraries are fine for typical servers, but benchmark on your actual hardware. Too aggressive → login endpoint becomes a DoS target.

4. **TOTP window=1 matters.** Without `window: 1` (accepts tokens 30s before/after), users with slightly off clocks fail 2FA. With `window: 1`, you're still secure — the window is 90 seconds total.

5. **OAuth state parameter MUST be validated.** Skipping state validation = CSRF on your OAuth callback. `await redis.get(\`oauth:${state}\`)` must return a valid session before proceeding.

## Related Skills
- **dev/saas**: Session-to-org resolution; organization membership checks after auth
- **dev/caching**: Redis for refresh token storage, rate limiting on auth endpoints
- **devops/security**: Secrets management for JWT keys; rotation procedures
