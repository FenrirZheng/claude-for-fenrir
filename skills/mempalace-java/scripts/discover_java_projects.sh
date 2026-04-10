#!/usr/bin/env bash
# Discover Java projects (Maven/Gradle) under a parent directory.
# Finds root-level pom.xml or build.gradle files (max-depth 2 to skip submodules)
# and outputs unique project root directories.
#
# Usage: discover_java_projects.sh <parent-dir> [max-depth]
#
# Requires: fdfind (fd-find package)

set -euo pipefail

PARENT_DIR="${1:?Usage: discover_java_projects.sh <parent-dir> [max-depth]}"
MAX_DEPTH="${2:-2}"

if ! command -v fdfind &>/dev/null; then
    echo "ERROR: fdfind not found. Install with: sudo apt install fd-find" >&2
    exit 1
fi

if [ ! -d "$PARENT_DIR" ]; then
    echo "ERROR: Directory not found: $PARENT_DIR" >&2
    exit 1
fi

# Find pom.xml and build.gradle at root project level only
fdfind -t f "^(pom\.xml|build\.gradle(\.kts)?)$" "$PARENT_DIR" --max-depth "$MAX_DEPTH" \
    --exec dirname {} \; \
    | sort -u
