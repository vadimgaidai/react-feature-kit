---
type: regex
target: last_message
pattern: 'refine'
flags: i
---

A `fail` blocks the hand-off: the exit line sends the user to `refine` for the failed criterion, never straight to `review`.
