---
name: python-venv
description: Ensures a Python virtual environment (venv) is created and used before running project Python code. Trigger when creating or running Python scripts in a project, running pytest, or before `pip install` / `python` / `python3` commands that operate on project dependencies. Do NOT trigger for globally-installed developer CLIs managed by pipx (e.g. poetry, ruff, black, mypy, uv, mempalace, httpie) — those already live in their own isolated venvs. Never use system Python directly for project work — always go through a project-local venv first.
---

# Python Virtual Environment Setup

System-level Python installations are shared across all projects and users. Installing packages into them causes version conflicts, breaks OS tools, and makes projects non-reproducible. A virtual environment (venv) isolates each project's dependencies so nothing leaks.

## Before Any Python Command

Before running `python`, `pip`, `pytest`, or any Python script, ensure a venv exists and is active:

### 1. Check for an existing venv

```bash
test -d .venv/bin/activate && echo "venv exists" || echo "no venv"
```

If a `.venv` directory already exists in the current project root, skip to step 3.

### 2. Create the venv (only if it doesn't exist)

```bash
python3 -m venv .venv
```

This creates a `.venv` directory in the current working directory with its own Python interpreter and pip.

### 3. Use the venv Python

Instead of calling `python` or `pip` directly, always use the venv's binaries:

```bash
.venv/bin/python script.py
.venv/bin/pip install package-name
```

Or activate first then run:

```bash
source .venv/bin/activate && python script.py
source .venv/bin/activate && pip install -r requirements.txt
```

Activation is per-shell-invocation — since each Bash tool call is a fresh shell, you need `source .venv/bin/activate &&` before every command, or use the full `.venv/bin/python` path (which is simpler).

### 4. Install dependencies

If the project has a `requirements.txt`, install into the venv:

```bash
.venv/bin/pip install -r requirements.txt
```

If you need to install a one-off package:

```bash
.venv/bin/pip install some-package
```

## Rules

- **Never run bare `pip install`** — always `.venv/bin/pip install` or activate first.
- **Never run bare `python`** — always `.venv/bin/python` or activate first.
- **One venv per project** — create `.venv` at the project root, not in subdirectories.
- **If a venv already exists, reuse it** — don't recreate it unless it's broken.
- **Add `.venv/` to `.gitignore`** if it's not already there.

## When NOT to use this skill

This skill governs **project dependencies** — libraries a project imports, scripts run from the project, pytest, etc. It does NOT govern **globally-installed developer CLIs** — tools you use *to work on* projects, which should already live in their own per-tool venvs via `pipx` (or an equivalent per-tool installer).

Skip this skill when the command you're about to run is a global developer CLI. Common examples:

- Package / environment managers: `pipx`, `poetry`, `uv`, `pdm`, `hatch`
- Linters / formatters / type checkers: `ruff`, `black`, `isort`, `mypy`, `pyright`
- Dev tooling: `pre-commit`, `httpie`, `tox`, `mempalace`

How to tell if a CLI is already isolated — inspect the shebang of the binary on PATH:

```bash
head -1 $(which <tool>)
# If it points at a per-tool venv such as:
#   ~/.local/share/<tool>-venv/bin/python
#   ~/.local/pipx/venvs/<tool>/bin/python
# then the tool is already isolated — leave it alone, do NOT force it into a project .venv.
```

If you need to **install** a new global developer CLI, prefer `pipx install <tool>` over bare `pip install --user` — the former creates a dedicated venv, the latter pollutes `~/.local`'s user site-packages and is exactly what this skill exists to prevent. Installing *project* dependencies still goes through the project's `.venv/bin/pip`, per the Rules above.

**Edge case — a skill's own prerequisites say `pip install <tool>`**: treat that as "install this CLI, by whatever isolation-preserving mechanism is appropriate". For a project dependency → project `.venv`. For a global dev CLI → `pipx install`. Do not follow the literal `pip install` if it would pollute system or user Python.
