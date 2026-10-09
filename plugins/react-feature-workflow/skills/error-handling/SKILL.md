---
name: error-handling
description: Who owns an error in this stack — the cache owns request errors, one owner per action notification, the resolver owns client form rules, a catch translates/recovers/rethrows with a real outcome. Use when writing a try, a catch, an error state, a toast, a retry or a fallback, or reviewing any hunk that contains one.
---

# Error handling

Each rule with the hunk it replaces: [references/recipes.md](references/recipes.md). Which
query state to read, when a boundary takes the error, and where a mutation's callbacks go are
the `tanstack-query` skill's rules (§States, §Mutations); this skill only says who owns the
error and what a `catch` may do with it.

- **The cache owns request errors.** A `try/catch` inside a `queryFn` that mirrors the error
  into state is a second copy of the cache; one that swallows is a deleted error. Render the
  cache's states, not your own.
- **`?? []` and `?.` are fine on a value the contract makes optional.** They are a finding
  when they stand in for the error branch or paper over a required field — a failed load then
  renders as an empty list.
- **One owner per user notification.** For an action that is the mutation hook's `onError`.
  A `catch` around an awaited mutation is the caller's control flow — stop the chain, keep the
  dialog open — never a second toast. Overriding a callback on spread options must call the
  one it replaces, or the rollback it carried is gone.
- **The resolver owns client rules; `setError` owns what only the server knows** — a field
  from the API response, or `root.*` for the whole form. Moving a check into the schema must
  not change the payload: a validation that only checked becomes a transform only on purpose.
- **A `catch` translates, recovers to an explicit outcome, or rethrows after doing work.**
  "Recover" never means returning something the caller reads as success. Log-and-continue and
  an empty catch are deleted errors; a catch that only rethrows is a `try` to delete.
- **Classify before messaging:** known HTTP status, network/timeout, cancelled, unknown.
  Unknown is not network, and an unmapped 4xx is not a server error. One generic toast for
  every class leaves the user without a next step.
- **Retry = failure kind × operation safety.** Network, timeout, `429` with `Retry-After` and
  5xx are candidates — only on a read, or a write the server deduplicates by an idempotency
  key sent unchanged on every attempt. Read what the HTTP client and the shared `QueryClient`
  already retry before adding a layer.
- **Catch only what can throw here.** Open the callee; a `try` with a placeholder result like
  `"—"` needs a named failure it is handling.

## Reviewing

Name the consequence, not the construct. A `try/catch`, a fallback, an optional chain or a
local `onError` is not a finding by itself — say which of these it causes:

- **lost error** — log-and-continue, empty catch, `queryFn` that swallows, `?? []` where the
  error branch should be
- **false success** — a catch that returns a value the caller treats as done, a follow-up that
  runs before the write landed
- **duplicate notification** — toast in the handler and in `onError`, local `onError` beside
  a `MutationCache`/`QueryCache` handler that already toasts
- **wrong UI state** — data read before the pending branch, a refetch error blanking data the
  cache still holds, a success toast on a conflict
- **unsafe retry** — a retried non-idempotent write, a retry that ignores `Retry-After`, an
  unknown error classified as network and retried
- **lost callback** — `...options, onError` that drops the rollback the options carried

## Overlap with the project's lint

A line the project's own lint reported in this review session goes under Checks and is
not re-derived. A rule merely present in the config is not proof it ran: without that
diagnostic in hand, the finding stands.
