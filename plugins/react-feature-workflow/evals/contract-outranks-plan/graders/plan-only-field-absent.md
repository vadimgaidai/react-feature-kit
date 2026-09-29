---
type: regex
target: { source: file, path: src/entities/comment/model/types.ts }
pattern: 'email'
flags: 'i'
match: not_contains
---

The plan's prose asks for an author email; the contract does not define one. A field
absent from the slice does not exist, however plausible the plan makes it sound.
