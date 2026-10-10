---
type: regex
target: last_message
pattern: 'AC-2[\s\S]{0,300}?static[\s\S]{0,200}?comment-form\.tsx:\d+'
flags: i
---

AC-2 is `static` and cites the line in `comment-form.tsx` where the submit control is disabled while the mutation is pending. A verdict with no `file:line` behind it is not a verdict.
