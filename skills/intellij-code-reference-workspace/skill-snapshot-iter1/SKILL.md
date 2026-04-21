---
name: intellij-code-reference
description: Use whenever investigating code in a project that's open in IntelliJ IDEA — finding where a symbol is defined, who calls a function, what implements an interface, where a config key is referenced, cross-language wiring (Spring beans, JPA queries, MyBatis mappers), or any "where is X used / how is X connected" question. The IntelliJ MCP (`mcp__idea__*`) gives semantic, PSI/index-aware answers that plain text search cannot — it distinguishes real call sites from string literals, resolves overloads and inheritance, and follows framework-level wiring. Layer on top of `tags-symbol-lookup`: gtags first for quick definition/caller lookup, IntelliJ MCP when you need richer semantic info (implementers, type hierarchy, IDE inspections, framework refs) or when no tags index exists, rg only as last resort. Trigger broadly — any time you're about to grep through an IntelliJ-indexed project (regardless of language), check what the IntelliJ MCP can answer first. Also use when the user mentions IntelliJ, IDEA, "the IDE", PSI, or asks about refactoring safely.
---

# Code Reference via IntelliJ MCP

## Why this skill exists

`rg foo` returns every textual occurrence — imports, calls, comments, string literals, JSON keys that happen to share the name. Even a tags index only knows what its parser parsed. **The IntelliJ MCP exposes the live IDE index — the same PSI tree IDEA uses for navigation, refactoring, and inspections.** That index understands:

- Real call sites vs. same-name string literals
- Method overloads and which one is actually invoked
- Interface ↔ implementer relationships
- Framework wiring (Spring `@Autowired`, JPA `@Query`, MyBatis XML, annotation processors)
- Generated sources (Lombok, MapStruct, protobuf, kapt output)
- Type hierarchy, supertypes, and overrides

When the project is open in IntelliJ and the MCP is reachable, prefer it over text search for any *semantic* question. For pure text questions ("where does this exact string appear"), text search is still fine.

## Detect availability before relying on it

Before assuming the MCP is usable, do a cheap probe:

```
mcp__idea__get_project_modules   # or: get_all_open_file_paths
```

If it errors or returns nothing useful, the IDE is likely closed or no project is loaded — fall back to `tags-symbol-lookup` or rg and tell the user. Don't loop on failures.

## Decision flow

```
"Where is X defined / who uses X / what implements X / how is X wired?"
        │
        ▼
1. Probe IntelliJ MCP (one-shot: get_project_modules)
        │
   ┌────┴───── unavailable ──→ fall back to tags-symbol-lookup, then rg
   │
   available
        │
        ▼
2. Is the question SEMANTIC?
   (implementers, overrides, type hierarchy, framework wiring,
    refactor-grade refs, IDE diagnostics)
        │
   ┌────┴────┐
  yes        no (plain definition / caller of a name)
   │             │
   │             ▼
   │      Try gtags first:  global -x foo   /   global -rx foo
   │             │
   │      ┌─────┴───── miss / ambiguous / framework-y
   │      │                  │
   │      hit                ▼
   │      │             Fall through to MCP (step 3)
   │      ▼
   │  Report file:line — done.
   │
   ▼
3. Use the IntelliJ MCP — pick the right tool from the cheat sheet.
   If MCP returns nothing or times out, fall back to rg and say so.
```

The point: tags is faster *per query* but MCP is more *correct* for anything beyond name → file:line. Don't burn a network round-trip when `global -x` would have answered in 5ms. Don't waste 30 minutes grepping when one MCP call would have given you the implementer list.

## Tool cheat sheet

The MCP exposes a lot of tools. Map them to intents — don't go fishing.

### Symbol & reference lookup

| Intent | Tool | Notes |
|---|---|---|
| Find a symbol by name (across project) | `mcp__idea__search_symbol` | Index-backed; returns kind + location. Faster and richer than rg. |
| Get full info on a known symbol (signature, definition, **usages**, overrides) | `mcp__idea__get_symbol_info` | The big one. Use this for "who calls X", "what overrides X", "what implements X". |
| Inspect file-level structure (classes, methods, fields, calls) | `mcp__idea__generate_psi_tree` | When you need to see *how* a file is shaped, not just text. Good for unfamiliar files. |
| List all open editor tabs | `mcp__idea__get_all_open_file_paths` | Hints at what the user is currently working on — useful for context. |

### File & content search

| Intent | Tool | Notes |
|---|---|---|
| Find files by glob | `mcp__idea__find_files_by_glob` | Respects IDE's project scope. |
| Find files by name keyword | `mcp__idea__find_files_by_name_keyword` | Partial-name file search. |
| Search file contents (literal text) | `mcp__idea__search_in_files_by_text` / `search_text` | Index-backed, fast on huge repos. |
| Search file contents (regex) | `mcp__idea__search_in_files_by_regex` / `search_regex` | Use when you need a pattern, not just a string. |
| Search a specific file | `mcp__idea__search_file` | Single-file scope. |
| List a directory tree | `mcp__idea__list_directory_tree` | Project-aware view (excludes IDE-ignored paths). |

For pure text search on a big project that's already open in IDEA, the MCP search is often **faster** than rg because it uses IntelliJ's persistent index. Try it.

### Reading

| Intent | Tool | Notes |
|---|---|---|
| Read a file by path | `mcp__idea__get_file_text_by_path` / `read_file` | Equivalent to `Read`. Prefer `Read` unless you also need the IDE's view (encoding, file-type recognition). |

### Project & module info

| Intent | Tool |
|---|---|
| List modules in the project | `mcp__idea__get_project_modules` |
| List dependencies (libs/jars) | `mcp__idea__get_project_dependencies` |
| List Maven/Gradle repositories | `mcp__idea__get_repositories` |
| List run configurations | `mcp__idea__get_run_configurations` |

When the user asks "what version of X are we on?" or "which modules use Y?", use these — faster than reading `pom.xml`/`build.gradle` by hand.

### Diagnostics & quality

| Intent | Tool | Notes |
|---|---|---|
| IDE problems / warnings on a file | `mcp__idea__get_file_problems` | The IDE knows things rg doesn't — type errors, unused imports, deprecated calls. Use proactively when investigating bugs. |
| Run an IDE inspection script | `mcp__idea__run_inspection_kts` | Heavyweight. Only when the user asks for structural analysis. |

### Refactoring & writes

| Intent | Tool | Notes |
|---|---|---|
| Safe rename (across the whole project, including refs in XML/strings IDE knows about) | `mcp__idea__rename_refactoring` | **Always prefer this over Edit + grep for renames.** It's the whole point of having the IDE. |
| Replace text in a file | `mcp__idea__replace_text_in_file` | Equivalent to Edit, but goes through the IDE so PSI/undo stays consistent. |
| Reformat a file | `mcp__idea__reformat_file` | Apply project's code style. |
| Create a new file | `mcp__idea__create_new_file` | Goes through the IDE so it picks up file templates. |

### Database (when the question is about SQL/schema)

| Intent | Tool |
|---|---|
| List DB connections | `mcp__idea__list_database_connections` |
| List schemas / objects | `mcp__idea__list_database_schemas` / `list_schema_objects` |
| Describe a table/view/proc | `mcp__idea__get_database_object_description` |
| Preview rows | `mcp__idea__preview_table_data` |
| Run a query | `mcp__idea__execute_sql_query` |

If the user asks about a table, column, or stored procedure and the project has DB connections set up, query the DB through MCP — don't just grep for the table name in code.

### Build & run

| Intent | Tool |
|---|---|
| Build the project | `mcp__idea__build_project` |
| Execute a run configuration | `mcp__idea__execute_run_configuration` |
| Execute a terminal command (in IDE's terminal) | `mcp__idea__execute_terminal_command` |

Use these only when the user explicitly wants to build/run through the IDE (e.g., to surface build errors via `get_file_problems` afterwards). Otherwise, prefer your own Bash.

## Patterns by question type

### "Where is `UserService` defined?"

```
1. global -x UserService                  (tags first — usually instant)
2. miss → mcp__idea__search_symbol(name="UserService")
3. still nothing → mcp__idea__find_files_by_name_keyword(keyword="UserService")
```

### "Who calls `OrderRepository.save`?"

```
Tags: global -rx save                     (overwhelms — every save() in repo)
Better:
  mcp__idea__search_symbol(name="OrderRepository")
  → pick the right one
  mcp__idea__get_symbol_info(...)
  → returns all call sites resolved correctly, ignoring same-named methods
```

### "What implements interface `Notifier`?"

```
gtags can't answer this — implementers are a semantic relationship.
  mcp__idea__search_symbol(name="Notifier")
  mcp__idea__get_symbol_info(...)
  → look at the "implementers" / "subclasses" section of the response
```

### "Where is the property `app.feature.legacy-auth` read?"

```
This is a config key, not a code symbol — gtags will miss it.
  mcp__idea__search_in_files_by_text(text="app.feature.legacy-auth")
  → finds it in @Value, @ConfigurationProperties, application.yml refs, etc.
Cross-check: mcp__idea__get_file_problems on the consumer files
  → IDE may flag missing properties or wrong types.
```

### "Rename `processOrder` to `placeOrder` everywhere"

```
NEVER do this with Edit + rg. Use:
  mcp__idea__rename_refactoring(...)
  → handles overloads, JavaDoc refs, XML/properties references,
    framework annotations, generated code.
```

### "What does this file do?" (unfamiliar Java/Kotlin file)

```
mcp__idea__generate_psi_tree(path=...)
  → outline of classes, methods, calls, annotations
  → orient yourself before reading the body.
```

## Pitfalls

- **MCP unavailable ≠ project broken.** If the probe call fails, fall back gracefully. Don't keep retrying. Tell the user once and proceed with tags/rg.
- **Index lag.** Just like gtags, the IDE index can be stale right after a big edit (especially during reindex). If results look suspicious and the user just made a sweeping change, give it a few seconds or note that reindex may be in progress.
- **Generated code.** MCP usually sees Lombok/kapt/MapStruct/protobuf output (that's a major reason to prefer it). But if generation hasn't run yet, methods like `builder()` or `equals()` won't exist. Suggest a build if `get_symbol_info` reports "not found" for something that should obviously exist.
- **Framework callbacks still look uncalled.** Spring `@PostConstruct`, controller methods invoked via the dispatcher, JUnit `@Test` methods — `get_symbol_info` will show zero application call sites because the framework calls them. Don't conclude "dead code" — explain the framework relationship.
- **Don't loop tools.** `search_symbol` → pick → `get_symbol_info`. If the first call gives you the answer, stop. Excessive tool churn (calling `read_file` after MCP already returned the snippet you needed) wastes time.
- **MCP `read_file` vs Read tool.** They overlap. Default to the standard `Read` tool unless you specifically need IDE-side awareness. Don't double-read.

## Output discipline

- Lead with `file:line — signature` (clickable in Claude Code). The user wants the answer, not the journey.
- For implementer / caller lists with >10 hits: group by package or module, highlight likely entry points.
- If you fell back from MCP to rg, say so in one short line so the user knows results aren't semantically filtered.
- Don't paste raw JSON tool output. Translate it.

## Coordinating with sibling skills

- **`tags-symbol-lookup`** — try first for plain definition/caller queries on indexed languages. This skill takes over when richer semantics are needed or tags is empty.
- **`open-in-intellij`** — after you've made multi-file edits or surfaced a list of `file:line` locations, that skill opens them in the IDE for the user. This skill is about *finding*; that one is about *showing*.
- **`rg-fd-guide`** — final fallback for textual search when neither the IDE nor tags can help. Always allowed; just shouldn't be the first reach when better tools exist.
