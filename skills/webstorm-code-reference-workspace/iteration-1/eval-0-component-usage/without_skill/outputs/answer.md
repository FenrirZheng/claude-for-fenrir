# `apply-list` component usage in `camhr-pc`

## Tools used

Used the Grep tool (ripgrep-backed) to search the project for both the kebab-case tag (`apply-list`) and the PascalCase identifier (`ApplyList`). Grep was chosen because it's the fastest way to scan a Vue 2 project for both the component-tag form used in templates and the imported-symbol form used in `<script>` blocks.

## Hits (file:line — one-line context)

- `/home/fenrir/code/camhr/camhr-pc/pages/job-record/index.vue:17` — `<apply-list :active="active" :loading="loading" @search="getJobs" @delapply="delapply" />`
- `/home/fenrir/code/camhr/camhr-pc/pages/job-record/index.vue:41` — `<apply-list :active="active" :loading="loading" @search="getJobs" @delapply="delapply" />`
- `/home/fenrir/code/camhr/camhr-pc/pages/job-record/index.vue:51` — `import ApplyList from "~/components/blocks/apply-list.vue";`
- `/home/fenrir/code/camhr/camhr-pc/pages/job-record/index.vue:87` — `ApplyList,` (entry inside the `components: { ... }` registration object)

The source component file itself lives at `/home/fenrir/code/camhr/camhr-pc/components/blocks/apply-list.vue` (referenced by the import above).

## Summary

4 usages across 1 file (`pages/job-record/index.vue`): 1 import, 1 local-component registration, and 2 template usages (rendered in two different branches of the template).
