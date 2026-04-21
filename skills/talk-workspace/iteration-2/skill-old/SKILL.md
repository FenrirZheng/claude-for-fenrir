---
name: talk
description: Use the `talk` CLI to send messages between tmux panes — especially to coordinate with another Claude Code instance running in a sibling pane. Trigger whenever the user wants to (1) send text/prompts to another pane ("tell the other claude X", "send this to pane %42", "叫另一個 claude 做 Y"), (2) check whether another Claude is idle or busy ("is the other one done?", "ping pane X", "等另一個跑完", "看看那邊忙不忙"), (3) capture what another pane is showing ("what did the other claude just say?", "讀 pane Y 最後 N 行"), or (4) list/discover panes across tmux sessions. Also trigger when the user types a literal `talk <subcommand>` invocation (`talk list`, `talk send`, `talk ping`, `talk read`, `talk here`) as a shorthand. Do NOT trigger for general conversation ("let's talk about X", "跟我聊聊"), explaining code, or anything unrelated to tmux inter-pane messaging.
---

# talk — inter-pane messaging via tmux

`talk` is a small bash wrapper around `tmux` that lets one pane push text, capture output, or probe idle/busy state on another pane. Its main use case here: **coordinating between two Claude Code instances running in sibling tmux panes** (e.g. a "driver" Claude dispatching work to a "worker" Claude, or a human-Claude pair tag-teaming on a task).

Script lives at `/home/fenrir/code/ai-skills/talk-to-ai/talk` and should be on `PATH` as plain `talk`. If `command -v talk` comes back empty, symlink it once:

```bash
ln -s /home/fenrir/code/ai-skills/talk-to-ai/talk ~/.local/bin/talk
```

Everything below assumes `talk` is callable directly.

## Target format

Every subcommand (except `list` and `here`) takes a **target** — the pane to act on. Two forms:

- `session:window.pane` — e.g. `main:0.1`, `work:2.0`. Human-readable, stable across restarts of the shell inside the pane but not across tmux server restarts.
- `%<N>` — e.g. `%42`. The unique pane id tmux assigns. Shorter, unambiguous, survives window/pane renaming. Prefer this when you have it.

To discover targets, ask the user to run `talk here` in the other pane, or run `talk list` yourself and match on the `pane_title` / `pane_current_command` columns.

## Subcommand reference

### `talk list` — find panes
Lists every pane across every tmux session: pane id, `session:window.pane`, current command, title. Use this when the user wants to know "where is the other claude" or you need to pick a target.

### `talk here` — identify the current pane
Prints the current pane's `pane_id`, `session:window.pane`, and running command. Mostly a human-facing helper; from Claude's side it tells you **your own** id, which is useful so you don't accidentally send messages to yourself.

### `talk send <target> <message...>`
Pastes the message into the target pane and presses Enter. This is the default "say something" command. The send is atomic (via a tmux buffer), so long multi-line strings go through cleanly without the char-by-char races that `send-keys` has.

Examples:
```bash
talk send %42 "please run the integration tests and report back"
talk send main:0.1 "ack, starting on the refactor now"
```

### `talk type <target> <message...>`
Same as `send` but **does not press Enter**. Use when you want to stage a draft for the human in the other pane to review and submit themselves, or to pre-fill a prompt box without firing it.

### `talk read <target> [lines]`
Prints the last N lines of the target pane's buffer (default 80). Non-blocking — returns immediately. This is the right tool when you want to see what the other Claude said or check on progress.

```bash
talk read %42          # last 80 lines
talk read %42 200      # last 200 lines
```

### `talk ping <target>` — idle/busy probe
Reads the target pane's title and maps the Claude Code status indicator to an exit code:

| title prefix | state | exit |
|---|---|---|
| `✳ ` (U+2733) or literal `Claude Code` | idle | 0 |
| Braille spinner (U+2800–U+28FF) | busy | 1 |
| empty / other | unknown | 2 |

Use this to **wait for the other Claude to finish** without blocking on `tail`:

```bash
# Poll until idle, then act
until talk ping %42 >/dev/null 2>&1; do sleep 2; done
talk read %42 100
talk send %42 "next task: …"
```

Pair naturally with the `Monitor` tool when available — run the poll loop with `run_in_background`, monitor it, and the notification fires the moment the loop exits.

### `talk tail <target> [lines]` — follow output
Clears the screen and re-renders the last N lines every second until Ctrl-C. **Do not call `tail` from Claude** — it's a blocking human-facing TUI and will hang the Bash tool. Always prefer `read` (one-shot) or `ping` (polling).

## Common patterns

### Dispatch a task to another Claude and wait for the answer
```bash
talk send %42 "Please analyse @src/auth/ and list the top 3 risks."
until talk ping %42 >/dev/null 2>&1; do sleep 3; done
talk read %42 200
```
Kick it off in the background (`run_in_background: true`) so the current session keeps working. When the background Bash completes, the other Claude has finished and the captured `read` output is waiting.

### Peek without disturbing
```bash
talk read %42 50
```
Read-only. Safe to call any time, even mid-task on the other side.

### Stage a prompt for the human to edit
```bash
talk type %42 "draft reply: thanks for the patch, one nit about the naming — "
```
No Enter, so the human in the other pane can tweak before sending.

### Find the other Claude when you don't know its id
```bash
talk list | grep -i claude
```
The title column usually contains `Claude Code` plus the current task name, which makes it easy to pick out.

## Gotchas

- **Not inside tmux → hard fail.** `talk` exits with "not inside a tmux session" if `$TMUX` is unset. If you're being invoked from a non-tmux shell, surface the error to the user rather than trying to work around it.
- **Sending to your own pane** creates a feedback loop (you type a message, it arrives as your own input, you respond to it, etc.). Run `talk here` first if you're unsure.
- **`ping` depends on the Claude Code title format.** If the other pane is running a different Claude UI or the user has retitled the pane manually, `ping` may report `unknown` (exit 2) even though the pane is fine. Fall back to diffing `talk read` output over time.
- **Buffer paste, not keystrokes.** `send`/`type` deliver the message as a single paste, which means the receiving program sees it all at once. Most REPLs and prompt boxes handle this fine; a minority (some line-editing modes) may not — worth knowing if something looks off.
- **`read` only sees what's in tmux's scrollback.** If the other pane has scrolled past the history limit (default ~2000 lines), older content is gone. Grab what you need soon after it appears.

## Response style

When you actually run `talk` on the user's behalf, keep the reply tight: one line confirming what was sent / read / pinged, and — for reads — the captured output inline (trim aggressively if huge). The point of `talk` is to make cross-pane coordination feel lightweight; a verbose recap every turn defeats that.
