#!/usr/bin/env bash
# ~/.claude/hooks/worktree-guard.sh
#
# PreToolUse hook for Write / Edit / NotebookEdit / MultiEdit.
# Blocks edits where the target file is in a different git worktree than cwd.
#
# Rationale: When a Claude session runs in worktree A (branch X) but edits files
# in worktree B (branch Y), the changes land on branch Y silently. The operator
# often doesn't realize until much later. This hook catches the mismatch at
# write time and forces an explicit confirmation.
#
# Override: `touch /tmp/claude-worktree-ok` before triggering the edit. The
# marker allows ONE edit and is consumed automatically.
#
# Exit codes:
#   0 — allow (same worktree, different repos, non-repo files, override consumed)
#   2 — block (same repo, different worktrees) with stderr explanation to Claude

set -eu

input=$(cat)

# jq is required. If missing, fail open so we don't brick the session.
if ! command -v jq >/dev/null 2>&1; then
  echo "worktree-guard: jq not installed, skipping check" >&2
  exit 0
fi

tool_name=$(echo "$input" | jq -r '.tool_name // empty')
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')
cwd=$(echo "$input" | jq -r '.cwd // empty')

case "$tool_name" in
  Write|Edit|NotebookEdit|MultiEdit) ;;
  *) exit 0 ;;
esac

# Missing inputs — fail open (don't block on hook bugs)
[[ -z "$file_path" || -z "$cwd" ]] && exit 0

# Override marker: consumed on use
override_marker="/tmp/claude-worktree-ok"
if [[ -f "$override_marker" ]]; then
  rm -f "$override_marker" 2>/dev/null || true
  echo "worktree-guard: override marker consumed, allowing this edit" >&2
  exit 0
fi

# Resolve to absolute path
case "$file_path" in
  /*) abs_path="$file_path" ;;
  *)  abs_path="$cwd/$file_path" ;;
esac

# Walk up to find an existing directory (new file has non-existent dirname)
check_dir=$(dirname "$abs_path")
while [[ ! -d "$check_dir" && "$check_dir" != "/" ]]; do
  check_dir=$(dirname "$check_dir")
done

cwd_worktree=$(cd "$cwd" 2>/dev/null && git rev-parse --show-toplevel 2>/dev/null || echo "")
file_worktree=$(cd "$check_dir" 2>/dev/null && git rev-parse --show-toplevel 2>/dev/null || echo "")

# Neither in a git repo (system files, /tmp, etc) — allow
[[ -z "$cwd_worktree" && -z "$file_worktree" ]] && exit 0

# Only one side in a repo — allow (cross-boundary edit isn't the pattern we're blocking)
[[ -z "$cwd_worktree" || -z "$file_worktree" ]] && exit 0

# Same worktree — allow
[[ "$cwd_worktree" == "$file_worktree" ]] && exit 0

# Different worktree paths — check if same repo via common git dir
cwd_common=$(cd "$cwd" && git rev-parse --git-common-dir 2>/dev/null || echo "")
file_common=$(cd "$check_dir" && git rev-parse --git-common-dir 2>/dev/null || echo "")

# Normalize (git-common-dir may be relative to cwd)
cwd_common=$(cd "$cwd" && readlink -f "$cwd_common" 2>/dev/null || echo "")
file_common=$(cd "$check_dir" && readlink -f "$file_common" 2>/dev/null || echo "")

# Different repos — allow (editing obsidian from coinsasia, for example)
[[ "$cwd_common" != "$file_common" ]] && exit 0

# Same repo, different worktrees — BLOCK
cwd_branch=$(cd "$cwd" && git branch --show-current 2>/dev/null || echo "DETACHED")
file_branch=$(cd "$check_dir" && git branch --show-current 2>/dev/null || echo "DETACHED")

cat >&2 <<EOF
🚫 worktree-guard: cross-worktree edit blocked

  tool:          $tool_name
  cwd:           $cwd
  cwd worktree:  $cwd_worktree   (branch: $cwd_branch)
  target file:   $abs_path
  file worktree: $file_worktree   (branch: $file_branch)

These are different worktrees of the SAME repo. Your edit would land on branch
"$file_branch" (the worktree where the file physically lives), NOT on
"$cwd_branch" (your cwd's branch).

NEXT STEP: Report to the user, explain the mismatch, and ask how to proceed.
Do NOT retry the same tool call without explicit authorization.

If user authorizes the cross-worktree edit, they can run:
    touch /tmp/claude-worktree-ok

The marker allows ONE edit and deletes itself. Alternatively, the user can:
  - open a new session in the correct worktree, or
  - cd the bash shell into $file_worktree for this session's duration
    (note: Edit/Write use absolute paths, so cd alone doesn't fix it — the
     hook checks cwd vs file path, so cd into file_worktree then retry).
EOF

exit 2
