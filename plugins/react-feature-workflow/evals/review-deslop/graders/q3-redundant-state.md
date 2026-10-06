---
type: regex
target: last_message
pattern: 'fullName[\s\S]{0,400}?(deriv|during render|determined by|computed from|calculate|no state|useState)'
flags: i
---

Q3: `fullName` is fully determined by `first` and `last`; holding it in state and syncing it in an effect adds a render and a sync. The finding says what determines it and that it should be derived.
