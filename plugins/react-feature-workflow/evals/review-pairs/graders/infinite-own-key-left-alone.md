---
type: regex
target: last_message
pattern: 'note\.queries\.ts:\d+[^\n]{0,200}?(same key|shar(e|es|ing)|collid)'
flags: i
match: not_contains
---

`noteKeys.infinite(filters)` is its own factory entry under the shared `all()` prefix. It is
the legitimate twin and is not reported at its `file:line`.
