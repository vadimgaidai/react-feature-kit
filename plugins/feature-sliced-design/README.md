# Feature-Sliced Design

Keeps a [Feature-Sliced Design](https://feature-sliced.design/) project in shape while Claude writes. A skill answers where code goes; hooks refuse the write when it goes elsewhere.

## Install

```bash
claude plugin marketplace add vadimgaidai/react-feature-kit
claude plugin install feature-sliced-design@vadimgaidai --scope project
```

Needs `jq`. Without it the hooks exit silently and nothing is blocked. Keep `--scope project`: the hooks assume all of `src/` is FSD and would block writes in any other project. Do not install together with `feature-folders`.

## What the hooks refuse

Every `Write` and `Edit`:

- a file outside `app/`, `pages/`, `widgets/`, `features/`, `entities/`, `shared/`
- a filename that is not kebab-case (`UserCard.tsx`)
- an import through the `@/shared/ui` barrel instead of `@/shared/ui/button`
- an import against the layer order: an entity importing a feature, a feature importing another feature
- a domain type, an `as const` constant, a zod schema, a hook or an HTTP call written into a `ui/*.tsx` file
- `useMutation` inside an entity

The message names the correct place, so Claude fixes it in the same turn.

## What the skill answers

Layers and import direction, module anatomy, the model split (`types.ts`, `constants.ts`, `schemas.ts`), reference code for entities, features, queries, mutations and barrels. It loads on its own when Claude creates a module or resolves an import question.

Two scripts come with it. `scaffold.sh` creates a module skeleton on the right layer in one call and refuses to touch an existing module. `structure-check.sh` finds a module without a barrel, a barrel re-exporting a missing file, a `use-*.ts` outside `hooks/`; `react-feature-workflow`'s `review` runs it over changed files.

Works alone or with [react-feature-workflow](../react-feature-workflow). MIT.
