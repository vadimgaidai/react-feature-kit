---
type: regex
target: last_message
pattern: '(?i)boolean[\s\S]{0,40}?(flag|parameter)|flag parameter'
flags: i
---

The report flags `compact: boolean` as a boolean flag parameter on `badgeSize`.
