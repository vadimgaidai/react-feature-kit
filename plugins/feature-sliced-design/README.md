# Feature-Sliced Design

A [Claude Code](https://claude.com/claude-code) plugin for projects using [Feature-Sliced Design](https://feature-sliced.design/): a skill that answers layer and import-boundary questions with reference code, a scaffold script that creates module skeletons deterministically, and four hooks that reject a misplaced file, a wrong filename, a barrel import, an upward/sideways import, or model content in the wrong place before it is written — not in review after.

## Install

```bash
# from the root of a repository that is actually FSD
claude plugin marketplace add vadimgaidai/react-feature-kit
claude plugin install feature-sliced-design@vadimgaidai --scope project
```

Keep `--scope project`: at the default `user` scope these hooks would block writes in every project you open, FSD or not. Commit the `.claude/settings.json` the install writes, and install `jq` first — see [Requirements](#requirements). Details: [Getting started](../../docs/GETTING-STARTED.md), [Claude Code plugin docs](https://code.claude.com/docs/en/discover-plugins).

## What's inside

| Component | What it does |
|---|---|
| `structure` skill | Layers, import direction, module anatomy, the model split, and reference code for each kind of module (entity, feature, queries, mutations, typing, barrels) |
| `scaffold.sh` | Creates a module skeleton on the right layer in one shell call — directories, barrels, model files — so generation is spent only on the code that differs per feature. Checks kebab-case, refuses to touch an existing module |
| `structure-check.sh` | The script-checkable half of `structure/SKILL.md`'s `## Reviewing` section: a module missing its barrel, a barrel re-exporting a file that does not exist, a `use-*.ts` outside `hooks/`, a `.api.ts` with no sibling `.queries.ts`/`.mutations.ts` — run by `react-feature-workflow`'s `review` over changed files, not a hook |
| `fsd-validator` hook | Rejects a file written outside a valid FSD layer |
| `kebab-case-validator` hook | Rejects a filename that isn't kebab-case |
| `barrel-import-validator` hook | Rejects a barrel import of `@/shared/ui` (direct sub-path imports only) |
| `model-placement-validator` hook | Rejects a domain type, an as-const constant, a zod schema, a hook or an HTTP call defined in a UI file; an entity calling `useMutation`; and an upward or sideways import against the layer order — checks old files and new |

## Usage

The skill loads itself when Claude is creating a module, deciding which layer code belongs to, or resolving an import-boundary question — you don't invoke it by name. Ask Claude to "add a comments feature" in an FSD project and it scaffolds on the right layer with the right anatomy instead of guessing.

The hooks need nothing from you either. They run on every file Claude writes:

- a component dropped outside `app/`, `pages/`, `widgets/`, `features/`, `entities/` or `shared/` is rejected with an explanation of where it belongs;
- `UserCard.tsx` is rejected in favor of `user-card.tsx`;
- importing `Button` via the `@/shared/ui` barrel is rejected in favor of the direct path `@/shared/ui/button`;
- a `features/comments` file importing from `@/entities/article` is fine; the reverse — an entity importing a feature, or a feature importing another feature — is rejected;
- `export interface IComment { ... }` written into a `ui/*.tsx` file is rejected in favor of `model/types.ts`, whether that file is new or years old.

The rejection message tells Claude what to do instead, so it self-corrects in the same turn. A worked example is in [Use cases](../../docs/USE-CASES.md).

Import direction is hook-enforced since 0.3.0 — `model-placement-validator` checks every `Write`/`Edit` under a layer against the layers below it.

## Requirements

The four hooks shell out to `jq`. Without it they exit quietly instead of blocking a bad write — so the checks look like they're running when they aren't. Install `jq` first.

## Fits with

Pairs with [`react-feature-workflow`](../react-feature-workflow) (plan/build/review plus the React conventions) from the same marketplace, but works alone in any FSD project.

## License

MIT. Part of [React Feature Kit](https://github.com/vadimgaidai/react-feature-kit).
