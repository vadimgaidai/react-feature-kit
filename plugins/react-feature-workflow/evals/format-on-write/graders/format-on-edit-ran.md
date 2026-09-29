---
type: file_exists
path: .prettier-ran
---

`format-on-edit` ran after the write: the stub `prettier` the fixture installs records its
arguments in `.prettier-ran`, which nothing else creates. Without the plugin no hook runs
and the file never appears.
