# Benchmark: talk — token-cost behavioural eval (iteration-2)

**Metric:** incremental bytes added to the driver Claude's conversation context across the
full coordination workflow. For each command we sum:
- **input bytes** — the command string itself (lives in tool_use.input, re-sent every turn)
- **output bytes** — bytes returned as tool_result (lives in conversation, re-sent every turn)

Lower = less context bloat = fewer re-sent tokens on every subsequent turn in the driver's session.

Note: this is a *behavioural* eval, not a literal token-counting one. We run each plan's commands
against fixture files that stand in for the worker's scrollback / handoff file / `git show` output,
and count the bytes those commands would pull into the driver's context if executed.

## Summary

| Scenario | Description | old_skill | new_skill | delta | % saved |
|---|---|---:|---:|---:|---:|
| S1 | Code review dispatch | 4479 | 1178 | +3301 | **73.7%** |
| S2 | Long-running integration tests | 5137 | 1421 | +3716 | **72.3%** |
| S3 | Shared-worktree code review | 4324 | 2603 | +1721 | **39.8%** |
| **Total** | — | **13940** | **5202** | **+8738** | **62.7%** |

## Per-scenario breakdown

### S1 — Code review dispatch

**old_skill** — total **4479 B** (in 247 + out 4232)

> _Approach:_ Dispatch the review prompt to pane %42 via `talk send`, poll `talk ping` in a backgrounded until-loop so the foreground stays free, then capture the worker's final output with `talk read` once idle.

| step | cmd (truncated) | in | out | total | note |
|---|---|---:|---:|---:|---|
| 1 | `talk send %42 "Review /home/fenrir/code/coinsasia/backend/backend-api-golang/internal/e...` | 177 | 30 | 207 | send: tool_result is empty/minimal |
| 2 | `until talk ping %42 >/dev/null 2>&1; do sleep 3; done` | 53 | 120 | 173 | background poll — notification only |
| 3 | `talk read %42 200` | 17 | 4082 | 4099 | read last 200 lines |

**new_skill** — total **1178 B** (in 382 + out 796)

> _Approach:_ Dispatch via talk send asking the worker to write the final 3-risk summary to a file outside scrollback, background-poll with talk ping until idle, then Read the file exactly — avoiding pulling spinner/chain-of-thought noise into driver context.

| step | cmd (truncated) | in | out | total | note |
|---|---|---:|---:|---:|---|
| 1 | `talk send %42 "Review /home/fenrir/code/coinsasia/backend/backend-api-golang/internal/e...` | 300 | 30 | 330 | send: tool_result is empty/minimal |
| 2 | `until talk ping %42 >/dev/null 2>&1; do sleep 3; done` | 53 | 120 | 173 | background poll — notification only |
| 3 | `Read /tmp/scenario-1-risks.md` | 29 | 646 | 675 | Read → handoff fixture (646 B) |

### S2 — Long-running integration tests

**old_skill** — total **5137 B** (in 295 + out 4842)

> _Approach:_ Dispatch the task with talk send, then run a background ping-poll loop so the driver's foreground stays free; once the loop exits (worker idle), capture the tail with talk read — large enough to catch the <<<RESULT ... RESULT>>> block at the end of ~100 lines of per-package output.

| step | cmd (truncated) | in | out | total | note |
|---|---|---:|---:|---:|---|
| 1 | `talk send %42 "Run the full integration test suite (go test ./...) against the current ...` | 224 | 30 | 254 | send: tool_result is empty/minimal |
| 2 | `until talk ping %42 >/dev/null 2>&1; do sleep 15; done` | 54 | 120 | 174 | background poll — notification only |
| 3 | `talk read %42 200` | 17 | 4692 | 4709 | read last 200 lines |

**new_skill** — total **1421 B** (in 522 + out 899)

> _Approach:_ Dispatch the task with an explicit file-handoff instruction (worker writes the regression report to /tmp/scenario-2-regressions.md), then background a ping-only poll loop so the driver stays unblocked, and finally Read the small handoff file — keeping ~5 minutes of spinner/per-package scrollback out of the driver's context.

| step | cmd (truncated) | in | out | total | note |
|---|---|---:|---:|---:|---|
| 1 | `talk send %42 "Please run the full integration test suite (go test ./...) against the c...` | 433 | 30 | 463 | send: tool_result is empty/minimal |
| 2 | `until talk ping %42 >/dev/null 2>&1; do sleep 10; done` | 54 | 120 | 174 | background poll — notification only |
| 3 | `Read /tmp/scenario-2-regressions.md` | 35 | 749 | 784 | Read → handoff fixture (749 B) |

### S3 — Shared-worktree code review

**old_skill** — total **4324 B** (in 148 + out 4176)

> _Approach:_ Since the driver and worker share the same worktree and the worker already committed a1b2c3d on the current HEAD, read the diff directly with `git show` locally instead of asking the worker to paste it — scrollback doesn't contain the diff. Then glance at the tail of the worker's pane to confirm the test-pass lines, and finally tell the worker to hold off on pushing while review happens.

| step | cmd (truncated) | in | out | total | note |
|---|---|---:|---:|---:|---|
| 1 | `git show a1b2c3d` | 16 | 2429 | 2445 | git show → 2429 B |
| 2 | `talk read %42 60` | 16 | 1717 | 1733 | read last 60 lines |
| 3 | `talk send %42 "Hold off on pushing — reviewing the diff now. I'll come back with feedba...` | 116 | 30 | 146 | send: tool_result is empty/minimal |

**new_skill** — total **2603 B** (in 144 + out 2459)

> _Approach:_ Shared-worktree: skip scrollback (no diff there) and use the commit hash worker already shared as the checkpoint — run `git show a1b2c3d` locally to see the exact diff, then after review send a decision back via `talk send`.

| step | cmd (truncated) | in | out | total | note |
|---|---|---:|---:|---:|---|
| 1 | `git show a1b2c3d` | 16 | 2429 | 2445 | git show → 2429 B |
| 2 | `talk send %42 "Reviewed a1b2c3d — looks good, tests green on both branches. Hold off on...` | 128 | 30 | 158 | send: tool_result is empty/minimal |

