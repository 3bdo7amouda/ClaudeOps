# skill: dev/saas
# triggers: saas, multi-tenant, tenancy, organization, workspace, feature flag, onboarding, plan, tier, pricing, freemium

## Multi-Tenancy Strategies
```
Row-level (recommended for most):
  - All tenants in same DB, tenant_id on every table
  - Simpler ops, good up to millions of tenants
  - RLS (Row Level Security) in Postgres for isolation

Schema-per-tenant:
  - Each tenant = separate Postgres schema
  - Better isolation, harder migrations
  - Good for regulated industries

DB-per-tenant:
  - Full isolation, highest cost
  - Only for enterprise/compliance requirements
```

## Postgres RLS (Row-Level Security)
```sql
-- Enable RLS on all tenant tables
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;

-- Policy: users only see their org's data
CREATE POLICY tenant_isolation ON posts
  USING (org_id = current_setting('app.current_org_id')::uuid);

-- Set at query time (in connection pool middleware)
SET LOCAL app.current_org_id = '...';
```

## Tenant Resolution Middleware
```typescript
// Resolve tenant from subdomain, header, or JWT claim
export async function tenantMiddleware(req: Request, res: Response, next: NextFunction) {
  const host = req.hostname                          // acme.app.com
  const subdomain = host.split('.')[0]               // acme
  const org = await db.organizations.findUnique({ where: { slug: subdomain } })
  if (!org) return res.status(404).json({ error: 'Organization not found' })
  req.orgId = org.id
  req.org   = org
  next()
}
```

## Feature Flags
```typescript
// Simple DB-backed feature flags (no vendor needed to start)
interface FeatureFlag { name: string; enabled: boolean; planFilter?: string[] }

export async function isEnabled(flag: string, ctx: { orgId: string; plan: string }): Promise<boolean> {
  const ff = await redis.get(`ff:${flag}`)
  if (!ff) return false
  const config = JSON.parse(ff) as FeatureFlag
  if (!config.enabled) return false
  if (config.planFilter && !config.planFilter.includes(ctx.plan)) return false
  // Check org-level overrides
  const override = await redis.get(`ff:${flag}:org:${ctx.orgId}`)
  if (override !== null) return override === 'true'
  return true
}

// Usage
if (await isEnabled('ai-features', { orgId: req.orgId, plan: user.plan })) {
  // show AI features
}
```

## Plan / Tier Enforcement
```typescript
const PLANS = {
  free:  { maxUsers: 3,  maxProjects: 1,  features: [] },
  pro:   { maxUsers: 10, maxProjects: 10, features: ['ai', 'api'] },
  team:  { maxUsers: 50, maxProjects: 100, features: ['ai', 'api', 'sso', 'audit'] },
} as const

export async function enforceLimit(orgId: string, resource: 'users' | 'projects') {
  const org = await db.organizations.findUnique({ where: { id: orgId }, include: { _count: true } })
  const plan = PLANS[org.plan as keyof typeof PLANS]
  const limit = plan[`max${resource.charAt(0).toUpperCase() + resource.slice(1)}` as 'maxUsers' | 'maxProjects']
  const current = org._count[resource]
  if (current >= limit) throw new PlanLimitError(`${resource} limit reached (${limit}). Upgrade to add more.`)
}
```

## Onboarding Flow
```typescript
// Track completion state
interface OnboardingStep {
  id: string
  completed: boolean
  completedAt?: Date
}

const STEPS = ['create-workspace', 'invite-team', 'connect-integration', 'first-action']

export async function getOnboardingProgress(orgId: string) {
  const progress = await db.onboarding.findMany({ where: { orgId } })
  return STEPS.map(id => ({
    id,
    completed: progress.some(p => p.stepId === id && p.completed),
    required: ['create-workspace', 'first-action'].includes(id),
  }))
}

// Complete a step
export async function completeStep(orgId: string, stepId: string) {
  await db.onboarding.upsert({
    where: { orgId_stepId: { orgId, stepId } },
    create: { orgId, stepId, completed: true, completedAt: new Date() },
    update: { completed: true, completedAt: new Date() },
  })
}
```

## Audit Log
```typescript
export async function audit(ctx: { orgId: string; userId: string; action: string; resource: string; resourceId: string; metadata?: object }) {
  await db.auditLogs.create({
    data: { ...ctx, metadata: ctx.metadata ?? {}, createdAt: new Date() }
  })
}
// Usage: await audit({ orgId, userId, action: 'user.invite', resource: 'user', resourceId: invitedId })
```
