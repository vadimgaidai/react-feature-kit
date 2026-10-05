# Code splitting, Suspense and error boundaries

> Canonical code shape. Replace the placeholders (`[entity]`, `[Entity]`) with real names.

## Lazy route

```tsx
const [Entity]Page = lazy(() => import("@/pages/[entity]"))

<Route
  path={paths.[entity].list}
  element={
    <ErrorBoundary FallbackComponent={RouteError}>
      <Suspense fallback={<[Entity]PageSkeleton />}>
        <[Entity]Page />
      </Suspense>
    </ErrorBoundary>
  }
/>
```

One route's dependencies stop being everyone's download. The fallback is a skeleton the size
of the page, not a centered spinner — a spinner is a layout shift when the page arrives.

## Split the content, not the trigger

```tsx
const [Entity]EditorDialogContent = lazy(() => import("./[entity]-editor-dialog-content"))

export const [Entity]EditorDialog = () => {
  const [isOpen, setIsOpen] = useState(false)
  const preload = () => import("./[entity]-editor-dialog-content")

  return (
    <Dialog open={isOpen} onOpenChange={setIsOpen}>
      <DialogTrigger asChild>
        <Button onMouseEnter={preload} onFocus={preload}>{t("actions.edit")}</Button>
      </DialogTrigger>
      <DialogContent>
        {isOpen && (
          <ErrorBoundary FallbackComponent={DialogError}>
            <Suspense fallback={<DialogSkeleton />}>
              <[Entity]EditorDialogContent />
            </Suspense>
          </ErrorBoundary>
        )}
      </DialogContent>
    </Dialog>
  )
}
```

The button stays eager; the editor, its schema and its rich-text dependency load on intent.
Prefetch the dialog's data on the same hover (`tanstack-query` skill, prefetch on intent).

## Heavy widget at the point of use

```tsx
const RevenueChart = lazy(() => import("./revenue-chart"))
```

Charts, editors, maps, date pickers, PDF viewers, drag-and-drop: each is an import inside the
component that renders it, never a top-level import of the page.

## Boundary placement

```tsx
<Suspense fallback={<HeaderSkeleton />}>
  <[Entity]Header id={id} />
</Suspense>
<Suspense fallback={<CommentsSkeleton />}>
  <[Entity]Comments id={id} />
</Suspense>
```

Each region that loads on its own gets its own boundary, so a slow comments query does not
blank the header. A single boundary at the root turns every chunk and every
`useSuspenseQuery` into a full-page fallback.

## Transition around a route swap

```tsx
const [isPending, startTransition] = useTransition()
const open = (id: string) => startTransition(() => navigate(paths.[entity].details(id)))
```

The current screen stays visible, dimmed on `isPending`, instead of flashing the fallback.

## Error boundary with a real retry

```tsx
const RouteError = ({ error, resetErrorBoundary }: FallbackProps) => {
  const { t } = useTranslation()

  return (
    <ErrorState
      title={t("errors.title")}
      description={error.message}
      action={<Button onClick={resetErrorBoundary}>{t("actions.retry")}</Button>}
    />
  )
}

<QueryErrorResetBoundary>
  {({ reset }) => (
    <ErrorBoundary FallbackComponent={RouteError} onReset={reset}>
      …
    </ErrorBoundary>
  )}
</QueryErrorResetBoundary>
```

A chunk fetch fails after every deploy on a stale hashed filename; without a boundary the app
goes blank. `resetErrorBoundary` re-attempts the import, and `onReset={reset}` re-attempts
the queries inside — without it the retry re-renders the same cached error.

Boundaries catch render-time throws. A rejected promise in a handler, a `setTimeout` or an
un-awaited call never reaches one; handle those where they happen.
