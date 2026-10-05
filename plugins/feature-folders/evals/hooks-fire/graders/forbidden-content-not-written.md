---
type: regex
target: { source: file, path: src/features/demo/components/demo-panel.tsx }
pattern: 'IDemoResult'
match: not_contains
---

`src/features/demo/components/demo-panel.tsx` as actually written to disk never
contains the domain interface — the hook refused it, and the content never entered
the file.
