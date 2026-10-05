# State placement, memoization and render shape

> Canonical code shape. Replace the placeholders (`[Entity]`, `I[Entity]`) with real names.

## Push state down

```tsx
const [isFilterOpen, setIsFilterOpen] = useState(false)
return (
  <>
    <[Entity]Table rows={rows} />
    <FilterPopover open={isFilterOpen} onOpenChange={setIsFilterOpen} />
  </>
)
```

Every toggle re-renders the table. The flag is read by one subtree:

```tsx
const FilterPopover = () => {
  const [isOpen, setIsOpen] = useState(false)
  …
}
```

Lift only when a second sibling reads it, and only to their closest common parent.

## Not state: derived, server, URL

```tsx
const activeCount = items.filter((item) => item.status === [Entity]Status.Active).length
const { data: items } = useQuery([entity]Queries.list(filters))
const [searchParams] = useSearchParams()
const page = Number(searchParams.get("page") ?? 1)
```

A computed value is computed; a response lives in the cache; a filter, tab or page the user
expects to survive refresh and back lives in the URL.

## Group what changes together

```tsx
const [position, setPosition] = useState({ x: 0, y: 0 })
```

Two `useState`s updated in the same handler are one piece of state. Three or more fields with
transitions between them are a reducer.

## A ref is a value that never renders

```tsx
const timeoutRef = useRef<ReturnType<typeof setTimeout>>(undefined)

const schedule = () => {
  clearTimeout(timeoutRef.current)
  timeoutRef.current = setTimeout(save, 500)
}
```

The same value in `useState` re-renders on every schedule for nothing. Read and write
`ref.current` only in handlers, effects and cleanup — never during render.

## Memoize both-or-neither

```tsx
const sorted = useMemo(() => sortByScore(items), [items])
```

Expensive work on stable input. The same `useMemo` with `[filters]` where `filters` is an
object literal built in the parent's render compares every time and never hits — stabilize
the input or drop the memo. An O(n²) body inside `useMemo` is still O(n²): fix it first.

## A lookup instead of a scan

```tsx
const authorById = new Map(authors.map((author) => [author.id, author]))
return comments.map((comment) => (
  <Comment key={comment.id} comment={comment} author={authorById.get(comment.authorId)} />
))
```

`authors.find(…)` inside the `map` is n×m per render.

## Keys and hoisting

```tsx
const DEFAULT_FILTERS: I[Entity]Filters = { status: "all", page: 1 }

export const [Entity]List = ({ items }: I[Entity]ListProps) => {
  const [filters, setFilters] = useState(DEFAULT_FILTERS)

  if (items.length === 0) {
    return <EmptyState title={t("[entity].empty")} />
  }

  return items.map((item) => <[Entity]Row key={item.id} item={item} />)
}
```

Static objects sit above the component, so `useState` and any memo see the same reference
every render; keys are identities, never indexes on a list that can reorder, filter or grow. A component declared inside another's body remounts its
whole subtree on every render of the parent.

## Lazy initializer, functional update

```tsx
const [draft, setDraft] = useState(() => parseDraft(storage.get(key)))
const increment = () => setCount((count) => count + 1)
```

`useState(parseDraft(…))` runs the parse every render and keeps the first result. A `setCount
(count + 1)` called twice in one handler increments once.

## Context: split churn from stable

```tsx
const SessionContext = createContext<ISession | null>(null)
const SessionActionsContext = createContext<ISessionActions | null>(null)

<SessionContext value={session}>
  <SessionActionsContext value={actions}>{children}</SessionActionsContext>
</SessionContext>
```

A consumer that only needs `actions` no longer re-renders on every session refresh. Before
adding a context at all, pass the subtree as `children` — most prop drilling disappears.

```tsx
const session = use(SessionContext)
```

`use` may sit behind a condition or an early return; `useContext` may not.
