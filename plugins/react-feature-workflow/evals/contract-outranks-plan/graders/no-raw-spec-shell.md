---
type: tool_used
tool: Bash
input_match: 'openapi\.json'
min: 0
max: 1
weight: 0.5
---

The raw OpenAPI spec is not read through the shell either — `cat`, `head`, `jq` and
friends count the same as `Read`. One attempt is tolerated for the same reason as in
`no-raw-spec-read`: the guard refuses it, and the refusal is still a call.
