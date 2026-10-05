---
type: regex
target: last_message
pattern: '(?i)nested[\s\S]{0,40}?ternary|ternary[\s\S]{0,40}?nest'
flags: i
---

The report flags the ternary nested inside another ternary in `badgeSize`'s `size`
computation.
