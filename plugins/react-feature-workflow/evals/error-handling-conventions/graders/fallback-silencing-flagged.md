---
type: regex
target: last_message
pattern: 'lineItems[\s\S]{0,60}?\?\?|\?\?[\s\S]{0,60}?lineItems|fallback[\s\S]{0,40}?hid'
flags: i
---

The report flags `data?.lineItems ?? []` as a fallback that turns a missing required field
into a silent empty list.
