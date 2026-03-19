---
name: new-skill
description: "Create a new skill from scratch. Use when user asks to create, build, or scaffold a new skill. Generates properly formatted SKILL.md with frontmatter, directories, and registers in the Obsidian vault skill index."
---

# New Skill — Skill Creator

## When This Fires
- User asks to "create a skill", "make a new skill", "save this as a skill"
- Agent nudge fires after solving a complex, reusable problem

## Steps

### 1. Check existing skills first
Read `~/katana-agent/agent/memory/skills/_index.md` to see if a similar skill already exists.
If yes → update the existing skill instead of creating a duplicate.

### 2. Gather info
- **Name:** kebab-case (e.g., `jwt-auth-pattern`)
- **Category:** coding, devops, research, personal, automation, or ask user
- **Description:** Concise trigger text (max 200 chars, wrapped in quotes)

### 3. Create the skill folder

```
~/katana-agent/agent/memory/skills/{category}/{skill-name}/
├── SKILL.md              # Main skill file
├── references/           # (optional) supporting docs
└── scripts/              # (optional) executable helpers
```

### 4. Write SKILL.md

```yaml
---
aliases: [{skill-name}]
name: {skill-name}
description: "{concise description}"
created: {YYYY-MM-DD}
agent: {which-agent-created-this}
tags: [skill, {category}, {relevant-tags}]
times_used: 0
last_used: null
---

# {Skill Title}

## When to Use
{When should the agent trigger this skill}

## Steps
{Step-by-step instructions}

## Gotchas
{Common pitfalls and edge cases}

## Related
- Created during [[{session-name}]]
```

### 5. Update the index
Append to `~/katana-agent/agent/memory/skills/_index.md`:
```markdown
## {Category}
- [[{skill-name}]] — {brief description}
```

### 6. Confirm
```
✓ Created skill: {skill-name}
  Location: ~/katana-agent/agent/memory/skills/{category}/{skill-name}/
  Indexed in: ~/katana-agent/agent/memory/skills/_index.md
```

## Rules
- Put instructions, code snippets, bash commands INLINE in SKILL.md
- Only use references/ for large files that would bloat the skill
- Only use scripts/ for executable files the agent runs directly
- Keep SKILL.md under 500 lines
- Always use [[wikilinks]] to connect to related sessions/projects
- Always include the `aliases` frontmatter field for Obsidian wikilink resolution
