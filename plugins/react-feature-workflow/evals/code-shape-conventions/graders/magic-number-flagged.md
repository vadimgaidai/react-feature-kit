---
type: regex
target: last_message
pattern: '(?i)magic[\s\S]{0,20}?number'
flags: i
---

The report flags the `* 42` multiplier in `badgeSize` as a magic number with a domain
meaning.
