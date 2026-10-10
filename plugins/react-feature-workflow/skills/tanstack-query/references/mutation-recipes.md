# Mutation Recipes

> Canonical code shape. Replace the placeholders (`[entity]` kebab-case, `[feature]` kebab-case, `[Entity]` PascalCase, `I[Entity]` type identifiers) with real names. Real infrastructure (`queryClient`) keeps its real name.
>
> The plain mutation + invalidation shape lives in the structure skill's `mutations.md`. This file covers the cases beyond it.

## Targeted invalidation

Sweeping the entity on every write refetches lists that did not change. Match the breadth of the invalidation to the breadth of the change:

Invalidate the edited item, and every list that might contain it:

```typescript
onSuccess: (_data, variables) => {
  queryClient.invalidateQueries({ queryKey: [entity]Keys.byId(variables.id) })
  queryClient.invalidateQueries({ queryKey: [entity]Keys.lists() })
}
```

`lists()` is the unfiltered parent key — it matches every filter combination by prefix. Do **not** write `list({})` here: that only works because TanStack partial-matches an empty object against any filters, and it stops working the moment anyone passes `exact: true`.

Create and delete change *which* items exist, so nothing narrower than the entity is safe — `[entity]Keys.all()` is correct there. Edit changes one known item, so it is not.

`invalidateQueries` marks matching queries stale and refetches the **active** ones; inactive ones refetch when something mounts them. That is the desired behaviour — don't reach for `refetchQueries` to force the rest.

## Writing the server's response into the cache

Only with the complete object the server just returned:

```typescript
onSuccess: (updated: I[Entity]) => {
  queryClient.setQueryData([entity]Keys.byId(updated.id), updated)
  queryClient.invalidateQueries({ queryKey: [entity]Keys.lists() })
}
```

The detail view updates without a round trip; the lists still refetch, because this response says nothing about ordering, totals or which page the item now belongs to. Writing a locally-assembled object here is how a screen ends up rendering a field the API never returned.

## Optimistic update with rollback

For cheap, reversible, high-frequency actions only — a toggle, a reorder, a like:

Three steps in `onMutate`: stop in-flight refetches from landing on top of the optimistic value, snapshot the previous value for rollback, then apply the expected result — once, here, never reapplied on the server response.

```typescript
export const useToggle[Entity]Mutation = () => {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: [feature]Api.toggle,
    onMutate: async (id: string) => {
      await queryClient.cancelQueries({ queryKey: [entity]Keys.byId(id) })

      const previous = queryClient.getQueryData<I[Entity]>([entity]Keys.byId(id))

      queryClient.setQueryData<I[Entity]>([entity]Keys.byId(id), (old) =>
        old ? { ...old, isActive: !old.isActive } : old
      )

      return { previous }
    },
    onError: (_error, id, context) => {
      queryClient.setQueryData([entity]Keys.byId(id), context?.previous)
    },
    onSettled: (_data, _error, id) => {
      queryClient.invalidateQueries({ queryKey: [entity]Keys.byId(id) })
    },
  })
}
```

All four steps are load-bearing. Skipping `cancelQueries` lets a refetch that started before the click overwrite the optimistic value; skipping the snapshot leaves no rollback; skipping `onSettled` leaves the cache holding a guess.

**The cheaper alternative:** when the optimistic value is visible in exactly one component, don't touch the cache at all — render from `isPending`.

```tsx
const toggle = useToggle[Entity]Mutation()
const isActive = toggle.isPending ? !item.isActive : item.isActive
```

React 19's `useOptimistic` covers the same ground for a value that lives in component state rather than the query cache — see the `react` skill.

## Concurrent mutations on the same key

Two toggles fired before either settles race the rollback: the naive version snapshots
`previous` once per `onMutate` call, so the second mutation's `onError` restores the value from
*before the first mutation*, erasing whatever the first one already committed.

```typescript
onMutate: async (id: string) => {
  await queryClient.cancelQueries({ queryKey: [entity]Keys.byId(id) })
  const previous = queryClient.getQueryData<I[Entity]>([entity]Keys.byId(id))
  queryClient.setQueryData<I[Entity]>([entity]Keys.byId(id), (old) =>
    old ? { ...old, isActive: !old.isActive } : old
  )
  return { previous }
},
onError: (_error, id, context) => {
  const current = queryClient.getQueryData<I[Entity]>([entity]Keys.byId(id))
  if (current?.isActive !== context?.previous?.isActive) {
    queryClient.setQueryData([entity]Keys.byId(id), context?.previous)
  }
},
onSettled: (_data, _error, id) => {
  queryClient.invalidateQueries({ queryKey: [entity]Keys.byId(id) })
},
```

The guard in `onError` rolls back only if the cache still holds *this* mutation's optimistic
value — a later mutation may already have overwritten it with its own, and restoring
`context.previous` over that would erase the later one's state.

The cheaper alternative, and the one to prefer when the action can legitimately fire twice in
a row: skip the rollback write entirely and let `onSettled`'s invalidation reconcile the cache
with the server — correct under any number of concurrent calls, at the cost of one extra
refetch.

## Mutation state read elsewhere

When a header or toolbar needs to know a mutation is running somewhere else in the tree, give the mutation a `mutationKey` and read it — don't lift the hook or thread a prop:

```typescript
const pendingCount = useMutationState({
  filters: { mutationKey: [feature]Keys.submit(), status: "pending" },
  select: (mutation) => mutation.state.variables,
}).length
```

## Sequencing after a mutation

Navigation, toasts and storage writes go in the hook's `onSuccess`, or in `mutate`'s per-call callbacks when the follow-up is specific to one call site:

```typescript
mutate(payload, {
  onSuccess: (created) => navigate(paths.[entity].details(created.id)),
})
```

Never watch `isSuccess` in a `useEffect` to trigger the follow-up — it re-fires on re-mount and on every re-render where the flag is still true.

**`mutate` does not throw.** Errors reach `onError` and the `error` field. Use `mutateAsync` only when you genuinely need to `await` the result inside a larger async flow, and then it does throw — an unhandled `mutateAsync` rejection is an unhandled promise rejection.
