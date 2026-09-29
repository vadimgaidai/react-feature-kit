---
type: regex
target: trace
pattern: 'openapi\\?":\s*\\?"3\.0\.0'
match: not_contains
---

The body of the spec never entered the window. The version string exists only in
`api/openapi.json` — not in the contract, the plan or any hook message — so its absence from
the trace means neither `Read` nor the shell got past the guard. Tolerates the JSON-escaped
quotes of a raw trace.
