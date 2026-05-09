# ClaudeOps

![skills](https://img.shields.io/badge/skills-56-0ea5e9?style=flat-square)
![domains](https://img.shields.io/badge/domains-10-6366f1?style=flat-square)
![mcp](https://img.shields.io/badge/MCP_servers-4-10b981?style=flat-square)
![model](https://img.shields.io/badge/Claude-Sonnet_4.6-000?style=flat-square)

> A Claude Code workspace for the solo DevOps engineer shipping the whole stack.

56 skills across 10 domains. MCP servers that read your live environment. Hooks that enforce quality on every file write. Production artifacts you copy once and fill in. Keywords in your requests route to the right skill — automatically, no wrangling, no wasted tokens.

---

```mermaid
flowchart LR
    req(["your request"]) --> router["claude.md\nkeyword router"]

    router -->|"keyword match"| skills["56 skills / 10 domains\non-demand load"]
    router -->|"always-on"| hooks["Hooks\npre-bash · post-edit"]

    skills -->|"reads live data"| mcp["MCP Servers\nGitHub · Postgres · Fetch · Filesystem"]
    skills -->|"copy → fill → ship"| artifacts["Artifacts\nTerraform · Helm · Docker · GHA"]

    mcp & artifacts & hooks --> out(["working\ninfrastructure"])
```

---

## How It Works

Drop a request. The right skill loads. You never think about it.

**`claude.md`** is the always-loaded root — your identity, your stacks, and a routing table that maps keywords to skills. **MCP servers** give Claude live access to your GitHub repos, real databases, and external docs. **Hooks** run automatically on every Bash call and file write to catch problems before they land.

```
"set up Terraform for the new service"    → devops/infra + artifacts/terraform/
"add Stripe billing"                       → dev/payments
"this is broken"                           → workflow/debugging
"ship the feature"                         → workflow/ship  (chains 5 sub-skills)
"new service, scaffold everything"         → workflow/new-service  (8-phase checklist)
"incident, service is down"                → workflow/incident  (mitigate-first protocol)
```

Each skill is a tight `.md` file — under 250 lines, code over prose, zero fluff.

---

## What's Inside

```
ClaudeOps/
├── claude.md                     ← Root config + keyword router (always loaded)
├── SKILLS_INDEX.md               ← Every skill, every trigger
├── .mcp.json                     ← MCP server config (GitHub · Postgres · Fetch · FS)
├── .claude/
│   ├── settings.json             ← Hooks + pre-approved permissions
│   └── hooks/
│       ├── pre-bash.sh           ← Blocks dangerous commands before they run
│       └── post-edit.sh          ← terraform fmt · py_compile · yaml lint on every write
├── artifacts/                    ← Production templates — copy, replace PLACEHOLDER_, ship
│   ├── terraform/                ← S3+DynamoDB backend, module skeleton
│   ├── github-actions/           ← Full CI/CD (OIDC + Trivy + staging gate), PR checks
│   ├── docker/                   ← Node.js + Python multi-stage, dev compose
│   ├── k8s/                      ← Deployment + HPA + Ingress (nginx + cert-manager)
│   └── helm/                     ← Full chart with helpers, HPA, ingress toggle
├── projects/
│   └── _template/claude.md       ← Copy for every new project
└── skills/
    ├── devops/      12 skills     ← The main event
    ├── dev/         17 skills
    ├── frontend/     6 skills
    ├── workflow/     6 skills     ← +3 new: ship · incident · new-service
    ├── ai/           4 skills
    ├── ui-ux/        3 skills
    ├── marketing/    3 skills
    ├── analytics/    2 skills
    ├── mobile/       1 skill
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

### Workflow (6) — the ones that keep you honest

| Skill | What it enforces |
|-------|-----------------|
| `workflow/planning` | No code without a written plan. Exact file paths, verification step, risk assessment. |
| `workflow/debugging` | 4-phase: investigate → pattern → hypothesis → fix. No vibes-based guessing. |
| `workflow/verification` | Can't claim done without running the check. Checklists by change type. |
| `workflow/ship` | Full shipping lifecycle. Chains 5 sub-skills in order. Has abort conditions. |
| `workflow/incident` | Mitigate-first. Triage → rollback → root cause → fix → postmortem template. |
| `workflow/new-service` | 8-phase scaffold from zero. Nothing skipped, nothing assumed. |

### AI (4)
`prompting` · `agents` · `context-engineering` · `evaluation`

### Everything else
`analytics/product` · `analytics/errors` · `marketing/copywriting` · `marketing/seo` · `marketing/campaigns` · `mobile/expo` · `ui-ux/components` · `ui-ux/motion` · `ui-ux/prototyping`

---

## Live Data — MCP Servers

Skills read your actual environment instead of generating from assumptions.

| Server | What it unlocks | Env var required |
|--------|----------------|-----------------|
| **GitHub** | Read repos, PRs, issues, files live | `GITHUB_PERSONAL_ACCESS_TOKEN` |
| **Postgres** | Query real databases mid-task | `DATABASE_URL` |
| **Fetch** | Pull docs, OpenAPI specs, external APIs | `uvx` installed |
| **Filesystem** | Cross-project file access | — |

Config lives in `.mcp.json`. Add the env vars — MCPs activate automatically.

---

## Automatic Enforcement — Hooks

Two hooks run on every action without being asked.

| Hook | Trigger | What it does |
|------|---------|-------------|
| `pre-bash.sh` | Before every Bash call | Blocks `rm -rf /`, `DROP DATABASE`, `DELETE FROM` without WHERE, `terraform destroy -auto-approve`, and other catastrophic patterns. Exit 1 = command never runs. |
| `post-edit.sh` | After every Write/Edit | Runs `terraform fmt` on `.tf` files, `py_compile` on `.py`, YAML/JSON parse checks. Feedback goes back to Claude immediately. |

`settings.json` also pre-approves 25+ common read-only commands (`git diff`, `kubectl get`, `helm lint`, `aws ec2 describe-*`) so you're not prompted for things that can't cause damage.

---

## Artifacts

Production-ready templates in `artifacts/`. Copy the file, replace `PLACEHOLDER_*` values, ship.

| Artifact | File | Use with |
|----------|------|----------|
| Terraform state backend | `artifacts/terraform/backend.tf` | `devops/infra` |
| Terraform module skeleton | `artifacts/terraform/module/` | `devops/infra` |
| GitHub Actions CI/CD | `artifacts/github-actions/ci-cd.yml` | `devops/cicd` |
| GitHub Actions PR checks | `artifacts/github-actions/pr-checks.yml` | `devops/cicd` |
| Node.js Dockerfile | `artifacts/docker/Dockerfile.node` | `devops/containers` |
| Python Dockerfile | `artifacts/docker/Dockerfile.python` | `devops/containers` |
| Dev docker-compose | `artifacts/docker/compose.dev.yml` | `devops/containers` |
| K8s Deployment + HPA | `artifacts/k8s/deployment.yaml` | `devops/containers` |
| K8s Ingress | `artifacts/k8s/ingress.yaml` | `devops/networking` |
| Helm chart (full) | `artifacts/helm/` | `devops/containers` + `devops/gitops` |

The GitHub Actions CI/CD artifact includes: OIDC auth, multi-arch Docker build with layer cache, Trivy image scan (blocks on CRITICAL/HIGH), staging deploy + smoke test, manual approval gate before prod.

---

## Default Stacks

| Domain | Stack |
|--------|-------|
| IaC | Terraform (AWS-first) + Terragrunt, S3+DynamoDB state |
| CI/CD | GitHub Actions (OIDC), GitLab CI |
| GitOps | ArgoCD + Kustomize, Argo Rollouts |
| Containers | Docker multi-stage + Kubernetes + Helm |
| Monitoring | Prometheus + Grafana + Loki + OpenTelemetry |
| Secrets | AWS Secrets Manager + External Secrets Operator |
| Backend | Node.js (Fastify) or Python (FastAPI) + PostgreSQL + Redis |
| Frontend | Next.js App Router + TypeScript + Tailwind |
| AI | Anthropic SDK, claude-sonnet-4-6, prompt caching |

---

## Get Going

**1. Clone it**
```bash
git clone https://github.com/3bdo7amouda/ClaudeOps
```
Point Claude Code's workspace path at this directory.

**2. Wire up MCP** (optional but recommended)
```bash
export GITHUB_PERSONAL_ACCESS_TOKEN=ghp_...
export DATABASE_URL=postgres://user:pass@host:5432/db
# uvx must be installed for the Fetch server
```

**3. Start a project**
```bash
cp projects/_template/claude.md my-project/CLAUDE.md
# Fill in: stack, environments, active skills
```

**4. Set up product context** (marketing skills need this)

Say: *"set up project context"* — Claude runs an interview and writes `.agents/project-context.md`. Every marketing skill picks it up automatically.

**5. Just work**

Keywords in your requests pull in the right skill. Hooks run in the background. Check `SKILLS_INDEX.md` to see everything.

---

## Why Skills Hit Different

These aren't tips or suggestions. They're enforced workflows with actual teeth:

- **Iron Law** — the one rule you can't rationalize around
- **FORBIDDEN** — hard constraints, in caps, no debate
- **Red Flags** — the exact thought patterns that mean you're about to mess up
- **Gotchas** — the non-obvious ways this blows up in production
- **Related Skills** — when to hand off to a different skill mid-task
