---
type: regex
target: last_message
pattern: 'joinName[\s\S]{0,400}?formatName|formatName[\s\S]{0,400}?joinName'
flags: i
---

Q2: `joinName` repeats `formatName` from `src/shared/lib/format.ts`. The finding names the existing helper — that is the evidence, not the pattern.
