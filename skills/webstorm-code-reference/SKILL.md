---
name: webstorm-code-reference
description: "Use whenever investigating or editing code in a JS/TS/Vue/React/Node project open in WebStorm — finding where a component is defined, who imports a hook, what implements an interface, where a config key or translation key is referenced, module-alias and re-export resolution, cross-file wiring (Next.js routes, Nuxt pages, Vue composables, Redux selectors), or any 'where is X used / how is X connected' question. The WebStorm MCP (`mcp__webstorm__*`) gives semantic, PSI/index-aware answers — it resolves TypeScript types, follows barrel re-exports, distinguishes real call sites from same-name string literals, resolves overloads, understands `tsconfig` path aliases, and doesn't silently skip `node_modules`/gitignored paths the way `rg` does. Use for write actions too — `rename_refactoring`, `replace_text_in_file`, `reformat_file`, `create_new_file` all apply edits live through the IDE so the user sees changes in their editor immediately. **Language-based routing:** WebStorm MCP for JS/TS/Vue/React/Node/frontend projects; IntelliJ MCP (`mcp__idea__*`, via the `intellij-code-reference` skill) for Java/Kotlin. Trigger broadly — any time you're about to `rg` through a WebStorm-indexed project, grep for a component/hook name, do a find-and-replace rename, or answer a 'where is X used' question, check what the MCP can answer first. Also use when the user mentions WebStorm, 'the IDE', IDE refactoring, PSI, tsconfig paths, or barrel exports."
---

# Code Reference via WebStorm MCP

## Why this skill exists

`rg foo` returns every textual occurrence — and silently returns *nothing* when its ignore rules exclude the wrong directory, when your scope is off, or when the symbol crosses a `tsconfig` path alias. A tags index only knows what its parser parsed, and JS/TS has enough flavors (JSX, TSX, Vue SFC, Svelte, MDX) that tags coverage is uneven.

**The WebStorm MCP exposes the live IDE index — the same PSI tree WebStorm uses for navigation, refactoring, and inspections.** That index understands TypeScript types, real call sites (vs same-name string literals), method overloads, interface ↔ implementer relationships, module aliases (`tsconfig.json` `paths`, webpack/vite aliases), barrel re-exports, Vue SFC `<script setup>` bindings, JSX component usage, and generated sources (graphql-codegen `.generated.ts`, OpenAPI clients, `.d.ts` from build steps). If the project is open in WebStorm, prefer MCP over text search for any *semantic* question — and even for "did this string appear anywhere" on big monorepos, MCP's `search_in_files_by_text` is index-backed and immune to gitignore / `node_modules` surprises.

## Language-based routing

This skill is the JS/TS/frontend counterpart to `intellij-code-reference`. Pick by language, not by editor name:

| Project language / stack | Use |
|---|---|
| TypeScript, JavaScript, JSX, TSX | **WebStorm MCP** (`mcp__webstorm__*`) — this skill |
| Vue (SFC), React, Svelte, Solid | **WebStorm MCP** — this skill |
| Node.js, Next.js, Nuxt, Remix, NestJS | **WebStorm MCP** — this skill |
| Java, Kotlin, Scala, Groovy | **IntelliJ MCP** (`mcp__idea__*`) — `intellij-code-reference` skill |
| Android (Kotlin/Java) | **IntelliJ MCP** |
| Mixed Spring Boot + frontend | Java/Kotlin files → IntelliJ MCP; frontend files → WebStorm MCP. Pick per-query based on the file you're reasoning about. |

If both MCPs are available and you're not sure which project is indexed, call `mcp__webstorm__get_project_modules` or `mcp__idea__get_project_modules` to check — the one that answers is the one that's live.

## Decision flow

```
"Where is X defined / who uses X / what implements X / how is X wired?"
        │
        ▼
Is the question SEMANTIC?
  (type/interface implementers, hook call sites across re-exports,
   component usages, refactor-grade refs, IDE diagnostics,
   tsconfig alias resolution, barrel-export chains)
        │
   ┌────┴────┐
  yes        no (plain definition / caller of a code symbol)
   │             │
   │             ▼
   │      gtags first:  global -x foo   /   global -rx foo
   │      (only if gtags indexes the language — TS coverage varies)
   │             │
   │      ┌──────┴────── miss / ambiguous / crosses an alias
   │      │                  │
   │      hit                ▼
   │      │             Try MCP (skip ahead).
   │      ▼
   │  Report file:line — done.
   │
   ▼
Try MCP. No need to probe first — call the tool you actually need
(e.g. `search_symbol`, `search_in_files_by_text`). If it errors,
that's your signal WebStorm isn't reachable; fall back to gtags then rg
and tell the user once.
```

The point: tags is faster *per query* when it covers the language, MCP is more *correct* for anything beyond name → file:line, and rg is the last resort. Don't burn a round-trip when `global -x` would have answered in 5ms. Don't trust an empty rg result on a monorepo — especially when the symbol might be imported under an alias — try MCP before declaring "doesn't exist".

## Tool cheat sheet

All tools are prefixed `mcp__webstorm__`. Shapes mirror the IntelliJ MCP, so if you know one, the other is near-identical.

### Symbol & reference lookup

| Intent | Tool | Notes |
|---|---|---|
| Find a symbol by name (class, function, component, hook, type) | `search_symbol` | Index-backed; returns kind + location. Handles camelCase JS/TS naming. |
| Get info on a known symbol (signature, JSDoc/TSDoc, definition) | `get_symbol_info` | Returns signature + docs. **Does not return a usages list** — for callers/refs use `search_in_files_by_text` or `search_in_files_by_regex` after locating the symbol. |
| File-level structure (exports, functions, JSX tree) | `generate_psi_tree` | When you need to see *how* a file is shaped, including JSX / Vue template nesting, before reading the body. |
| What's the user looking at? | `get_all_open_file_paths` | Hints at current focus. |

### File & content search

| Intent | Tool |
|---|---|
| Find files by glob (e.g. `**/*.tsx`) | `find_files_by_glob` |
| Find files by name keyword | `find_files_by_name_keyword` |
| Search content (literal text) | `search_in_files_by_text` |
| Search content (regex) | `search_in_files_by_regex` |
| List a directory tree | `list_directory_tree` |

For text search on a project that's open in WebStorm, MCP's `search_in_files_by_text` is often **faster** than rg (uses WebStorm's persistent index) and **doesn't silently skip `node_modules`/gitignored paths**. Prefer it when rg returns suspiciously zero results — especially likely when a symbol is exported through a barrel file or aliased via `tsconfig` `paths`.

### Project info

| Intent | Tool |
|---|---|
| List modules / workspaces | `get_project_modules` |
| List dependencies (packages) | `get_project_dependencies` |
| List run configurations | `get_run_configurations` |
| List repositories in the workspace | `get_repositories` |

When the user asks "what version of React are we on?", "which packages use lodash?", or "do we have `@types/node` installed?", these beat reading `package.json` / lockfiles by hand — the MCP already resolved the effective dependency graph.

### Diagnostics, refactoring, build

| Intent | Tool |
|---|---|
| IDE problems on a file (TS errors, ESLint, etc.) | `get_file_problems` |
| Safe rename across the project (imports, JSX usage, tests) | `rename_refactoring` — **always prefer over Edit + grep for renames** |
| Reformat (Prettier / IDE style) | `reformat_file` |
| Write text into a file via IDE | `replace_text_in_file` |
| Create a new file via IDE | `create_new_file` |
| Open file in editor | `open_file_in_editor` |
| Read file through IDE | `read_file` (prefer the standard `Read` tool) |
| Build / run via IDE | `build_project`, `execute_run_configuration`, `execute_terminal_command` |
| Run IDE inspections (scripted) | `run_inspection_kts`, `generate_inspection_kts_api`, `generate_inspection_kts_examples` |

## Patterns by question type

**"Where is `useFoo` defined?"** — gtags first if it indexes TS in this repo (`global -x useFoo`); otherwise MCP `search_symbol`. Hooks and components are the sweet spot for `search_symbol` — name-based lookup, unique-ish names.

**"What implements / extends `FooProps`?"** — MCP only. `search_symbol("FooProps")` → `search_in_files_by_regex('(extends|implements)\s+FooProps\b')` to cross-check. For TS utility types (`Pick<FooProps>`, `Partial<FooProps>`) include those patterns too.

**"Who uses `<Foo />` component?"** — `search_in_files_by_text("<Foo")` catches JSX opening tags. Don't stop there: also search `"Foo "` (for `<Foo prop=...`) and `" Foo,"` (for imports), or just `search_in_files_by_regex('\\bFoo\\b')` and scan. Re-exports via `index.ts` barrels will show up through MCP — rg will miss them if the barrel isn't in the search scope.

**"Who calls `api.getUser`?"** — `search_in_files_by_text("getUser")` then filter by `.getUser(` call shape with a regex pass. Watch for destructuring (`const { getUser } = api`) — that rebinds the name and subsequent calls look unrelated to `api`.

**"Where is the translation key `auth.login.title` used?"** — MCP `search_in_files_by_text` (i18n keys are strings; gtags can't parse them, rg may miss them on large monorepos with many locales).

**"Where is `process.env.STRIPE_KEY` read?"** — MCP `search_in_files_by_text("STRIPE_KEY")`. Environment variable usage is pure-text, but MCP's index beats rg on monorepos where server/edge/client packages all reference the same var.

**"Rename `getUser` to `fetchUser` everywhere"** — `rename_refactoring`. Never Edit + rg — you'll miss re-exports, JSX bindings, and string-key references. The IDE rename handles `import { getUser as gu }` aliases correctly.

**"What does this Vue SFC / React component do?" (unfamiliar)** — `generate_psi_tree` for the outline before reading the body. Useful for big SFCs where `<template>` / `<script>` / `<style>` sections interleave logic.

**"Where is route `/users/[id]` handled?"** — For Next.js / Nuxt / Remix, this is a file-path convention. Start with `find_files_by_glob('**/users/[id]*')` or `find_files_by_name_keyword('[id]')`. Then trace handlers with `search_in_files_by_text`.

**"What types does `User` extend / intersect with?"** — `get_symbol_info("User")` first for the signature, then `search_in_files_by_regex('\\bUser\\b\\s*[&|]|extends\\s+User\\b')` for intersections and extensions.

## Pitfalls

- **MCP unreachable ≠ project broken.** If a call errors with a connection/no-project message, fall back to tags/rg and say so once. Don't retry in a loop.
- **Index lag.** Right after a sweeping edit (or during reindex after `pnpm install` / branch switch), MCP may miss new code. If results look stale, note it and suggest a re-index.
- **Generated code.** MCP usually sees `.generated.ts` (graphql-codegen, OpenAPI, Prisma client) and `.d.ts` from build steps — a major reason to prefer it. If `search_symbol` reports "not found" for something that should exist after a codegen step, suggest running the codegen script.
- **Framework-invoked code looks uncalled.** Next.js `page.tsx`/`route.ts`, Nuxt `pages/`, NestJS `@Controller` methods, Vitest/Jest `describe`/`it` blocks — zero application call sites is normal, the framework/test runner invokes them via file convention or decorator. Don't conclude "dead code" — explain the framework relationship.
- **Barrel re-exports hide usages from rg.** `export { Foo } from './foo'` in an `index.ts` means consumers `import { Foo } from '@pkg/core'` and rg looking for the literal source path finds nothing. MCP follows the re-export chain.
- **Module aliases.** `tsconfig` `paths`, webpack `resolve.alias`, Vite aliases — rg sees `@/components/Foo` as literal text. MCP resolves the alias. If a grep misses obvious call sites, check for an alias.
- **Don't loop tools.** One `search_symbol` → one cross-check → done. Don't `read_file` what MCP already returned in a snippet.
- **Both `mcp__webstorm__read_file` and the standard `Read` tool exist.** Default to `Read` — faster and doesn't require the IDE.
- **Don't Edit during rename.** If you're partway through a `rename_refactoring`, don't simultaneously edit the same files with `Edit` — you'll race the IDE's refactor. Let rename finish, then verify.

## Output discipline

- Lead with `file:line — signature`. The user wants the answer, not the journey.
- For lists with >10 hits: group by package/workspace or by file-role (component vs test vs story), highlight likely entry points.
- If you fell back from MCP to rg, say so in one short line so the user knows results aren't semantically filtered.
- Don't paste raw JSON tool output — translate it into a readable table or list.
- When reporting rename results, summarize "renamed in N files across M packages" — don't dump the full diff unless asked.

## Coordinating with sibling skills

- **`intellij-code-reference`** — the Java/Kotlin sibling. If the project you're looking at is a Spring Boot backend, switch over. If it's a mixed repo, pick per-file.
- **`tags-symbol-lookup`** — try first for plain definition/caller queries on gtags-indexed languages. This skill takes over when richer semantics are needed, gtags doesn't cover the language, or tags is empty.
- **`open-in-intellij`** — despite the name, the same pattern applies to WebStorm (both use the same JetBrains MCP surface). After you've made multi-file edits or surfaced `file:line` locations, use `mcp__webstorm__open_file_in_editor` to open them in the IDE. This skill is about *finding and editing*; opening-for-the-user is a separate concern — batch opens in a single turn, dedupe against already-open tabs (`get_all_open_file_paths`).
- **`rg-fd-guide`** — last-resort textual search when neither the IDE nor tags help, or when you need features MCP doesn't expose (e.g. multiline regex on files outside the project root).
