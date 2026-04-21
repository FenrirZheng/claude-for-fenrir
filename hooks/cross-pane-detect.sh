#!/usr/bin/env bash
# ~/.claude/hooks/cross-pane-detect.sh
#
# UserPromptSubmit hook. Detects when the incoming prompt arrived via
# `talk send` from another tmux pane (identified by the /communicate-with
# skill's signature line) and:
#
#   1. Writes the source pane id to a per-session state file
#   2. Injects a <system-reminder> into the prompt forcing Claude to
#      dispatch this turn's reply via a Bash `talk send <pane> …` call
#
# The Stop hook (~/.claude/hooks/cross-pane-enforce.sh) consumes the state
# file and blocks turn end if the tool wasn't called.
#
# Exit codes:
#   0 — always (detect-only hook; does not block prompts)

set -eu

input=$(cat)

# jq is required. If missing, fail open so we don't brick the session.
if ! command -v jq >/dev/null 2>&1; then
  echo "cross-pane-detect: jq not installed, skipping" >&2
  exit 0
fi

session_id=$(echo "$input" | jq -r '.session_id // empty')
prompt=$(echo "$input" | jq -r '.prompt // empty')

[[ -z "$session_id" || -z "$prompt" ]] && exit 0

state_file="/tmp/claude-xpane-${session_id}"

# Detect the /communicate-with signature: "Please reply via /communicate-with %N"
# (emitted verbatim by ~/.claude/commands/communicate-with.md).
# Extract the pane id. Use grep -oE in two passes to be robust.
pane=$(grep -oE 'Please reply via /communicate-with %[0-9]+' <<<"$prompt" | grep -oE '%[0-9]+' | head -n1)

if [[ -z "$pane" ]]; then
  # Not cross-pane this turn — clear any stale state so Stop hook doesn't
  # mistakenly enforce against a later normal turn.
  rm -f "$state_file" 2>/dev/null || true
  exit 0
fi

# Mark session as cross-pane for this turn
echo "$pane" > "$state_file"

# Resolve own pane id so the injected reply template carries the signature
# the OTHER side's detect hook needs to re-fire (keeps the conversation
# auto-bidirectional). Prefer $TMUX_PANE (inherited from the tmux client
# wrapping Claude Code), fall back to asking tmux directly.
own_pane="${TMUX_PANE:-}"
if [[ -z "$own_pane" ]] && command -v tmux >/dev/null 2>&1; then
  own_pane=$(tmux display-message -p "#{pane_id}" 2>/dev/null || true)
fi

if [[ -z "$own_pane" ]]; then
  sig_block="  (warning: own pane id unresolved — reply will be one-way; the"$'\n'"  other side's hook will NOT re-fire. Set TMUX_PANE or run under tmux.)"
  sig_line=""
else
  # The body goes inside outer single quotes on the talk-send command, so
  # "I'm" needs the bash close-reopen trick: I'\''m  (close, escaped ', reopen)
  sig_line="I'\\''m in pane $own_pane. Please reply via /communicate-with $own_pane."
  sig_block=""
fi

# Inject system reminder. stdout content (exit 0) is appended to prompt
# context per UserPromptSubmit spec.
cat <<MSG
<system-reminder>
CROSS-PANE REPLY MODE ACTIVE — source pane: $pane / this pane: ${own_pane:-unknown}

This prompt arrived via "talk send" from pane $pane. Your reply MUST be
dispatched via a Bash tool call running "talk send $pane …". Free-text
output in this turn does NOT reach $pane — only the Bash call does.

Required shape (Bash tool, single-quoted body per CLAUDE.md → Bash
quoting hazards — avoid double quotes and backticks). The trailing
signature line is REQUIRED so the recipient's detect hook fires and
the conversation stays auto-bidirectional:

  talk send $pane '<your full reply, multi-line OK, Markdown/code fences OK>

$sig_line'
$sig_block

If the reply body contains literal apostrophes, use the close-reopen
trick (replace each ' in the body with '\''), or fall back to a heredoc
with a single-quoted delimiter (append the same signature line inside
the body):

  talk send $pane "\$(cat <<'END'
  <body with 'apostrophes' and \$literals preserved verbatim>

  I'm in pane ${own_pane:-<this pane>}. Please reply via /communicate-with ${own_pane:-<this pane>}.
  END
  )"

The Stop hook will block turn end if no such Bash call is observed. If
the block fires, you will see a stderr message explaining how to retry.

Escape hatches (use only when appropriate):

  (a) [[no-dispatch]] marker
      If this turn should NOT be dispatched to $pane — for example, the
      real user (not the agent in $pane) interrupted to ask you something
      privately — include the literal marker [[no-dispatch]] anywhere in
      your text reply. The Stop hook will skip enforcement and allow a
      normal text-only turn.

  (b) One-shot override
      The real user can run "touch /tmp/claude-xpane-ok" to bypass
      enforcement ONCE for this session. The marker is consumed on use.
</system-reminder>
MSG

exit 0
