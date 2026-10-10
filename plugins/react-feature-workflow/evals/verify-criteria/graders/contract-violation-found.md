---
type: regex
target: last_message
pattern: 'authorAvatarUrl'
---

The contract pass catches `authorAvatarUrl` on the `Comment` type: the slice lists four fields and this is not one of them, so it is a field the API never sends.
