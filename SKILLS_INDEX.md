# Skills Index

Master index of all workspace skills. Claude loads the matching skill when trigger keywords appear.

## DevOps Skills (12) — Primary Domain

| Skill | Path | Trigger Keywords | Description |
|-------|------|-----------------|-------------|
| Infrastructure | `skills/devops/infra` | terraform, IaC, provision, cloudformation, hcl | Terraform modules, remote state, workspace workflow, drift detection |
| CI/CD | `skills/devops/cicd` | pipeline, CI/CD, github actions, gitlab ci, deploy | GitHub Actions OIDC, matrix builds, reusable workflows, rollback |
| Containers | `skills/devops/containers` | docker, container, dockerfile, k8s, helm, hpa | Multi-stage builds, multi-arch, K8s deployments, HPA, Helm |
| Cloud | `skills/devops/cloud` | aws, s3, ec2, rds, iam, vpc, lambda, ecr, eks | AWS CLI, VPC 3-tier, Lambda, IAM least privilege, EKS checklist |
| Monitoring | `skills/devops/monitoring` | prometheus, grafana, loki, alerting, otel, tracing | PromQL, alerts, LogQL, SLOs, OpenTelemetry, runbooks |
| Automation | `skills/devops/automation` | bash, script, automate, cron, python, makefile | Bash template, retry/backoff, Python skeleton, parallel ops |
| Security | `skills/devops/security` | secrets, vault, sops, trivy, cve, hardening | Secrets manager, External Secrets, Trivy, SBOM, supply chain |
| DNS | `skills/devops/dns` | dns, route53, cloudflare, ssl, tls, cert-manager | Route53, ACM certs, Cloudflare, email auth (SPF/DKIM) |
| Disaster Recovery | `skills/devops/dr` | backup, disaster recovery, rto, rpo, restore, failover | Postgres WAL-G, S3 versioning, failover runbooks, DR drills |
| Cost / FinOps | `skills/devops/cost` | cost, finops, billing, optimize, spot, reserved | Budget alerts, Karpenter spot, unused resource cleanup |
| GitOps | `skills/devops/gitops` | gitops, argocd, flux, canary, progressive delivery, rollout | ArgoCD apps, Kustomize overlays, Argo Rollouts canary, CI handoff |
| Networking | `skills/devops/networking` | ingress, nginx ingress, cert-manager, service mesh, linkerd | Ingress config, cert-manager, NetworkPolicy, Linkerd, ExternalDNS |

## Development Skills (17)

| Skill | Path | Trigger Keywords | Description |
|-------|------|-----------------|-------------|
| Auth | `skills/dev/auth` | auth, jwt, oauth, oidc, login, mfa, 2fa, better-auth | Better Auth, JWT refresh, argon2, TOTP, OAuth2, security checklist |
| Payments | `skills/dev/payments` | stripe, payments, billing, subscription, invoice | Stripe Checkout, webhook handler, subscription sync, portal |
| Queues | `skills/dev/queues` | queue, job, worker, bullmq, celery, sqs, cron | BullMQ, retry/backoff, Celery, SQS, dead-letter queues |
| Email | `skills/dev/email` | email, resend, sendgrid, ses, deliverability, spf, dkim | Resend SDK, React Email, DNS auth, webhooks, suppression |
| SaaS | `skills/dev/saas` | saas, multi-tenant, feature flag, onboarding, plan | RLS tenancy, feature flags, plan enforcement, audit log |
| Storage | `skills/dev/storage` | storage, s3, upload, presigned url, cdn, cloudfront | Presigned upload, Sharp, CloudFront CDN, private downloads |
| Search | `skills/dev/search` | search, full-text, typesense, pgvector, semantic | Postgres FTS, Typesense, pgvector, sync patterns |
| Realtime | `skills/dev/realtime` | realtime, websocket, sse, socket.io, live, push | SSE pub/sub, WebSocket, AI streaming, Redis fanout |
| Caching | `skills/dev/caching` | cache, redis, invalidation, ttl, rate limit, session | Cache-aside, data structures, rate limiting, sessions |
| Backend | `skills/dev/backend` | backend, server, service, microservice, express, fastapi | Express/FastAPI structure, error handling, structured logging |
| API | `skills/dev/api` | api, rest, endpoint, route, openapi, pagination | REST conventions, response shapes, OpenAPI, cursor pagination |
| Database | `skills/dev/database` | database, sql, postgres, migration, schema, prisma | Postgres patterns, Prisma, Drizzle, window functions, UPSERT |
| Testing | `skills/dev/testing` | test, jest, vitest, pytest, unit, integration, e2e | TDD, AAA pattern, coverage targets, Supertest |
| GraphQL | `skills/dev/graphql` | graphql, gql, apollo, pothos, resolver, dataloader | Pothos schema, graphql-yoga, DataLoader (N+1), subscriptions |
| Webhooks | `skills/dev/webhooks` | webhook, signature verification, svix, outgoing webhook | HMAC verify, idempotency, retry/backoff, Svix managed |
| Notifications | `skills/dev/notifications` | push notification, fcm, apns, in-app, notification bell | Expo push, FCM, in-app system, web push, notification center |
| CLI | `skills/dev/cli` | cli, command line, oclif, commander, clack, terminal | clack+commander (Node), typer+rich (Python), bin setup |

## Frontend Skills (6)

| Skill | Path | Trigger Keywords | Description |
|-------|------|-----------------|-------------|
| Next.js | `skills/frontend/nextjs` | nextjs, app router, server component, rsc, server action | App Router, RSC, server actions, middleware, metadata |
| React | `skills/frontend/react` | react, component, hook, vite, tsx | TypeScript components, React Query, RHF+Zod, hooks |
| Design System | `skills/frontend/design-system` | design system, tokens, theme, tailwind, cva | CSS variables, cva, fluid typography, WCAG color |
| Performance | `skills/frontend/performance` | performance, lighthouse, bundle, lazy load, web vitals | Code splitting, image optimization, Core Web Vitals |
| Accessibility | `skills/frontend/accessibility` | a11y, accessibility, aria, wcag, keyboard | ARIA patterns, focus trap, reduced motion, skip nav |
| State | `skills/frontend/state` | state management, zustand, redux, global state, store | Zustand+immer, slice pattern, selectors, URL state |

## UI/UX Skills (3)

| Skill | Path | Trigger Keywords | Description |
|-------|------|-----------------|-------------|
| Components | `skills/ui-ux/components` | ui component, button, form, modal, layout | Layout primitives, modal portal, form fields |
| Motion | `skills/ui-ux/motion` | animation, motion, transition, framer | Framer Motion, spring physics, AnimatePresence |
| Prototyping | `skills/ui-ux/prototyping` | prototype, wireframe, mockup, figma | Lo-fi HTML wireframe, user flow checklist |

## Analytics Skills (2)

| Skill | Path | Trigger Keywords | Description |
|-------|------|-----------------|-------------|
| Product Analytics | `skills/analytics/product` | analytics, posthog, mixpanel, event tracking, funnel | PostHog, event taxonomy, server-side tracking, GDPR |
| Error Tracking | `skills/analytics/errors` | sentry, error tracking, crash, apm, error boundary | Sentry SDK, React error boundary, custom errors, alerts |

## Marketing Skills (3)

| Skill | Path | Trigger Keywords | Description |
|-------|------|-----------------|-------------|
| Copywriting | `skills/marketing/copywriting` | copy, headline, cta, landing page, tagline | Headline formulas, value prop, CTA principles |
| SEO | `skills/marketing/seo` | seo, meta, sitemap, keywords, organic | On-page checklist, schema markup, AI/AEO optimization |
| Campaigns | `skills/marketing/campaigns` | campaign, ad, funnel, conversion, churn | AIDA, platform specs, funnel metrics, churn playbook |

## AI Skills (4)

| Skill | Path | Trigger Keywords | Description |
|-------|------|-----------------|-------------|
| Prompting | `skills/ai/prompting` | prompt, system prompt, llm, few-shot | XML sections, position-aware placement, structured output |
| Agents | `skills/ai/agents` | agent, tool use, agentic, autonomous, mcp | Tool definitions, agentic loop, multi-agent, memory layers |
| Context Engineering | `skills/ai/context-engineering` | context, tokens, memory, rag, chunking, cache | Budget, U-shape attention, RAG, prompt caching, KV-cache |
| Evaluation | `skills/ai/evaluation` | llm eval, evaluation, benchmark, judge, hallucination | Promptfoo, LLM-as-judge, regression suite, CI integration |

## Workflow Skills (6) — Process Enforcement

| Skill | Path | Trigger Keywords | Description |
|-------|------|-----------------|-------------|
| Planning | `skills/workflow/planning` | plan, planning, how should i, let's build, architect, implement, create a system | Iron Law planning gate before implementation; task format with file paths; complexity thresholds |
| Debugging | `skills/workflow/debugging` | debug, not working, broken, bug, root cause, failing, weird behavior, diagnose | 4-phase process: investigate → pattern → hypothesis → implement; domain-specific CLI commands |
| Verification | `skills/workflow/verification` | verify, done, complete, finished, ship, deploy, does it work, confirm | FORBIDDEN to skip after changes; checklists by change type; completion statement format |
| Ship Feature | `skills/workflow/ship` | ship feature, ready to ship, e2e workflow, full feature, release feature | Full shipping lifecycle: plan → implement → test → CI/CD → verify; orchestrates sub-skills per phase |
| Incident Response | `skills/workflow/incident` | incident, outage, down, on-call, alert firing, production issue, pagerduty | Mitigate-first protocol: triage → rollback → root cause → fix → postmortem |
| New Service | `skills/workflow/new-service` | new service, scaffold, bootstrap service, new microservice, start from scratch, greenfield | 8-phase scaffold: backend → docker → k8s/helm → CI/CD → monitoring → gitops → verify |

## Project Context (1) — Shared Foundation

| Skill | Path | Trigger Keywords | Description |
|-------|------|-----------------|-------------|
| Project Context | `skills/project-context` | project context, product context, what are we building, brand, positioning | Generates `.agents/project-context.md`; all marketing skills read this first |

## Mobile Skills (1)

| Skill | Path | Trigger Keywords | Description |
|-------|------|-----------------|-------------|
| Expo / React Native | `skills/mobile/expo` | expo, react native, mobile, ios, android, eas | Expo Router, auth guard, secure storage, push, EAS |

---

**Total: 56 skills across 9 domains**

## Artifacts Index

Ready-to-copy production templates. Copy and replace `PLACEHOLDER_*` values.

| Artifact | Path | Use with skill |
|---|---|---|
| Terraform state backend | `artifacts/terraform/backend.tf` | `devops/infra` |
| Terraform module skeleton | `artifacts/terraform/module/` | `devops/infra` |
| GitHub Actions CI/CD | `artifacts/github-actions/ci-cd.yml` | `devops/cicd` |
| GitHub Actions PR checks | `artifacts/github-actions/pr-checks.yml` | `devops/cicd` |
| Node.js Dockerfile | `artifacts/docker/Dockerfile.node` | `devops/containers` |
| Python Dockerfile | `artifacts/docker/Dockerfile.python` | `devops/containers` |
| Dev docker-compose | `artifacts/docker/compose.dev.yml` | `devops/containers` |
| K8s Deployment + Service + HPA | `artifacts/k8s/deployment.yaml` | `devops/containers` |
| K8s Ingress (nginx + cert-manager) | `artifacts/k8s/ingress.yaml` | `devops/networking` |
| Helm chart (full) | `artifacts/helm/` | `devops/containers` + `devops/gitops` |

## Solo Product Builder — Completeness Matrix

| Capability | Skill | ✓ |
|------------|-------|---|
| Infrastructure as Code | devops/infra | ✓ |
| CI/CD pipelines | devops/cicd | ✓ |
| Containers + K8s + Helm | devops/containers | ✓ |
| Cloud (AWS) | devops/cloud | ✓ |
| GitOps (ArgoCD) | devops/gitops | ✓ |
| Networking + Ingress | devops/networking | ✓ |
| Monitoring + Tracing | devops/monitoring | ✓ |
| Secrets + Security | devops/security | ✓ |
| DNS + TLS | devops/dns | ✓ |
| Backups + DR | devops/dr | ✓ |
| Cost Optimization | devops/cost | ✓ |
| Automation scripts | devops/automation | ✓ |
| Authentication | dev/auth | ✓ |
| Payments (Stripe) | dev/payments | ✓ |
| Background Jobs | dev/queues | ✓ |
| Transactional Email | dev/email | ✓ |
| Multi-tenancy / SaaS | dev/saas | ✓ |
| File Storage + CDN | dev/storage | ✓ |
| Search (FTS + Vector) | dev/search | ✓ |
| Real-time (WS/SSE) | dev/realtime | ✓ |
| Caching (Redis) | dev/caching | ✓ |
| REST API | dev/api | ✓ |
| GraphQL API | dev/graphql | ✓ |
| Webhook handling | dev/webhooks | ✓ |
| Push Notifications | dev/notifications | ✓ |
| Database + ORM | dev/database | ✓ |
| Testing (unit/e2e) | dev/testing | ✓ |
| CLI tooling | dev/cli | ✓ |
| Next.js / SSR | frontend/nextjs | ✓ |
| React SPA | frontend/react | ✓ |
| Design System | frontend/design-system | ✓ |
| State Management | frontend/state | ✓ |
| Performance | frontend/performance | ✓ |
| Accessibility | frontend/accessibility | ✓ |
| UI Components | ui-ux/components | ✓ |
| Animations | ui-ux/motion | ✓ |
| Product Analytics | analytics/product | ✓ |
| Error Tracking | analytics/errors | ✓ |
| Copywriting | marketing/copywriting | ✓ |
| SEO | marketing/seo | ✓ |
| Campaigns | marketing/campaigns | ✓ |
| LLM Agents | ai/agents | ✓ |
| Prompting | ai/prompting | ✓ |
| Context Engineering | ai/context-engineering | ✓ |
| LLM Evaluation | ai/evaluation | ✓ |
| Mobile (Expo) | mobile/expo | ✓ |
| Planning gate | workflow/planning | ✓ |
| Systematic debugging | workflow/debugging | ✓ |
| Completion verification | workflow/verification | ✓ |
| Shared project context | project-context | ✓ |
