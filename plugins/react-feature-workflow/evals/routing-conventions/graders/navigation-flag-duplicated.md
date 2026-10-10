---
type: regex
target: last_message
pattern: 'isNavigating|navigation\.state'
flags: i
---

The report flags the hand-rolled `isNavigating` state as a duplicate of the router's own
`useNavigation().state`.
