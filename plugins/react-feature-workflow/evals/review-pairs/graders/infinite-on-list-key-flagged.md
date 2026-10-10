---
type: regex
target: last_message
pattern: 'task\.queries\.ts:\d+[\s\S]{0,300}?(same key|shar(e|es|ing)|list\(filters\)|infinite\(|collid|one cache entry)'
flags: i
---

`taskQueries.infinite` uses `taskKeys.list(filters)` — the same key as the plain list, so two
data shapes share one cache entry. The finding names the shared key and the separate
`infinite(filters)` entry that replaces it.
