---
type: regex
target: last_message
pattern: 'authorEmail[\s\S]{0,300}?(?:contract|not (?:in|defined|listed|part))|(?:contract|not (?:in|defined|listed|part))[\s\S]{0,300}?authorEmail'
flags: i
---

The report names `authorEmail` as the field the contract does not define — the field and the
word "contract" (or "not in / defined / listed") within a few lines of each other. A regex,
not a judge: on 2026-09-29 three haiku votes failed a report whose first finding read
"`authorEmail` is not in the contract", and three votes at temperature zero are one vote.
