# Feature Workflow

A plan → build → review workflow for [Claude Code](https://claude.com/claude-code), plus self-loading React conventions and Figma agents. The workflow core works in any TypeScript project; the React skills load only where they apply.

## Why

One long chat per feature wastes tokens and loses the spec. This plugin splits the work:

- `analyze` writes the spec to disk — `PLAN.md` plus an API contract — in one session;
- `implement` builds from those files in a **fresh session**; the planning conversation is not needed;
- `review` checks the diff against the plan in a third session, unbiased by having written the code.

Heavy payloads never enter your context: Figma frames are read by the `block-builder` subagent, bugs are reproduced by `bug-fixer` — only the result comes back.

## Install

```bash
/plugin marketplace add vadimgaidai/react-feature-kit
/plugin install feature-workflow@vadimgaidai
```

## Three kinds of work

`analyze` classifies the request first — a block, a page, or a feature — and scales the interview and the plan to it.

### A block — a hero, a card, a header

No planning. One subagent call:

```
@feature-workflow:block-builder https://figma.com/design/XX/landing?node-id=42-15 → src/widgets/hero
```

Builds the block from shadcn primitives and semantic tokens — flex/grid, no `fixed` — and reports every design value that had no token. Running `analyze` on a single block tells you exactly this and stops.

### A page — a landing assembled from blocks

```
/feature-workflow:analyze build the landing from https://figma.com/design/XX/landing
```

The interview is short: page name, one Figma node URL **per block** (a block is a section — hero, pricing, footer), which composites repeat, text/i18n, and what "done" means. No API questions — there is no data. Then:

```
/feature-workflow:implement
```

Each block goes to `block-builder` — one subagent call per block, so the Figma payloads never touch your session — and the implementer assembles the page. Run `@feature-workflow:theme-sync` once beforehand so blocks map onto tokens that match the design.

### A feature — a table, a chat, a checkout: anything with data and state

Three commands, **each in a fresh session**:

```
/feature-workflow:analyze add comments to articles
```

Claude asks a handful of questions, one at a time, each with a recommended answer: name, endpoints (a Swagger URL plus a list like `GET /articles/{id}/comments`), the UI and its loading/empty/error states, permissions, and what counts as done. It doesn't ask what it can find out itself. It writes two files to `.planning/comments/`:

- `contract.md` — request/response shapes for the endpoints you named, pulled from your OpenAPI spec with `$ref`s resolved;
- `PLAN.md` — modules in build order: types, queries and what they invalidate, form schemas, components with their states, i18n keys, acceptance criteria.

**Read the plan** — it's a normal markdown file; fix it before any code exists. Then, in fresh sessions:

```
/feature-workflow:implement    # builds the plan in order, runs your typecheck
/feature-workflow:review       # checks the diff against the plan and the contract
```

`implement` follows your project's conventions (it reads `CLAUDE.md` and one existing module of the same kind), delegates presentational blocks with a Figma URL to `block-builder`, and finishes by telling you what it built and what it skipped. `review` only reports; it changes code when you ask. Narrow it with `/feature-workflow:review contract` (or `correctness`, `consistency`, `perf`).

### A bug

Skip the workflow entirely:

```
@feature-workflow:bug-fixer the comment form submits twice on slow connections
```

A subagent reproduces it, finds the cause and fixes it with the smallest change.

## What's inside

**Commands and agents** — the things you invoke:

| Command | What it does |
|---|---|
| `/feature-workflow:analyze` | Classifies the request, interviews you accordingly, writes `PLAN.md` + a trimmed API contract |
| `/feature-workflow:implement` | Builds everything in the plan, in order, and runs your typecheck |
| `/feature-workflow:review` | Checks the diff against the plan and the contract |
| `/feature-workflow:api-contract` | Trims a Swagger/OpenAPI spec to the endpoints you name, standalone |
| `@feature-workflow:block-builder` | Builds one presentational block from a Figma node URL |
| `@feature-workflow:theme-sync` | Maps a Figma file's variables onto your shadcn tokens, light and dark |
| `@feature-workflow:bug-fixer` | Reproduces and fixes one bug |
| a hook | Runs Prettier on every file Claude writes or edits |

**Convention skills** — these load themselves when relevant; you never invoke them, and they cost no context until they apply:

| Skill | What it covers |
|---|---|
| `react` | React 19 and the Compiler: state, effects, memoization, Suspense, Actions and `use` |
| `tanstack-query` | Query keys, `enabled` / `select` / `useQueries`, how a mutation touches the cache |
| `shadcn-ui` | Semantic tokens instead of raw colors, extending primitives, dark-mode-safe spacing and icons |
| `react-hook-form-zod` | Where schemas live, the `z.input === z.output` rule, the usual resolver errors |

## Theme sync

Run once per design, before building blocks against it:

```
@feature-workflow:theme-sync https://www.figma.com/design/XXXX/my-design-system
```

Reads the Figma variables, maps them onto shadcn's semantic tokens by role, writes the light **and** dark palettes into your CSS, and reports every variable that had no counterpart.

## Keeping the context small

- Run `implement` and `review` in **fresh sessions**. The files on disk are the handoff; the planning chat is dead weight, and the session that wrote the code is its worst reviewer.
- Point at the plan by path, don't paste it — pasting spends the tokens twice.
- One `.planning/<name>/` folder per unit of work, so `implement` has a single authoritative brief.
- Keep the agents as subagents: they read far more than they report.
- One concern per session — a bug fix folded into a feature build produces a diff `review` can't judge.

## Requirements

- The Prettier hook shells out to `node`.
- `theme-sync` and `block-builder` need the [Figma MCP server](https://developers.figma.com/docs/figma-mcp-server/) connected. Without it, `implement` simply builds all UI itself.
- The convention skills assume React; in a non-React project they never load and the workflow runs as-is.

## License

MIT. Part of [React Feature Kit](https://github.com/vadimgaidai/react-feature-kit).
