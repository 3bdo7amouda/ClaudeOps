# skill: workflow/new-service
# triggers: new service, scaffold, bootstrap service, new microservice, start from scratch, new project, greenfield, new repo

## What This Skill Does
Scaffolds a production-ready service from zero. Follows a fixed order so nothing gets missed.
Each phase loads the relevant sub-skill. Use `artifacts/` templates — don't write boilerplate from scratch.

---

## Checklist — tick before moving to next phase

- [ ] Phase 1: name, stack, and ports decided
- [ ] Phase 2: backend scaffolded and running locally
- [ ] Phase 3: Docker image builds and runs
- [ ] Phase 4: K8s manifests + Helm chart generated
- [ ] Phase 5: CI/CD pipeline passing
- [ ] Phase 6: Monitoring wired up
- [ ] Phase 7: GitOps deployment configured
- [ ] Phase 8: Smoke test passes in staging

---

## Phase 1 — Decision Gate (5 min)
Before touching files, answer:

```
Service name: _______          (lowercase, kebab-case)
Runtime:      Node/Python/Go
Port:         _______          (avoid 3000/8080 collisions in the cluster)
Exposed?      yes/no           (does it need an Ingress?)
DB needed?    yes/no           (PostgreSQL? separate schema or existing?)
Queue needed? yes/no
Auth?         yes/no           (own JWT or trust upstream gateway?)
```

---

## Phase 2 — Backend Scaffold
**Load: `dev/backend`**

```bash
# Node (Fastify)
mkdir -p src/{routes,services,db,middleware,lib}
touch src/index.ts src/config.ts

# Python (FastAPI)
mkdir -p app/{routers,services,db,middleware}
touch app/main.py app/config.py
```

Required from day one:
- Health endpoint: `GET /health → { status: "ok", version: "..." }`
- Structured JSON logging (pino / structlog)
- Config via env vars only — no hardcoded values
- Graceful shutdown handler

---

## Phase 3 — Docker
**Load: `devops/containers`**
**Copy: `artifacts/docker/Dockerfile.node` or `artifacts/docker/Dockerfile.python`**

```bash
docker build -t <service>:local .
docker run --rm -p <port>:<port> <service>:local
curl -sf http://localhost:<port>/health
```

FORBIDDEN: `FROM node:latest`, `RUN npm install` without lockfile, running as root.

---

## Phase 4 — Kubernetes + Helm
**Load: `devops/containers`**
**Copy: `artifacts/helm/` → `infra/helm/<service>/`**

```bash
# Replace placeholders in chart
sed -i 's/PLACEHOLDER_NAME/<service>/g' infra/helm/<service>/Chart.yaml
sed -i 's/PLACEHOLDER_NAME/<service>/g' infra/helm/<service>/values.yaml

# Validate
helm lint infra/helm/<service>/
helm template infra/helm/<service>/ | kubectl apply --dry-run=client -f -
```

Also copy `artifacts/k8s/ingress.yaml` if the service is externally exposed.

---

## Phase 5 — CI/CD
**Load: `devops/cicd`**
**Copy: `artifacts/github-actions/ci-cd.yml` → `.github/workflows/ci-cd.yml`**

Update these values in the copied workflow:
```yaml
env:
  SERVICE_NAME: <your-service>
  ECR_REGISTRY: ${{ secrets.ECR_REGISTRY }}
  EKS_CLUSTER: ${{ secrets.EKS_CLUSTER }}
```

Required secrets in GitHub:
- `ECR_REGISTRY` — your ECR account URL
- `AWS_ROLE_ARN` — OIDC role for CI
- `EKS_CLUSTER` — cluster name

---

## Phase 6 — Monitoring
**Load: `devops/monitoring`**

Minimum instrumentation before shipping:
```typescript
// Node — expose /metrics for Prometheus
import client from 'prom-client';
client.collectDefaultMetrics();
app.get('/metrics', (req, res) => {
  res.set('Content-Type', client.register.contentType);
  res.end(await client.register.metrics());
});
```

Add to Grafana:
- Request rate, error rate, latency (RED)
- Pod restarts alert
- Memory/CPU usage

---

## Phase 7 — GitOps Registration
**Load: `devops/gitops`**

```bash
# Create ArgoCD app pointing at your Helm chart
argocd app create <service> \
  --repo https://github.com/<org>/<infra-repo> \
  --path infra/helm/<service> \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace <namespace> \
  --sync-policy automated \
  --auto-prune \
  --self-heal
```

---

## Phase 8 — Verification
**Load: `workflow/verification`**

```bash
# Staging smoke test
kubectl rollout status deployment/<service> -n staging --timeout=3m
curl -sf https://<service>.staging.<domain>/health
# Watch error rate for 2 min — zero errors = ship to prod
```

FORBIDDEN to mark done without running these commands and seeing green output.

## Related Skills
- `dev/backend` — phase 2
- `devops/containers` — phases 3, 4
- `devops/cicd` — phase 5
- `devops/monitoring` — phase 6
- `devops/gitops` — phase 7
- `workflow/verification` — phase 8
- `workflow/planning` — if scope is large, plan first
