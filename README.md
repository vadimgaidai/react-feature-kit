# React Feature Kit

Two plugins for [Claude Code](https://claude.com/claude-code): a plan / build / review workflow for React features, and Feature-Sliced Design structure enforcement.

The workflow is organized around keeping the context window small and the API honest. Request and response shapes are cut out of your OpenAPI spec by a script, so field names are never guessed. Figma frames are read inside subagents that return components and a short report, not payloads. The plan is a file on disk, so building and reviewing run in fresh sessions without the planning chat. Module skeletons come from a shell script, not from generation, and the module a build mirrors is outlined by another rather than read.

## Install

```bash
# from the repository root
claude plugin marketplace add vadimgaidai/react-feature-kit
claude plugin install react-feature-workflow@vadimgaidai --scope project       # plan / build / review + React conventions + Figma agents
claude plugin install feature-sliced-design@vadimgaidai --scope project  # FSD structure — only if the project uses FSD
```

Keep `--scope project` — without it the install defaults to `user` scope and the plugins load in every project you open. Scopes, what gets written to `.claude/settings.json`, teammates' setup and requirements: [docs/GETTING-STARTED.md](./docs/GETTING-STARTED.md).

## Which command do I run?

`/analyze` classifies every request as one of three shapes — a block, a page, or a feature — and scales the interview and the plan to it.

| You want… | Run |
|---|---|
| one block from a Figma frame as a component | `@react-feature-workflow:block-builder <node-url> into <path>` — no planning needed |
| a landing / marketing page from a Figma file | `@react-feature-workflow:theme-sync` once, then `/react-feature-workflow:analyze` |
| a feature with an API, forms or state | `/react-feature-workflow:analyze`, then `/react-feature-workflow:implement`, then `/react-feature-workflow:review`, each in a fresh session |
| changes to what was just built, before review | `/react-feature-workflow:refine <what to change>` — fixes against the same plan, updates `PLAN.md` when you changed your mind |
| the app theme to match a design | `@react-feature-workflow:theme-sync <figma-url>` |
| one bug fixed | `@react-feature-workflow:bug-fixer <describe the bug>` |
| an OpenAPI spec trimmed to the endpoints you use | `/react-feature-workflow:api-contract` |

Not sure which shape your request is? Run `/react-feature-workflow:analyze` — classifying the request is its first step. Or classify it yourself with a prefix: `/react-feature-workflow:analyze layout: build the landing from <url>` (also `block:` and `feature:`) — with a prefix the shape is your call, without one `analyze` determines it from the request.

Seven situations worked end to end — a feature with an API, a landing assembled from Figma blocks, a rebrand, a contract that drifted — are in [docs/USE-CASES.md](./docs/USE-CASES.md), including what each command writes to disk and where it stops instead of guessing.

## The plugins

- **[react-feature-workflow](./plugins/react-feature-workflow)** — `/analyze`, `/implement`, `/review` and `/api-contract`; four convention skills (React 19, TanStack Query, shadcn/ui, RHF + Zod) that load themselves as Claude writes the matching layer; three subagents (`theme-sync`, `block-builder`, `bug-fixer`) that keep Figma payloads and bug reproductions out of your session. Full walkthrough in its README.
- **[feature-sliced-design](./plugins/feature-sliced-design)** — a `structure` skill, a module scaffolder, and three `Write|Edit` hooks that reject a misplaced file, a non-kebab-case filename or a barrel import at write time, so the mistake never reaches review. Needs `jq`.

The reasoning behind the shape of the kit — what stays out of the context window, why the contract outranks the plan, why `implement` doesn't fan out — is in [docs/DESIGN.md](./docs/DESIGN.md).

## Third-party skills

This repo contains only original work. Install other people's skills from their own repositories, so they stay attributed and keep updating from source:

```bash
npx skills@latest add shadcn/ui -s shadcn -y
```

## Contributing

Dev loop, checks and the release rule live in [CONTRIBUTING.md](./CONTRIBUTING.md). `./scripts/check-all.sh` runs everything CI runs.

## License

MIT.
