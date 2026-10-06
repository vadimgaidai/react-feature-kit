---
type: regex
target: last_message
pattern: 'comment-panel\.tsx:\d+[\s\S]{0,400}?space-y-2'
---

The report flags `space-y-2` at its `comment-panel.tsx` line — `ui-conventions` prefers
`gap-*` because space utilities break on wrapping and on flex direction changes.
