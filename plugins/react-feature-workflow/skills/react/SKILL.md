---
name: react
description: React 19 and React Compiler rules — where state belongs, when memoization is warranted, what effects are actually for, refs and context, error boundaries, and how to split code with lazy + Suspense. Use when writing or reviewing React components, adding a route/modal/heavy widget, chasing a re-render problem, or reaching for useEffect/useMemo/useCallback/useRef/useContext.
---

# React 19

Code shapes, before and after: [references/effects.md](references/effects.md),
[references/state-and-rendering.md](references/state-and-rendering.md),
[references/code-splitting.md](references/code-splitting.md),
[references/actions.md](references/actions.md).

## Where state belongs

Most re-render problems are placement problems; memoization fixes none of them.

- Push state down to the subtree that reads it; lift only to the closest common ancestor.
- Server data lives in the query cache, URL state in the query string, anything computable
  from props or state in render.
- Group state that always changes together; split state that changes independently.
- A value that never triggers a render — an id, a timer handle, the previous value — is a ref.

## Effects

An effect synchronizes with something outside React. That is the whole list.

- Derived state is computed in render; an event's side effect lives in its handler; fetching
  belongs to the query cache.
- `key` resets state on identity change before an effect does.
- Every effect that subscribes, opens or schedules returns a cleanup.

## Memoization and rendering

The Compiler removes the reflex, not the responsibility.

- Memoize when the work is expensive **and** the inputs are stable; churning deps are a dead
  cache. Fix the algorithm before caching its result.
- A `find`/`filter` over a second collection repeated per rendered item is a lookup built
  once (`code-shape` §Collections; a loop by itself is not the problem). No `key={index}` on
  a list that reorders, filters or grows.
- Hoist static JSX and objects; never define a component inside another's render.
- `useState(() => expensive())` for real work; functional `setState` when the next value
  depends on the previous.

## Refs and context

- A ref survives re-renders without causing them. Never read or write `ref.current` during
  render. `ref` is a plain prop; a ref callback may return a cleanup.
- Context is for ambient, rarely-changing values — theme, locale, session, a `FormProvider`.
  Every consumer re-renders on change, so split a churning value from a stable one, and try
  `children` composition before adding one.
- `<ThemeContext value={theme}>` is the provider; `use(Context)` may be called conditionally.

## Code splitting and boundaries

- Lazy: routes, the *content* of modals, drawers and popovers, heavy third-party widgets,
  anything behind a tab, wizard step or permission check. Never: above the fold, or a
  component smaller than the request.
- One `<Suspense>` per route plus one per independently-loading region, with a fallback the
  shape of the content. Preload on hover/focus; `useTransition` around a route swap.
- Every Suspense boundary has an error boundary beside it, and retrying resets the boundary.

## Actions, transitions and `use`

- `useTransition` owns the pending flag for non-form async work; `useOptimistic` for a local
  optimistic value — cache-owned values use the mutation's `onMutate` instead.
- `useActionState`, `<form action>` and `useFormStatus` have no place beside React Hook Form
  + Zod, not even for one field — [references/actions.md](references/actions.md) says what breaks.
- `use(promise)` needs a promise created outside render; `use` is not a fetching hook.

## React 19 specifics

No `forwardRef`; `<title>`, `<meta>` and `<link>` hoist to `<head>`; no blanket `memo`.

## Reviewing

In order of how often it hurts:

- a redundant effect — any shape in [references/effects.md](references/effects.md)
- state above the only subtree that reads it, or duplicating cached server data
- a scan over a second collection repeated per rendered item
- a memo whose deps churn
- an index key on a dynamic list
- a context whose value churns every render
- a route, modal or heavy widget imported eagerly
- a Suspense boundary with no error boundary beside it
- a ref read during render
