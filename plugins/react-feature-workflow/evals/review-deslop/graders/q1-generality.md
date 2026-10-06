---
type: regex
target: last_message
pattern: 'format\.ts:\d+[\s\S]{0,600}?createFormatter[\s\S]{0,400}?(one call|single call|nobody|never (passed|varied|used)|not varied|no caller|unused option|only.{0,20}default)'
flags: i
---

Q1: `createFormatter` and its `FormatterOptions` exist for one operation whose separator and case never vary. The finding names the factory at its line and says what is never used.
