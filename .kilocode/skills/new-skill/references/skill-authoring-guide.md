# Skill Authoring Reference

## Frontmatter (Required)
```yaml
---
name: my-skill-name          # kebab-case, max 64 chars
description: "Trigger text"   # MUST be in quotes, max 200 chars
---
```

## Frontmatter (Optional for Obsidian)
```yaml
---
aliases: [my-skill-name]     # For Obsidian wikilink resolution
created: 2026-02-26
tags: [skill, category]
times_used: 0
last_used: null
---
```

## Description Best Practices
- Include WHAT the skill does AND WHEN to trigger it
- Bad: "Helps with development"
- Good: "Create JWT auth middleware for Express. Use when setting up authentication."

## File Structure
```
skill-name/
├── SKILL.md          # Main file — instructions, code, examples
├── references/       # Supporting docs (API specs, long boilerplate)
├── scripts/          # Executable files (setup.sh, scaffold.py)
└── assets/           # Templates, configs, images
```

## Cross-Platform Compatibility
- Claude Code: `.claude/skills/{name}/SKILL.md`
- KiloCode: `.kilocode/skills/{name}/SKILL.md`
- Codex: `.codex/skills/{name}/SKILL.md`
- Katana Vault: `~/katana-agent/agent/memory/skills/{category}/{name}/SKILL.md`
