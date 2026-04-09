---
name: project-init
description: Adds **project-level** .claude/settings.json with Bash(*) and file operation allowedTools to a project. Use this skill whenever the user runs /init, initializes a project, sets up Claude Code for a repo, or mentions adding project-level Claude settings. Also trigger when the user asks about allowing Bash commands, file search, file read/write, or configuring project permissions.
---

# Project Init Settings

When initializing a project or when this skill is triggered, ensure the project has a **project-level** `.claude/settings.json` file that allows all Bash commands and file operations without per-action approval.

## Important: Project Settings vs Global Settings

Claude Code has two separate settings files — this skill targets the **project-level** one:

| Setting | Path | Scope |
|---------|------|-------|
| **Project** (this skill) | `<project-root>/.claude/settings.json` | Committed to git, shared with team |
| Global (NOT this skill) | `~/.claude/settings.json` | User-level, private, not shared |

Always write to `<project-root>/.claude/settings.json`. Never modify `~/.claude/settings.json`.

## What to do

1. Check if `.claude/settings.json` exists **in the project root** (not `~/.claude/`).

2. **If it doesn't exist**, create `<project-root>/.claude/settings.json`:

```json
{
  "allowedTools": [
    "Bash(*)",
    "Read(*)",
    "Edit(*)",
    "Write(*)"
  ]
}
```

3. **If it already exists**, read it and merge the above tools into the existing `allowedTools` array (don't duplicate any that are already present, don't overwrite other settings).

4. Confirm to the user what was done, and mention this is the project-level settings file.

## Allowed Tools Reference

| Tool | Purpose |
|------|---------|
| `Bash(*)` | All shell commands without per-command approval |
| `Read(*)` | Read any file without prompting |
| `Edit(*)` | Edit any file without prompting |
| `Write(*)` | Create/overwrite any file without prompting |

Note: `Glob` and `Grep` (file search tools) are read-only and allowed by default — they don't need explicit entries.

## Notes

- The `<project-root>/.claude/` directory may not exist yet — create it if needed.
- This is a **project-level** setting (committed to git, shared with the team), not the global user setting at `~/.claude/settings.json`.
