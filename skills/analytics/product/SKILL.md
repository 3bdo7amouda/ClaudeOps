# skill: analytics/product
# triggers: analytics, posthog, mixpanel, amplitude, product analytics, event tracking, funnel, retention, gtm, ga4

## PostHog — Recommended (open-source, self-hostable)
```typescript
// lib/analytics.ts
import PostHog from 'posthog-js'

export const posthog = PostHog.init(process.env.NEXT_PUBLIC_POSTHOG_KEY!, {
  api_host: process.env.NEXT_PUBLIC_POSTHOG_HOST ?? 'https://app.posthog.com',
  capture_pageview: false,       // manual control
  capture_pageleave: true,
  session_recording: { maskAllInputs: true },  // GDPR-safe
  person_profiles: 'identified_only',
})

// Identify user after login
export function identify(userId: string, traits: Record<string, unknown>) {
  posthog.identify(userId, traits)
}

// Track events
export function track(event: string, properties?: Record<string, unknown>) {
  posthog.capture(event, properties)
}

// Group by org
export function group(orgId: string, orgTraits: Record<string, unknown>) {
  posthog.group('company', orgId, orgTraits)
}
```

## Event Taxonomy — Standard Schema
```typescript
// Naming: <noun>_<past_tense_verb>
// Always include: source, org_id, plan

const EVENTS = {
  // Auth
  user_signed_up:       (method: 'email' | 'google' | 'github') => ({ method }),
  user_logged_in:       (method: string) => ({ method }),
  user_invited:         (role: string) => ({ role }),

  // Onboarding
  onboarding_step_completed: (step: string, order: number) => ({ step, order }),
  onboarding_completed: () => ({}),

  // Core product
  project_created:      (type: string) => ({ type }),
  feature_used:         (feature: string) => ({ feature }),

  // Billing
  trial_started:        (plan: string, days: number) => ({ plan, days }),
  plan_upgraded:        (from: string, to: string) => ({ from, to }),
  plan_downgraded:      (from: string, to: string) => ({ from, to }),
  subscription_cancelled: (reason?: string) => ({ reason }),
} as const

// Usage
track('user_signed_up', { ...EVENTS.user_signed_up('google'), source: 'landing_page' })
```

## Feature Flags (PostHog)
```typescript
// Server-side feature flag check
import { PostHog } from 'posthog-node'
const phServer = new PostHog(process.env.POSTHOG_KEY!, { host: process.env.POSTHOG_HOST })

export async function isFeatureEnabled(flag: string, userId: string): Promise<boolean> {
  return posthog.isFeatureEnabled(flag, userId)
}

// A/B test variant
const variant = await phServer.getFeatureFlag('pricing-experiment', userId)
// variant = 'control' | 'variant-a' | 'variant-b'
```

## Server-Side Tracking (Node.js)
```typescript
import { PostHog } from 'posthog-node'
const phServer = new PostHog(process.env.POSTHOG_KEY!)

// Track server events (queue jobs, webhooks, etc.)
phServer.capture({
  distinctId: userId,
  event: 'payment_processed',
  properties: { amount, currency, plan, orgId },
})

// Shutdown gracefully
await phServer.shutdown()
```

## Key Metrics to Track
```
Acquisition:
  user_signed_up + source + referrer

Activation (Aha moment):
  Define: first action that predicts retention
  Example: "project_created within 24h of signup"
  Target: >60% of signups

Retention:
  DAU/WAU/MAU ratio
  D1, D7, D30 retention curves
  Feature usage frequency

Revenue:
  trial_started → plan_upgraded conversion
  MRR by plan, CAC, LTV

Referral:
  invite_sent, invite_accepted
```

## Privacy / GDPR
```typescript
// Opt-out on cookie rejection
if (!cookiesAccepted) {
  posthog.opt_out_capturing()
  return
}
posthog.opt_in_capturing()

// Anonymize before deletion
await phServer.capture({ distinctId: userId, event: '$delete_person' })
```
