---
type: regex
target: last_message
pattern: 'AC-4[\s\S]{0,300}?(unverifiable|manual)[\s\S]{0,400}?(offline|network)'
flags: i
---

AC-4 cannot be settled by reading code or running the suite, so it is `unverifiable` on the `manual` tier with the steps a human performs — not a quiet pass and not a fail.
