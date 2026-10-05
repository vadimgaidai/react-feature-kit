# Error handling recipes

> Canonical code shape. Replace the placeholders (`[entity]`, `[Entity]`, `I[Entity]`) with real
> names. Every user-facing string is a `t()` key; `t` comes from `useTranslation()` in the
> component. Where the cache's own error states live: the `tanstack-query` skill.

## A request error is a query state

```tsx
const [error, setError] = useState<Error | null>(null)
const { data } = useQuery({
  ...[entity]Queries.byId(id),
  queryFn: async (ctx) => {
    try {
      return await [entity]Api.getById(id, ctx)
    } catch (e) {
      setError(e as Error)
      throw e
    }
  },
})
```

The cache already holds the error. Read it, or let the boundary take it:

```tsx
const { data, isError, error, refetch } = useQuery([entity]Queries.byId(id))

if (isError) {
  return <ErrorState error={error} onRetry={refetch} />
}
```

```tsx
const { data } = useSuspenseQuery([entity]Queries.byId(id))
```

With `useSuspenseQuery` the error boundary beside the Suspense boundary renders the retry
(`react` skill, references/code-splitting.md).

## An action error is `onError`

```tsx
const onSubmit = async (values: T[Entity]Form) => {
  try {
    await mutateAsync(values)
  } catch {
    toast.error(t("[entity].errors.save"))
  }
}
```

```tsx
const { mutate } = useMutation({
  ...[entity]Mutations.update(),
  onError: (error) => toast.error(t(describe(error).messageKey)),
})
const onSubmit = (values: T[Entity]Form) => mutate(values)
```

The handler stays a one-liner, the error surface is in the hook where retries and rollbacks
already are, and nothing watches `isError` from an effect.

## A form error is a schema rule

```tsx
const onSubmit = (values: T[Entity]Form) => {
  if (values.title.trim().length === 0) {
    setError("title", { message: "[entity].form.titleRequired" })
    return
  }
  mutate(values)
}
```

```ts
title: z.string().trim().min(1, "[entity].form.titleRequired")
```

The schema carries the key, the field renders `t(error.message)`. `setError` is for what only
the server knows — a taken slug, a stale version — set from the mutation's `onError` with the
field name the API returned.

## A catch does one of three things

```ts
try {
  await [entity]Api.publish(id)
} catch (error) {
  console.error(error)
}
```

Logged and forgotten; the caller believes it published.

Translate:

```ts
catch (error) {
  throw new PublishError(id, { cause: error })
}
```

Recover:

```ts
catch (error) {
  if (isConflict(error)) {
    return refetch()
  }
  throw error
}
```

Rethrow as-is: then there is nothing to catch, and the `try` is deleted.

## A fallback is a wrong screen

```tsx
const items = data?.items ?? []
const title = [entity]?.title ?? t("[entity].untitled")
```

If the contract marks `items` required and the fetch failed, the user sees an empty list and
no error. If `[entity]` cannot be null here, the `?.` hides the place where it became null.
Narrow at the boundary that can actually produce the empty case, and let the rest be loud:

```tsx
if (isError) {
  return <ErrorState error={error} onRetry={refetch} />
}

const { items } = data
```

## 4xx says, 5xx retries

```ts
const MESSAGE_KEY_BY_STATUS: Record<number, string> = {
  403: "[entity].errors.forbidden",
  409: "[entity].errors.conflict",
}

const describe = (error: unknown): IErrorDescription => {
  if (!(error instanceof HTTPError)) {
    return { messageKey: "errors.network", retryable: true }
  }

  const { status } = error.response
  const messageKey = MESSAGE_KEY_BY_STATUS[status] ?? "errors.server"

  return { messageKey, retryable: status >= 500 }
}
```

The UI reads `retryable` to choose between a retry button and a dismissable message, and
`t(messageKey)` for the text. One `toast.error(t("errors.generic"))` for every branch gives
the user no next step.

## Retry only what is idempotent

```ts
mutationOptions({ mutationFn: [entity]Api.publish, retry: 0 })
queryOptions({ queryFn: [entity]Api.getList, retry: 3 })
```

A retried `POST` that succeeded the first time is a duplicate. Reads retry; writes do not,
unless the endpoint takes an idempotency key.

## Nothing throws here

```ts
try {
  const total = items.reduce((sum, item) => sum + item.price, 0)
  return formatAmount(total)
} catch {
  return "—"
}
```

Arithmetic and a formatter over typed data cannot throw. The `try` documents a fear, not a
failure; delete it.
