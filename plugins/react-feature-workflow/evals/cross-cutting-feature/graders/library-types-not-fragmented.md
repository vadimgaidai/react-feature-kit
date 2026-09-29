---
type: tool_used
tool: Bash
input_match: 'react-tour-lib/dist'
min: 0
max: 3
---

The library's 750-line declaration file is read at most a few times, not grepped a dozen times. The real session made 14 shell calls on one `.d.mts` because the long-read guard refused the whole read and the shell guard refused `grep | head`; both are fixed, and this is the regression check.
