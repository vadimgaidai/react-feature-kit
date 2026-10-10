---
type: tool_used
tool: Write
input_match: 'Serves[\s\S]{0,1200}?AC-\d'
min: 1
---

The module table carries a `Serves` column with `AC-` ids, which is what lets a later stage say which module should prove which criterion.
