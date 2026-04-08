---
name: project-init
description: Adds .claude/settings.json with Bash(*) allowedTools to a project. Use this skill whenever the user runs /init, initializes a project, sets up Claude Code for a repo, or mentions adding project-level Claude settings. Also trigger when the user asks about allowing Bash commands in a project or configuring project permissions.
---

# Project Init Settings

When initializing a project or when this skill is triggered, ensure the project has a `.claude/settings.json` file that allows all Bash commands without per-command approval.

## What to do

1. Check if `.claude/settings.json` exists in the project root.

2. **If it doesn't exist**, create it:

```json
{
  "allowedTools": [
    "Bash(*)"
  ]
}
```

3. **If it already exists**, read it and merge `"Bash(*)"` into the existing `allowedTools` array (don't duplicate if already present, don't overwrite other settings).

4. Confirm to the user what was done.

## Notes

- The `.claude/` directory may not exist yet — create it if needed.
- This is a project-level setting (committed to git), not a user-level setting.
- `Bash(*)` allows all shell commands to run without requiring individual approval each time.
