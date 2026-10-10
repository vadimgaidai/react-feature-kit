---
name: react
description: React 19 and React Compiler rules — where state belongs, when memoization is warranted, what effects are actually for, refs and context, error boundaries, and how to split code with lazy + Suspense. Use when writing or reviewing React components, adding a route/modal/heavy widget, chasing a re-render problem, or reaching for useEffect/useMemo/useCallback/useRef/useContext.
---

# React 19

Code shapes, before and after: [references/effects.md](references/effects.md),
[references/state-and-rendering.md](references/state-and-rendering.md),
[references/code-splitting.md](references/code-splitting.md),
[references/actions.md](references/actions.md), [references/lifecycle.md](references/lifecycle.md).

## Where state belongs

Most re-render problems are placement problems; memoization fixes none of them.

- Push state down to the subtree that reads it; lift only to the closest common ancestor.
- Server data lives in the query cache, URL state in the query string, anything computable
  from props or state in render.
- Group state that always changes together; split state that changes independently. Two
  flags that can both be true (`isLoading` and `isError` together) are a union of states, not
  two booleans — `typescript` skill, discriminated unions.
- A value that never triggers a render — an id, a timer handle, the previous value — is a ref.
- **Render stays pure.** No mutation, toast, navigation or storage write while rendering —
  each belongs in a handler or an effect. Props, state and query data are read-only: no
  `sort`/`reverse`/`splice`/property assignment on them; a sorted or filtered view is a new
  array ([references/lifecycle.md](references/lifecycle.md) §Immutability).

## Effects

An effect synchronizes with something outside React. That is the whole list.

- Derived state is computed in render; an event's side effect lives in its handler; fetching
  belongs to the query cache.
- `key` resets state on identity change before an effect does — for a draft copied from a
  prop on purpose, not a workaround for one synced by mistake (references/lifecycle.md).
- Every effect that subscribes, opens or schedules returns a cleanup, and a second setup
  after cleanup creates nothing extra; a `hasRun` flag guards firing, not releasing.
- A response arriving after the input it answered has changed is stale: compare it against
  the current input before using it, or let the query cache's key change do that for you.

## Memoization and rendering

The Compiler removes the reflex, not the responsibility. A `useMemo`/`useCallback` buys an
expensive computation or a reference something depends on for stability; neither, remove it.

- Memoize when the work is expensive **and** the inputs are stable; churning deps are a dead
  cache. Fix the algorithm before caching its result.
- A `find`/`filter` over a second collection repeated per rendered item is a lookup built
  once (`code-shape` §Collections; a loop by itself is not the problem). No `key={index}` on
  a list that reorders, filters or grows; a replaced search keeps order, duplicates and
  missing values.
- Hoist static JSX and objects; never define a component inside another's render — a
  component type that changes identity between renders remounts its subtree, the same loss
  of state as a `key` that changes for the wrong reason.
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
- Every Suspense boundary has an error boundary beside it; a query's retry and a failed
  chunk's retry are different mechanisms — references/code-splitting.md.

## Actions, transitions and `use`

- `useTransition` owns the pending flag for non-form async work; `useOptimistic` for a local
  optimistic value — cache-owned values use the mutation's `onMutate` instead.
- `useActionState`, `<form action>` and `useFormStatus` have no place beside React Hook Form
  + Zod, not even for one field — [references/actions.md](references/actions.md) says what breaks.
- `use(promise)` needs a promise created outside render; `use` is not a fetching hook.

## React 19 specifics

No `forwardRef`; `<title>`, `<meta>` and `<link>` hoist to `<head>`; no blanket `memo`; `ref`
is a plain prop; `<Context value>` instead of `<Context.Provider value>`. These are React 19's
API — check `package.json` once in the session before applying one; an 18 project still needs
`forwardRef` and `Context.Provider`.

## Reviewing

In order of how often it hurts:

- a redundant effect — any shape in [references/effects.md](references/effects.md)
- state above the only subtree that reads it, or duplicating cached server data
- a mutation, toast, navigation or storage write during render
- props, state or query data mutated in place instead of copied
- a scan over a second collection repeated per rendered item
- a memo whose deps churn, or a `useMemo`/`useCallback` that buys neither a real computation
  nor a stable reference anything depends on
- an index key on a dynamic list, a component defined inside another's render, or a `key`
  that changes for the wrong reason — each resets state the user did not ask to lose
- a subscription, timer or listener with no cleanup, or a `hasRun` flag standing in for one
- a stale async result (a late search or save) rendered over a screen that has since changed
- two state flags that can both be true where a union of states was meant
- a context whose value churns every render
- a route, modal or heavy widget imported eagerly
- a Suspense boundary with no error boundary beside it, or a retry that re-throws the same
  cached error/rejection instead of actually resetting
- a ref read during render
