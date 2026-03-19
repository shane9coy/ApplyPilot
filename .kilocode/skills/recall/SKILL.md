---
name: recall
description: "Search and retrieve memories. Triggered by /recall, 'what did we work on', 'do you remember', 'what do you know about me', or references to past sessions and projects."
---

# Recall — Retrieve Memories

## When This Fires
- User types `/recall` with a query
- User asks: "what did we work on yesterday?"
- User asks: "what do you know about me?"
- User asks: "what's the status of project X?"
- User asks: "do you remember when we..."
- User references a past session or project

## How To Search

### Determine what user is asking for

| Question type | Search where |
|--------------|-------------|
| "What do you know about me?" | `~/katana-agent/agent/memory/core/user.md` |
| "How should you behave?" | `~/katana-agent/agent/memory/core/soul.md` |
| "What did we work on?" / project status | `~/katana-agent/agent/memory/work.md` |
| "What skills do we have?" | `~/katana-agent/agent/memory/skills/_index.md` |
| Unclear | Search all files |

### Search work.md
Entries are formatted as:
```
## YYYY-MM-DD — project-tag
Summary of work done...
```

Filter by project tag, date, or keyword.

### Search projects/
Check `~/katana-agent/agent/memory/projects/{name}/sessions.md` for project-specific history.

### Full-text search
For broad queries, use grep across all .md files:
```bash
grep -r -i "search term" ~/katana-agent/agent/memory/ --include="*.md"
```

## Response Format
Present findings concisely:
```
🔍 Found 3 entries for "redis":

1. 2026-02-19 — redis-cache
   Implemented connection pooling. Fixed deadlock in transaction handler.

2. 2026-02-15 — redis-cache
   Initial setup with Sentinel failover. Chose ioredis over node-redis.

3. 2026-02-10 — api-gateway
   Added Redis caching layer for auth tokens. 15ms → 2ms latency improvement.
```
