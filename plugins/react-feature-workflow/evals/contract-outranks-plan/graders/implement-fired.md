---
type: tool_used
tool: Skill
input_match: '"skill"\s*:\s*"(?:[\w-]+:)?implement"'
min: 1
---

The `implement` skill fires when the request names it. A plain-language "build the plan"
request fired it in 2 of 6 runs on 2026-09-29, and only after the model had already read the
plan and explored the codebase — so the prompt names the skill and this grader is a sanity
check, not a discoverability measure.
