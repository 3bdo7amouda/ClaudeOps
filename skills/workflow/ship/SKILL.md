# skill: workflow/ship
# triggers: ship feature, ready to ship, end to end, e2e workflow, full feature, release feature

## What This Skill Does
Orchestrates the full lifecycle for shipping a feature: plan → implement → test → CI/CD → verify.
Loads sub-skills automatically at each phase. Never skips a gate.

---

## Phase 1 — Planning Gate
**Load: `workflow/planning`**

No code until plan is written and reviewed.
Must include: exact file paths, verification step, risk assessment.

Shortcut: ask yourself — "If someone else read this plan, could they implement it?"
If no → plan isn't done.

---

## Phase 2 — Implementation
**Load: relevant domain skill** (auto-detected from feature type)

| Feature type | Skill |
|---|---|
| API endpoint / business logic | `dev/backend` + `dev/api` |
| Auth change | `dev/auth` |
| DB schema change | `dev/database` |
| Frontend UI | `frontend/nextjs` or `frontend/react` |
| Background job | `dev/queues` |
| Payment flow | `dev/payments` |
| Storage / upload | `dev/storage` |

**FORBIDDEN during implementation:**
- Shipping without migrations for schema changes
- Hardcoding secrets or env vars
- Skipping error handling at system boundaries

---

## Phase 3 — Tests
**Load: `dev/testing`**

Required before CI:
```
unit tests  → cover new logic
integration → cover DB/external calls
e2e (if UI) → cover the golden path
```

Pass threshold: no regressions in existing tests. New code ≥ 80% coverage.

---

## Phase 4 — CI/CD Hook
**Load: `devops/cicd`**

Check:
- [ ] Pipeline passes locally (`make test` or equivalent)
- [ ] Docker build succeeds (if containerized)
- [ ] GitHub Actions workflow triggered and green
- [ ] Deploy to staging before prod

If DB migration: verify migration runs clean on staging data before prod deploy.

---

## Phase 5 — Verification
**Load: `workflow/verification`**

FORBIDDEN to claim done without:
```bash
# Run the actual verification command — not "should work"
curl -sf https://$STAGING_URL/health
# or
npm run e2e
# or
kubectl rollout status deployment/$APP --timeout=3m
```

Post-ship checklist:
- [ ] Feature works in staging
- [ ] No error spike in Sentry / error tracking
- [ ] No latency regression in monitoring
- [ ] Feature flag enabled for target users (if applicable)

---

## Abort Conditions
Stop and fix before continuing if:
- Tests fail on main
- Staging deploy fails
- Health check returns non-200
- Error rate increases > 1% after rollout

On abort: load `workflow/debugging` to root-cause before retrying.

## Related Skills
- `workflow/planning` — phase 1
- `workflow/debugging` — when something breaks mid-ship
- `workflow/verification` — phase 5
- `devops/gitops` — if using ArgoCD for deploy
- `devops/cicd` — pipeline config
