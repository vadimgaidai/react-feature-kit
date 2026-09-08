# Compound Component Pattern

> Canonical code shape. Replace the placeholders (`[name]` kebab-case, `[Name]` PascalCase, `I[Name]` type identifiers) with real names, and the `@/components/ui/` import paths with the project's own primitives alias.

When a component has 2+ tightly related sub-components, export an object with `.Root` and named sub-components.

### Definition

```tsx
// [name]/[name].tsx
import type { FC, ReactNode } from "react"

import { SidebarInset, SidebarProvider } from "@/components/ui/sidebar"

interface I[Name]Props {
  children: ReactNode
}

const [Name]Root: FC<I[Name]Props> = ({ children }) => {
  return <SidebarProvider>{children}</SidebarProvider>
}

const [Name]Aside: FC = () => {
  return <Aside />
}

const [Name]Main: FC<{ children: ReactNode }> = ({ children }) => {
  return <SidebarInset>{children}</SidebarInset>
}

const [Name]Header: FC = () => {
  return <header className="flex h-16 shrink-0 items-center gap-2 border-b px-4">…</header>
}

const [Name]Content: FC<{ children: ReactNode }> = ({ children }) => {
  return <div className="flex flex-1 flex-col gap-4 p-4">{children}</div>
}

export const [Name] = {
  Root: [Name]Root,
  Aside: [Name]Aside,
  Main: [Name]Main,
  Header: [Name]Header,
  Content: [Name]Content,
}
```

### Usage

```tsx
<[Name].Root>
  <[Name].Aside />
  <[Name].Main>
    <[Name].Header />
    <[Name].Content>{children}</[Name].Content>
  </[Name].Main>
</[Name].Root>
```

Rules:

- 2+ sub-components → use this pattern.
- Always expose `.Root` as the wrapper.
- Internal helpers that are not part of the public surface stay as separate files in the module, not on the compound object.
- Does **not** apply to the shadcn-managed primitives folder (`components/ui/` by default) — those files belong to the CLI and stay flat.
