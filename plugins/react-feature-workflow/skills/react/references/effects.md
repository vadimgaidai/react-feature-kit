# Effects you do not need

> Every shape here is the same defect: an effect doing work that belongs in render, a handler,
> the query cache or a subscription primitive. Each pair shows the effect and what replaces it.

## Derived state

```tsx
const [fullName, setFullName] = useState("")
useEffect(() => {
  setFullName(`${first} ${last}`)
}, [first, last])
```

Two renders per change and a frame where `fullName` is stale. Compute it:

```tsx
const fullName = `${first} ${last}`
```

If it is expensive, `useMemo` — still render, never state.

## Syncing a prop into state

```tsx
const [draft, setDraft] = useState(comment.body)
useEffect(() => {
  setDraft(comment.body)
}, [comment.body])
```

Either the prop is the value — read it — or the component owns a draft that should reset when
the entity changes, which is what `key` is for:

```tsx
<CommentEditor key={comment.id} comment={comment} />
```

## An event's side effect

```tsx
useEffect(() => {
  if (submitted) {
    toast.success(t("[entity].saved"))
  }
}, [submitted])
```

It happened because the user clicked, so it lives where the click is handled:

```tsx
const { mutate } = useMutation({
  ...[entity]Mutations.update(),
  onSuccess: () => toast.success(t("[entity].saved")),
})
```

## Calling `onChange` when state changes

```tsx
useEffect(() => {
  onChange(value)
}, [value, onChange])
```

Fires on mount with the initial value and once more per render where `onChange` is a new
closure. Call it in the handler that changes the value:

```tsx
const handleChange = (next: string) => {
  setValue(next)
  onChange(next)
}
```

## Fetching

```tsx
useEffect(() => {
  [entity]Api.getById(id).then(setItem)
}, [id])
```

No cancellation, no cache, a race when `id` changes mid-flight. The cache owns it:

```tsx
const { data: item } = useQuery([entity]Queries.byId(id))
```

## Mirroring server data into state

```tsx
const { data } = useQuery([entity]Queries.list(filters))
const [items, setItems] = useState<I[Entity][]>([])
useEffect(() => {
  if (data) {
    setItems(data)
  }
}, [data])
```

Two sources of truth that drift on the first invalidation. Read `data`; derive with `select`
when the shape differs (`tanstack-query` skill).

## Initializing on mount

```tsx
const [config, setConfig] = useState<Config | null>(null)
useEffect(() => {
  setConfig(buildConfig(props))
}, [])
```

A lazy initializer runs once and has no null frame:

```tsx
const [config] = useState(() => buildConfig(props))
```

## Chained effects

```tsx
useEffect(() => {
  setTotal(items.reduce(sum, 0))
}, [items])

useEffect(() => {
  setIsFree(total === 0)
}, [total])

useEffect(() => {
  if (isFree) {
    setShipping(null)
  }
}, [isFree])
```

Three renders to reach a value render could produce in one. Compute the chain, or make the
one event that starts it set everything:

```tsx
const total = items.reduce(sum, 0)
const isFree = total === 0
const shipping = isFree ? null : quote
```

## Analytics on mount

```tsx
useEffect(() => {
  track("article_viewed", { id })
}, [id])
```

Fires twice in StrictMode and again on every remount. Route-level views belong to the router's
navigation hook; interaction events belong to the handler that caused them.

## Subscribing to a store

```tsx
const [online, setOnline] = useState(navigator.onLine)
useEffect(() => {
  const on = () => setOnline(true)
  const off = () => setOnline(false)
  window.addEventListener("online", on)
  window.addEventListener("offline", off)

  return () => {
    window.removeEventListener("online", on)
    window.removeEventListener("offline", off)
  }
}, [])
```

`useSyncExternalStore` handles subscribe, snapshot and tearing:

```tsx
const online = useSyncExternalStore(subscribeToNetwork, () => navigator.onLine)
```

## What is left for an effect

Syncing with something React does not own — a third-party widget's instance, a `WebSocket`,
`document.title` where the `<title>` element cannot reach, an `IntersectionObserver`. Each
returns a cleanup.
