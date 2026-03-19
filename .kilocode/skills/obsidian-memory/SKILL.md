---
name: obsidian-memory
description: "Connect to Katana's centralized memory vault. Use when remembering, recalling, or referencing past sessions, projects, user preferences, or agent identity. Triggered by: /remember, /recall, session start, or any reference to past work."
---

# Obsidian Memory Vault

## Location
All memory files live in `~/katana-agent/agent/memory/`. This is an Obsidian-compatible vault.

## Structure
```
~/katana-agent/agent/memory/
├── core/
│   ├── soul.md          — Your identity and behavior. READ ON SESSION START.
│   ├── user.md          — Facts about the user. READ ON SESSION START.
│   └── routines.md      — Learned patterns and workflows.
├── sessions/            — Past session summaries (date-prefixed .md files)
├── projects/            — Per-project context and history
├── skills/              — Reusable skills (you can create new ones here)
│   └── _index.md        — Master index of all skills
└── work.md              — Running work log (newest entries at TOP)
```

## On Session Start
1. Read `~/katana-agent/agent/memory/core/soul.md` for your identity
2. Read `~/katana-agent/agent/memory/core/user.md` for user context
3. Check if current project has a folder in `~/katana-agent/agent/memory/projects/`
4. If so, read the project's latest session entries

## Writing Memories

### Work Log (work.md)
Prepend new entries at the TOP of `~/katana-agent/agent/memory/work.md`:
```markdown
## YYYY-MM-DD — project-tag
Summary of what was accomplished. Key decisions. What's next.
```

### Project Memory
If working on a specific project, also update:
`~/katana-agent/agent/memory/projects/{project-name}/sessions.md`

### Core Memory (rare — important personal facts only)
If user reveals preferences, facts, or identity info:
- Update `~/katana-agent/agent/memory/core/user.md` in the appropriate section
- Always confirm before writing to core files

### Soul Updates (very rare)
If user requests a behavior change:
- Append to `~/katana-agent/agent/memory/core/soul.md` → Learned Behaviors section
- Always notify user when modifying soul.md

## Recalling Memories
When asked about past work:
1. Search `~/katana-agent/agent/memory/work.md` for relevant entries
2. Search `~/katana-agent/agent/memory/projects/` for project-specific context
3. Search `~/katana-agent/agent/memory/skills/_index.md` for relevant skills
4. Use grep/find for keyword matching across all .md files

## Creating Skills
When you solve a complex, reusable problem:
1. Read `~/katana-agent/agent/memory/skills/_index.md` — check if similar skill exists
2. If exists → UPDATE the existing skill with new learnings (don't duplicate)
3. If new → create folder in appropriate category: `~/katana-agent/agent/memory/skills/{category}/{skill-name}/`
4. Write SKILL.md with proper frontmatter:
```yaml
---
aliases: [skill-name]
name: skill-name
created: YYYY-MM-DD
tags: [skill, category, relevant-tags]
times_used: 0
last_used: null
---
```
5. Update `~/katana-agent/agent/memory/skills/_index.md` with new entry
6. Use [[wikilinks]] to connect to related sessions and projects

## Formatting Rules (Obsidian Compatibility)
- Always include YAML frontmatter with date, tags, project
- Use `[[wikilinks]]` for cross-references between notes
- Use `#tags` for categorization
- Keep summaries concise (2-4 sentences per work.md entry)
- Name files descriptively (not just SKILL.md for standalone notes)
