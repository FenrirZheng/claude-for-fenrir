---
name: mempalace-java
description: Initialize, mine, and maintain Java projects (Maven/Gradle) in MemPalace. Use whenever the user mentions mempalace with Java projects, wants to mine a Java codebase, re-mine for updates, batch-process multiple Java projects, discover Java projects under a directory, or add Spring Boot / Maven / Gradle projects to their memory palace. Triggers on "mine Java project", "mempalace java", "discover projects", "batch mine", "re-mine", "update mempalace", "mine all projects under X", or any combination of mempalace + Java/Maven/Gradle/Spring Boot. Also use when the user wants to prepare a task list to mine multiple repositories at once.
---

# MemPalace Java Project Manager

Automates MemPalace initialization, mining, and maintenance for Java projects. Handles single projects, batch processing from an interactive list, and auto-discovery of Maven/Gradle projects under a parent directory.

## Prerequisites

Before starting, verify two things:

1. **mempalace CLI**: Run `mempalace status`. If not installed, tell the user to run `/mempalace:init` first.
2. **fdfind**: Run `fdfind --version`. Needed for auto-discovery mode. If missing, suggest `sudo apt install fd-find`.

## Determine the Mode

Ask the user which mode they want, or infer from context:

| Mode | When to use |
|------|-------------|
| **Single** | User provides one project path |
| **Batch (list)** | User provides multiple project paths |
| **Auto-discover** | User provides a parent directory and wants to find all Java projects underneath |

## Step 1: Ensure MCP Server is Registered

Check if the mempalace MCP server is already registered with Claude. Look for "mempalace" in the project's `.claude.json` or the user's `~/.claude.json`:

```bash
rg -l "mempalace" ~/.claude.json .claude.json 2>/dev/null
```

If not found, register it:

```bash
claude mcp add mempalace -- python -m mempalace.mcp_server
```

If already registered, skip this step silently.

## Step 2: Collect Target Projects

### Single project

Use the path the user provided. Verify it contains `pom.xml` or `build.gradle`:

```bash
ls <project-dir>/pom.xml <project-dir>/build.gradle 2>/dev/null
```

### Batch (interactive list)

Ask the user for paths. Accept them as a list (one per line, comma-separated, or space-separated). Validate each path has `pom.xml` or `build.gradle`.

### Auto-discover

Scan the parent directory for root-level Java projects. Use `--max-depth 2` to find root project build files without picking up sub-module pom.xml files:

```bash
fdfind -t f "^(pom\.xml|build\.gradle)$" <parent-dir> --max-depth 2
```

Then extract the project directories:

```bash
fdfind -t f "^(pom\.xml|build\.gradle)$" <parent-dir> --max-depth 2 --exec dirname {} | sort -u
```

Present the discovered list to the user for confirmation. They may want to exclude some projects (e.g., archived repos, BOMs without source code). Wait for confirmation before proceeding.

## Step 3: Determine Wing Names

Wing names group related projects so they can be searched together.

**First-time init**: Use the **immediate parent directory name** as the wing, so projects under the same parent folder naturally share a wing:

```
/home/user/code/casa/project-a  →  wing: casa
/home/user/code/casa/project-b  →  wing: casa
/home/user/code/other/service-x →  wing: other
```

Derive the wing for each project:

```bash
basename "$(dirname <project-dir>)"
```

If a project sits directly in `~/code/`, fall back to the project's own directory name as the wing.

**Re-mining**: If `mempalace.yaml` already exists, read the `wing:` field from it and use that value. This maintains consistency with the previous mine — do not override an existing wing assignment unless the user explicitly asks to change it.

## Step 4: Check for Mega-Files

For each project, check if large files need splitting before mining:

```bash
mempalace split <project-dir> --dry-run
```

If mega-files are found, split them:

```bash
mempalace split <project-dir>
```

If none found, continue.

## Step 5: Init and Mine

For each project, check whether it has been initialized before by looking for `mempalace.yaml`:

**First time** (no `mempalace.yaml`):

```bash
mempalace init <project-dir> --yes
mempalace mine <project-dir> --wing <wing_name>
```

The `--yes` flag is required because Claude Code cannot interact with stdin prompts. The init command auto-detects the folder structure and creates rooms from it.

**Re-mining** (already has `mempalace.yaml`):

```bash
mempalace mine <project-dir> --wing <wing_name>
```

The mine command is incremental — it skips files already filed, so re-mining is safe and only processes new or changed files.

Use a 10-minute timeout for the mine command on large projects (800+ files).

## Step 6: Batch Execution Strategy

**1-2 projects**: Run sequentially in the current session.

**3+ projects**: Create a task list using TaskCreate so the user can track progress. Process each project as a separate task. Mark each task completed as it finishes.

Example task list for auto-discovered projects:

```
Task 1: Mine casa/simple-pms          [pending]
Task 2: Mine casa/we                  [pending]
Task 3: Mine casa/we-business-starters [pending]
...
```

**IMPORTANT: Do NOT mine multiple projects in parallel.** MemPalace uses ChromaDB under the hood, and concurrent writes cause database locking errors and index corruption ("database is locked", "Index with capacity N cannot add records"). Always process projects sequentially — one at a time. If the palace becomes corrupted, run `mempalace repair` to rebuild the index.

## Step 7: Verify and Report

After all projects are processed:

```bash
mempalace status
```

Present a summary table:

| Project | Wing | Files | Drawers | Status |
|---------|------|-------|---------|--------|
| we-business-starter-iot | casa | 891 | 3259 | mined |
| simple-pms | casa | 200 | 750 | mined |

## Step 8: Suggest Next Steps

- `/mempalace:search` — search the newly mined content
- Run this skill again later to re-mine and pick up code changes
- Mine projects from other parent directories

## Error Handling

- **Init fails**: Log the error, skip the project, continue with remaining projects. Common cause: directory permissions or corrupt files.
- **No Java files found**: Skip the project with a note (false positive from discovery — e.g., a BOM-only module).
- **Mine times out**: Suggest the user run it independently with a longer timeout, or try `mempalace split` first.
- **Already mined, no changes**: The mine command reports "Files skipped (already filed)" — this is normal for re-mining. Report it as "up to date".
- **ChromaDB corruption** ("database is locked", "Index with capacity N cannot add records", palace shows 0 drawers unexpectedly): Run `mempalace repair` to rebuild the index. This is usually caused by a previous interrupted mine or concurrent access.
