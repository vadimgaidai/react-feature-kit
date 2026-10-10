---
type: regex
target: last_message
pattern: 'comment-list\.tsx:\d+[\s\S]{0,600}?(try|catch|\?\?)[\s\S]{0,400}?(cannot throw|can.t throw|never (throws|undefined|null)|required prop|prop type|internal data|not external|rules out|always an array|non-optional|plausible)'
flags: i
---

Q5: `comments.map` on a required prop cannot throw and `comments ?? []` guards a state the prop type rules out. `comments` is internal data (a required prop, not a fetch result), so the type *is* the guarantee here — the finding must say so, or mark the defence PLAUSIBLE and say what would settle it.
