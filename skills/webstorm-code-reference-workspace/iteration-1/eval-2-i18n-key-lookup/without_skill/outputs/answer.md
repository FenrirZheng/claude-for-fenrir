# i18n Key Lookup — `page_head_btn_login`

## 1. Picked Key

- **Key:** `page_head_btn_login`
- **Source locale file:** `/home/fenrir/code/camhr/camhr-pc/locales/en.json` (line 357)
- **English value:** `"Login"`
- Also defined in the sibling locale files (same line 357 across `th.json`, `zh.json`, `vi.json`, `km.json`, `ko.json`).

The key was selected from entries in `en.json` containing the word `login`. I picked one with multiple usages across Vue files so the reference list is meaningful.

## 2. Tools Used

- **Grep tool** (ripgrep under the hood) — used to:
  1. List all keys containing `login` inside `locales/en.json` (case-insensitive, with line numbers).
  2. Search the whole `camhr-pc` project tree for the exact key string to find every reference in Vue/JS files.
- **Bash** only for an initial `ls` of the project root and the `locales/` directory.
- No files were modified.

## 3. References (file:line — one-line context)

Locale definitions (the declaration sites):

- `/home/fenrir/code/camhr/camhr-pc/locales/en.json:357` — `"page_head_btn_login": "Login",`
- `/home/fenrir/code/camhr/camhr-pc/locales/zh.json:357` — `"page_head_btn_login": "登录",`
- `/home/fenrir/code/camhr/camhr-pc/locales/th.json:357` — `"page_head_btn_login": "เข้าสู่ระบบ",`
- `/home/fenrir/code/camhr/camhr-pc/locales/vi.json:357` — `"page_head_btn_login": "Đăng nhập",`
- `/home/fenrir/code/camhr/camhr-pc/locales/km.json:357` — `"page_head_btn_login": "ចូលគណនី",`
- `/home/fenrir/code/camhr/camhr-pc/locales/ko.json:357` — `"page_head_btn_login": "로그인",`

Code references (via `$t('…')` in Vue templates):

- `/home/fenrir/code/camhr/camhr-pc/pages/enterprise/index.vue:16` — `@click="toLogin">{{$t('page_head_btn_login')}}</button>`
- `/home/fenrir/code/camhr/camhr-pc/pages/enterprise/index.vue:54` — `@click="toLogin">{{$t('page_head_btn_login')}}</button>`
- `/home/fenrir/code/camhr/camhr-pc/components/blocks/enterprise-header.vue:78` — `<div class="sub-login cursor-pointer" @click="toLogin">{{ $t('page_head_btn_login') }}</div>`
- `/home/fenrir/code/camhr/camhr-pc/components/blocks/enterprise-header.vue:222` — `<div class="sub-login cursor-pointer" @click="toLogin">{{ $t('page_head_btn_login') }}</div>`
- `/home/fenrir/code/camhr/camhr-pc/components/blocks/header.vue:123` — `@click="toLogin">{{ $t('page_head_btn_login') }}</div>`
- `/home/fenrir/code/camhr/camhr-pc/components/blocks/header.vue:346` — `<m-button class="ph-login">{{ $t('page_head_btn_login') }} | {{ $t('page_head_btn_register') }}</m-button>`

## 4. Summary

The i18n key `page_head_btn_login` is used exclusively inside Vue template bindings via `$t(...)` — no JS `this.$t`, `i18n.t`, or `$te` call sites were found. It appears **6 times** across **4 Vue files**, all of which are header/top-nav "Login" button entry points:

- `components/blocks/header.vue` (main site header, desktop + mobile variants) — 2 hits
- `components/blocks/enterprise-header.vue` (employer-side header) — 2 hits
- `pages/enterprise/index.vue` (enterprise landing page) — 2 hits

Every call site is paired with an `@click="toLogin"` handler, confirming this key is strictly the user-facing label for the primary "Login" entry button across the site's chrome. It is translated in all 6 supported locales (en, zh, th, vi, km, ko) and is consistently placed at line 357 of each locale JSON.
