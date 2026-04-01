---
name: rg-fd-guide
description: >
  Reference guide for using ripgrep (rg) and fd-find (fdfind) effectively.
  Use this skill whenever you are about to search for files, search file contents,
  list files by pattern, or run any shell command involving grep, find, locate, or
  file discovery. Also trigger when the user asks how to search, find, or filter
  files — even if they say "grep" or "find", since those should be replaced with
  rg/fdfind. Covers flags, patterns, recipes, piping, and Debian-specific setup.
---

# rg & fd Quick Reference

## Hard Rules

1. **Never `grep`** — use `rg`.
2. **Never `find`** — use `fdfind`.
3. **The binary is `fdfind`**, not `fd` (Debian/Ubuntu installs it as `fdfind`).

## Key Patterns

```bash
# Custom file type filtering
rg --type-add 'config:*.{yaml,yml,toml,json}' -t config 'pattern'

# Exclude patterns
rg -g '!*test*' -g '!node_modules/' 'pattern'

# Recently modified files → search
fdfind --changed-within 1h -t f -e yaml -e json | xargs rg 'pattern'

# fdfind exec with placeholders: {} {/} {.} {/.} {//}
fdfind -e py --exec-batch wc -l

# Hidden/ignored files (both skip by default)
rg --hidden 'pattern'
fdfind -HI 'pattern'
```
