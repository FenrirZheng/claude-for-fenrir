# i18n Key Lookup — `page_login_btn_forgetPassword`

## 1. Key picked

- **Key:** `page_login_btn_forgetPassword`
- **Source locale file:** `/home/fenrir/code/camhr/camhr-pc/locales/en.json` (line 496)
- **English value:** `"Forget Password"`
- Also defined in sibling locale files: `km.json` (L493), `ko.json` (L493), `zh.json` (L494), `vi.json` (L493), `th.json` (L493).

## 2. Tools used and why

- **`mcp__webstorm__find_files_by_glob`** — located `locales/en.json` quickly through the WebStorm index.
- **`mcp__webstorm__list_directory_tree`** — confirmed the set of locale files in `locales/`.
- **`mcp__webstorm__search_in_files_by_text`** (the tool the skill specifically recommends for i18n key lookups) — searched the full project for the exact key `page_login_btn_forgetPassword` with `caseSensitive=true`. Two scoped follow-up searches (`components/`, `pages/`) re-ran the query against specific directories to confirm no missed call sites.
- **`Read`** (built-in) — grabbed the single hit's surrounding lines to produce a meaningful one-line context.
- **No fallback needed.** All MCP calls succeeded; no errors encountered.
- A secondary `search_in_files_by_text` for the fragment `forgetPassword` under `*.{vue,js,ts}` returned empty, which is consistent — the substring only appears as part of the full key inside the `$t(...)` call (the method name on line 66 is `@click="forgetPassword"`, an unrelated Vue method — not a translation key reference).

## 3. References

### Code references (Vue/JS)

| File | Line | Context |
|------|------|---------|
| `/home/fenrir/code/camhr/camhr-pc/components/blocks/phone-password-login.vue` | 67 | `$t('page_login_btn_forgetPassword')` — rendered inside an `el-button` label in the phone/password login block |

### Locale definitions (not call sites, listed for completeness)

| File | Line |
|------|------|
| `/home/fenrir/code/camhr/camhr-pc/locales/en.json` | 496 |
| `/home/fenrir/code/camhr/camhr-pc/locales/zh.json` | 494 |
| `/home/fenrir/code/camhr/camhr-pc/locales/km.json` | 493 |
| `/home/fenrir/code/camhr/camhr-pc/locales/ko.json` | 493 |
| `/home/fenrir/code/camhr/camhr-pc/locales/th.json` | 493 |
| `/home/fenrir/code/camhr/camhr-pc/locales/vi.json` | 493 |

## 4. Summary

The i18n key `page_login_btn_forgetPassword` (English: "Forget Password") is referenced exactly **once in code** — on line 67 of `components/blocks/phone-password-login.vue`, used via `$t(...)` as the label for the "Forget Password" text button inside the phone + password login form. It is defined in all six locale JSON files under `locales/`. No dynamic/interpolated references, no `$te(...)` / `i18n.t(...)` / `this.$t(...)` usages found elsewhere in the project. The MCP's `search_in_files_by_text` was sufficient; no fallback to `rg` was required.
