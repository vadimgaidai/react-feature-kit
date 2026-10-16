---
name: routing
description: URL state, search params, Back/Forward, nested routes, and how a route meets the query cache. Use when building or reviewing navigation, a loader, search params, pagination restored from the URL, a route-level loading/error state, or any hook (`use-*-filters`, `use-*-sort`) whose values come from the URL, whatever folder it sits in.
---

# Routing

Code shapes: [references/search-params.md](references/search-params.md),
[references/loader-and-query.md](references/loader-and-query.md). This skill owns URL state
and route-level loading/error states. Placement of route files: the structure skill loaded in
this project. Query shape inside a loader or a component: the `tanstack-query` skill.

Check `package.json` once per session for the router in use (React Router, TanStack Router) —
the mechanism names below (`useSearchParams`, `useNavigation`, `errorElement` vs a route's own
`errorComponent`/`loader`) are the router's own API and differ between them.

## URL as the source of truth

- Filters, sort and pagination are restored from the URL on load, so a shared link opens the
  same screen the sender saw. State derived from the URL is read from it on every render, not
  copied into `useState` once on mount — a copy stops tracking Back and Forward.
- Updating one search param merges with the current ones; it never replaces the whole search
  string, or a filter change silently drops the sort the user had picked. The hook's setter
  takes a patch of the fields that change, never the whole filter state re-passed.
- Back and Forward changing the URL must change the rendered UI with no extra step — if it
  doesn't, something read the URL into state once instead of on every render.

## Routes and the query cache

- A route loader and a component's query must not hold two independent copies of the same
  data. The loader prefetches into the query cache (`queryClient.ensureQueryData`), and the
  component reads the same query — never a loader that returns its own fetched object for the
  component to store separately.
- Navigation pending and error states use the router's own mechanism — a loading indicator
  driven by the router's own pending/transition state, and a route's own error boundary or
  `errorElement` — never a parallel `isNavigating` flag kept in component state.
- Nested routes own their own loading boundary. A child route's fetch does not blank the
  parent's already-rendered chrome; only the child's own region shows its pending state.

## Reviewing

In order of how often it hurts:

- a filter, sort or page number not restored from the URL on load
- updating one search param that drops the others instead of merging
- a filters setter that takes the whole state instead of a patch, or that writes a filter's
  off value (`false`, `[]`) as a param instead of deleting it
  (`references/search-params.md`)
- URL-derived state copied into `useState` once instead of read on every render
- Back/Forward not changing the rendered UI
- a loader and a component's query holding two independent copies of the same data
- a navigation pending or error flag kept in component state instead of the router's own
  mechanism
- a child route's fetch blanking the parent's already-rendered chrome
