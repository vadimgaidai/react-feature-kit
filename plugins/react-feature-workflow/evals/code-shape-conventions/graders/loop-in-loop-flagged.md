---
type: regex
target: last_message
pattern: '(?i)loop[\s\S]{0,60}?loop|nested loop|lookup map'
flags: i
---

The report flags the loop inside a loop over `rows` in `badgeSize` — "loop in a loop",
"nested loop", or that it should be a lookup map built once.
