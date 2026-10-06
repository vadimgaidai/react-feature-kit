---
type: regex
target: last_message
pattern: 'comment-panel\.tsx:\d+[\s\S]{0,400}?commentSchema'
---

The report flags `commentSchema` defined inline in `comment-panel.tsx`, at its line, quoting
the project's own rule from `.claude/rules/forms.md`, whose `paths:` matches the file:
schemas go in `<module>/schemas.ts`, never inline in a component.
