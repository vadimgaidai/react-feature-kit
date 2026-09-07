# Feature-Sliced Design

**Where a module goes and what is inside it.** A [Claude Code](https://claude.com/claude-code) plugin for projects using [Feature-Sliced Design](https://feature-sliced.design/): one skill that answers layer and import-boundary questions with example code, a deterministic scaffolder, and three hooks that reject a misplaced file, a wrong filename or a barrel import **before it is written** — not in review after.

## Install

```bash
/plugin marketplace add vadimgaidai/react-feature-kit
/plugin install feature-sliced-design@vadimgaidai
```

## What's inside

| Component | What it does |
|---|---|
| `structure` skill | Layers, import direction, module anatomy, the model split, and reference code for each kind of module (entity, feature, queries, mutations, typing, barrels) |
| `scaffold.sh` | Creates a module skeleton on the right layer, checks kebab-case, refuses to touch an existing module |
| `fsd-validator` hook | Rejects a file written outside a valid FSD layer |
| `kebab-case-validator` hook | Rejects a filename that isn't kebab-case |
| `barrel-import-validator` hook | Rejects a barrel import of `@/shared/ui` (direct sub-path imports only) |

## Usage

The skill loads itself when Claude is creating a module, deciding which layer code belongs to, or resolving an import-boundary question — you don't invoke it by name. Ask Claude to "add a comments feature" in an FSD project and it scaffolds on the right layer with the right anatomy instead of guessing.

The hooks need nothing from you either. They run on every file Claude writes:

- a component dropped outside `app/`, `pages/`, `widgets/`, `features/`, `entities/` or `shared/` is rejected with an explanation of where it belongs;
- `UserCard.tsx` is rejected in favor of `user-card.tsx`;
- importing `Button` via the `@/shared/ui` barrel is rejected in favor of the direct path `@/shared/ui/button`.

The rejection message tells Claude what to do instead, so it self-corrects in the same turn.

Import direction (an entity importing from a feature) is described by the `structure` skill but not enforced by a hook, so that class of mistake is caught in review rather than at write time.

## Requirements

The three hooks shell out to `jq`. Without it they exit quietly instead of blocking a bad write — so the checks look like they're running when they aren't. Install `jq` first.

## Fits with

Pairs with [`feature-workflow`](../feature-workflow) (plan/build/review plus the React conventions) from the same marketplace, but works alone in any FSD project.

## License

MIT. Part of [React Feature Kit](https://github.com/vadimgaidai/react-feature-kit).
