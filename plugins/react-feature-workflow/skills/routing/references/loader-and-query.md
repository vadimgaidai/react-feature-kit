# A loader that prefetches, a component that reads the query

> Canonical code shape. Replace the placeholders (`[entity]`) with real names. Shown for React
> Router's data APIs; a framework with its own loader convention (TanStack Router, Remix)
> follows the same shape through its own `ensureQueryData`-equivalent.

## The loader never owns a second copy of the data

```tsx
export const [entity]DetailLoader = (queryClient: QueryClient) => async ({ params }: LoaderFunctionArgs) => {
  await queryClient.ensureQueryData([entity]Queries.byId(params.id as string))
  return null
}
```

`ensureQueryData` fetches only if the key is missing or stale, and writes into the same cache
the component's own `useQuery` reads — the loader's job is to have the data ready before the
route renders, not to hand the component a value. A loader that does
`return [entity]Api.getById(params.id)` and a component that reads `useLoaderData()` instead
of `useQuery` creates exactly the two-copies bug: the loader's snapshot and the query cache
diverge on the first mutation that invalidates the query.

```tsx
const [Entity]DetailPage = () => {
  const { id } = useParams()
  const { data: [entity] } = useQuery([entity]Queries.byId(id as string))

  return <[Entity]Detail [entity]={[entity]} />
}
```

`[entity]` is already in the cache from the loader, so there is no pending flash on first
render.

## Route-level pending and error, not a parallel flag

`navigation.state` is `"loading"` during a route transition — the router's own flag:

```tsx
const navigation = useNavigation()

<Route
  path={paths.[entity].details}
  loader={[entity]DetailLoader(queryClient)}
  errorElement={<[Entity]RouteError />}
  element={<[Entity]DetailPage />}
/>
```

A component that instead tracks `const [isNavigating, setIsNavigating] = useState(false)`
around its own `navigate()` calls duplicates `navigation.state`, and drifts from it the moment
a navigation is triggered from somewhere else (a link, the browser's Back button) that never
touches that `setIsNavigating`.

## Nested routes keep their own boundary

```tsx
<Route path={paths.[entity].root} element={<[Entity]Layout />}>
  <Route index element={<[Entity]Overview />} />
  <Route path="activity" element={<[Entity]Activity />} loader={activityLoader} />
</Route>
```

`[Entity]Layout` renders its chrome once and an `<Outlet />` for the child. Only
`[Entity]Activity`'s own region shows a pending state while `activityLoader` runs — switching
tabs between `Overview` and `Activity` never re-fetches or blanks the shared layout above it.
