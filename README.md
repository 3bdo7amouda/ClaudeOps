# ClaudeOps

> A Claude Code workspace built for the solo DevOps engineer who somehow has to ship the whole damn product.

52 skills. 10 domains. They load on-demand by keyword — no wasted tokens, no manual wrangling. DevOps is the heart of it, but everything else is here too (auth, payments, frontend, AI, marketing) because *you* are the whole team.

---

## How It Works

Drop a request. The right skill loads. You never think about it.

**`claude.md`** wires everything together — your identity, your stacks, and a routing table that maps keywords to skills automatically.

**Skills** live in `skills/` and snap in when trigger words hit:

```
"set up Terraform for AWS"     → devops/infra loads
"add Stripe billing"           → dev/payments loads
"this is broken"               → workflow/debugging loads
"let's build X"                → workflow/planning loads
"I'm done"                     → workflow/verification loads
```

Each skill is a tight `.md` file under 250 lines. Code over prose. Zero fluff.

---

## What's Inside

```
ClaudeOps/
├── claude.md                    ← Root config (always loaded)
├── SKILLS_INDEX.md              ← Every skill, every trigger
├── projects/
│   └── _template/claude.md     ← Copy this for every new project
└── skills/
    ├── devops/     12 skills    ← The main event
    ├── dev/        17 skills
    ├── frontend/    6 skills
    ├── workflow/    3 skills    ← These enforce the hard rules
    ├── ai/          4 skills
    ├── ui-ux/       3 skills
    ├── marketing/   3 skills
    ├── analytics/   2 skills
    ├── project-context/         ← Shared product context
    ├── mobile/      1 skill
    └── _shared/conventions.md
```

---

## The Skills

### DevOps (12) — your home turf

| Skill | Triggers |
|-------|----------|
| `devops/infra` | terraform, IaC, provision, cloudformation |
| `devops/cicd` | pipeline, CI/CD, github actions, gitlab, deploy |
| `devops/containers` | docker, container, k8s, helm, hpa |
| `devops/cloud` | aws, s3, ec2, rds, iam, vpc, lambda, eks |
| `devops/monitoring` | prometheus, grafana, loki, alerting, otel |
| `devops/automation` | bash, script, automate, cron, makefile |
| `devops/security` | secrets, vault, trivy, cve, hardening |
| `devops/gitops` | gitops, argocd, flux, canary, progressive delivery |
| `devops/networking` | ingress, cert-manager, service mesh, linkerd |
| `devops/dns` | dns, route53, cloudflare, ssl, tls |
| `devops/dr` | backup, disaster recovery, rto, rpo, failover |
| `devops/cost` | cost, finops, spot, reserved, billing |

### Development (17)
`auth` · `payments` · `queues` · `email` · `saas` · `storage` · `search` · `realtime` · `caching` · `backend` · `api` · `database` · `testing` · `graphql` · `webhooks` · `notifications` · `cli`

### Frontend (6)
`nextjs` · `react` · `design-system` · `performance` · `accessibility` · `state`

### Workflow (3) — the ones that keep you honest

| Skill | What it enforces |
|-------|-----------------|
| `workflow/planning` | No code without a written plan. Forces exact file paths, verification step, risk assessment. |
| `workflow/debugging` | 4-phase: investigate → pattern → hypothesis → fix. No vibes-based guessing. |
| `workflow/verification` | Can't claim done without running the check. Checklists by change type. |

### AI (4)
`prompting` · `agents` · `context-engineering` · `evaluation`

### Everything else
`analytics/product` · `analytics/errors` · `marketing/copywriting` · `marketing/seo` · `marketing/campaigns` · `mobile/expo` · `ui-ux/components` · `ui-ux/motion` · `ui-ux/prototyping`

---

## Default Stacks

| Domain | Stack |
|--------|-------|
| IaC | Terraform (AWS-first) + Terragrunt, S3+DynamoDB state |
| CI/CD | GitHub Actions (OIDC), GitLab CI |
| GitOps | ArgoCD + Kustomize, Argo Rollouts |
| Containers | Docker multi-stage + K8s + Helm |
| Monitoring | Prometheus + Grafana + Loki + OpenTelemetry |
| Secrets | AWS Secrets Manager + External Secrets Operator |
| Backend | Node.js (Fastify) or Python (FastAPI) + PostgreSQL + Redis |
| Frontend | Next.js App Router + TypeScript + Tailwind |
| AI | Anthropic SDK, claude-sonnet-4-6, prompt caching |

---

## Get Going

**1. Clone it**
```bash
git clone https://github/.com/3bdo7amouda/ClaudeOps
```
Point Claude Code's workspace path at this directory.

**2. Start a project**
```bash
cp projects/_template/claude.md my-project/CLAUDE.md
# Fill in: stack, environments, active skills
```

**3. Set up product context** (marketing skills need this)

Just say: *"set up project context"* — Claude runs an interview and writes `.agents/project-context.md`. Every marketing skill picks it up automatically from there.

**4. Just work**

Keywords in your requests pull in the right skill. Peek at `SKILLS_INDEX.md` if you want to see everything.

---

## Why Skills Hit Different

These aren't tips or suggestions. They're enforced workflows with actual teeth:

- **Iron Law** — the one rule you can't rationalize around
- **FORBIDDEN** — hard constraints, in caps, no debate
- **Red Flags** — the exact thought patterns that mean you're about to mess up
- **Gotchas** — the non-obvious ways this blows up in production
- **Related Skills** — when to hand off to a different skill mid-task
