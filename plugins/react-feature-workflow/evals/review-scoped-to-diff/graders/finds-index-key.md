---
type: regex
target: last_message
pattern: 'index[\s\S]{0,80}?key|key[\s\S]{0,80}?index'
flags: i
---

The report flags the index key on the reordered list — `key={index}`, "index key", "key by
index", any phrasing that puts the two words within a line of each other.
