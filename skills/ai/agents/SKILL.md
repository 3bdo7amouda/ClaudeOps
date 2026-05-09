# skill: ai/agents
# triggers: agent, tool use, agentic, autonomous, function calling, mcp, workflow

## Tool Definition Pattern (Anthropic)
```python
tools = [
    {
        "name": "search_web",
        "description": "Search the web for current information. Use when you need facts after your knowledge cutoff. Returns top 5 results with title, URL, and snippet.",
        "input_schema": {
            "type": "object",
            "properties": {
                "query": { "type": "string", "description": "Search query, 2-6 words" }
            },
            "required": ["query"]
        }
    }
]
```

## Agentic Loop
```python
def run_agent(task: str, tools: list, max_turns: int = 10) -> str:
    messages = [{"role": "user", "content": task}]

    for _ in range(max_turns):
        response = client.messages.create(
            model="claude-sonnet-4-6",
            tools=tools,
            messages=messages,
        )

        if response.stop_reason == "end_turn":
            return response.content[0].text

        tool_results = []
        for block in response.content:
            if block.type == "tool_use":
                result = execute_tool(block.name, block.input)
                tool_results.append({
                    "type": "tool_result",
                    "tool_use_id": block.id,
                    "content": str(result)
                })

        messages += [
            {"role": "assistant", "content": response.content},
            {"role": "user", "content": tool_results}
        ]

    return "Max turns reached"
```

## From: agent-skills-for-context-engineering (tool-design)
Tool consolidation principle:
```
If a human engineer cannot say definitively which tool to use in a situation,
an agent cannot be expected to do better.

→ Consolidate overlapping tools — 2 general-purpose > 10 specialized
→ Vercel case study: reduced 17 tools → 2, achieved BETTER performance
→ Keep tool count 10-20 max before namespacing (db_*, web_*)
→ Tool description answers: WHAT it does, WHEN to use it, WHAT it returns

Tool naming: snake_case verb-noun (search_web, create_file, get_customer)
Never: search, create, get (too vague)

MCP naming: always fully qualified — ServerName:tool_name
```

## From: agent-skills-for-context-engineering (memory-systems)
Memory layer selection:
```python
# Working (context only) — always
scratchpad = "Current state: processing step 3 of 5"

# Short-term (session) — intermediate results
session_store = {}  # dict or file

# Long-term (cross-session) — use framework
# Prototype: plain files
# Scale: Mem0 (vector + graph, multi-tenant)
# Complex reasoning: Zep/Graphiti (temporal knowledge graph)
# Full control: Letta or Cognee

# Benchmark: Letta filesystem agents scored 74% on LoCoMo
# using BASIC file operations — beats Mem0 at 68.5%
# Tool sophistication < retrieval reliability
```

## Rules
- Write tool descriptions as if explaining to a smart intern
- Tool names: snake_case, verb_noun pattern
- Always handle `max_turns` — agents can loop infinitely
- Log all tool calls for debugging
- Validate tool outputs before feeding back
- Tool schemas inflate 2-3x after JSON serialization — audit serialized count
- Multi-agent token cost: supervisor ~5x, swarm ~8x, hierarchical ~15x baseline — budget accordingly

## Gotchas

1. **Sub-agent context pollution.** Sub-agents inherit the full parent context if you pass it. Always give sub-agents a clean, minimal context — only what they need. Pass results back compressed (1-2k token summaries), never raw.

2. **Tool count explosion.** 10+ tools = poor tool selection. The Vercel case study: 17 tools → 2 tools → better performance. Consolidate before adding.

3. **`max_turns` is not optional.** An agent without a turn limit WILL loop indefinitely on ambiguous tasks. `max_turns=10` is a safe default; reduce for sub-agents.

4. **Spec review before quality review — never reversed.** Beautiful code that doesn't meet the spec is failing code. Enforce order: spec compliance first, code quality second.

5. **The forward_message pattern prevents telephone game degradation.** Without it, by the 3rd agent in a chain, the original task intent is garbled. Always include the original task in every handoff.

## Related Skills
- **ai/context-engineering**: How to budget tokens across multi-agent turns; prompt caching for orchestrators
- **ai/evaluation**: How to eval agent pipelines end-to-end; LLM-as-judge for sub-agent outputs
- **ai/prompting**: Tool description writing; system prompt structure for sub-agents

## Multi-Agent Architecture — Pattern Selection
```
Supervisor (orchestrator + workers):
  ✓ Sequential dependencies between tasks
  ✓ One agent needs outputs of another
  ✗ Bottleneck: supervisor context fills fast
  Token cost: ~5x baseline

Swarm (peer agents, shared state):
  ✓ Independent parallel tasks
  ✓ No cross-task dependencies
  ✗ Coordination overhead; hard to debug
  Token cost: ~8x baseline

Hierarchical (supervisor → sub-supervisors → workers):
  ✓ Very large, complex tasks (>50 subtasks)
  ✗ Highest complexity; 15x+ token cost
  Token cost: ~15x baseline

Default: Supervisor pattern unless tasks are provably independent → Swarm.
```

## Orchestrator + Sub-Agents (Supervisor Pattern)
```python
def orchestrator(task: str) -> str:
    subtasks = decompose(task)

    results = []
    for subtask in subtasks:
        result = run_agent(subtask, tools=subtask_tools, max_turns=5)
        # CRITICAL: compress sub-agent output before passing to orchestrator
        # Raw sub-agent output will fill orchestrator context window
        results.append(summarize(result, max_tokens=1500))

    return synthesize(results)
```

## The Telephone Game Problem (and fix)
```python
# WRONG — context degrades as it passes through agents
task → agent_A.run() → raw_output → agent_B.run(raw_output)
# By agent B, critical details from task are lost

# RIGHT — forward_message preserves the original task reference
def forward_message(original_task: str, intermediate_result: str) -> str:
    return f"""
## Original Task
{original_task}

## Work Completed So Far
{intermediate_result}

## Your Role
Continue from where the previous agent left off.
"""
```

## Two-Stage Review (spec compliance → code quality)
```python
# Always in this order — never reversed
def reviewed_implementation(spec: str, code: str) -> str:
    # Stage 1: Does it meet the spec? (not: is it beautiful code?)
    spec_review = run_agent(
        f"Review this code ONLY for spec compliance.\nSpec: {spec}\nCode: {code}",
        max_turns=3
    )
    if spec_review.has_failures:
        code = fix(code, spec_review.failures)

    # Stage 2: Code quality (given spec is met)
    quality_review = run_agent(
        f"Review this code for quality, patterns, and maintainability.\nCode: {code}",
        max_turns=3
    )
    return apply_quality_fixes(code, quality_review)
```
