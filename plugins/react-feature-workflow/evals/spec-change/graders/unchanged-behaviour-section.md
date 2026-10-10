---
type: tool_used
tool: Write
input_match: '## Unchanged behaviour[\s\S]{1,400}?[A-Za-z]{4}'
min: 1
---

A delta spec owes an `## Unchanged behaviour` section: what must keep working exactly as it does today is the half of a change nobody writes down and everybody regresses.
