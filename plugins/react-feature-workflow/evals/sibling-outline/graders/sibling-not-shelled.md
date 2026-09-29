---
type: tool_used
tool: Bash
input_match: 'entities/article/[^ \n]*\.tsx?'
min: 0
max: 1
---

No sibling source file is read through the shell (one attempt tolerated: the shell-read
guard refuses it, and the refusal is still a call). Without the plugin the model reads the
whole module in one call — `for f in …; do cat "$f"; done` — which the `Read` graders never
see; with it, a range read goes through `Read` with `offset`/`limit`, where its size is
visible. The outline script itself takes the module directory, not a file, so this does not
match its invocation.
