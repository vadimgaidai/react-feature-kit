---
name: typescript
description: Type discipline — narrowing at the boundary, discriminated unions over optional soup, satisfies, no enum, no any. Use when writing types, narrowing, generics or casting, or reviewing any .ts file.
---

# TypeScript

## Types come from the contract and from inference

A hand-written interface that mirrors `z.infer` or a contract shape is a second source of
truth. Derive it instead.

## Narrow at the boundary, once

Parse unknown input (`zod`, a type guard) where it enters; downstream code trusts the type.
`as` is a claim the compiler cannot check; a guard is one it can.

## Discriminated unions over optional soup

`{ status: 'error'; error } | { status: 'ok'; data }` instead of
`{ data?: T; error?: E; isLoading?: boolean }`.

## `satisfies` for shape-checking a literal without widening it

## No `enum`

`as const` object plus a derived union. The structure skills own which file it lives in.

## Const-derived unions: a known set of values lives in one constant

A prop like `size` is not typed `'sm' | 'md' | 'lg'` inline. The set is a constant and the
type is derived from it, so there is one place to add a value and the runtime list
(options, iteration, validation) and the type cannot drift apart:

```ts
export const BUTTON_SIZES = ['sm', 'md', 'lg'] as const
export type ButtonSize = (typeof BUTTON_SIZES)[number]
```

The same holds for a `variant`, a `status`, a `Record` key — any string whose set of values
is known. An inline union is the typed-string version of a magic string.

## `unknown` at the edge, never `any`

`any` disables the compiler for everything it touches, not just the value it's assigned to.

## Don't re-check what the type already guarantees

No runtime `typeof` for what the type already says; no `!`; no `?? fallback` on a value the
type says is present.

## Type-only imports are `import type`

Generic parameters stay `T`, `K`, `TData` — a descriptive name on a generic parameter is
noise the call site never reads.

## Reviewing

In order of how often it hurts:

- `as` outside a boundary
- `any` / `!` / `@ts-ignore`
- an optional-everything interface where a union was meant
- a duplicated inferred type
- a `typeof` guard on a value the type already narrows
- a non-exhaustive `switch` on a union
- an inline string-literal union for a prop or a key whose set should be a const-derived union
- a type that lets an invalid state be built — two booleans where a union of states was
  meant, an optional field that is required in every real case, a string where the set of
  values is known
- an invariant held only in a comment or a runtime check, when the type could carry it

## Overlap with the project's lint

A line the project's own lint reported in this review session goes under Checks and is
not re-derived. A rule merely present in the config is not proof it ran: without that
diagnostic in hand, the finding stands.
