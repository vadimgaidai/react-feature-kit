# Providers — a file, or a folder once it needs one

> Canonical code shape. Replace placeholders (`[name]` kebab-case, `[Name]`
> PascalCase) with real names.

A provider that is mounted in `src/app/` or in a layout is global by
[references/placement.md](placement.md)'s rule — more than one
page sees it. A provider owned and mounted by exactly one module (rare) stays
inside that module's own `providers/`, same shape, one layer down.

## Trivial: a single file

State, no persistence, no config. Everything in one file.

```typescript
// src/providers/[name]-provider.tsx
import { createContext, useContext, useState, type ReactNode } from "react"

interface I[Name]ContextType {
  value: string
  setValue: (value: string) => void
}

export const [Name]Context = createContext<I[Name]ContextType>({
  value: "",
  setValue: () => undefined,
})

export const use[Name] = (): I[Name]ContextType => useContext([Name]Context)

export const [Name]Provider = ({ children }: { children: ReactNode }) => {
  const [value, setValue] = useState("")
  return <[Name]Context.Provider value={{ value, setValue }}>{children}</[Name]Context.Provider>
}
```

## Grown: a folder

The moment a provider gets its own persistence (localStorage, a subscription)
or its own config constants, split it — one file per concern, same names every
time so any provider folder reads the same way:

```
src/providers/[name]/
├── config.ts      # storage keys, limits — values only
├── types.ts       # the context's value type, event/state shapes
├── storage.ts     # read/write helpers, if it persists anything
├── provider.tsx   # the component; imports the context from index.ts
└── index.ts       # createContext + use[Name]() + re-exports Provider
```

`index.ts` owns the context object and the consuming hook; `provider.tsx`
imports the context back from `index.ts` rather than creating its own, so
there is exactly one `createContext` call per provider, findable by opening
one file.

```typescript
// src/providers/[name]/index.ts
import { createContext, useContext } from "react"
import type { I[Name]ContextType } from "./types"

export const [Name]Context = createContext<I[Name]ContextType>({ /* defaults */ })
export const use[Name] = (): I[Name]ContextType => useContext([Name]Context)
export { [Name]Provider } from "./provider"
export type * from "./types"
```

Don't split preemptively — a provider with no persistence and no config stays
the single-file form until it actually grows one of those.

## Mounting

Global providers are composed once, in the narrowest layout or app shell that
covers every consumer — never in every page that happens to use one.

```tsx
// src/layouts/dashboard/dashboard-layout.tsx
const DashboardLayout = () => (
  <SessionLogProvider>
    <BreadcrumbProvider>
      <Outlet />
    </BreadcrumbProvider>
  </SessionLogProvider>
)
```
