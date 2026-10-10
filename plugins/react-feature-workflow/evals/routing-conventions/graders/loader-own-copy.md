---
type: regex
target: last_message
pattern: 'ordersLoader[\s\S]{0,120}?(ensureQueryData|two copies|useLoaderData)|useLoaderData[\s\S]{0,120}?ordersLoader'
flags: i
---

The report flags `ordersLoader` fetching and returning its own data for `useLoaderData`
instead of prefetching into the query cache with `ensureQueryData`, which the component would
then read via `useQuery` — two independent copies of the same data.
