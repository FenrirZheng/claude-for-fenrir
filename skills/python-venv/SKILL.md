---
name: python-venv
description: Ensures a Python virtual environment (venv) is created and used before running any Python code. Use this skill whenever you are about to run python, python3, pip, pip3, or any Python script, or when installing Python packages. Also trigger when creating Python scripts that will need dependencies, running pytest, or using any Python-based CLI tool that requires pip-installed packages. Never use the system Python directly — always go through a project-local venv first.
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
