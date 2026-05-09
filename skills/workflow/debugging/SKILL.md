# skill: workflow/debugging
# triggers: debug, debugging, not working, broken, error, bug, fix, investigate, root cause, failing, weird behavior, unexpected, trace, diagnose

## Iron Law
**NEVER guess at a fix. Root cause first, always.**
Violating the letter of this rule is violating the spirit of it.

## 4-Phase Debugging Process

### Phase 1 — Root Cause Investigation
```
1. Read the EXACT error message — not a paraphrase, the actual text
2. Identify: what was expected vs. what actually happened
3. Locate the FIRST failure point, not the symptom
4. Gather evidence:
   □ Full stack trace
   □ Reproduction steps (minimal)
   □ Recent changes (git log --oneline -10)
   □ Environment delta (works in dev, fails in prod? → env diff)
```

### Phase 2 — Pattern Analysis
```
Before touching any code:
□ Has this class of bug appeared before? (git log --grep "keyword")
□ Is this a known anti-pattern for this stack?
□ Is the failure deterministic or flaky?
□ Does it fail for ALL users or only some? → scope narrows

Common patterns by domain:
  Race condition     → timing-dependent, fails intermittently
  State mutation     → works once, fails on second call
  Env mismatch       → works locally, fails in CI/prod
  Type coercion      → JavaScript/Python edge cases
  N+1 query          → works with 1 record, slow/fails with 1000
  Cache poisoning    → stale data served after update
```

### Phase 3 — Hypothesis + Evidence
```
For each hypothesis:
  1. State it precisely: "I believe X is failing because Y"
  2. Design a test that DISPROVES it, not confirms it
  3. Run the test — observe the actual result
  4. If disproved → eliminate, form new hypothesis
  5. If confirmed → proceed to Phase 4

NEVER:
  - Apply a fix before confirming root cause
  - Stack multiple hypotheses at once
  - Change two variables simultaneously
```

### Phase 4 — Implementation + Verification
```bash
# Before fix: capture baseline
git stash                         # or note current state
npm test -- --testPathPattern=affected  # run failing tests

# Apply MINIMAL fix
# After fix: verify
npm test -- --testPathPattern=affected  # tests pass
npm test                          # no regressions
git diff                          # review what changed
```

## Red Flags — STOP
- "I'll just try this and see" → No. State a hypothesis first.
- "Probably just a typo" → Verify it before moving on.
- "This worked before, so it must be..." → Evidence, not memory.
- "Let me add a try/catch around it" → That hides bugs, not fixes them.
- "It's working now, not sure why" → Find out why. Luck is not reliability.

**All of these mean: go back to Phase 1.**

## Debugging by Domain

### Network / API
```bash
curl -v https://api.example.com/endpoint  # verbose headers + body
curl -w "\n%{http_code} %{time_total}s\n" https://...

# Check DNS
dig api.example.com
nslookup api.example.com

# Check from inside K8s pod
kubectl exec -it deploy/app -- curl -v http://service:3000/health
```

### Database
```sql
-- What's actually in the table?
SELECT * FROM users WHERE id = 'suspect-id';

-- Is the query hitting the index?
EXPLAIN ANALYZE SELECT ...;

-- Active locks
SELECT * FROM pg_locks JOIN pg_stat_activity ON ...;

-- Recent slow queries
SELECT query, calls, total_time/calls as avg_ms
FROM pg_stat_statements ORDER BY avg_ms DESC LIMIT 10;
```

### Container / K8s
```bash
kubectl describe pod <pod>           # events section — read this first
kubectl logs <pod> --previous        # last crash logs
kubectl get events --sort-by='.lastTimestamp' -n <ns>
docker run --rm -it <image> sh       # enter broken image
```

### Node.js / Python async
```bash
# Node: trace unhandled rejections
node --trace-warnings --trace-uncaught server.js

# Python: asyncio debug mode
PYTHONASYNCIODEBUG=1 python app.py
```

## Gotchas

1. **Symptom vs. cause.** The error you see is almost never where the bug is. `TypeError: Cannot read property 'x' of undefined` means something upstream returned undefined — debug there, not at the crash site.

2. **Flaky tests mask real bugs.** A test that fails 1-in-10 runs is a production bug waiting to happen. Never mark flaky tests as expected — find the race condition.

3. **Works on my machine = environment bug.** Always diff: Node version, env vars, dependencies, OS. `nvm use` + `npm ci` before declaring it unreproducible.

4. **Silent failures in async code.** `Promise.all([...])` swallows individual errors. Always `.catch()` or use `Promise.allSettled()` + check each result.

5. **The fix that makes tests pass but doesn't fix the bug.** If you don't understand WHY the fix works, you haven't fixed the root cause.

## Related Skills
- **workflow/verification**: After fixing, always verify with this pattern before closing the issue
- **dev/testing**: Write a regression test that would have caught this bug
- **devops/monitoring**: Add alerting/logging so this class of bug is caught earlier next time
