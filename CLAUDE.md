## Explanation Style

When I ask you to **explain code** or **explain how something works** (not for simple task execution), go deep:
- Walk through the code path step by step
- Explain the *why* behind design choices, not just the *what*
- Include background context (what problem it solves, what alternatives exist)
- Surface non-obvious gotchas or tradeoffs

For regular task execution (edits, fixes, commands), stay concise per Claude Code defaults.

## Language

- Technical documentation, source code, and Claude Code configuration files are written in English.
- When I write to you in Chinese, reply in Traditional Chinese (zh-TW) unless I switch.

## Dates & Timezone

- All dates/times use UTC+8, format `YYYY-MM-DD HH:MM`.

## Tool Preferences (Debian/Ubuntu)

Install once: `sudo apt install ripgrep fd-find`. On Debian the fd binary is `fdfind`, not `fd`.

IMPORTANT: The following are mandatory rules, not suggestions.

- Searching file contents: always use `rg`, never `grep`.
- Searching/listing files: always use `fdfind`, never `find`.
- Custom file type filtering: use `rg --type-add`.


## Multi-session / Multi-worktree discipline

IMPORTANT: The following are mandatory rules when collaborating across tmux panes or git worktrees.

- **Worktree anchoring (both sides)**: In any repo with multiple worktrees, when reporting file changes across panes/sessions, the **reporter** must state the working tree path + branch (e.g. `/home/fenrir/code/coinsasia-tidy-up-prd` on branch `tidy-up-prd`), and the **reviewer** must confirm the worktree path before reading or modifying files. Bare relative paths like `backend/docs/prd/...` are ambiguous and will send the reviewer to the wrong clone.
- **Session-open worktree check**: Before the first Write/Edit/NotebookEdit/MultiEdit of a session, run `pwd && git worktree list && git branch --show-current` as a single Bash call, and state the resolved worktree + branch in the first user-facing message. This is a discipline complement to the `worktree-guard` PreToolUse hook (`~/.claude/hooks/worktree-guard.sh`), which blocks cross-worktree edits with exit 2. If the hook fires, you MUST report to the user and ask for authorization — do not retry without either (a) explicit user instruction + `touch /tmp/claude-worktree-ok` override, or (b) switching to the correct worktree.
- **Ground-truth verification before review**: When receiving a "done" report with filesystem claims, run `git status` + `ls` on the claimed paths before reading content. Don't assume the work landed on disk. If claimed files don't exist or `git status` shows clean, ask the reporter to confirm their `pwd` / worktree before assuming the work failed.
- **Self-grill before A/B/C recommendations**: Before recommending between design alternatives, write at least 2 sharp counter-questions per option and answer them — answered before stating the recommendation, not retrofit to support a pre-decided answer. Shallow first-pass recommendations waste reviewer cycles.
- **Precedent verification before citing**: Before citing an existing file as precedent for a new pattern, read its full frontmatter (especially `status`, `version`, `mode` if applicable) and verify the precedent actually matches your premise. A file with `status: open` audit-trail is not a precedent for pending-change semantics. Cite-then-discover wastes a full review cycle.


## Bash quoting hazards

- In `Bash` tool calls, never use backticks inside double-quoted strings — they trigger command substitution and silently strip content from the argument. When passing multi-line text to CLIs like `talk send`, use a heredoc or single-quoted string.


## Claude Code Config

All Claude Code config and memory files in any `.claude/` directory — both global (`~/.claude/`) and project-level (`./.claude/`) — are written in English.


## 不要要求開MR
