---
name: ui-conventions
description: shadcn/ui + Tailwind conventions — semantic tokens instead of raw colors, extending primitives via ComponentProps, compound components, icon and spacing rules that survive dark mode. Use when building or fixing UI on shadcn/Tailwind, wrapping a primitive, or deciding how to style a component.
---

# shadcn/ui + Tailwind

## Use a primitive before writing one

1. Does an installed primitive already cover this? Use it directly — `@/components/ui/[name]` in a default shadcn setup, or wherever the project's `components.json` puts them. Import the module, not a barrel.
2. Not installed? Search the registry with the `shadcn` MCP server and add it with the CLI. Don't hand-roll a Dialog.
3. Wrapping a primitive? Extend its prop type via `ComponentProps<typeof X>` and forward `...rest` — see [references/extending-components.md](references/extending-components.md).
4. Two or more related nested parts? Compound Component Pattern — an object with `.Root` and named parts, with or without shared state. If the parts need shared state, `.Root` owns it; context is added only when state or actions actually have to reach a part, never to make a component look like the pattern — see [references/compound-component.md](references/compound-component.md).
5. Building a form? Layout is `Field`/`FieldGroup` from the `react-hook-form-zod` skill, not this one.
6. Otherwise one exported component per file, props as an interface.

Placement and naming — which folder a primitive, a domain wrapper or a compound component lives in — is the structure skill loaded in this project.

## Styling

- **Semantic tokens only** — `bg-background`, `text-foreground`, `border-border`, `text-muted-foreground`. Never a raw hex, never an arbitrary value where a token exists.
- **No `dark:` overrides in components.** Dark mode is a token-layer concern; a `dark:` in a component means the token set is wrong. Fix the tokens (see the `theme-sync` agent), not the component.
- **`size-*` when width equals height** — `size-4`, not `h-4 w-4`.
- **`gap-*` over `space-y/x-*`** — space utilities break on wrapping and on flex direction changes.
- `className` on an exported component is for **layout positioning only** (margins, grid placement). Anything else belongs inside the component or in a variant.
- Spacing and sizes come from the Tailwind scale. A raw px value is a signal the design has no matching token — surface that rather than hardcoding it.
- **A Tailwind scale class is a claim about the project's theme, not about default Tailwind.** A project that resets a namespace in `@theme` (`--<ns>-*: initial`) keeps only the keys it redefines — every other class in that namespace **silently emits no CSS**: no type error, no lint error, just a missing style (a reset radius scale that redefines only `xs`/`sm`/`md` makes `rounded-xl` a no-op). This holds for any tokenized namespace — radius, spacing, font-size, color — the example is not the rule. `@theme` is Tailwind v4; in a v3 project `theme.extend` in `tailwind.config` only adds to the default scale, while a key set directly under `theme` replaces that part of it — that direct key is v3's reset — check `package.json` once to know which file to read. Before the first use of a scale class from a namespace, check that file for it; if the namespace is reset, only the keys listed there exist. (If the project runs `eslint-plugin-better-tailwindcss` with `no-unknown-classes`, the check is machine-enforced — don't re-verify by hand.)
- A design value with no matching token: use the nearest existing token, or **ask the user** before adding a token to `@theme`. An arbitrary bracket value (`rounded-[12px]`, `text-[13px]`, `gap-[7px]`) is never the answer for a property that has a token scale — brackets are reserved for values no scale owns (`backdrop-blur-[200px]`).

## Icons

- `lucide-react`. Inside a Button, mark placement with `data-icon="inline-start"` / `data-icon="inline-end"` and let the Button own the sizing — no `size-*` on the icon there.
- A standalone icon gets an explicit `size-*` and, when it carries meaning, an accessible label.

## Component shape

- Extract a sub-component once JSX passes ~80 lines, or when a chunk owns its own state.
- Extract a helper when logic is reused or branches more than once — never an `if/else` chain inside JSX.
- One file does one thing: fetch, map, or render. Growing state moves into a `use-*` hook.
- Loading, empty and error are real states, not afterthoughts. A list that renders nothing on empty is a bug.

The reference files use placeholders — `[name]` kebab-case, `[Name]` PascalCase, `I[Name]` type identifiers. Real infrastructure (the primitives folder, `cn`) keeps its real name; swap the import paths for the project's own aliases.

## Never

- Copy a primitive's source to tweak one style — extend it.
- Reach for an arbitrary Tailwind value (`w-[327px]`) when a scale step or token fits — or invent a scale class without confirming the key exists in the project's `@theme`.
- Ship a component that only looks right in one theme.
- Put a user-facing string in JSX, a toast, a schema message or a fallback — every visible text is a `t()` key.
- Let a compound component's part hold a competing copy of state `Root` already owns, or render
  a context-reading part outside its `Root` without throwing — [references/compound-component.md](references/compound-component.md) has the contract.
- Add state, a Provider or a Context to a compound component for the pattern's sake, with no
  behaviour that needs it. A part's own local state is allowed even when nothing else reads it.

## Reviewing

In order of how often it hurts:

- a raw hex, an arbitrary Tailwind value, or a scale class from a namespace the project's `@theme`/`tailwind.config` has reset without that key
- an icon-only button with no accessible name
- a label not associated with its field, or an error not tied to the field it describes (`aria-describedby`, `aria-invalid`)
- a `dark:` override inside a component instead of a token fix
- a compound component part holding its own copy of state `Root` already owns — a part's own local state is not this
- a context-reading part rendered outside its `Root` that fails silently instead of throwing a named error
- state, a Provider or a Context added to a compound component for the pattern's sake, with no behaviour that needs it — a part's own local state nothing else reads is allowed
- controlled and uncontrolled state both driving the same compound component at once
- a wrapper around a primitive that swallows `onKeyDown`, re-implements focus trapping, or breaks roving tabindex instead of forwarding to the primitive
- a button inside a form with no explicit `type`, so an action button submits
- focus or typed input lost on pending or error — the control should be disabled, not unmounted, and the text should stay
- a primitive's source copied and tweaked instead of extended via `ComponentProps`
- a user-facing string that is not a `t()` key, including a number, date or plural formatted by hand instead of through the project's i18n formatting
- a component that only looks right in one theme
- loading, empty or error collapsed into the same render, or an empty list rendering nothing
- a new compound part added for symmetry with no caller that needs it
- `h-4 w-4` instead of `size-4`, or `space-y/x-*` instead of `gap-*`
