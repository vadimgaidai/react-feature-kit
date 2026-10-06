---
type: regex
target: last_message
pattern: 'ready to merge|safe to merge|mergeable'
flags: i
match: not_contains
---

The verdict never speaks for what was not reviewed: correctness and security are `/code-review`'s and `/security-review`'s, so "ready to merge" is not a verdict this skill can give.
