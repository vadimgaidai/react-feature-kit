---
type: tool_used
tool: Read
input_match: 'entities/article/'
min: 0
max: 0
---

Review is scoped to the diff: the untouched sibling module the plan names is never opened
file by file. Outlining it for the consistency pass is fine (that is a Bash call, not a
`Read`); reading its files is what "reads hunks, not the modules they touch" rules out.
