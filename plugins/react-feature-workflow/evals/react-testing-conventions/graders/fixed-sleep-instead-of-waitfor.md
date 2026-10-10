---
type: regex
target: last_message
pattern: 'setTimeout\(resolve, ?500\)|arbitrary sleep|fixed (sleep|timer)|findBy|waitFor'
flags: i
---

The report flags `await new Promise((resolve) => setTimeout(resolve, 500))` as an arbitrary
sleep standing in for `findBy*`/`waitFor` to await async UI.
