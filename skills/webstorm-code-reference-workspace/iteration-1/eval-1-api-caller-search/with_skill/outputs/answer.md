# companyService.js caller map

## Tools used
Used the WebStorm MCP (`mcp__webstorm__find_files_by_glob`, `mcp__webstorm__get_file_text_by_path`, `mcp__webstorm__search_in_files_by_text`, `mcp__webstorm__search_in_files_by_regex`) because this is a Vue 2 / Nuxt project open in WebStorm and the skill says to prefer PSI/index-backed search for semantic "who calls X" questions — the class is accessed through a re-export in `api/index.js` and surfaces on each component via Vuex `mapActions`, both of which plain `rg` would only resolve by chance.

## The service

`api/companyService.js` exports a default class `CompanyService` with six async methods:
`getCompanyInfo`, `collectionCompany`, `delCollectionCompany`, `getCollectionCompany`, `getCompanyList`, `getLocations`.

It is instantiated once in `api/index.js:12` as `company: new CompanyService(app, store)`, exposed as `this.app.api.company.*`. The **only direct caller** of every method is the Vuex module `store/company.js`; Vue components reach the methods indirectly via `mapActions('company/...')` or `mapActions({ x: 'company/x' })`. The grouping below follows the real call chain.

## Direct callers (of the class methods on `api.company`)

### `store/company.js` — the sole direct caller
| Method on `api.company` | Action wrapper | Line |
|---|---|---|
| `getCompanyInfo` | action `getCompanyInfo` | `store/company.js:38` |
| `collectionCompany` | action `setCollectionCompany` | `store/company.js:44` |
| `delCollectionCompany` | action `delCollectionCompany` | `store/company.js:49` |
| `getCollectionCompany` | action `getCollectionCompany` | `store/company.js:56` |
| `getCompanyList` | action `getCompanyList` | `store/company.js:65` |
| `getLocations` | action `getLocations` (company-namespaced) | `store/company.js:72` |

## Indirect callers (Vue components that invoke the store actions above)

### `pages/company.vue` — company profile page
- `mapActions` block at `pages/company.vue:554-562` imports:
  - `getCompanyInfo` → `company/getCompanyInfo` (line 556) → uses `CompanyService.getCompanyInfo`
  - `setCollectionCompany` → `company/setCollectionCompany` (line 557) → uses `CompanyService.collectionCompany`
  - `delCollectionCompany` → `company/delCollectionCompany` (line 558) → uses `CompanyService.delCollectionCompany`
  - `getLocations` → `company/getLocations` (line 561) → uses `CompanyService.getLocations`
- Call sites:
  - `pages/company.vue:574` — `await this.getCompanyInfo(Number(this.$route.query.employerId))`
  - `pages/company.vue:575` — `// this.getLocations({ employerId: ... })` **(commented out — the only reachable caller of `CompanyService.getLocations` is currently disabled)**
  - `pages/company.vue:731` — `res = await this.delCollectionCompany(params)`
  - `pages/company.vue:733` — `res = await this.setCollectionCompany(this.companyInfo.employerId)` → `CompanyService.collectionCompany`

### `pages/favorite/index.vue` — favorites page
- `mapActions` at `pages/favorite/index.vue:89` maps `getCollectionCompany: "company/getCollectionCompany"` → `CompanyService.getCollectionCompany`
- Call site: `pages/favorite/index.vue:117` — `await this.getCollectionCompany(data)`

### `components/blocks/company-list.vue`
- `mapActions` at `components/blocks/company-list.vue:72` maps `delCollectionCompany: "company/delCollectionCompany"` → `CompanyService.delCollectionCompany`
- Call site: `components/blocks/company-list.vue:92` — `res = await this.delCollectionCompany(params)`

### `components/blocks/optimal-company.vue`
- `mapActions` at `components/blocks/optimal-company.vue:52` maps `getCompanyList: "company/getCompanyList"` → `CompanyService.getCompanyList`
- Call sites:
  - `components/blocks/optimal-company.vue:58` — `//   this.getCompanyList(data);` *(commented)*
  - `components/blocks/optimal-company.vue:65` — `let companyDatas = await this.getCompanyList(data)`

## Not callers (disambiguation)

`components/blocks/condition.vue:196` and `components/blocks/job-browse.vue:81` also `mapActions({ getLocations: "getLocations" })` and call `this.getLocations()` — but these map to the **root** store's `getLocations` in `store/index.js:85`, which delegates to `api.common.getLocations` (`api/common.js:26`), **not** `CompanyService.getLocations`. Likewise, the many `companyService` hits in `nuxt.config.js` and `components/blocks/*-header.vue`, `pages/enterprise/index.vue`, `components/blocks/phone-password-login.vue`, `components/blocks/banner-login.vue` refer to a same-named **config key** (enterprise portal base URL) and are unrelated to `api/companyService.js`.

## Summary

- `api/companyService.js` has **one** direct consumer: the Vuex module `store/company.js`, which wraps every method 1:1 as an action.
- **4 Vue files** reach the service indirectly through those Vuex actions:
  - `pages/company.vue` — uses `getCompanyInfo`, `collectionCompany`, `delCollectionCompany` (actively); `getLocations` only via a commented-out line.
  - `pages/favorite/index.vue` — uses `getCollectionCompany`.
  - `components/blocks/company-list.vue` — uses `delCollectionCompany`.
  - `components/blocks/optimal-company.vue` — uses `getCompanyList`.
- Coverage per method: `getCompanyInfo`, `collectionCompany`, `delCollectionCompany`, `getCollectionCompany`, `getCompanyList` all have live callers. **`getLocations` currently has no live caller** — its only invocation (`pages/company.vue:575`) is commented out.
