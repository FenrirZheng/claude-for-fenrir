#!/usr/bin/env python3
"""Score each plan.json for total bytes added to the driver's conversation context.

Context bytes = len(command string) [tool_use.input] + len(tool_result) [stdout captured back].
Both accumulate permanently in the sender's conversation and get re-sent on every subsequent turn,
so this is the right proxy for "incremental token cost of cross-pane coordination".
"""
import json
import re
from pathlib import Path

WORKSPACE = Path("/home/fenrir/.claude/skills/talk-workspace/iteration-2")
FIXTURES = WORKSPACE / "fixtures"


def load(name: str) -> str:
    return (FIXTURES / name).read_text()


SCROLLBACK = {
    "1": load("scenario-1-scrollback.txt"),
    "2": load("scenario-2-scrollback.txt"),
    "3": load("scenario-3-scrollback.txt"),
}
HANDOFF = {
    "1": load("scenario-1-file-handoff.md"),
    "2": load("scenario-2-file-handoff.md"),
    "3": load("scenario-3-git-show.txt"),  # shared-worktree uses git show, not a file
}


def last_n_lines(text: str, n: int) -> str:
    lines = text.splitlines(keepends=True)
    if n >= len(lines):
        return "".join(lines)
    return "".join(lines[-n:])


def awk_range_slice(text: str, start_pat: str, end_pat: str) -> str:
    lines = text.splitlines(keepends=True)
    out, collecting = [], False
    for line in lines:
        if not collecting and re.search(start_pat, line):
            collecting = True
        if collecting:
            out.append(line)
            if re.search(end_pat, line):
                collecting = False
    return "".join(out)


def score_command(cmd: str, scenario_id: str) -> tuple[int, int, str]:
    """Return (input_bytes, output_bytes, note)."""
    cmd = cmd.strip()
    input_bytes = len(cmd)

    # Read tool
    if cmd.startswith("Read "):
        parts = cmd.split()
        limit = None
        offset = 0
        for p in parts[2:]:
            if p.startswith("limit="):
                limit = int(p.split("=")[1])
            elif p.startswith("offset="):
                offset = int(p.split("=")[1])
        content = HANDOFF[scenario_id]  # proxy: /tmp/*.md stand-in
        lines = content.splitlines(keepends=True)
        sliced = lines[offset : (offset + limit) if limit else None]
        out = "".join(sliced)
        return input_bytes, len(out), f"Read → handoff fixture ({len(out)} B)"

    # git show / git diff — only meaningful for shared-worktree scenario
    if cmd.startswith("git show") or cmd.startswith("git diff"):
        return input_bytes, len(HANDOFF["3"]), f"git show → {len(HANDOFF['3'])} B"

    # talk send — the "send OK" stdout is minimal, but the command string (including the message)
    # IS the input cost the sender pays, already counted in input_bytes.
    if cmd.startswith("talk send") or cmd.startswith("talk type"):
        return input_bytes, 30, "send: tool_result is empty/minimal"

    # ping polling loop
    if "talk ping" in cmd and "until " in cmd:
        # Backgrounded poll: tool_result is a small completion notification.
        # Foreground poll would accumulate multiple title reads, but still bounded (~200 B).
        return input_bytes, 120, "background poll — notification only"

    # single ping
    if "talk ping" in cmd:
        return input_bytes, 50, "ping: title line"

    # talk read [with optional awk pipe]
    if cmd.startswith("talk read"):
        pipe = None
        if "|" in cmd:
            left, pipe = cmd.split("|", 1)
            left = left.strip()
        else:
            left = cmd
        parts = left.split()
        n = 80
        if len(parts) >= 4:
            try:
                n = int(parts[3])
            except ValueError:
                pass
        captured = last_n_lines(SCROLLBACK[scenario_id], n)
        if pipe and "awk" in pipe:
            m = re.search(r"'/([^/]+)/\s*,\s*/([^/]+)/'", pipe)
            if m:
                captured = awk_range_slice(captured, m.group(1), m.group(2))
        return input_bytes, len(captured), f"read last {n} lines" + (
            " | awk range" if pipe else ""
        )

    if cmd.startswith("talk list"):
        return input_bytes, 400, "list panes"

    return input_bytes, 100, f"unknown cmd — default 100"


def score_plan(path: Path) -> dict:
    plan = json.loads(path.read_text())
    sid = plan["scenario_id"]
    rows = []
    tot_in = tot_out = 0
    for c in plan["commands"]:
        ib, ob, note = score_command(c["cmd"], sid)
        tot_in += ib
        tot_out += ob
        rows.append(
            {
                "step": c["step"],
                "cmd": c["cmd"],
                "input_bytes": ib,
                "output_bytes": ob,
                "total": ib + ob,
                "note": note,
            }
        )
    return {
        "scenario_id": sid,
        "skill_version": plan["skill_version"],
        "approach": plan.get("approach", ""),
        "total_input_bytes": tot_in,
        "total_output_bytes": tot_out,
        "total_context_bytes": tot_in + tot_out,
        "commands": rows,
    }


SCENARIOS = [
    ("1", "scenario-1-code-review", "Code review dispatch"),
    ("2", "scenario-2-long-task", "Long-running integration tests"),
    ("3", "scenario-3-shared-worktree", "Shared-worktree code review"),
]

results = {}
for sid, dirname, _ in SCENARIOS:
    for v in ("old", "new"):
        p = WORKSPACE / dirname / f"{v}_skill" / "plan.json"
        results[f"s{sid}-{v}"] = score_plan(p)

(WORKSPACE / "benchmark.json").write_text(json.dumps(results, indent=2))

md = [
    "# Benchmark: talk — token-cost behavioural eval (iteration-2)\n\n",
    "**Metric:** incremental bytes added to the driver Claude's conversation context across the\n",
    "full coordination workflow. For each command we sum:\n",
    "- **input bytes** — the command string itself (lives in tool_use.input, re-sent every turn)\n",
    "- **output bytes** — bytes returned as tool_result (lives in conversation, re-sent every turn)\n\n",
    "Lower = less context bloat = fewer re-sent tokens on every subsequent turn in the driver's session.\n\n",
    "Note: this is a *behavioural* eval, not a literal token-counting one. We run each plan's commands\n",
    "against fixture files that stand in for the worker's scrollback / handoff file / `git show` output,\n",
    "and count the bytes those commands would pull into the driver's context if executed.\n\n",
    "## Summary\n\n",
    "| Scenario | Description | old_skill | new_skill | delta | % saved |\n",
    "|---|---|---:|---:|---:|---:|\n",
]

tot_old = tot_new = 0
for sid, _, desc in SCENARIOS:
    o = results[f"s{sid}-old"]["total_context_bytes"]
    n = results[f"s{sid}-new"]["total_context_bytes"]
    tot_old += o
    tot_new += n
    pct = (o - n) / o * 100 if o > 0 else 0
    md.append(f"| S{sid} | {desc} | {o} | {n} | {o - n:+d} | **{pct:.1f}%** |\n")

pct_tot = (tot_old - tot_new) / tot_old * 100
md.append(
    f"| **Total** | — | **{tot_old}** | **{tot_new}** | **{tot_old - tot_new:+d}** | **{pct_tot:.1f}%** |\n\n"
)

md.append("## Per-scenario breakdown\n\n")
for sid, _, desc in SCENARIOS:
    md.append(f"### S{sid} — {desc}\n\n")
    for v in ("old", "new"):
        r = results[f"s{sid}-{v}"]
        md.append(f"**{v}_skill** — total **{r['total_context_bytes']} B** (in {r['total_input_bytes']} + out {r['total_output_bytes']})\n\n")
        md.append(f"> _Approach:_ {r['approach']}\n\n")
        md.append("| step | cmd (truncated) | in | out | total | note |\n|---|---|---:|---:|---:|---|\n")
        for b in r["commands"]:
            cmd = b["cmd"].replace("|", "\\|")
            if len(cmd) > 90:
                cmd = cmd[:87] + "..."
            md.append(f"| {b['step']} | `{cmd}` | {b['input_bytes']} | {b['output_bytes']} | {b['total']} | {b['note']} |\n")
        md.append("\n")

(WORKSPACE / "benchmark.md").write_text("".join(md))
print((WORKSPACE / "benchmark.md").read_text())
