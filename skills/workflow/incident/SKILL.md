# skill: workflow/incident
# triggers: incident, outage, down, on-call, alert firing, production issue, pagerduty, service unavailable, degraded, latency spike

## Iron Law
**Mitigate first. Root-cause second. Postmortem third.**
Never spend time finding the perfect fix while users are affected.

---

## Phase 1 — Triage (first 5 minutes)
**Load: `devops/monitoring`**

```bash
# Establish blast radius immediately
kubectl get pods --all-namespaces | grep -v Running
kubectl top nodes
kubectl top pods -A

# Check error rates
# Grafana: look at request rate, error rate, latency (RED metrics)
# Loki: grep for ERROR/FATAL in the last 10 min

# Is it infra or app?
kubectl describe node <node>        # node pressure?
kubectl logs -n <ns> <pod> --tail=50  # app errors?
```

Answer these before doing anything else:
- [ ] What is broken? (specific service / endpoint)
- [ ] When did it start? (correlate with recent deploys)
- [ ] How many users affected?
- [ ] Is it complete outage or degraded?

---

## Phase 2 — Immediate Mitigation
**Load: `devops/gitops`** if rollback needed

**Option A — Rollback (fastest)**
```bash
# ArgoCD rollback
argocd app history <app>
argocd app rollback <app> <revision>

# Kubectl rollback
kubectl rollout undo deployment/<name>
kubectl rollout status deployment/<name> --timeout=2m
```

**Option B — Traffic shift**
```bash
# Scale up healthy replica, scale down broken one
kubectl scale deployment/<broken> --replicas=0
kubectl scale deployment/<healthy> --replicas=3
```

**Option C — Feature flag kill switch**
If PostHog / LaunchDarkly: disable the flag for the affected feature immediately.

Do NOT attempt a fix under pressure. Rollback first if available.

---

## Phase 3 — Root Cause
**Load: `workflow/debugging`**

Only start this after blast radius is contained.
Follow the 4-phase debugging process:
1. Investigate: logs, metrics, traces around the failure time
2. Pattern: what changed? (recent deploy, config change, traffic spike, external API)
3. Hypothesis: form one specific theory
4. Fix: implement targeted, minimal fix

```bash
# Correlate with deploys
git log --oneline --since="2 hours ago"
kubectl rollout history deployment/<name>

# Check external dependencies
curl -sf https://<dependency>/health
aws rds describe-db-instances --query 'DBInstances[*].[DBInstanceStatus]'

# Look for resource exhaustion
kubectl describe pod <pod> | grep -A5 Events
```

---

## Phase 4 — Deploy Fix
**Load: `devops/cicd`** + **`workflow/verification`**

- Fix must go through CI (no manual kubectl apply in prod except for hotfixes)
- Hotfix path: branch from main → fix → fast-track CI → deploy → verify
- Verify with actual traffic, not just health endpoint

```bash
# Post-fix verification
kubectl rollout status deployment/<name> --timeout=5m
curl -sf https://$PROD_URL/health
# Watch error rate for 5min in Grafana before declaring resolved
```

---

## Phase 5 — Post-Mortem
Write within 24–48h of incident resolution.

```markdown
## Incident: <title>
**Date:** YYYY-MM-DD  **Duration:** Xh Ym  **Severity:** P1/P2/P3

### Timeline
- HH:MM — alert fired / user reported
- HH:MM — triage started
- HH:MM — mitigation applied
- HH:MM — root cause identified
- HH:MM — fix deployed
- HH:MM — resolved

### Root Cause
[One paragraph. Specific, not vague. "A nil pointer in the auth middleware when..."]

### What Went Well
- [something that helped]

### What Went Wrong
- [something that slowed response]

### Action Items
- [ ] Owner: fix — due date
- [ ] Owner: add alert — due date
- [ ] Owner: add test — due date
```

---

## Severity Levels
| Level | Definition | Response Time |
|---|---|---|
| P1 | Full outage, all users | Immediate, all hands |
| P2 | Degraded, >10% users affected | <15 min |
| P3 | Single feature broken, workaround exists | <1h |
| P4 | Minor bug, no user impact | Next sprint |

## Related Skills
- `devops/monitoring` — reading Grafana/Prometheus/Loki during triage
- `devops/gitops` — ArgoCD rollback
- `workflow/debugging` — root cause analysis
- `workflow/verification` — confirming fix worked
- `devops/cicd` — fast-track deploy
