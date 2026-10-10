---
type: regex
target: last_message
pattern: 'fullName[\s\S]{0,700}?(determined by|derived from|computed from|first[\s\S]{0,30}last)[\s\S]{0,700}?(derive|during render|compute[\s\S]{0,20}render|drop the state|remove the state|no state)'
flags: i
---

One finding checked for all three parts, on the clearest planted case: `fullName` (what),
determined by `first` and `last` (why not here), derive it during render (fix). A report that
only names the pattern ("effect sets state") fails here.
