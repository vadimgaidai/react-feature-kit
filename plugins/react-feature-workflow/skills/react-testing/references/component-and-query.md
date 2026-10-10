# A component test with a real `QueryClient`

> Canonical code shape. Replace the placeholders (`[Entity]`) with real names. Shown for
> Vitest + React Testing Library + MSW; a Jest project swaps `vi` for `jest`.

```tsx
const createTestQueryClient = () =>
  new QueryClient({
    defaultOptions: { queries: { retry: false }, mutations: { retry: false } },
  })

const renderWithQuery = (ui: ReactNode) => {
  const queryClient = createTestQueryClient()
  return render(<QueryClientProvider client={queryClient}>{ui}</QueryClientProvider>)
}

test("shows the item once the request resolves", async () => {
  server.use(
    http.get("/api/[entity]s/:id", () => HttpResponse.json({ id: "1", name: "Widget" }))
  )

  renderWithQuery(<[Entity]Badge id="1" />)

  expect(screen.getByText(/loading/i)).toBeInTheDocument()
  expect(await screen.findByText("Widget")).toBeInTheDocument()
})

test("shows a retry affordance on failure", async () => {
  server.use(http.get("/api/[entity]s/:id", () => HttpResponse.error()))

  renderWithQuery(<[Entity]Badge id="1" />)

  expect(await screen.findByRole("alert")).toHaveTextContent(/couldn't load/i)
})
```

`retry: false` on the test client is what keeps the failure test fast and deterministic — the
production client's own retry policy is `tanstack-query`'s concern, not this test's. Mocking
the HTTP layer (MSW) instead of `useQuery` itself means the real query — its key, its `select`,
its error classification — is what runs; a `vi.mock("@tanstack/react-query")` that returns
`{ data: mockItem, isPending: false }` directly proves nothing about whether the component
asked for the right key.

## Unmount and a subscription

```tsx
test("unsubscribes from the store on unmount", () => {
  const unsubscribe = vi.fn()
  vi.spyOn(networkStatusStore, "subscribe").mockReturnValue(unsubscribe)

  const { unmount } = render(<OnlineIndicator />)
  unmount()

  expect(unsubscribe).toHaveBeenCalledOnce()
})
```

This is the test `react`'s cleanup rule is for: a component that subscribes without returning
a cleanup passes every other test in the suite and fails only this one.
