---
type: tool_used
tool: Skill
input_match: '"skill"\s*:\s*"(?:[\w-]+:)?spec"'
min: 1
---

The `spec` skill fires — every grader below measures what it writes, so a run where it never loaded fails here rather than silently failing the rest.
