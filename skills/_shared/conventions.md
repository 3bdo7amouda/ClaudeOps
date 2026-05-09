# Shared Conventions

## Naming
- Files: kebab-case
- Env vars: UPPER_SNAKE_CASE
- DB tables: snake_case plural (`users`, `audit_logs`)
- API routes: kebab-case (`/user-profiles`, not `/userProfiles`)
- Docker images: lowercase with hyphens
- Git branches: `feat/`, `fix/`, `chore/`, `hotfix/` prefixes

## Git Commit Format
```
feat: add stripe webhook handler
fix: resolve token refresh race condition
chore: update node to 20.x
refactor: extract auth middleware
test: add integration tests for billing
docs: add deployment runbook
```
- Imperative mood, lowercase, no period
- Subject line ≤72 chars

## PR Rules
- Title: imperative mood, ≤60 chars
- One logical change per PR
- Include test evidence + screenshots for UI changes
- Link to issue/ticket

## Error Codes (API)
```typescript
// Consistent error shape across all endpoints
{ "error": "RESOURCE_NOT_FOUND", "message": "User not found", "statusCode": 404 }

// Standard codes
NOT_FOUND          → 404   // resource doesn't exist
UNAUTHORIZED       → 401   // no/invalid token
FORBIDDEN          → 403   // valid token, wrong role
VALIDATION_ERROR   → 422   // invalid input shape
CONFLICT           → 409   // duplicate / state conflict
RATE_LIMITED       → 429   // too many requests
INTERNAL_ERROR     → 500   // unexpected server error
```

## Logging Format (structured JSON)
```json
{ "level": "info", "ts": "2025-01-01T00:00:00Z", "service": "api",
  "traceId": "abc-123", "userId": "usr_abc", "event": "payment.created",
  "amount": 4999, "durationMs": 42 }
```
- No PII in logs (mask email, card, SSN)
- Always include `traceId` for distributed tracing
- `durationMs` on all external calls

## Environment Variables
```bash
# .env.example — always commit this
DATABASE_URL=postgresql://localhost:5432/mydb
REDIS_URL=redis://localhost:6379
JWT_SECRET=          # required — set in secrets manager
LOG_LEVEL=info
APP_URL=http://localhost:3000
```
- Never commit `.env`
- Full URL in `DATABASE_URL` — never separate host/pass vars

## Code Quality Gates (all PRs)
```
□ Linting       eslint / ruff / golangci-lint
□ Type check    tsc --noEmit / mypy / go vet
□ Tests         jest / pytest / go test (80%+ on business logic)
□ Security      trivy / snyk / semgrep
□ Bundle size   if frontend PR touches bundle
```

## Secrets — Hard Rules
```javascript
// NEVER — not even in dev
const secret = "sk-abc123"

// ALWAYS — from environment
const secret = process.env.SECRET_KEY   // set via secrets manager in prod
```
- Rotate any secret that was ever committed (treat as compromised)
- Pre-commit hook: `detect-secrets` or `gitleaks`

## API Versioning
```
/api/v1/users      ← stable version in URL
Accept: application/vnd.myapp.v2+json  ← header versioning for internal
```
- Bump major version for breaking changes
- Deprecate old version with `Sunset` header, 6-month notice

## Health Endpoints (required on all services)
```
GET /health  → { status: "ok" }                        200 always (liveness)
GET /ready   → { status: "ok", db: "ok", redis: "ok" } 200 if dependencies healthy (readiness)
GET /metrics → Prometheus text format                   (if instrumented)
```
