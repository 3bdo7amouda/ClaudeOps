# ClaudeOps

A Claude Code workspace for DevOps engineers who ship entire products alone.

52 skills across 10 domains. Skills load on-demand by keyword — no token overhead unless you need them. DevOps is the primary domain. Everything else (auth, payments, frontend, AI, marketing) exists because a solo DevOps engineer building a product needs all of it.

---

## How It Works

**`claude.md`** loads every session and defines your identity, default stacks, and skill routing table.

**Skills** live in `skills/` and load automatically when trigger keywords appear in your request. You never manually invoke them.

```
"set up Terraform for AWS"     → devops/infra loads
"add Stripe billing"           → dev/payments loads
"this is broken"               → workflow/debugging loads
"let's build X"                → workflow/planning loads
"I'm done"                     → workflow/verification loads
```

Each skill is a single focused `.md` file under 250 lines. Code over prose. No fluff.

---

## Structure

```
ClaudeOps/
├── claude.md                    ← Root config (always loaded)
├── SKILLS_INDEX.md              ← Full skill reference with all triggers
├── projects/
│   └── _template/claude.md     ← Copy this for every new project
└── skills/
    ├── devops/     12 skills    ← Primary domain
    ├── dev/        17 skills
    ├── frontend/    6 skills
    ├── workflow/    3 skills    ← Process enforcement
    ├── ai/          4 skills
    ├── ui-ux/       3 skills
    ├── marketing/   3 skills
    ├── analytics/   2 skills
    ├── project-context/         ← Shared product context
    ├── mobile/      1 skill
    └── _shared/conventions.md
```

---

## Skills

### DevOps (12)
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

### Workflow (3) — the ones that matter most
| Skill | What it enforces |
|-------|-----------------|
| `workflow/planning` | No code without a written plan. Forces exact file paths, verification step, risk assessment. |
| `workflow/debugging` | 4-phase process: investigate → pattern → hypothesis → fix. No guessing. |
| `workflow/verification` | FORBIDDEN to claim done without running the check. Checklists by change type. |

### AI (4)
`prompting` · `agents` · `context-engineering` · `evaluation`

### Supporting
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

## Quick Start

**1. Clone and point Claude at it**
```bash
git clone https://github/.com/3bdo7amouda/ClaudeOps
```
In Claude Code settings, set your workspace path to this directory.

**2. Start a new project**
```bash
cp projects/_template/claude.md my-project/CLAUDE.md
# Fill in: stack, environments, active skills
```

**3. Set up product context** (for marketing skills)

Just say: *"set up project context"* — Claude runs the interview and writes `.agents/project-context.md`. All marketing skills read it automatically from then on.

**4. Work normally**

Trigger keywords in your requests load the right skill automatically. Check `SKILLS_INDEX.md` if you want to see all triggers.

---

## What Makes Each Skill Different

Skills aren't just tips — they're enforced workflows:

- **Iron Law** — absolute rule that can't be rationalized away
- **FORBIDDEN** — hard constraints in caps (from Remotion's pattern)
- **Red Flags** — exact internal monologue patterns that signal you're about to make a mistake
- **Gotchas** — non-obvious production failure modes
- **Related Skills** — when to switch to another skill mid-task

---

## Skill Quality Constraints

- Every skill under 250 lines
- Code blocks over prose
- No duplication across skills
- Triggers are conditions only — never process summaries

---

## Sources

Patterns extracted and normalized from 7 viral Claude skill repos:

| Repo | What Was Applied |
|------|-----------------|
| `obra/superpowers` | Iron Law, Red Flags, two-stage review, workflow skills |
| `muratcankoylan/agent-skills-for-context-engineering` | Gotchas pattern, token-consciousness, multi-agent costs |
| `coreyhaines31/marketingskills` | Shared product context, Related Skills cross-references |
| `remotion-dev/skills` | FORBIDDEN keyword pattern, progressive disclosure |
| `freshtechbro/claudedesignskills` | Skill quality constraints |
| `ComposioHQ/awesome-claude-skills` | Agent integration patterns |
| `AgriciDaniel/banana-claude` | Creative Director interception layer, domain routing |
