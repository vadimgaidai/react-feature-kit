---
type: regex
target: last_message
pattern: '(?i)(find|scan|search|lookup)[\s\S]{0,80}?(per row|per element|each row|every row|for each|repeated|inside the loop|in the loop|n ?[x×] ?m)|(lookup map|Map\(|new Map|built once)'
flags: i
---

The report flags the `tones.find(...)` repeated for every `row` in `badgeSize` as repeated
work — a scan over a second collection per element, or that it should be a lookup built
once. Naming it "a nested loop" is not enough on its own: `code-shape` does not forbid
nested traversal, it forbids repeated work.
