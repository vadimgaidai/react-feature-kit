---
type: regex
target: trace
pattern: '\[bucket-placement-validator\]'
match: not_contains
---

None of the three edits touch a new file, so the placement hook never has grounds to
fire — `src/utils/` and `src/helpers/` are unrecognized buckets, but the files inside
them already existed before this run.
