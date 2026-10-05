---
type: regex
target: last_message
pattern: 'optional[\s\S]{0,40}?(soup|union)|InviteView[\s\S]{0,80}?optional'
flags: i
---

The report flags `InviteView`'s all-optional fields as optional soup where a discriminated
union was meant.
