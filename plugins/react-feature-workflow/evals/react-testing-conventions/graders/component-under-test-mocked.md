---
type: regex
target: last_message
pattern: 'vi\.mock\("\./online-indicator|mock(s|ed|ing)[\s\S]{0,60}?(component|OnlineIndicator)[\s\S]{0,60}?under test'
flags: i
---

The report flags `vi.mock("./online-indicator", ...)` mocking the very component the test
file is for, which makes the "renders online" assertion pass against the mock's own JSX
instead of the real component.
