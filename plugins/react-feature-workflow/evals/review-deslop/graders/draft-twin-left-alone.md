---
type: regex
target: last_message
pattern: 'comment-draft\.tsx:\d+[^\n]{0,200}?(redundant|derived|determined by|sync|should (be )?(computed|derived)|remove the state)'
flags: i
match: not_contains
---

`CommentDraft` copies `comment.body` into state on purpose — an editable draft, reset by
`key={comment.id}` in `CommentEditor` — and never writes the prop back on a change. It is
the legitimate twin of the `fullName` defect and must not be reported as redundant or
derived state at its `file:line`.
