---
type: regex
target: trace
pattern: '\[model-placement-validator\]'
match: not_contains
---

Each edit fixes a bug in place — a guard, a trailing-hyphen fix, a typo fix — and
introduces no domain type, as-const map, schema, hook or HTTP call, so the content
hook never has grounds to fire either, old file or new.
