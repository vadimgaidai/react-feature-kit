---
type: regex
target: last_message
pattern: 'comment-panel\.tsx:\d+[\s\S]{0,400}?(redundant effect|derived state|during render)'
flags: i
---

The report flags `CommentPanel`'s effect that recomputes `total` from `comments` — state that
could be computed during render, not synced in an effect — citing `react`'s `## Reviewing`
rubric, at the effect's line.
