---
name: error-handling
description: Where errors live in this stack — the query cache owns request errors, the mutation hook owns action errors, the resolver owns form errors, a catch translates/recovers/rethrows. Use when writing a try, a catch, an error state, a toast, or a fallback, or reviewing any hunk that contains one.
---

# Error handling

Each rule with the hunk it replaces: [references/recipes.md](references/recipes.md).

- **The query cache owns request errors** — `isError` / `throwOnError` plus an error boundary
  (`tanstack-query` §States). A `try/catch` around a `queryFn` that re-throws is noise; one
  that swallows is a bug.
- **The mutation hook owns action errors** — in `onError`, not the submit handler, not an
  effect watching `isError`.
- **The resolver owns form errors.** A manual `setError` for something the schema could say
  is a schema gap.
- **A `catch` translates, recovers or rethrows.** Log-and-continue is none of them; an empty
  catch is a deleted error.
- **Fallbacks hide bugs.** `?? []` on a required list, `?.` on a value that cannot be null, a
  default object for a failed fetch — each turns a loud failure into a wrong screen.
- **4xx is a message to the user, 5xx and network are a retry.** Say which in the UI; never
  one generic toast for both.
- **No try/catch around code that cannot throw**, and no retry on a non-idempotent call.

## Reviewing

In order of how often it hurts:

- a catch that logs and continues
- a try/catch in a component body
- a local `onError` re-handling what the shared cache already handles
- `??` / `?.` silencing a value the contract marks required
- one toast for every failure class
- a fetch error state missing a retry

## Lint owns

`no-empty` (catch), `@typescript-eslint/no-floating-promises`,
`prefer-promise-reject-errors` — don't re-report any of these.
