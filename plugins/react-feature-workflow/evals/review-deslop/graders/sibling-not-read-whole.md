---
type: tool_used
tool: Read
input_match: '^(?![\s\S]*"(limit|offset)")[\s\S]*entities/article/'
min: 0
max: 0
---

The comparison module `src/entities/article/` is never read **whole**: no `Read` of one of
its files without a `limit`/`offset`. A ranged read of the part a question needs — its
query file to compare key factories, its error handling — is allowed and expected; the
skill asks for the purpose to be stated in the finding.
