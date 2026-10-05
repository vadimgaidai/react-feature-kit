---
type: regex
target: last_message
pattern: 'non-exhaustive|exhaustive[\s\S]{0,40}?switch|missing.{0,20}?"revoked"'
flags: i
---

The report flags `statusLabel`'s `switch` for not handling the `"revoked"` case of
`InviteStatus`.
