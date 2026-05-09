# skill: project-context
# triggers: project context, product context, about this project, what is this project, what are we building, product details, company, target users, brand, positioning

## What This Skill Does
Creates and maintains `.agents/project-context.md` — a shared context document read by all other skills (especially marketing, copywriting, and AI) before asking questions. Generate it once; all subsequent skills read it first.

## Check First
```
IF .agents/project-context.md exists:
  → Read it
  → Summarize what's captured
  → Ask which sections to update
  → Only gather info for changed sections
ELSE:
  → Run the interview below to generate it
```

## Generation Interview (first time only)
Ask these questions (can batch them):
```
1. Product name and one-line description
2. What problem does it solve? Who has this problem?
3. Target audience: job title, company size, pain level
4. Pricing model: free tier, paid tiers, pricing page URL
5. Primary competitors — and how you're different from each
6. Current growth stage: pre-launch / early adopters / growth / scale
7. Key metrics you track (MRR, DAU, NPS, etc.)
8. Brand voice: 3 adjectives. What you're NOT (3 adjectives).
9. Biggest objection prospects have before buying
10. Best performing content or channel so far (if any)
```

## Output Format (`.agents/project-context.md`)
```markdown
# Project Context
_Last updated: [date]_

## Product
**Name:** [name]
**One-liner:** [one sentence]
**Problem solved:** [concrete pain point]

## Audience
**Primary:** [job title] at [company type], [company size]
**Pain:** [specific frustration they have]
**Trigger:** [what makes them start looking for a solution]

## Positioning
**Category:** [what category you compete in]
**Differentiation:** [why you win vs. alternatives]
**Competitors:**
  - [Competitor A]: [how you differ]
  - [Competitor B]: [how you differ]

## Pricing
**Model:** [freemium / trial / paid-only]
**Tiers:** [list plans and prices]
**Key conversion point:** [what triggers upgrade]

## Brand Voice
**Tone:** [adj1], [adj2], [adj3]
**NOT:** [adj1], [adj2], [adj3]
**Write like:** [reference — e.g., "Stripe docs + Linear changelog"]

## Objections
1. [Top objection] → [Counter]
2. [Second objection] → [Counter]

## Traction
**Stage:** [pre-launch / seed / growth]
**Key metrics:** [MRR: $X, users: Y, etc.]
**Best channel so far:** [channel + result]

## Notes
[Anything else skills should know]
```

## Usage by Other Skills
Any skill that needs product context should begin with:
```
Read .agents/project-context.md first (if it exists).
If it doesn't exist, trigger the project-context skill.
```

Skills that should always check this first:
- `marketing/copywriting` — brand voice, audience, positioning
- `marketing/seo` — keywords, audience pain points
- `marketing/campaigns` — traction, channels, pricing
- `ai/prompting` — product tone for system prompts
- `dev/saas` — pricing tiers, plan structure

## Update Trigger
Re-run this skill when:
- Pricing changes
- Pivoting to a new audience
- Rebranding
- Major competitor enters the market
- Series A/B (positioning shift)

## Gotchas

1. **Stale context is worse than no context.** An outdated product-context.md confidently provides wrong information to every downstream skill. Always check the `Last updated` date and prompt for a refresh if it's >3 months old.

2. **Don't skip the "NOT" voice descriptors.** These are the most useful part. "Startup-y, jargon-heavy, salesy" as NOT descriptors prevents 80% of copy rewrites.

3. **Competitors section is a living document.** The market changes. If a skill produces copy that positions against a competitor that no longer exists or has changed, it's the stale context talking.

## Related Skills
- **marketing/copywriting**: Reads brand voice and audience from this context
- **marketing/campaigns**: Reads traction, channels, pricing from this context
- **marketing/seo**: Reads audience pain points and positioning from this context
- **dev/saas**: Reads plan structure and pricing from this context
