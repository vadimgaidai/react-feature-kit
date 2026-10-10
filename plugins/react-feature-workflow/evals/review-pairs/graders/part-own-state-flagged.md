---
type: regex
target: last_message
pattern: 'task-panel\.tsx:\d+[\s\S]{0,300}?(Root|context|own (copy|state)|competing|useState)'
flags: i
---

`TaskPanelTrigger` holds its own `isOpen` in `useState` instead of reading `TaskPanelRoot`'s
context, so the trigger and the content disagree. The finding names the `Root` that owns
the state.
