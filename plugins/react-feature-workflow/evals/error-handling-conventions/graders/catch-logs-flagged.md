---
type: regex
target: last_message
pattern: 'log[\s\S]{0,40}?continu|console\.log[\s\S]{0,60}?catch|catch[\s\S]{0,60}?console\.log'
flags: i
---

The report flags the `catch` in `InvoicePanel` that logs and continues instead of
translating, recovering or rethrowing.
