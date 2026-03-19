---
name: remember
description: "Store a memory from the current session. Triggered by /remember, 'remember this', 'save that', or session end in auto mode. Summarizes work, detects project, appends to correct memory file."
---

# Remember — Store Memory

## When This Fires
- User types `/remember`
- User says "remember this", "save that", "note that down"
- Auto mode: session is ending

## What To Do

### Step 1: Classify the memory

| Conversation contains... | Write to... |
|--------------------------|-------------|
| How the agent should behave | `~/katana-agent/agent/memory/core/soul.md` → Learned Behaviors |
| User preferences, goals, personal facts | `~/katana-agent/agent/memory/core/user.md` → appropriate section |
| Work done, code changes, decisions | `~/katana-agent/agent/memory/work.md` → new entry at top |

If session contains multiple types, write to multiple files.

### Step 2: Summarize
- Strip raw code blocks longer than 5 lines
- Strip tool call outputs and error logs
- Strip repetitive troubleshooting
- Keep: decisions, problems solved, features built, user preferences
- Condense to 1-3 sentences for work.md

### Step 3: Detect project context
1. If user specified: `/remember --project myapp` → use that
2. If inside a git repo: use repo folder name
3. If neither: ask user or tag as `general`

### Step 4: Write

**work.md** — prepend at TOP:
```
## YYYY-MM-DD — project-tag
Summary sentence(s).
```

**user.md** — find right section, append:
```
- YYYY-MM-DD: New context or preference noted here.
```

**soul.md** — append to Learned Behaviors:
```
- NEW: Description of learned behavior
```

### Step 5: Confirm (manual mode)
Before writing, show the user:
```
📝 Memory save:
→ work.md: "Summary of what happened"
   Tagged: project-name | YYYY-MM-DD

Save this? (y/n/edit)
```

### Step 6: Acknowledge
```
✓ Saved to work.md (project-name, YYYY-MM-DD)
```
