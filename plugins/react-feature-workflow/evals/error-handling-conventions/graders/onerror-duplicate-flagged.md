---
type: regex
target: last_message
pattern: 'handleResend|duplicate[\s\S]{0,40}?onError|onError[\s\S]{0,60}?(duplicate|handler)'
flags: i
---

The report flags `handleResend`'s call-site `onError` re-handling what the mutation's own
`onError` already handles.
