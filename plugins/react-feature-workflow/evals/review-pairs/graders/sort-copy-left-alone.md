---
type: regex
target: last_message
pattern: 'task-list\.tsx:\d+[^\n]{0,200}?(in place|mutat|immutab)'
flags: i
match: not_contains
---

`TaskList` sorts `[...tasks]` — a local copy. It is the legitimate twin and is not reported
for mutation at its `file:line`.
