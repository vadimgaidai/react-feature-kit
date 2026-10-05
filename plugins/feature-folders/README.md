# Feature Folders

A [Claude Code](https://claude.com/claude-code) plugin for projects that aren't
Feature-Sliced Design but still want "where does this go?" answered by a
table instead of a guess: a `structure` skill with global buckets
(`components/`, `hooks/`, `providers/`, `lib/`, `config/`, `api/`) plus
feature/page/layout modules, a scaffolder, and hooks that reject a new file
outside them or a wrong filename — not in review after.

Unlike [`feature-sliced-design`](../feature-sliced-design), this plugin has no
layer hierarchy and no import-direction rule, and its placement and naming
hooks only block **new** files — editing or overwriting a file that already
exists always passes. The content hook is different: a domain type, an
as-const constant, a schema, a hook or an HTTP call landing in a UI file is
new slop wherever it lands, so that hook checks old files and new alike.
Drop it into a project with years of existing structure and it steers new
work without fighting the old tree. Don't install both plugins in the same
project; pick the one that matches the project's actual architecture.

## Install

```bash
# from the repository root
claude plugin marketplace add vadimgaidai/react-feature-kit
claude plugin install feature-folders@vadimgaidai --scope project
```

Keep `--scope project`: at the default `user` scope these hooks would apply
in every project you open. Commit the `.claude/settings.json` the install
writes, and install `jq` first — see [Requirements](#requirements). Details:
[Getting started](../../docs/GETTING-STARTED.md).

## What's inside

| Component | What it does |
|---|---|
| `structure` skill | Global buckets, the page/layout/feature ladder, the global-vs-local placement table, and reference code for each kind of module (feature, page, layout, api, provider, component, barrel) |
| `scaffold.sh` | Creates a feature/page/layout/api module skeleton in one shell call. Checks kebab-case, refuses to touch an existing module |
| `bucket-placement-validator` hook | Rejects a **new** file written outside a recognized top-level bucket, with a pointer to where that role actually lives. Never blocks an edit to a file that already exists |
| `kebab-case-validator` hook | Rejects a filename that isn't kebab-case |
| `barrel-import-validator` hook | Rejects a barrel import of `@/components/ui` (direct sub-path imports only) |
| `model-placement-validator` hook | Rejects a domain type, an as-const constant, a zod schema, a hook or an HTTP call defined in a UI file, and a feature/page with its own `api/` folder — checks old files and new, since new content is new slop wherever it lands |

## Usage

The skill loads itself when Claude is creating a module, deciding whether a
component/hook/type/constant is local or global, or placing an API call — you
don't invoke it by name. Ask Claude to "add a comments feature" and it checks
the ladder (page, layout, or feature?), the table (local or global?), and
places the API call under `src/api/comments/` instead of guessing.

The hooks need nothing from you:

- a new file dropped outside `app/`, `pages/`, `layouts/`, `features/`,
  `components/`, `hooks/`, `providers/`, `lib/`, `config/`, `api/` or
  `assets/` is rejected with where it belongs — `src/utils/format.ts` points
  to `src/lib/`, `src/services/comments.ts` points to `src/api/comments/`;
- editing `src/utils/format.ts` because it already existed before this plugin
  was installed is never touched by the hook — only new files are checked;
- `UserCard.tsx` is rejected in favor of `user-card.tsx`;
- importing `Button` via the `@/components/ui` barrel is rejected in favor of
  the direct path `@/components/ui/button`;
- a `export interface IComment { ... }` written into a `components/*.tsx` file
  is rejected in favor of `<module>/types.ts`, whether that file is new or
  years old.

## Requirements

The four hooks shell out to `jq`. Without it they exit quietly instead of
blocking a bad write — install `jq` first.

## Fits with

Pairs with [`react-feature-workflow`](../react-feature-workflow) (plan/build/review
plus the React conventions) from the same marketplace, but works alone in any
React project.

## License

MIT. Part of [React Feature Kit](https://github.com/vadimgaidai/react-feature-kit).
