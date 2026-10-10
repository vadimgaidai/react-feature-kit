# Search params: a merging hook, restored on load

> Canonical code shape. Replace the placeholders (`[entity]`) with real names. Shown for
> React Router's `useSearchParams`; a TanStack Router project reads the same values off its
> typed route search instead — check `package.json` once per session.

## A hook that merges, never replaces

```tsx
const use[Entity]Filters = () => {
  const [searchParams, setSearchParams] = useSearchParams()

  const filters = {
    status: searchParams.get("status") ?? "all",
    page: Number(searchParams.get("page") ?? 1),
  }

  const setFilters = (patch: Partial<typeof filters>) => {
    setSearchParams((previous) => {
      const next = new URLSearchParams(previous)
      for (const [key, value] of Object.entries(patch)) {
        value === undefined ? next.delete(key) : next.set(key, String(value))
      }
      return next
    })
  }

  return [filters, setFilters] as const
}
```

`setSearchParams((previous) => ...)` reads the current params before writing — a plain object
literal (`setSearchParams({ status })`) replaces the whole query string and silently drops
`page`. Changing `status` resets `page` to `1` by also patching it in the same call; the two
are read from one object, so the component never has to sequence two updates.

## A paginated list restored from the URL

```tsx
const [filters] = use[Entity]Filters()
const { data, isPlaceholderData } = useQuery({
  ...[entity]Queries.list(filters),
  placeholderData: keepPreviousData,
})
```

Reloading this URL, or opening it fresh from a shared link, reproduces the exact list the
sender saw — the query key is built from the same URL-derived `filters`, not from state that
started at a default and only later synced.
