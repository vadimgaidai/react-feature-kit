---
type: tool_used
tool: Read
input_match: 'openapi\.json'
min: 0
max: 1
weight: 0.5
---

The raw OpenAPI spec is not opened with `Read`. One attempt is tolerated because the
contract-source guard refuses it and the refusal still counts as a call; whether the spec's
body reached the window is `spec-never-in-context`'s job.
