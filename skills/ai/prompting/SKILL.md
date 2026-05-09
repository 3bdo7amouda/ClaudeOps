# skill: ai/prompting
# triggers: prompt, system prompt, instruction, llm, claude, gpt, few-shot, chain of thought

## System Prompt Structure
```
[Identity] — who the model is and its primary purpose
[Behavior rules] — how it should respond (tone, format, limits)
[Domain knowledge] — what it knows or assumes
[Output format] — structure, length, style requirements
[Examples] — 2-3 few-shot examples for complex tasks
```

## XML Section Pattern (Claude-optimized)
```xml
<BACKGROUND>
You are a Python expert helping a development team.
Current project: Data processing pipeline in Python 3.9+
</BACKGROUND>

<INSTRUCTIONS>
- Write clean, idiomatic Python code with type hints
- Add docstrings only for non-obvious behavior
- Follow PEP 8; prefer pathlib over os.path
</INSTRUCTIONS>

<OUTPUT_FORMAT>
Code blocks with syntax highlighting.
Explain non-obvious decisions in comments, not prose.
</OUTPUT_FORMAT>
```

## Prompt Patterns

### Few-shot
```
Task: Classify customer feedback as positive/negative/neutral.
Examples:
  "Love this product!" → positive
  "Stopped working after a week" → negative
  "Arrived on time" → neutral

Now classify: "The interface is confusing but the support was helpful"
```

### Chain of Thought
```
Think step by step:
1. What is being asked?
2. What information do I have?
3. What are the constraints?
4. What is my answer and why?
```

### Structured Output
```
Respond ONLY with JSON. No preamble, no markdown fences.
Schema: { "category": string, "confidence": number, "reason": string }
```

## Claude-Specific
```python
model = "claude-sonnet-4-6"

client.messages.create(
    model=model,
    system="You are...",   # NOT in messages array
    messages=[{"role": "user", "content": "..."}],
    max_tokens=1024,
)
```

## From: agent-skills-for-context-engineering (context-fundamentals)
Position-aware placement rules:
```
Attention curve is U-shaped: beginning and end score 85-95% recall,
middle drops to 76-82%.

→ Place critical constraints at TOP and BOTTOM of system prompt
→ NEVER place safety constraints or output format in the middle
→ Place most important context first AND last (sandwich pattern)

Instruction altitude:
→ Too specific: "always use exactly 3 bullet points" → brittle
→ Too vague: "be helpful" → no signal
→ Correct: heuristic-driven with room for judgment
```

## From: banana-claude (prompt-engineering)
5-Component prompt structure for image/creative generation:
```
Component 1 — SUBJECT: specific characteristics, not "a person"
Component 2 — ACTION: strong present-tense verbs
Component 3 — LOCATION: environmental details, time of day
Component 4 — COMPOSITION: camera perspective, framing
Component 5 — STYLE: visual register + lighting combined

Write as natural paragraphs — NEVER comma-separated keyword lists.
```

## Token-Consciousness Principle
Before adding any instruction to a system prompt, challenge it:
```
"Does Claude actually need this — or does it already know it?"
"Can I assume Claude knows this from training?"
"Does this sentence justify its token cost?"
```
Default assumption: Claude is smart. Only add context it doesn't already have.

## Rules
- Specific > vague — vague prompts → vague outputs
- Give examples for complex formats
- State constraints explicitly ("under 3 sentences", "JSON only")
- Test with edge cases: empty input, adversarial input, max length
- Start minimal, add instructions reactively based on observed failures

## Gotchas

1. **System prompt length ≠ quality.** Longer system prompts have diminishing returns and higher token cost. A 200-token system prompt with the right constraints outperforms a 2000-token prompt with repetition and filler.

2. **Constraints in the middle of long prompts degrade.** U-shaped attention: 76-82% recall in the middle vs 85-95% at start/end. Put hard rules at the TOP and repeat them at the BOTTOM.

3. **Description text in skill files can override behavior.** (Superpowers finding) If the description summarizes the workflow, Claude follows the description instead of reading the full skill. Keep descriptions as triggering conditions only, never process summaries.

4. **Few-shot examples are the highest-signal instruction type.** One good example outperforms three paragraphs of prose instructions. If you're struggling to constrain output format, add an example.

5. **`max_tokens` too low silently truncates.** The model stops mid-sentence without error. Set `max_tokens` generously and monitor `stop_reason === 'max_tokens'` in production to catch truncation.

## Related Skills
- **ai/context-engineering**: Token budget management; prompt caching for stable system prompts
- **ai/agents**: Tool description writing — same principles apply (specific, behavioral, not structural)
- **ai/evaluation**: Test prompt changes with evals before shipping — regression suite for prompts
