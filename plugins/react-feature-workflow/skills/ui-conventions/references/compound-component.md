# Compound Component Pattern

> Canonical code shape. Replace the placeholders (`[name]` kebab-case, `[Name]` PascalCase, `I[Name]` type identifiers) with real names, and the `@/components/ui/` import paths with the project's own primitives alias.

When a component has 2+ tightly related sub-components that share one piece of state, export
an object with `.Root` and named sub-components, `.Root` owning the state and coordinating
the parts through context — never a part holding its own competing copy of it.

### Definition

```tsx
// [name]/[name].tsx
import {
  createContext,
  useContext,
  useState,
  type ComponentProps,
  type FC,
  type ReactNode,
} from "react"

interface I[Name]Context {
  isOpen: boolean
  toggle: () => void
}

const [Name]Context = createContext<I[Name]Context | null>(null)

const use[Name]Context = () => {
  const context = useContext([Name]Context)
  if (!context) {
    throw new Error("[Name].Trigger and [Name].Panel must be rendered inside [Name].Root")
  }
  return context
}

interface I[Name]RootProps {
  children: ReactNode
  open?: boolean
  defaultOpen?: boolean
  onOpenChange?: (open: boolean) => void
}

const [Name]Root: FC<I[Name]RootProps> = ({ children, open, defaultOpen = false, onOpenChange }) => {
  const [uncontrolledOpen, setUncontrolledOpen] = useState(defaultOpen)
  const isControlled = open !== undefined
  const isOpen = isControlled ? open : uncontrolledOpen

  const toggle = () => {
    const next = !isOpen
    if (!isControlled) {
      setUncontrolledOpen(next)
    }
    onOpenChange?.(next)
  }

  return <[Name]Context value={{ isOpen, toggle }}>{children}</[Name]Context>
}

const [Name]Trigger: FC<ComponentProps<"button">> = ({ onClick, ...rest }) => {
  const { isOpen, toggle } = use[Name]Context()

  return (
    <button
      type="button"
      aria-expanded={isOpen}
      onClick={(event) => {
        onClick?.(event)
        toggle()
      }}
      {...rest}
    />
  )
}

const [Name]Panel: FC<ComponentProps<"div">> = ({ hidden, ...rest }) => {
  const { isOpen } = use[Name]Context()

  return <div role="region" hidden={hidden ?? !isOpen} {...rest} />
}

export const [Name] = {
  Root: [Name]Root,
  Trigger: [Name]Trigger,
  Panel: [Name]Panel,
}
```

### Usage

Uncontrolled — `[Name]` owns the open state:

```tsx
<[Name].Root defaultOpen>
  <[Name].Trigger>{t("[name].toggle")}</[Name].Trigger>
  <[Name].Panel>{children}</[Name].Panel>
</[Name].Root>
```

Controlled — the parent owns it, and `[Name]` never also writes `uncontrolledOpen`:

```tsx
<[Name].Root open={isOpen} onOpenChange={setIsOpen}>
  <[Name].Trigger>{t("[name].toggle")}</[Name].Trigger>
  <[Name].Panel>{children}</[Name].Panel>
</[Name].Root>
```

### What each part of the contract looks like here

- **`Root` owns the shared state** — `isOpen` and `toggle` live in `[Name]Root`, nowhere else.
- **A part never keeps a competing copy** — `[Name]Trigger` and `[Name]Panel` read `isOpen`
  from context and call `toggle()`; neither declares its own `useState` for it.
- **A part outside its `Root` throws, naming the `Root` it needs** — `use[Name]Context` refuses
  silently-wrong behaviour (a `Panel` that renders as if always closed) in favour of an error
  that names the fix.
- **Controlled and uncontrolled never both drive the state** — `open !== undefined` decides
  which one the `isOpen` getter and the `toggle` setter use for the whole lifetime of this
  render; `toggle` only writes `uncontrolledOpen` when the parent isn't already driving `open`.
- **A wrapper around a primitive forwards events, `ref` and the props the primitive expects**
  — `[Name]Trigger` is `ComponentProps<"button">` plus `...rest`, and calls the caller's
  `onClick` before its own `toggle()`, never instead of it.
- **Composition over a primitive keeps focus and keyboard handling** — building this on top of
  a shadcn primitive (a `Popover`, a `Collapsible`) means wrapping `PopoverTrigger`/
  `PopoverContent` the same way: forward `...rest` through to the primitive so its own
  `onKeyDown`, focus trap and roving tabindex still run; a wrapper that intercepts `onKeyDown`
  without calling the primitive's own handler breaks keyboard use silently.
- **A new part is added for a scenario that exists** — a `[Name].Footer` is worth adding when
  a real caller needs a footer slot, not to mirror `Header` for symmetry.
- **Public exports follow the loaded structure skill** — `[Name]` is exported from the
  module's barrel; a caller never imports `[name]/[name]` directly past it.

Rules:

- 2+ sub-components sharing one piece of state → this pattern, with the state in `Root`'s
  context, never duplicated in a part.
- Always expose `.Root` as the wrapper; a part rendered outside it throws.
- Internal helpers that are not part of the public surface stay as separate files in the module, not on the compound object.
- Placement, including why it never lands in the shadcn-managed primitives folder: the structure skill loaded in this project.
