# Page, layout, or feature — a three-question ladder

> Replaces guessing with a test asked in order. Stop at the first "yes".

```
1. Does it wrap route(s) with persistent chrome (sidebar, header, tab bar)
   and mount providers shared by everything inside it?
     yes → layouts/<name>/
     no  → next question

2. Does it have its own entry in src/config's route paths?
     yes → pages/<name>/
     no  → next question

3. Is it needed by two or more pages, OR does it carry its own state/data
   independent of any one page (a context, a mutation, a piece of cache)?
     yes → features/<name>/
     no  → it is not a module yet — it stays inside the page's own
           components/ or hooks/, see references/placement.md
```

A request that seems to need a new top-level module usually answers "yes" to
exactly one of these. If it answers "yes" to none, it isn't a module — it's a
component or hook local to the page that asked for it, which is the common
case and needs no promotion at all.

## Worked examples

- A dashboard shell with a sidebar, mounted once in the router and wrapping
  every `/app/*` route: **layout** — `layouts/dashboard/dashboard-layout.tsx`.
- `/settings`, reachable from the router and from nowhere else as code: **page**
  — `pages/settings/settings-page.tsx`.
- A guided product tour: state persists across routes (a completed flag in
  storage), it is restarted from the settings page but runs on the home page,
  and it mounts a provider in the layout. Two different pages touch it and it
  owns its own state: **feature** — `features/guided-tour/`.
- A five-step onboarding checklist that only ever appears on the home page,
  reads no route param, and is restarted from nowhere else: not promoted —
  `pages/home/components/onboarding-checklist.tsx`, until a second page needs
  it or it grows its own persisted state.

## Module anatomy — the same skeleton for all three

```
<name>/
├── components/   # local sub-components — not imported outside this module
├── hooks/        # use-*.ts composed from src/api/ + local state
├── providers/    # a context this module owns and mounts itself (rare)
├── types.ts      # domain types local to this module
├── constants.ts  # values and as-const sets local to this module
└── index.ts      # public barrel — the only import surface
```

A page additionally has `<name>-page.tsx` at its root; a layout has
`<name>-layout.tsx`. A feature has neither — it is composed by whatever page or
layout uses it, so its barrel is its only fixed file beyond the skeleton.

Omit a folder the module doesn't need — a feature with no sub-components has
no `components/` folder at all, and most modules never need `providers/`.

See [references/placement.md](placement.md) for whether a given
component, hook or type stays inside this skeleton or is global from the
start, and [references/barrels.md](barrels.md) for what the barrel
exports.
