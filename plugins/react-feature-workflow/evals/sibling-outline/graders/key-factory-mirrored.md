---
type: regex
target: { source: file, path: src/entities/comment/api/comment.queries.ts }
pattern: 'commentKeys\s*=\s*\{[\s\S]*all:'
match: contains
---

`commentKeys` is a key factory built like `articleKeys` — an `all` root the other keys
spread from — not a bag of hand-written arrays.
