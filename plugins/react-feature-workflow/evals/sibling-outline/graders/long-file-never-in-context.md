---
type: regex
target: trace
pattern: 'legacy shape 2\d\d'
match: not_contains
---

The middle of the 400-line type file never entered the window. Lines 200–299 are what a
whole read brings in and what no range read of the head or the tail would touch.
