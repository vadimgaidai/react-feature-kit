---
type: regex
target: last_message
pattern: 'status[\s\S]{0,60}?useState|URL[\s\S]{0,40}?(restored|source of truth)[\s\S]{0,80}?status'
flags: i
---

The report flags `status` held in `useState` instead of being read from the URL, so a shared
link or a reload loses the selected filter.
