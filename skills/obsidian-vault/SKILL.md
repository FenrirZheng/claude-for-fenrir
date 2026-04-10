---
name: obsidian-vault
description: Search, create, and organize notes in the user's Obsidian vault at /home/fenrir/code/obsidian. Use whenever the user wants to save knowledge or learnings, find an existing note, update an index note, or organize their vault. Triggers on phrases like "write to obsidian", "save to my notes", "add to my knowledge base", "find my note on X", "search my obsidian", "記到筆記", "寫入obsidian", "查我的筆記", "remember this in obsidian", or any request to read from or write to their personal vault — including cases where the user doesn't explicitly say "obsidian" but is clearly persisting a learning or looking up prior knowledge they captured.
---

# Obsidian Vault

Manage the user's personal Obsidian vault at `/home/fenrir/code/obsidian` — search existing notes, create new ones, and keep index notes up to date.

## Conventions

These are the conventions for **new** content. The existing vault still has legacy nested folders (`java/jvm/...`, `postgrsql/__/...`) with lowercase-hyphen filenames. Leave those where they are, but write anything new at the root level in Title Case so the vault converges on a consistent flat structure over time.

- **Location**: see "Choosing where to place a note" below for the full decision process.
- **Filenames**: Title Case with spaces — e.g. `Spring Boot Auto Configuration.md`, `PostgreSQL Vacuum Tuning.md`.
- **Index notes**: Title Case with a `-Index` suffix — e.g. `Java-Index.md`, `Postgres-Index.md`, `Stock-Index.md`. An index note is a curated list of links that aggregates a topic area.
- **Links**: always use Obsidian wiki-links (`[[...]]`), never standard markdown links. For notes in subdirectories, use the shortest unambiguous name — Obsidian resolves paths automatically.
  - Correct: `[[Spring Boot Auto Configuration]]`
  - Also correct (with alias): `[[Spring Boot Auto Configuration|Spring Boot]]`
  - Wrong: `[Spring Boot Auto Configuration](Spring%20Boot%20Auto%20Configuration.md)`
- **Language**: the user writes in English and 繁體中文 (Traditional Chinese). Match the language of the conversation. Never use Simplified Chinese.

## Searching the vault

Use `rg` for content searches and `fdfind` for filename searches — the user's global CLAUDE.md mandates these over `grep`/`find`. The Grep and Glob tools work too and are often faster.

**Find notes by filename:**
```bash
fdfind -i "keyword" /home/fenrir/code/obsidian -e md
```

**Find notes by content:**
```bash
rg -l "keyword" /home/fenrir/code/obsidian -g '*.md'
```

**List all index notes:**
```bash
fdfind -i "index" /home/fenrir/code/obsidian -e md
```

**Find backlinks to a note** (who links to `Spring Boot Auto Configuration.md`):
```bash
# Search for the wiki-link target — most precise
rg -l "\[\[Spring Boot Auto Configuration" /home/fenrir/code/obsidian -g '*.md'
```

## Creating a new note

1. **Check for an existing note first.** Before writing, search by filename and content. If a closely related note already exists, append to it instead of creating a near-duplicate. The goal is to grow existing notes over time, not fragment knowledge.

2. **Pick a Title Case filename.** Turn the topic into a noun phrase: `PostgreSQL BRIN Index.md`, not `brin-index.md` or `postgres_brin.md`. A reader scanning a folder list should understand what the note is about from the filename alone.

3. **Choose the right location** — follow the "Choosing where to place a note" section below. Do NOT default to vault root without checking first.

4. **Write the note as one unit of learning.** One note = one idea or one tightly scoped topic. Keep it scannable: headers, bullets, fenced code blocks. Obsidian callouts are welcome where they help:
   ```markdown
   > [!tip] Title
   > Content

   > [!warning] Title
   > Content
   ```

5. **Link related notes at the bottom.** Always include a `## Related` section (or `## 相關筆記` in Chinese notes) at the end of the note. Before writing it, actively search the vault — `rg` on the key concepts from the new note, `fdfind` on obvious keyword matches — and add markdown links to any notes that depend on, complement, or are prerequisites for this one. Related links are how the vault stays connected, so a real search is worth the extra step. If the search genuinely turns up nothing, still include the heading as an empty placeholder; the user will fill it in over time.

6. **Update the relevant index note.** If the new note belongs to a topic that already has an index (e.g. a new JVM note → `Java-Index.md`), add a link under the best subheader. If no index exists but the topic now has a handful of related notes, suggest creating one and do so if the user agrees.

## Choosing where to place a note

Before writing a note, determine the correct location. **Do NOT default to vault root without checking first.**

**Decision process:**

1. **Search for an existing category directory.** Use `fdfind` or `ls` to check whether the vault already has a folder matching the note's topic — e.g. `codeVault/vector_database/`, `codeVault/ai-agent/`, `codeVault/spring/`, etc.
2. **If a matching category directory exists** → place the note inside it. Create a subdirectory for the specific product/technology if the category is broad (e.g. `codeVault/vector_database/chromadb/` for a ChromaDB note, not directly inside `vector_database/`).
3. **If no matching category directory exists** → place the note at vault root in Title Case. This is the fallback, not the default.

**The same rule applies to index notes.** An index that covers a category belongs inside that category directory, not at vault root. For example, `Vector Database-Index.md` goes inside `codeVault/vector_database/`, not at root.

**Do NOT mix unrelated products under the same index or subdirectory.** Each distinct product or technology gets its own subdirectory. A ChromaDB note does not belong under `milvus/`, even though both are vector databases — they share a parent category (`vector_database/`) but live in separate subdirectories.

**Wiki-links are path-agnostic.** Obsidian resolves `[[Note Name]]` regardless of which directory the note lives in, so moving a note between directories does not break incoming links. If two notes share the same filename, disambiguate with a path prefix: `[[chromadb/ChromaDB vs Filesystem Storage for AI Memory]]`.

## Updating an index note

Index notes are curated lists of markdown links, grouped by `##` subtopic headers. When adding an entry:

- Put it under the most relevant subheader. Create a new subheader if none fits.
- Keep entries grouped by meaning, not alphabetically — things that are read together should sit together.
- Don't duplicate entries that already appear under another heading.
- Preserve the existing structure of the index; don't rearrange unless the user asks.

**Example `Java-Index.md`:**

```markdown
# Java

## JVM

* [[JVM Parameter Tuning]]
* [[Java Application Warmup]]

## Concurrency

* [[AQS Foundation]]
* [[ConcurrentHashMap JDK 1.8 Internals]]

## Tooling

* [[Gradle BootJar Git Revision]]
```

## Handling the legacy nested vault

Many existing notes still live in subfolders like `java/jvm/`, `postgrsql/__/`, `codeVault/...` with lowercase-hyphen filenames. You'll encounter them when searching and when linking from a new note to something that already exists.

- **When linking to an existing nested note**, use the shortest unambiguous wiki-link — Obsidian resolves the path automatically. If two notes share the same filename, use the relative path form.
  Example: `[[BRIN 索引（Block Range Index）]]`
- **Don't proactively move or rename legacy notes.** Migration is a user decision. Silent restructuring destroys muscle memory and breaks links in ways that aren't obvious until much later.
- **If the user explicitly asks to migrate** a legacy note to the flat Title Case root: move the file, rename it, then use `rg -l "old/path/filename"` across the vault to find every note that linked to the old location and update those links too.

## After writing or editing

Briefly tell the user:
- The exact path of the note you wrote or edited
- A one-line summary of what was added
- Which index (if any) you updated
