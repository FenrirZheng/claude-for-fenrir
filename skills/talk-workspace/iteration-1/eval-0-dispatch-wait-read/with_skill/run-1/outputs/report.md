# talk dispatch-wait-read eval report

## Commands run (chronological)

1. `talk send %99 "Analyse the file /tmp/demo/auth.py and list the top 3 security risks as bullet points."`
   - Reason: `send` is the skill's default "deliver a prompt + Enter" action. Target `%99` per safety note. Failed with `can't find pane: %99`, which the task flagged as expected for the synthetic target.

2. `until talk ping %99 >/dev/null 2>&1; do sleep 3; done; talk read %99 200` (run_in_background: true)
   - Reason: Matches the skill's canonical "dispatch and wait" recipe. `ping` maps the Claude Code title glyph to idle/busy exit codes, so polling it every 3 s is cheaper than diffing `read` output. Chained `talk read %99 200` so the buffer is captured the instant the loop exits. Running via `run_in_background: true` keeps the user's foreground session unblocked — when the background Bash completes, the captured transcript is waiting to be Read. Picked 200 lines to comfortably cover a 3-bullet reply plus any preamble without flooding context.

3. Read the background task's output file — still empty, as expected (the poll loop will spin forever against a non-existent pane).

## Final reply to the user

> Dispatched the auth.py analysis task to `%99` with `talk send`, and kicked off a background poll (`talk ping` every 3 s, then `talk read %99 200` once it reports idle) so your session stays free. The initial send errored with `can't find pane: %99` — per your safety note, `%99` is a synthetic test target, so that's expected. No real output to summarize; once a live pane id is available I'd re-run the same dispatch-wait-read pattern and relay `%99`'s bullet list verbatim.

## Notable decisions

- Chose `read` over `tail`: the skill explicitly warns `tail` is a blocking TUI that hangs the Bash tool; `read` is one-shot and safe.
- Chose `ping`-poll over repeatedly diffing `read`: `ping` is O(1) on the pane title and the skill's documented idiom.
- Backgrounded the wait loop (`run_in_background: true`) so the user is not blocked; foreground shell stays responsive.
- Did not try to work around the `%99` error — task said to treat it as expected and move on.
