# `apply-list` component usage — camhr-pc

## Tools used

Used the WebStorm MCP (`mcp__webstorm__search_in_files_by_text` and `mcp__webstorm__search_in_files_by_regex`) per the skill's decision flow — this is a Vue 2 project indexed in WebStorm, so the IDE index resolves the kebab-case template tag, the PascalCase JS binding, and the import path in a single semantic query without gitignore/alias blind spots.

## Definition

- `/home/fenrir/code/camhr/camhr-pc/components/blocks/apply-list.vue` — component source (SFC)

## References

All usages live in a single consumer:

- `/home/fenrir/code/camhr/camhr-pc/pages/job-record/index.vue:17` — `<apply-list :active="active" :loading="loading" @search="getJobs" @delapply="delapply" />` (template usage, first tab)
- `/home/fenrir/code/camhr/camhr-pc/pages/job-record/index.vue:41` — `<apply-list :active="active" :loading="loading" @search="getJobs" @delapply="delapply" />` (template usage, second tab)
- `/home/fenrir/code/camhr/camhr-pc/pages/job-record/index.vue:51` — `import ApplyList from "~/components/blocks/apply-list.vue";` (ES import via `~` alias)
- `/home/fenrir/code/camhr/camhr-pc/pages/job-record/index.vue:87` — `ApplyList,` (local `components: { ... }` registration)

## Summary

4 references across 1 file (`pages/job-record/index.vue`): 1 import, 1 components-option registration, 2 template instantiations. The component is defined at `components/blocks/apply-list.vue` and is only consumed by the job-record page.
