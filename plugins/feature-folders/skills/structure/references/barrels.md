# Barrel exports

> Canonical code shape. Replace placeholders (`[name]` kebab-case, `[Name]`
> PascalCase) with real names.

Every feature, page, layout and API resource exposes its public surface
through one `index.ts`. External code imports only from the barrel — never by
reaching into a module's internal files.

### Feature barrel

```typescript
// src/features/[name]/index.ts
export { use[Name] } from "./hooks/use-[name]"
export type { I[Name]Payload } from "./types"
```

### Page barrel

```typescript
// src/pages/[name]/index.ts
export { default } from "./[name]-page"
```

### Layout barrel

```typescript
// src/layouts/[name]/index.ts
export { default } from "./[name]-layout"
```

### API resource barrel

See [references/api.md](api.md) for the full shape; it exports the
api object, the queries/keys, the mutation hooks and the types together.

### Consuming

```typescript
// Correct — through the barrel
import { use[Name] } from "@/features/[name]"
import { [resource]Queries } from "@/api/[resource]"

// Wrong — reaching into internals
import { use[Name] } from "@/features/[name]/hooks/use-[name]"
import { [resource]Api } from "@/api/[resource]/[resource].api"
```

Exception: `src/components/ui/` is a flat, CLI-managed primitives folder, not
a module — it is always imported by direct file path
(`@/components/ui/button`), and the barrel-import hook blocks importing it as
a barrel.
