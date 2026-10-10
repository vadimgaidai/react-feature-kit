---
type: regex
target: last_message
pattern: 'AC-3[\s\S]{0,300}?fail'
flags: i
---

AC-3 fails: nothing in the mutation or the form handles a 409, so the conflict message the spec requires cannot appear.
