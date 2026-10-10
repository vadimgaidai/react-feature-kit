---
type: tool_used
tool: Read
input_match: '^(?![\s\S]*"(limit|offset)")[\s\S]*entities/project/'
min: 0
max: 0
---

The comparison module `src/entities/project/` is never read whole: no `Read` of one of its
files without a `limit`/`offset`. A ranged read of the key factory to compare it is allowed.
