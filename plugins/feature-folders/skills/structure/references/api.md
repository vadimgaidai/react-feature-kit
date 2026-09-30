# API — global, per backend resource

> Canonical code shape. Replace placeholders (`[resource]` kebab-case,
> `[Resource]` PascalCase, `I[Resource]`) with real names.

Every HTTP call lives under `src/api/<resource>/`, one folder per **backend**
resource (`articles`, `users`, `auth`) — never per feature. Two features
calling the same endpoint share one client function, one query key and one
cache entry; a feature never gets its own `api/` folder. See
[references/placement.md](placement.md).

### Folder layout

```
src/api/[resource]/
├── [resource].api.ts          # direct HTTP calls, typed both ways
├── [resource].queries.ts      # read side — queryOptions + query keys
├── [resource].mutations.ts    # write side — use…Mutation hooks
├── types.ts                   # request/response shapes, from contract.md
└── index.ts                   # barrel
```

Omit `queries.ts` for a write-only resource, `mutations.ts` for a read-only
one. Both exist by default from the scaffolder; delete the one you don't need.

### `types.ts`

```typescript
export interface I[Resource] {
  id: string
}

export interface ICreate[Resource]Payload {
  name: string
}
```

### `[resource].api.ts`

```typescript
import type { I[Resource], ICreate[Resource]Payload } from "./types"

import { httpClient } from "@/lib/http"

export const [resource]Api = {
  list: async (): Promise<Array<I[Resource]>> => {
    return httpClient.get("[resource]").json<Array<I[Resource]>>()
  },
  create: async (payload: ICreate[Resource]Payload): Promise<I[Resource]> => {
    return httpClient.post("[resource]", { json: payload }).json<I[Resource]>()
  },
}
```

> A resource whose calls must bypass the shared client (an auth flow that must
> not send the Bearer token) calls the HTTP library directly instead of
> `httpClient` — say so where it happens, don't silently "fix" it into the
> shared client.

### `[resource].queries.ts`

```typescript
import { queryOptions } from "@tanstack/react-query"

import { [resource]Api } from "./[resource].api"
import { createQueryKeyFactory } from "@/lib/query"

export const [resource]Keys = createQueryKeyFactory("[resource]", (all) => ({
  list: () => [...all(), "list"] as const,
}))

export const [resource]Queries = {
  list: () =>
    queryOptions({
      queryKey: [resource]Keys.list(),
      queryFn: () => [resource]Api.list(),
    }),
}
```

### `[resource].mutations.ts`

```typescript
import { useMutation, useQueryClient } from "@tanstack/react-query"

import { [resource]Api } from "./[resource].api"
import { [resource]Keys } from "./[resource].queries"

export const useCreate[Resource]Mutation = () => {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: [resource]Api.create,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [resource]Keys.list() })
    },
  })
}
```

### `index.ts`

```typescript
export { [resource]Api } from "./[resource].api"
export { [resource]Queries, [resource]Keys } from "./[resource].queries"
export { useCreate[Resource]Mutation } from "./[resource].mutations"
export type { I[Resource], ICreate[Resource]Payload } from "./types"
```

### Consuming from a feature

```typescript
// a feature's own hook composes the global api/ layer with local state
import { [resource]Queries } from "@/api/[resource]"
```

A feature or page never imports another module's `api/` files by reaching
past its barrel, and never re-implements a call `src/api/<resource>/` already
has — see [references/placement.md](placement.md) for the test
that decides when a type or constant is the resource's and when it is a
module's own.
