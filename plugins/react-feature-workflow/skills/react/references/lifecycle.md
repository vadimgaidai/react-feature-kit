# Lifecycle: identity, staleness, cleanup, state models

> Canonical code shape. Replace the placeholders (`[Entity]`) with real names.

## Component identity: the accidental sync versus the intentional draft

**The bug** — an effect syncing a prop into state because the prop changed. `effects.md`
already shows this: the effect is extra renders and a stale frame for no reason, because the
component should either read the prop directly or let `key` reset it.

**The legitimate twin** — a component that copies a query value into state *on purpose*,
because the user edits a draft before saving it back. This is not a finding; the draft is the
component's own state, not a duplicate of the query's:

```tsx
const CommentEditor = ({ comment }: { comment: I[Entity] }) => {
  const [draft, setDraft] = useState(comment.body)
  const { mutate, isPending } = use[Entity]UpdateMutation()

  return (
    <form onSubmit={(event) => {
      event.preventDefault()
      mutate({ id: comment.id, body: draft })
    }}>
      <Textarea value={draft} onChange={(event) => setDraft(event.target.value)} />
      <SubmitButton isPending={isPending}>{t("actions.save")}</SubmitButton>
    </form>
  )
}

<CommentEditor key={comment.id} comment={comment} />
```

The rubric's test: does the component ever write the prop's *current* value back into state
on a dependency change? The bug does, every time, which makes the state a lagging copy. The
draft does not — it is seeded once per `comment.id` and then diverges from the prop on
purpose, until submit. `key={comment.id}` is what resets the draft when the editor is pointed
at a different comment; an effect that called `setDraft(comment.body)` on every `comment.body`
change would overwrite in-progress edits on a background refetch, which is the bug, not the
feature.

## Stale async results

A search box whose last keystroke's response can still outrun an earlier one. Without the
`ignore` guard below, the slower response wins however it lands:

```tsx
useEffect(() => {
  let ignore = false
  searchApi.search(query).then((results) => {
    if (!ignore) setResults(results)
  })
  return () => {
    ignore = true
  }
}, [query])
```

The `ignore` flag is the minimum fix for a hand-rolled effect: cleanup runs before the next
effect, so a response arriving after `query` changed again is dropped. The query cache does
the same thing by construction — a `useQuery` keyed on `query` discards a response for a key
that is no longer the active one, so prefer it over hand-rolled fetching entirely
(`tanstack-query` skill).

## Cleanup: with and without release

The first leaks — the listener survives the component:

```tsx
useEffect(() => {
  window.addEventListener("resize", handleResize)
}, [])
```

The second releases what it acquired:

```tsx
useEffect(() => {
  window.addEventListener("resize", handleResize)
  return () => window.removeEventListener("resize", handleResize)
}, [])
```

A `hasRun` ref that skips the body on the second call prevents a duplicate side effect; it
does not release whatever the first call acquired. Both problems can be present in the same
effect — guarding re-entry is not a substitute for a cleanup function.

## State model: a union instead of independent flags

The interface admits `isLoading: true`, `isError: true` and `data` present — all three at
once; the union admits exactly the three states that can occur:

```ts
interface I[Entity]State {
  isLoading: boolean
  isError: boolean
  data?: I[Entity]
}

type T[Entity]State =
  | { status: "loading" }
  | { status: "error"; error: Error }
  | { status: "success"; data: I[Entity] }
```

The query cache already returns a union (`tanstack-query` skill, §States) — this shape is for
local state that tracks a multi-step process (upload progress, a wizard) the cache doesn't
cover. The test: can two fields disagree about what is currently true? If so, the type should
have refused to let that value exist.
