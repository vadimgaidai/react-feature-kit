---
type: regex
target: last_message
pattern: 'comment-panel\.tsx:\d+[\s\S]{0,400}?dark:bg-slate-900'
---

The report flags `dark:bg-slate-900` at its `comment-panel.tsx` line — `ui-conventions` rules
out a `dark:` override in a component; the token layer owns dark mode. The line number has to
be there: a report that only mentions dark mode in passing is not a finding.
