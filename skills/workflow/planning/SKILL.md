# skill: workflow/planning
# triggers: plan, planning, design, approach, how should i, how do i, architect, structure, strategy, before we start, let's build, implement, create a system

## Iron Law
**NO implementation without a written plan reviewed first.**
Violating the letter of this rule is violating the spirit of it.

## When This Skill Fires
Before writing any code for a non-trivial task (>1 file changed, or any new feature/refactor), produce a plan in this format first. Simple bug fixes and single-line edits are exempt.

## Plan Format

```markdown
## Objective
[One sentence: what is being built and why]

## Approach
[2-3 sentences: the chosen strategy and why alternatives were rejected]

## Tasks
- [ ] Task 1 — exact file path: `src/auth/middleware.ts`, what changes
- [ ] Task 2 — exact file path: `tests/auth.test.ts`, what to test
- [ ] Task 3 — exact file path: `infra/iam.tf`, what resource is added

## Verification
- How to test that it works: [specific command or check]
- What a successful outcome looks like: [observable state]

## Risks / Open Questions
- [Any non-obvious assumption or dependency that could fail]
```

## Plan Quality Rules
```
Every task must have:
  ✓ Exact file path (not "update the auth module")
  ✓ Specific change described (not "add auth logic")
  ✓ Testable/verifiable outcome

A plan is READY when:
  ✓ You could hand it to someone else and they'd know what to do
  ✓ Every task is independently completeable
  ✓ The verification step is observable, not just "it works"

A plan is NOT READY when:
  ✗ It says "implement X" without specifying how
  ✗ Any task is longer than 2 sentences (split it)
  ✗ No verification step
  ✗ Risks section is empty (there are always risks)
```

## Complexity Thresholds
```
SKIP planning (just do it):
  - Single file change, <20 lines
  - Fixing a clearly identified bug
  - Config value update
  - Documentation update

LIGHT plan (5 min):
  - 2-5 files changed
  - New endpoint on existing pattern
  - Adding a test suite

FULL plan (required):
  - New feature touching 5+ files
  - Database migration
  - New infrastructure resource
  - Auth/security changes
  - Breaking API changes
  - Any multi-service coordination
```

## Architecture Decision Pattern
When there are multiple valid approaches, document the tradeoff before picking one:

```markdown
## Options Considered
| Option | Pros | Cons | Decision |
|--------|------|------|----------|
| REST endpoint | Simple, cached by CDN | Extra round-trip | ✗ |
| Server Action | No extra route, type-safe | No CDN cache | ✓ |
| GraphQL | Flexible | Adds dependency | ✗ |

**Chosen:** Server Action because [specific constraint that made this the right call]
```

## Red Flags — STOP
- "I'll figure out the details as I go" → No. Plan first.
- "It's simple, I don't need a plan" → Simple tasks don't need planning. Non-trivial ones do.
- "The plan will change anyway" → Plans are not contracts. They prevent wasted direction.
- "I'll just start and we can adjust" → Starting without direction wastes context and creates debt.

**All of these mean: write the plan first.**

## Gotchas

1. **Plans without file paths are wishes.** "Update the service layer" could mean 15 different things. "Update `src/services/billing.ts` lines 45-70 to add idempotency key" is a task.

2. **Missing verification = the plan isn't done.** If you can't state how you'll know it worked, you don't understand the objective yet.

3. **Unaddressed risks become blockers.** The "risks" section isn't pessimism — it's where blockers hide. If you skip it, they appear mid-implementation.

4. **10-task plans usually have 3 real tasks and 7 implementation details.** Split the real tasks, drop the details (they're obvious).

## Related Skills
- **workflow/verification**: The verification step in your plan should align with this skill
- **workflow/debugging**: If implementation reveals a bug, switch to debugging mode — don't plan through it
- **devops/infra**: For infrastructure changes, use this skill's workflow pattern inside your plan
