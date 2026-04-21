---
name: webstorm-open
description: Open files in WebStorm via the `webstorm` CLI when the user writes a terse `ws <path>` or `ws <path>:<line>` shortcut. Trigger on any message where the user's content is (or begins with) `ws ` followed by one or more file paths, optionally with `:line` suffixes — e.g. `ws src/app.vue`, `ws src/app.vue:42`, `ws components/Foo.vue:10 pages/index.vue`. Also trigger on lowercase variants and when the user pastes just `ws path` with no other context. Do NOT trigger when `ws` is part of a longer sentence (e.g. "how do ws and rg compare?") or refers to WebSocket / Windows Server / workspace — the signal is `ws` as the literal first token followed by what looks like a file path.
---

# ws — open file(s) in WebStorm

Shorthand dispatcher: when the user types `ws <path>` (optionally `:line`, optionally multiple paths), open each in WebStorm via the `webstorm` CLI.

## Syntax the user writes

```
ws <path>                   # open file
ws <path>:<line>            # open file and jump to line
ws <path1> <path2>:<line>   # multiple files in one shot
```

Paths may be relative (to the current working directory) or absolute. Line numbers are 1-based, as WebStorm expects.

## What to do

For each `<path>[:<line>]` token after `ws`:

1. Split on the **last** `:` — everything before is the path, everything after (if numeric) is the line number. If the last segment isn't a pure integer, treat the whole token as a path with no line (handles Windows-style `C:\foo` edge cases, though unlikely on Linux).
2. Resolve the path:
   - Absolute (`/…`) → use as-is.
   - Relative → leave relative; `webstorm` resolves against the CWD of the shell invocation, which is this session's working directory. That's what the user expects.
3. Verify the file exists with a quick stat. If it doesn't, tell the user and skip it rather than launching WebStorm on a ghost path — the IDE will create an empty buffer, which is almost never what `ws` was meant to do.
4. Invoke the CLI:
   ```
   webstorm [--line <N>] <path>
   ```
   Pass `--line` only when a line number was given. Do not pass `--wait` — the user wants control back immediately.
5. Run it in the background so the shell returns right away and the user isn't blocked by the IDE process. Use the Bash tool's `run_in_background: true`. Redirect stderr to stdout so any CLI complaint is captured in the task output if the user later wants to check.

When the user passes multiple paths, run a single Bash call that chains them (`webstorm … ; webstorm …`) rather than one tool call per file — it's faster and the output stays together. WebStorm's CLI is happy to be invoked repeatedly; the second call just focuses an already-open window.

## Response style

Keep the reply to the user tight — one line per file, confirming what was opened. The IDE coming to the foreground is the real feedback; the chat message is just an ack.

Example reply:
```
Opened src/app.vue:42 in WebStorm.
```

If a file was skipped because it didn't exist, say so plainly and move on:
```
Skipped missing: src/nope.vue
Opened src/app.vue:42 in WebStorm.
```

## Examples

**Input:** `ws src/components/Header.vue:88`
**Action:** `webstorm --line 88 src/components/Header.vue` (background)
**Reply:** `Opened src/components/Header.vue:88 in WebStorm.`

**Input:** `ws pages/index.vue`
**Action:** `webstorm pages/index.vue` (background)
**Reply:** `Opened pages/index.vue in WebStorm.`

**Input:** `ws store/user.js:12 middleware/auth.js:5`
**Action:** `webstorm --line 12 store/user.js ; webstorm --line 5 middleware/auth.js` (background, single Bash call)
**Reply:**
```
Opened store/user.js:12 in WebStorm.
Opened middleware/auth.js:5 in WebStorm.
```

**Input:** `ws /absolute/path/to/file.ts:100`
**Action:** `webstorm --line 100 /absolute/path/to/file.ts` (background)

## Why a skill and not just a Bash call

Two things the skill enforces that a raw Bash invocation wouldn't:

- **Parse `:line` correctly.** The token is one string from the user's perspective but two arguments to the CLI. Getting this wrong (e.g. passing `src/app.vue:42` as a filename) makes WebStorm create a file literally named `app.vue:42`.
- **Non-blocking launch.** Without `run_in_background`, the Bash tool waits on the `webstorm` process, which on a cold-start IDE can hang the conversation for many seconds. The user sent `ws` to get out of the terminal, not to sit in it.

## Related

For semantic code navigation inside an already-open WebStorm project (find usages, rename, resolve types), use the `webstorm-code-reference` skill and its `mcp__webstorm__*` tools — those operate on the running IDE. `ws` is strictly a "just open this file" shortcut.
