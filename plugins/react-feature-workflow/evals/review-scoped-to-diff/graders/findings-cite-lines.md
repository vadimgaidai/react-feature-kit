---
type: regex
pattern: '[\w./-]+\.tsx?:\d+'
match: contains
---

Findings carry a `file:line`, so each verdict is checkable rather than asserted.
