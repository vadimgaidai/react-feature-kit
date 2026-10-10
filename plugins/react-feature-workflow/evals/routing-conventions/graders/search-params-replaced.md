---
type: regex
target: last_message
pattern: 'setSearchParams\(\{ ?status|drops?[\s\S]{0,40}?(other )?params|replac(e|ing)[\s\S]{0,40}?search'
flags: i
---

The report flags `setSearchParams({ status: next })` for replacing the whole query string
instead of merging, which would silently drop any other param already in the URL.
