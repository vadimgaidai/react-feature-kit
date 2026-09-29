---
type: tool_used
tool: Bash
input_match: 'pnpm (?:add|install|i)\b|npm (?:install|i)\b|yarn add'
min: 0
max: 0
---

The plan records the dependency as already installed; `implement` may not add what the plan does not name, and adds nothing the plan says is there.
