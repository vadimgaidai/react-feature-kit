# Error handling recipes

> Canonical code shape. Replace the placeholders (`[entity]`, `[Entity]`, `I[Entity]`) with real
> names. Every user-facing string is a `t()` key; `t` comes from `useTranslation()` in the
> component. Where the cache's own error states live: the `tanstack-query` skill. `HTTPError`
> and `TimeoutError` are the `ky` classes the project's `httpClient` throws.

## A request error is a query state

```tsx
const [error, setError] = useState<Error | null>(null)
const { data } = useQuery({
  ...[entity]Queries.list(filters),
  queryFn: async (ctx) => {
    try {
      return await [entity]Api.getList(filters, ctx)
    } catch (e) {
      setError(e as Error)
      throw e
    }
  },
})

return <[Entity]List items={data.items} />
```

Two bugs: the cache already holds `error`, and `data` is `undefined` while pending, so
`data.items` throws on first render. Render the cache's states instead — which ones, and when
a boundary takes the error, is `tanstack-query` §States:

```tsx
const { data, isPending, isLoadingError, isRefetchError, error, refetch } = useQuery(
  [entity]Queries.list(filters),
)

if (isPending) {
  return <[Entity]ListSkeleton />
}

if (isLoadingError) {
  return <ErrorState error={error} onRetry={refetch} />
}

if (data.items.length === 0) {
  return <EmptyState title={t("[entity].empty")} />
}

return (
  <>
    {isRefetchError && <InlineAlert message={t("errors.refreshFailed")} onRetry={refetch} />}
    <[Entity]List items={data.items} />
  </>
)
```

What this skill cares about: the failed first load has its own branch, the empty response has
its own copy, and a refetch error does not blank data the user already has. `data?.items ??
[]` would have rendered the empty state for a failed first load — that is the fallback to
flag, not the operator. With `useSuspenseQuery` the boundary beside the Suspense boundary
owns the error; its reset shape is in the `react` skill, references/code-splitting.md, "Error
boundary with a real retry".

## One owner for the action's toast

```tsx
const { mutateAsync } = useMutation({
  ...[entity]Mutations.update(),
  onError: (error) => toast.error(t(describe(error).messageKey)),
})

const onSubmit = async (values: T[Entity]Form) => {
  try {
    await mutateAsync(values)
    onClose()
  } catch {
    toast.error(t("[entity].errors.save"))
  }
}
```

Two toasts for one failure. The hook owns the notification; the call site's follow-up goes
where `tanstack-query` §Mutations puts it:

```tsx
const onSubmit = (values: T[Entity]Form) => mutate(values, { onSuccess: onClose })
```

Nothing to catch: failure reaches the hook's `onError`, and the dialog stays open because
`onSuccess` never ran.

Where a chain genuinely awaits a previous result, the catch is the caller's control flow, not
a second toast:

```tsx
const onSubmit = async (values: T[Entity]Form) => {
  try {
    const { fileId } = await upload.mutateAsync(values.file)
    await save.mutateAsync({ ...values, fileId })
    onClose()
  } catch {
    // ! each hook's onError already notified; stop the chain, stay open
  }
}
```

Adding `onError` on top of spread options:

```tsx
const options = [entity]Mutations.toggle()

useMutation({
  ...options,
  onError: (...args) => {
    options.onError?.(...args)
    toast.error(t(describe(args[0]).messageKey))
  },
})
```

Without the first line the spread `onError` — and the optimistic rollback it performs — is
replaced, not extended. If a `MutationCache` `onError` on the shared client already toasts,
there is no local toast at all.

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
title: z.string().refine((value) => value.trim().length > 0, "[entity].form.titleRequired")
```

The schema carries the key, the field renders `t(error.message)`, and the payload is
unchanged: the original check only inspected the value. `z.string().trim().min(1, …)` would
also strip whitespace from what is sent — a normalization, which the `react-hook-form-zod`
skill puts in `onSubmit` when building the payload, and which is a separate decision from
moving the rule.

`setError` is for what only the server knows, set from the mutation's `onError`:

```tsx
onError: (error) => {
  const field = fieldFromApiError(error)

  if (field) {
    setError(field.name, { type: "server", message: field.messageKey })
    return
  }

  setError("root.serverError", { message: describe(error).messageKey })
},
```

Render the root one with `t(errors.root?.serverError?.message)`. Root errors are cleared on
the next submit; field errors set this way persist until the field re-validates.

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

Recover — to an outcome the caller can read, never to a value that looks like success:

```ts
const publish = async (id: string): Promise<TPublishOutcome> => {
  try {
    await [entity]Api.publish(id)
    return { status: "published" }
  } catch (error) {
    if (isConflict(error)) {
      await queryClient.invalidateQueries({ queryKey: [entity]Keys.byId(id) })
      return { status: "conflict" }
    }
    throw error
  }
}
```

`return refetch()` here would hand the caller fresh data and a resolved promise — a success
toast on a publish that never happened. The caller branches on `status` and shows the conflict
copy with the refreshed entity.

Rethrow after work:

```ts
catch (error) {
  restoreDraft(snapshot)
  throw error
}
```

The catch did something the caller cannot: undo local state. A catch whose body is only
`throw error` did nothing, and the `try` is deleted.

## Classify before messaging

```ts
const describe = (error: unknown): IErrorDescription => {
  if (!(error instanceof HTTPError)) {
    return { messageKey: "errors.network", retryable: true }
  }

  const { status } = error.response
  const messageKey = MESSAGE_KEY_BY_STATUS[status] ?? "errors.server"

  return { messageKey, retryable: status >= 500 }
}
```

A `TypeError` from a bug, a `ZodError` from a bad contract and an aborted request all become
"network, retry", and an unmapped `422` becomes "server error". Four classes, each its own
text and its own retry answer:

```ts
const MESSAGE_KEY_BY_STATUS: Record<number, string> = {
  403: "[entity].errors.forbidden",
  409: "[entity].errors.conflict",
  429: "errors.rateLimited",
}

const describe = (error: unknown): IErrorDescription => {
  if (error instanceof HTTPError) {
    const { status, headers } = error.response
    const isServer = status >= 500
    const retryAfterMs = status === 429 ? parseRetryAfter(headers.get("Retry-After")) : undefined

    return {
      kind: "http",
      messageKey: MESSAGE_KEY_BY_STATUS[status] ?? (isServer ? "errors.server" : "errors.request"),
      retryable: isServer || status === 429,
      retryAfterMs,
    }
  }

  if (error instanceof TimeoutError || error instanceof TypeError) {
    return { kind: "network", messageKey: "errors.network", retryable: true }
  }

  if (error instanceof DOMException && error.name === "AbortError") {
    return { kind: "cancelled", messageKey: null, retryable: false }
  }

  return { kind: "unknown", messageKey: "errors.unexpected", retryable: false }
}
```

`fetch` rejects a network failure with a `TypeError`; `ky` adds `TimeoutError`. A cancelled
request gets no toast — the user navigated away. Unknown is reported, not retried, and the
original error is kept for the error reporter. The UI reads `retryable` and `retryAfterMs` to
choose between a retry button, a wait, and a dismissable message.

## Retry is failure kind × operation safety

```ts
mutationOptions({ mutationFn: [entity]Api.publish, retry: 2 })
```

A retried `POST` that succeeded the first time is a duplicate. Two inputs decide a retry: the
failure must be transient (network, timeout, `429` after `Retry-After`, 5xx), and repeating
the operation must be safe. Reads are safe; a write is safe only when the server deduplicates
it by an idempotency key, and the same key is sent on every attempt:

```ts
mutationOptions({
  mutationFn: ({ id, idempotencyKey }: IPublishInput) =>
    [entity]Api.publish(id, { headers: { "Idempotency-Key": idempotencyKey } }),
  // server dedupes by Idempotency-Key, so a repeat is safe
  retry: (failureCount, error) => failureCount < 2 && describe(error).retryable,
})
```

The key is generated once per user intent, not per attempt. `ky` already retries `GET`, `PUT`
and `DELETE` on `408`/`413`/`429`/5xx and honours `Retry-After`; `POST` is never retried
there. What the shared `QueryClient` retries, and the comment an override needs, is
`tanstack-query` §Read the shared client.

## Catch what can throw here

```ts
try {
  const total = items.reduce((sum, item) => sum + item.price, 0)
  return formatAmount(total)
} catch {
  return "—"
}
```

Open `formatAmount`. If it is `Intl.NumberFormat` with a currency code from the data, an
unknown code throws a `RangeError` — then the catch handles a named failure and says so:

```ts
catch (error) {
  if (error instanceof RangeError) {
    return t("errors.badCurrency")
  }
  throw error
}
```

If it only concatenates strings, nothing in the block throws, the `try` documents a fear, and
`"—"` would hide a wrong total behind a dash. Either way the decision comes from the callee,
not from the shape of the block.
