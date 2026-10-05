---
type: regex
target: last_message
pattern: 'one toast|generic toast|toast[\s\S]{0,60}?every failure'
flags: i
---

The report flags the generic `"Something went wrong"` toast used for every failure class
instead of distinguishing a 4xx message from a 5xx/network retry.
