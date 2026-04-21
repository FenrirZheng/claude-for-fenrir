#!/usr/bin/env bash
# ~/.claude/hooks/cross-pane-enforce.sh
#
# Stop hook. Paired with cross-pane-detect.sh (UserPromptSubmit).
#
# When the detect hook marked the current session as "cross-pane" (because
# the incoming prompt carried a /communicate-with signature), this hook
# verifies that the assistant actually dispatched via a Bash `talk send
# <pane> …` call in the most recent turn. If not, it exits 2 to block turn
# end, forcing Claude to produce a corrective response.
#
# Escape hatches (checked in order):
#   1. /tmp/claude-xpane-ok marker   — consumed on use, allows THIS turn
#   2. [[no-dispatch]] text marker    — in assistant's text output
#   3. Bash `talk send <pane> …` call — in assistant's tool_use content
#
# Exit codes:
#   0 — allow turn end (no cross-pane mode, escape hatch hit, or tool called)
#   2 — block turn end with stderr explanation

set -eu

input=$(cat)

if ! command -v jq >/dev/null 2>&1; then
  echo "cross-pane-enforce: jq not installed, skipping" >&2
  exit 0
fi

session_id=$(echo "$input" | jq -r '.session_id // empty')
stop_hook_active=$(echo "$input" | jq -r '.stop_hook_active // false')

[[ -z "$session_id" ]] && exit 0

state_file="/tmp/claude-xpane-${session_id}"

# No cross-pane flag for this turn — nothing to enforce.
[[ ! -f "$state_file" ]] && exit 0

pane=$(cat "$state_file")

# Escape hatch 1: one-shot user override. Consumes marker AND state file.
override="/tmp/claude-xpane-ok"
if [[ -f "$override" ]]; then
  rm -f "$override" "$state_file" 2>/dev/null || true
  echo "cross-pane-enforce: override consumed, allowing this turn (pane $pane)" >&2
  exit 0
fi

# Loop guard: if we already blocked once and are firing again, don't
# block infinitely. Clear state and allow — the user can see the missing
# dispatch via the unchanged /tmp state file (removed here) and retry
# manually if needed.
if [[ "$stop_hook_active" == "true" ]]; then
  rm -f "$state_file" 2>/dev/null || true
  echo "cross-pane-enforce: stop_hook_active=true, yielding to avoid loop (pane $pane)" >&2
  exit 0
fi

# Extract the last assistant message from the transcript.
last_assistant=$(echo "$input" | jq '[.messages[]? | select(.role=="assistant")] | last // empty')

if [[ -z "$last_assistant" || "$last_assistant" == "null" ]]; then
  # No assistant message yet — nothing to check. Shouldn't happen on Stop,
  # but fail open.
  exit 0
fi

# Escape hatch 2: [[no-dispatch]] marker in any text content of the last
# assistant turn.
text_has_marker=$(
  echo "$last_assistant" \
    | jq -r '.content[]? | select(.type=="text") | .text' \
    | grep -cF '[[no-dispatch]]' || true
)
if [[ "${text_has_marker:-0}" -gt 0 ]]; then
  rm -f "$state_file" 2>/dev/null || true
  echo "cross-pane-enforce: [[no-dispatch]] marker found, skipping enforcement" >&2
  exit 0
fi

# Escape hatch 3 (the normal path): Bash `talk send <pane> …` was called.
# Extract the `command` string of every Bash tool_use and grep for a
# `talk send` targeting the stored pane. Permissive on surrounding quotes
# (none / single / double), strict on pane-id word boundary.
bash_cmd_hits=$(
  echo "$last_assistant" \
    | jq -r '.content[]? | select(.type=="tool_use" and .name=="Bash") | .input.command // empty' \
    | grep -cE "\\btalk[[:space:]]+send[[:space:]]+['\"]?${pane}\\b" || true
)
if [[ "${bash_cmd_hits:-0}" -gt 0 ]]; then
  rm -f "$state_file" 2>/dev/null || true
  exit 0
fi

# No escape hatch matched — block.
cat >&2 <<MSG
🚫 cross-pane-enforce: talk send $pane was not called

This turn responded to a cross-pane message from pane $pane but did NOT
dispatch via a Bash "talk send" call. Your free text reply has not
reached $pane.

NEXT STEP: run Bash with a single-quoted body (per CLAUDE.md → Bash
quoting hazards — avoid double quotes and backticks):

  talk send $pane '<your full reply, multi-line OK>'

If the reply body contains literal apostrophes, use the close-reopen
trick (replace each ' in the body with '\''), or fall back to a heredoc
with a single-quoted delimiter:

  talk send $pane "\$(cat <<'END'
  <body with 'apostrophes' and \$literals preserved verbatim>
  END
  )"

Alternatives (only if appropriate):
  - Include [[no-dispatch]] literally in your text reply to declare this
    turn is intentionally local (e.g. clarifying with the real user)
  - User can run "touch /tmp/claude-xpane-ok" to bypass once
MSG

exit 2
