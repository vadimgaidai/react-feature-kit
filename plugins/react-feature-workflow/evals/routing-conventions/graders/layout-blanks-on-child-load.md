---
type: regex
target: last_message
pattern: 'OrdersLayout[\s\S]{0,120}?(navigation\.state|blank|return null)|return null[\s\S]{0,80}?navigation\.state'
flags: i
---

The report flags `OrdersLayout` returning `null` while `navigation.state === "loading"`,
which blanks the already-rendered header chrome for any child route's own loading state —
the child should own its own loading boundary instead.
