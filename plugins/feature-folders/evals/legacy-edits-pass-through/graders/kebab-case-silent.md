---
type: regex
target: trace
pattern: '\[kebab-case-validator\]'
match: not_contains
---

`OldWidget.tsx` is not kebab-case, but it already existed before this run — editing it
must never trip the naming hook, which only checks files it is asked to create.
