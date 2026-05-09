# skill: ai/context-engineering
# triggers: context, window, tokens, memory, retrieval, rag, embedding, chunking

## Context Window Budget
```
Model: claude-sonnet-4-6 — 200k tokens
Effective capacity: 60-70% of nominal (120-140k before degradation)

Typical allocation:
├── System prompt:        2-5k tokens
├── Retrieved context:   10-50k tokens
├── Conversation history: 5-20k tokens
├── Current task:         1-5k tokens
└── Reserved for output:  2-8k tokens
```

## From: agent-skills-for-context-engineering (context-fundamentals)
Attention mechanics — U-shaped curve:
```
Beginning of context:  85-95% recall accuracy
Middle of context:     76-82% recall accuracy  ← DANGER ZONE
End of context:        85-95% recall accuracy

→ Place critical constraints at TOP and END (sandwich)
→ Never bury safety rules, output format, or key facts in the middle
→ Tool schemas consume 2-3x more tokens than source code — audit serialized count
→ Message history can reach 70-80% of window after 20-30 tool call turns
```

## From: agent-skills-for-context-engineering (context-compression)
Compression strategy:
```python
# Structured summary template (prevents silent information loss)
SUMMARY_TEMPLATE = """
## Session Intent
{what_user_is_trying_to_accomplish}

## Files Modified
{list_of_files_with_specific_changes}  # function names, not just file names

## Decisions Made
{key_decisions_and_rationale}

## Current State
{tests_passing_failing, blocking_issues}

## Next Steps
{ordered_list_of_remaining_work}
"""

# Trigger compaction at 70-80% utilization — NOT when window fills
# Target: 50-70% reduction with <5% quality degradation
# If >70% reduction: audit for critical info loss
```

## RAG Pattern
```python
def retrieve_context(query: str, k: int = 5) -> str:
    embedding = embed(query)
    results = vector_store.search(embedding, k=k)
    # Filter by relevance score — discard below 0.75
    filtered = [r for r in results if r.score > 0.75]
    return "\n\n".join([
        f"[Source: {r.source}]\n{r.text}"
        for r in filtered
    ])

def answer_with_context(question: str) -> str:
    context = retrieve_context(question)
    return client.messages.create(
        model="claude-sonnet-4-6",
        system=f"Answer using this context:\n\n{context}",
        messages=[{"role": "user", "content": question}]
    ).content[0].text
```

## Chunking Strategy
```python
# Semantic chunking (preferred over fixed-size)
def chunk_document(text: str, max_chunk: int = 512) -> list[str]:
    sentences = split_sentences(text)
    chunks, current = [], []
    current_len = 0
    for sentence in sentences:
        if current_len + len(sentence) > max_chunk and current:
            chunks.append(' '.join(current))
            current, current_len = [], 0
        current.append(sentence)
        current_len += len(sentence)
    if current: chunks.append(' '.join(current))
    return chunks
# Split at natural semantic boundaries (section headers, paragraph breaks)
# NOT arbitrary character limits that sever mid-concept
```

## Memory Patterns
```python
# Short-term: sliding window
messages = messages[-20:]  # keep last 20 turns

# Long-term: summarize old turns
if len(messages) > 30:
    summary = summarize(messages[:-10])
    messages = [{"role": "system", "content": f"Prior context: {summary}"}] + messages[-10:]
```

## KV-Cache Optimization
```
Prompt ordering for maximum cache hits:
1. System prompt (most stable — never changes within session)
2. Tool definitions (stable across requests)
3. Frequently reused templates and few-shot examples
4. Conversation history (grows but shares prefix)
5. Current query and dynamic content (least stable — always last)

→ Remove timestamps, session IDs from system prompt
→ Move dynamic metadata to user messages
→ Even one whitespace change invalidates cached blocks downstream
→ Target: 70%+ cache hit rate → 50%+ cost reduction
```

## Prompt Caching (Anthropic)
```python
# Add cache_control to stable content — saves 90% on cached tokens
response = client.messages.create(
    model="claude-sonnet-4-6",
    system=[
        {
            "type": "text",
            "text": STABLE_SYSTEM_PROMPT,
            "cache_control": {"type": "ephemeral"}  # cache for 5 min
        }
    ],
    messages=[
        # Large stable doc cached
        {"role": "user", "content": [
            {"type": "text", "text": LARGE_DOCUMENT, "cache_control": {"type": "ephemeral"}},
            {"type": "text", "text": user_question},
        ]},
    ],
    max_tokens=1024,
)
# Check cache performance
print(response.usage.cache_read_input_tokens)    # tokens from cache
print(response.usage.cache_creation_input_tokens) # tokens written to cache
```
```
Cache rules:
- Min 1024 tokens to be eligible for caching
- Cache TTL: 5 minutes (ephemeral)
- Tokens saved: charged at 10% of base input price
- Order: system → tools → conversation history → current message
- Target 70%+ cache hit rate = ~50% cost reduction
```

## Rules
- Put most important context at start AND end (U-shaped attention)
- Compress history aggressively — summaries over raw transcripts
- Filter retrieved chunks by relevance score (>0.75 threshold)
- Always measure actual token usage: `response.usage.input_tokens`
- Design for 60-70% effective capacity, not 100% nominal
- Cache system prompts + tools — they're reused every turn
