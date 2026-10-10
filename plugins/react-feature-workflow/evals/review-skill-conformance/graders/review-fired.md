---
type: tool_used
tool: Skill
input_match: '"skill"\s*:\s*"(?:[\w-]+:)?review"'
min: 1
---

The `review` skill fires — every finding below is measured against what the skill does, so
a run where it never loaded fails here rather than silently failing five regexes.
