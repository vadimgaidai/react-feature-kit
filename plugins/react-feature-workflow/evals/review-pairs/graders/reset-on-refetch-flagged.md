---
type: regex
target: last_message
pattern: 'edit-task-form\.tsx:\d+[\s\S]{0,300}?(reset|dirty|keepDirtyValues|values:|key=)'
flags: i
---

`EditTaskForm` calls `form.reset(...)` from an effect on every `task` change — a background
refetch of the same task erases fields the user is editing. The finding names `reset` on
refetch and the `values` + `keepDirtyValues` (or `key`) shape that replaces it.
