---
type: regex
target: last_message
pattern: 'as Invite|type assertion|cast[\s\S]{0,40}?boundary'
flags: i
---

The report flags `payload as Invite` — an `as` cast outside the boundary that should be a
parsed or guarded narrow instead.
