# Code shapes

> One pair per rule: the shape that gets reported, then the shape that replaces it. Placeholders
> (`[entity]`, `[Entity]`, `I[Entity]`) stand for real names.

## The least code

```ts
export const get[Entity]ById = (id: string) => [entity]Api.getById(id)
export { formatDate as formatCreatedAt } from "@/shared/lib/format"
const result = items.filter(isActive)
return result
```

A forwarding wrapper, a renaming re-export and a once-used variable. Call `[entity]Api.getById`
directly, import `formatDate` under its own name, return the expression.

```ts
switch (status) {
  case [Entity]Status.Draft:
    return t("[entity].status.draft")
  case [Entity]Status.Published:
    return t("[entity].status.published")
  default:
    return t("[entity].status.unknown")
}
```

`status` is a two-member union; the `default` is a branch for a state the type rules out. Make
the switch exhaustive (`typescript` skill) and delete it.

## Comments

```ts
// Calculate the badge size based on the count
const badgeSize = count > 99 ? "lg" : "sm"

// TODO: drop the cap once the API paginates
const visible = items.slice(0, 50)

// ! Safari fires blur before click; keep the timeout
const timeout = setTimeout(close, 0)
```

The first says what the line says. The second names deferred work. The third names a
constraint a reader would otherwise "clean up". Only the last two survive.

## Two parameters

```ts
const submit = (articleId: string, body: string, onDone: () => void) => …
submit(id, text, refresh)
```

```ts
interface ISubmitOptions { articleId: string; body: string; onDone: () => void }
const submit = ({ articleId, body, onDone }: ISubmitOptions) => …
submit({ articleId: id, body: text, onDone: refresh })
```

The call site reads, order stops mattering, an optional field stops being an `undefined`
placeholder in the middle.

## Guard clauses

```ts
const canEdit = (user: IUser | null, [entity]: I[Entity]) => {
  if (user) {
    if ([entity].authorId === user.id) {
      if (![entity].isLocked) {
        return true
      }
    }
  }

  return false
}
```

```ts
const canEdit = (user: IUser | null, [entity]: I[Entity]) => {
  if (!user) {
    return false
  }

  if ([entity].authorId !== user.id) {
    return false
  }

  return ![entity].isLocked
}
```

## Ternaries

```tsx
const labelKey = isOwner
  ? isLocked
    ? "[entity].actions.locked"
    : "[entity].actions.edit"
  : isAdmin
    ? "[entity].actions.moderate"
    : "[entity].actions.view"
```

```tsx
const ACTION_KEY_BY_ROLE: Record<[Entity]Role, string> = {
  owner: "[entity].actions.edit",
  admin: "[entity].actions.moderate",
  viewer: "[entity].actions.view",
}

const isLockedForOwner = isLocked && role === "owner"
const labelKey = isLockedForOwner ? "[entity].actions.locked" : ACTION_KEY_BY_ROLE[role]
```

A ternary picks between two values. Anything that reads as a decision tree is a lookup, a named
boolean or a sub-component.

```tsx
isPending ? <Spinner /> : error ? <ErrorState /> : <[Entity]List items={data} />
```

Three render branches are early returns, not a ternary chain.

## One loop per body

```ts
for (const comment of comments) {
  const author = users.find((user) => user.id === comment.authorId)
  …
}
```

```ts
const userById = new Map(users.map((user) => [user.id, user]))
for (const comment of comments) {
  const author = userById.get(comment.authorId)
  …
}
```

The inner scan is n×m. Build the lookup once; if the inner loop is real work, it is a helper
with a name.

## Explicit returns

```ts
const parsePage = (raw: string | null) => {
  if (raw === null) {
    return
  }

  const page = Number(raw)

  if (Number.isNaN(page)) {
    return 1
  }

  return page
}
```

Three return shapes: `undefined`, `1`, `number`. Decide what the function returns when the
input is bad and return that in every branch:

```ts
const parsePage = (raw: string | null): number => {
  const page = Number(raw)
  return Number.isNaN(page) || page < 1 ? 1 : page
}
```

## Boolean parameters

```ts
formatAmount(total, true)
```

```ts
formatAmount(total, { withCurrency: true })
```

Or two functions: `formatAmount` and `formatPrice`. The call site `(x, true)` tells a reader
nothing.

## Names

```ts
const data = await [entity]Api.getList()
const flag = user.id === [entity].authorId
const handleClick = () => mutate(values)
class [Entity]Manager {}
const formatDate2 = …
```

```ts
const [entity]s = await [entity]Api.getList()
const isOwner = user.id === [entity].authorId
const submit[Entity] = () => mutate(values)
const formatShortDate = …
```

A name carries the domain word; the type is already in the type. `Manager`, `Helper`, `Utils`
and `Service` are the absence of a name. A `2` means the author did not grep.

## Extract on a second caller

```ts
const buildQueryKey = (filters: I[Entity]Filters) => [entity]Keys.list(filters)
const { data } = useQuery({ queryKey: buildQueryKey(filters), … })
```

One caller, one line: inline it. Extract when the second caller appears, or when the chunk
holds its own state (a hook) — the same size test as the ternary rule, in the other direction.

## Magic numbers

```ts
if (body.length > 2000) …
setTimeout(save, 500)
```

```ts
const COMMENT_MAX_LENGTH = 2000
const AUTOSAVE_DELAY_MS = 500
```

A number with a domain meaning gets the domain's name, in `constants.ts` when a second file
needs it. `0`, `1` and an array index are not magic.
