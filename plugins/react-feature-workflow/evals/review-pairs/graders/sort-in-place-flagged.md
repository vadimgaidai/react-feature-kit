---
type: regex
target: last_message
pattern: 'task-board\.tsx:\d+[\s\S]{0,300}?(in place|mutat|props|copy|\[\.\.\.tasks\])'
flags: i
---

`TaskBoard` calls `tasks.sort(...)` on the prop itself — mutating props during render. The
finding names the in-place mutation and the local copy that replaces it.
