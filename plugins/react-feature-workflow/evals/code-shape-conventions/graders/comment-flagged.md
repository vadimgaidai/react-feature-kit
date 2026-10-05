---
type: regex
target: last_message
pattern: '(?i)comment[\s\S]{0,80}?(todo|directive|delet)'
flags: i
---

The report flags the narrative comment above `badgeSize` — anything that names it a comment
that isn't `TODO:` / `!` / a directive and should be deleted.
