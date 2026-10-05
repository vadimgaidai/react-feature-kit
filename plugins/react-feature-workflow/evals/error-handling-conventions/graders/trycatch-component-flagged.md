---
type: regex
target: last_message
pattern: 'try/catch[\s\S]{0,60}?component|component[\s\S]{0,60}?try/catch|InvoicePanel[\s\S]{0,80}?try'
flags: i
---

The report flags the `try/catch` wrapping the whole `InvoicePanel` component body — the
query cache already owns this error.
