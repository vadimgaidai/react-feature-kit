---
type: regex
target: last_message
pattern: 'comment\.queries\.ts:\d+[\s\S]{0,400}?hand-written'
---

The report flags `["comment", id]` at its `comment.queries.ts` line as a hand-written query
key instead of one built by a key factory, quoting `tanstack-query` §Query keys' own
"hand-written" wording.
