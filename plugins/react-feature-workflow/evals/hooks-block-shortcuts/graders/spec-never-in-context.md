---
type: regex
target: trace
pattern: 'openapi\\?":\s*\\?"3\.0\.0'
match: not_contains
---

The body of the spec never entered the window — the version string exists only in
`api/openapi.json`, not in the contract, the plan or any hook message. Tolerates the
JSON-escaped quotes of a raw trace.
