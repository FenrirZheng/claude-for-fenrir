# Call-site report: `api/companyService.js`

## 1. Tools used

- **`rg` (ripgrep)** for all content searches, per the mandatory global tool-preference rule (`Always use rg, never grep`).
- **`Read`** to inspect the exported API surface of `api/companyService.js`, the plugin wiring in `api/index.js` / `plugins/api.js`, and the Vuex module `store/company.js`.

### Why these tools
The question is a plain "where are these exported functions called from?" query. ripgrep is fast, respects path globs, and returns `file:line` directly — perfect for enumerating call sites. The `Read` tool was used only to confirm the exported function names, the indirection layer (`new CompanyService(...)` attached to `app.api.company`), and to rule out false-positive matches (the string "companyService" also appears as a **config URL key** in `nuxt.config.js` and several components, which is unrelated to the service module).

## 2. Architecture note (important for reading the results)

`api/companyService.js` exports a **class** (`CompanyService`), not individual named functions. It is instantiated once in `api/index.js` and exposed on the Nuxt `app` as `app.api.company` by `plugins/api.js`:

```
api/companyService.js  →  api/index.js (new CompanyService)  →  plugins/api.js (app.api = createApi(...))
```

As a result, **the only file that calls methods on `companyService` directly is the Vuex store module `store/company.js`**. Vue pages/components reach these APIs indirectly, by dispatching `company/*` actions via `mapActions` / `this.$store.dispatch`. Both layers are reported below.

## 3. Direct call sites (file → companyService methods)

### `/home/fenrir/code/camhr/camhr-pc/store/company.js`  (Vuex module — the sole direct caller)

| companyService method     | Call site (file:line) |
|---------------------------|-----------------------|
| `getCompanyInfo`          | `store/company.js:38` |
| `collectionCompany`       | `store/company.js:44` |
| `delCollectionCompany`    | `store/company.js:49` |
| `getCollectionCompany`    | `store/company.js:56` |
| `getCompanyList`          | `store/company.js:65` |
| `getLocations`            | `store/company.js:72` |

All 6 exported methods of `CompanyService` are consumed, each exactly once, inside this store module's `actions`.

### `/home/fenrir/code/camhr/camhr-pc/api/index.js`  (wiring only, not a functional call)

| Reference                        | Line |
|----------------------------------|------|
| `import CompanyService from './companyService';` | `api/index.js:6`  |
| `company: new CompanyService(app, store),`       | `api/index.js:17` |

## 4. Indirect call sites — Vue pages/components that dispatch the matching `company/*` Vuex actions

These don't call `companyService` methods directly, but they are the real UI-level consumers. Mapping is 1:1 between Vuex action name and underlying `companyService` method (same names, see `store/company.js` above), **except** `setCollectionCompany` (Vuex action) which wraps `collectionCompany` (service method).

### `/home/fenrir/code/camhr/camhr-pc/pages/company.vue`
| Vuex action dispatched       | Underlying companyService method | Line |
|------------------------------|----------------------------------|------|
| `company/getCompanyInfo`     | `getCompanyInfo`                 | `pages/company.vue:556` |
| `company/setCollectionCompany` | `collectionCompany`            | `pages/company.vue:557` |
| `company/delCollectionCompany` | `delCollectionCompany`         | `pages/company.vue:558` |
| `company/getLocations`       | `getLocations`                   | `pages/company.vue:561` |

### `/home/fenrir/code/camhr/camhr-pc/pages/favorite/index.vue`
| Vuex action dispatched         | Underlying companyService method | Line |
|--------------------------------|----------------------------------|------|
| `company/getCollectionCompany` | `getCollectionCompany`           | `pages/favorite/index.vue:89` |

### `/home/fenrir/code/camhr/camhr-pc/components/blocks/optimal-company.vue`
| Vuex action dispatched   | Underlying companyService method | Line |
|--------------------------|----------------------------------|------|
| `company/getCompanyList` | `getCompanyList`                 | `components/blocks/optimal-company.vue:52` |

### `/home/fenrir/code/camhr/camhr-pc/components/blocks/company-list.vue`
| Vuex action dispatched         | Underlying companyService method | Line |
|--------------------------------|----------------------------------|------|
| `company/delCollectionCompany` | `delCollectionCompany`           | `components/blocks/company-list.vue:72` |

## 5. False positives explicitly ruled out

`rg`'s initial case-insensitive sweep flagged these files, but on inspection they all reference a **different** identifier — a config URL key named `companyService` in `nuxt.config.js` (`http://47.243.46.222:30105`, etc.), used for cross-site redirects to the enterprise portal. They do **not** use the API module:

- `nuxt.config.js` (lines 10, 76, 137, 163) — defines the URL
- `pages/enterprise/index.vue:295` — `window.location.href = config.companyService`
- `components/blocks/enterprise-header.vue:405, 451`
- `components/blocks/header.vue:607`
- `components/blocks/phone-password-login.vue:364`
- `components/blocks/banner-login.vue:225`

## 6. Summary

- `api/companyService.js` exposes a single class `CompanyService` with **6 methods**: `getCompanyInfo`, `collectionCompany`, `delCollectionCompany`, `getCollectionCompany`, `getCompanyList`, `getLocations`.
- The class is instantiated once in `api/index.js` and bound to `app.api.company` via the `plugins/api.js` Nuxt plugin.
- **There is exactly one direct caller: the Vuex store module `store/company.js`**, which wraps each of the 6 methods in a matching action.
- Four Vue files (`pages/company.vue`, `pages/favorite/index.vue`, `components/blocks/optimal-company.vue`, `components/blocks/company-list.vue`) reach the service indirectly by dispatching `company/*` actions. `pages/company.vue` is the heaviest consumer (4 of the 6 actions).
- All 6 service methods are reachable from at least one Vue page/component; no dead methods were found.
