---
type: tool_used
tool: Read
input_match: 'article/model/types\.ts"(?![\s\S]*"limit")'
min: 0
max: 1
---

The 400-line type file is not read without a `limit`. One attempt is tolerated because the
long-read guard refuses it and the refusal still counts as a call; whether the file's body
reached the window is `long-file-never-in-context`'s job.
