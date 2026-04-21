# Iteration-2 scenarios

## Scenario 1 — Code review dispatch

**Worker task:** "Review `/home/fenrir/code/coinsasia/backend/backend-api-golang/internal/exchangeapi/auth/handlers.go` and list the top 3 security risks. Keep the answer short — 3 short bullets."

**Worker behaviour:** ~60 seconds. Streams noisy progress (spinners, file-read markers, chain-of-thought). Final 3-risk summary appears in the last few lines.

**Fixture:** `fixtures/scenario-1-scrollback.txt` (60 lines, 4140 bytes) — full scrollback after worker completes.
`fixtures/scenario-1-file-handoff.md` (7 lines, 648 bytes) — what the worker would write to `/tmp/review.md` if asked to hand off via file.

**Driver goal:** Get the 3 risks back into the driver's context for user to see. Nothing further.

---

## Scenario 2 — Long-running test suite

**Worker task:** "Run the full integration test suite (`go test ./...`) against the current wallet service and identify regressions. For each regression, give test name, failure mode, and suspected root cause."

**Worker behaviour:** ~5 minutes. Streams per-package pass/fail lines while running. Final report appears at the end.

**Fixture:** `fixtures/scenario-2-scrollback.txt` (116 lines, 4906 bytes) — full scrollback. Note the `<<<RESULT ... RESULT>>>` marker block at the end.
`fixtures/scenario-2-file-handoff.md` (11 lines, 759 bytes) — file-handoff form.

**Driver goal:** Get the regression report back; don't block on the wait.

---

## Scenario 3 — Shared-worktree review

**Setup:** Driver and worker share the SAME git worktree — `/home/fenrir/code/coinsasia`, branch `feature/fenrir-backend`. Both panes see the same HEAD.

**Worker task (already dispatched 2 minutes ago):** "Add cookie-fallback to the auth middleware. Write tests for both branches. Commit when done."

**Worker behaviour:** Just finished. Its last scrollback line says roughly: "committed as a1b2c3d ... want me to push or review first?"

**Fixture:** `fixtures/scenario-3-scrollback.txt` (47 lines, 1789 bytes) — worker's chatter-heavy scrollback, no inline diff.
`fixtures/scenario-3-git-show.txt` (69 lines, 2429 bytes) — what `git show a1b2c3d` would return.

**Driver goal:** See the worker's changes — the diff — and confirm tests pass. Do NOT push. Review only.
