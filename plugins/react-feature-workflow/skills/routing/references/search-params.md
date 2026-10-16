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
        if (value === undefined) {
          next.delete(key)
          continue
        }
        next.set(key, String(value))
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
are read from one object, so the component never has to sequence two updates. The setter
takes a patch, so adding a filter touches this hook and no call site (`code-shape` §A setter
takes a patch).

## A filter whose off value is no param

`archived: false` or `tags: []` means the param is absent, never `archived=false` or
`tags=`. The hook maps the domain value to the param once; call sites keep passing `false`
and `[]`, and the `undefined → delete` loop above does the rest:

```tsx
const PARAM_ON = "1"

const toParam = (value: string | number | boolean | Array<string>): string | undefined => {
  if (Array.isArray(value)) {
    return value.length > 0 ? value.join(",") : undefined
  }

  if (typeof value === "boolean") {
    return value ? PARAM_ON : undefined
  }

  return String(value)
}

const filters = {
  tags: parseTags(searchParams.get("tags")),
  archived: searchParams.get("archived") === PARAM_ON,
}
```

The loop calls `toParam(value)` in place of `String(value)`. `PARAM_ON` is the one string
both the reader and the writer agree on (`code-shape` §Magic numbers and boundary literals).
`tags` is a known set, so `parseTags` filters against the const-derived union
(`typescript` §Const-derived unions) and returns `Array<[Entity]Tag>`, not `Array<string>`;
where that parser lives is `code-shape` §A pure helper beside a hook.

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
