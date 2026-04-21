# webstorm-code-reference — Iteration 1 Results

## Per-eval results

| Eval | With-skill | Baseline | With-skill tokens / time | Baseline tokens / time | Winner |
|---|---|---|---|---|---|
| 0. Component usage (`apply-list`) | ✅ 4 hits (WebStorm MCP) | ✅ 4 hits (rg) | 35.8k / 35.7s | 27.9k / 28.5s | Tie on correctness; baseline cheaper |
| 1. API caller search (`companyService.js`) | ✅ Full wiring + dead-code callout (WebStorm MCP only) | ✅ Full wiring, false-positive ruled out (rg + Read) | 53.4k / 113s | 34.7k / 80.7s | Slight edge: with-skill flagged `getLocations` commented-out caller & distinguished root vs companyService getLocations |
| 2. i18n key lookup | ✅ `page_login_btn_forgetPassword` → 1 hit (WebStorm MCP text search) | ✅ `page_head_btn_login` → 6 hits (rg) | 40.4k / 60.4s | 32.1k / 52.5s | Different keys picked — both valid; tie |
| 3. **Java negative test** (routing) | ✅ Correctly routed Java → IntelliJ MCP; IDE not open → fell back to rg per skill pitfall; found **3 caller sites** for semantically-similar user-creation methods (`BgUserService.addBgUser` + `SeekerService.registerSeeker`) | ❌ Searched only literal `UserService`, got 0 matches, stopped. Missed the "similarly-named user-creation service method" part of the prompt. | 48.3k / 109.5s | 32.5k / 80.0s | **With-skill clearly better** — routing rule worked, fallback worked, broader semantic interpretation of the ask |

## Cost/quality summary

- **Correctness**: 8/8 objective assertions passed for with-skill; 7/8 for baseline (eval-3 fail). The one failure was the Java negative test where the skill's routing rule led to a better answer.
- **Token cost**: with-skill used ~40% more tokens on average (44.5k vs. 31.8k). The overhead is reading the skill + preferring MCP tools (which return richer structured data).
- **Wall clock**: with-skill was slower on average (79.7s vs. 60.4s). MCP calls add latency over raw rg.

## Key qualitative observations

1. **The routing rule fired correctly in eval-3** — the with-skill subagent read the Language-based routing table, identified the Java project should go to IntelliJ MCP, tried it, hit a real "IDE not open" error, and correctly fell back per the skill's Pitfalls section. It also interpreted "UserService.create or similarly-named" more generously than baseline, which is exactly what a richer semantic-search tool enables.

2. **The baseline did surprisingly well on JS/TS queries** — with both `rg` + manual `Read` to trace Vuex wiring in eval-1, the baseline covered the same ground as MCP. For simple name-based lookups in small Vue projects, the MCP's semantic advantage is modest.

3. **MCP cost is real** — `search_in_files_by_text`/`search_symbol` return more data per call, and the skill encourages cross-checking. That adds tokens. For trivial searches, baseline may be preferable. The skill does acknowledge this in its decision flow ("gtags first if indexed").

4. **The skill did NOT over-prescribe MCP** — in eval-3, the subagent correctly fell back to rg when IntelliJ MCP was unreachable, without looping retries. The Pitfalls section saying "say so once, don't retry" did its job.

## Potential skill improvements to consider

1. **Acknowledge token/time cost tradeoff more explicitly** in the decision flow — the skill already says "don't burn a network round-trip when gtags would answer in 5ms", but could be clearer that for small-to-medium Vue/React projects with normal rg, the MCP overhead may not pay back unless the query is genuinely semantic.

2. **Add guidance for "IDE not open" case** — eval-3 showed this happens in real multi-repo workflows. The current Pitfalls section covers it ("MCP unreachable ≠ project broken") but could be more prominent / include an example.

3. **No obvious content-level bugs**. The skill description clearly triggered the right routing; the decision flow was followed; fallbacks worked.
