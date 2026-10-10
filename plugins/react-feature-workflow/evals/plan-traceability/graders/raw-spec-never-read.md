---
type: regex
target: trace
pattern: 'rawSpecUniqueToken'
match: not_contains
---

The raw OpenAPI file never enters the window: the contract slice is the only shape source, and the guard hook refuses the file by `Read` or through the shell.
