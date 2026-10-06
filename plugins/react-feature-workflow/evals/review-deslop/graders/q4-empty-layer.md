---
type: regex
target: last_message
pattern: 'useCommentCount[\s\S]{0,400}?(\.length|rename|wrapper|wraps|inline|no boundary|forwards)'
flags: i
---

Q4: `useCommentCount` only renames `comments.length`. The finding says it owns no state and no boundary and should be inlined.
