#!/usr/bin/env python3
"""Ensure a Python virtual environment exists in the given project root.

Usage: ensure_venv.py [PROJECT_ROOT]

Prints the absolute path to the venv directory on stdout.
- If a venv (.venv, venv, or env) already exists and is healthy, prints its path.
- If a venv exists but is corrupted (missing bin/python), deletes and recreates it.
- If no venv exists, creates .venv.

Exit codes:
  0 - success (venv path printed to stdout)
  1 - could not create venv (no python3/python or venv module missing)
"""

import os
import shutil
import subprocess
import sys

VENV_NAMES = [".venv", "venv", "env"]


def find_python():
    """Find a usable python interpreter."""
    for cmd in ["python3", "python"]:
        if shutil.which(cmd):
            return cmd
    return None


def find_existing_venv(project_root):
    """Look for an existing venv directory with a working python binary."""
    for name in VENV_NAMES:
        venv_dir = os.path.join(project_root, name)
        python_bin = os.path.join(venv_dir, "bin", "python")
        if os.path.isdir(venv_dir):
            if os.path.isfile(python_bin):
                return venv_dir  # healthy
            # corrupted — remove and let caller recreate
            shutil.rmtree(venv_dir)
            print(f"Removed corrupted venv: {venv_dir}", file=sys.stderr)
            return None
    return None


def create_venv(project_root, python_cmd):
    """Create a new .venv in the project root."""
    venv_dir = os.path.join(project_root, ".venv")
    result = subprocess.run(
        [python_cmd, "-m", "venv", venv_dir],
        capture_output=True, text=True
    )
    if result.returncode != 0:
        print(f"Failed to create venv: {result.stderr.strip()}", file=sys.stderr)
        return None
    return venv_dir


def main():
    project_root = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else os.getcwd())

    venv_dir = find_existing_venv(project_root)
    if venv_dir:
        print(os.path.abspath(venv_dir))
        return 0

    python_cmd = find_python()
    if not python_cmd:
        print("Error: neither python3 nor python found in PATH", file=sys.stderr)
        return 1

    venv_dir = create_venv(project_root, python_cmd)
    if not venv_dir:
        return 1

    print(os.path.abspath(venv_dir))
    return 0


if __name__ == "__main__":
    sys.exit(main())
