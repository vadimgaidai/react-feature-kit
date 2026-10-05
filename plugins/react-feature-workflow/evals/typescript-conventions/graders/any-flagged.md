---
type: regex
target: last_message
pattern: 'rawPayload[\s\S]{0,80}?\bany\b|\bany\b[\s\S]{0,80}?rawPayload'
flags: i
---

The report flags `payload: any` on `rawPayload`.
