---
type: regex
target: last_message
pattern: 'filter-panel\.tsx:\d+[^\n]{0,200}?(own (copy|state)|competing|duplicate)'
flags: i
match: not_contains
---

`FilterPanel`'s parts read `isOpen` and `toggle` from `Root`'s context through
`useFilterPanel`, which throws outside `Root`. It is the legitimate twin and is not reported
at its `file:line`.
