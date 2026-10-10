---
type: regex
target: last_message
pattern: 'edit-note-form\.tsx:\d+[^\n]{0,200}?(erase|every (refetch|render)|dirty fields lost|should not reset)'
flags: i
match: not_contains
---

`EditNoteForm` resets only when `note.id` changes (`key`) and keeps dirty values across a
refetch (`values` + `keepDirtyValues`). It is the legitimate twin and is not reported at its
`file:line`.
