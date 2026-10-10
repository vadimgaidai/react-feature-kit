---
type: regex
target: last_message
pattern: 'badge-overlaps\.ts:\d+[^\n]{0,200}?(repeated|lookup|Map\(|built once|n ?[x×] ?m|per (row|element))'
flags: i
match: not_contains
---

`overlappingPairs` must visit every pair of boxes — a nested traversal the task needs, not
a search repeated per element. It is the legitimate twin of `badgeSize`'s `tones.find` and
must not be reported as repeated work at its `file:line`.
