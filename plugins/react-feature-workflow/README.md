# React Feature Workflow

A plan / build / review workflow for [Claude Code](https://claude.com/claude-code), plus self-loading React conventions and Figma agents. The workflow core works in any TypeScript project; the React skills load only where they apply.

`/spec` interviews you and writes the behaviour to disk as `SPEC.md` — rules with ids, UI states, permissions, acceptance criteria — and you fix it before any module exists. `/plan` turns it into `PLAN.md` plus an API contract sliced from your OpenAPI spec, each module citing the criteria it serves, so field names come from the backend rather than from Claude. `/implement` builds from those files in a fresh session; `/review` checks the diff against the convention skills and the sibling module in a third, so the reviewer hasn't just written the code it judges. Figma frames are read by subagents that return components and a short report — the payloads never enter your session.

## Install

```bash
# from the repository root
claude plugin marketplace add vadimgaidai/react-feature-kit
claude plugin install react-feature-workflow@vadimgaidai --scope project
```

Keep `--scope project` (the default is `user` — the plugin would load in every project you open), then commit the `.claude/settings.json` it writes. From a running session, use `/plugin` and pick project scope. Details: [Getting started](../../docs/GETTING-STARTED.md), [Claude Code plugin docs](https://code.claude.com/docs/en/discover-plugins).

## Four kinds of work

`spec` classifies the request first — a block, a page, a feature, or a change to something that exists — and scales the spec to it. Or classify it yourself with a prefix — `spec block: …`, `spec layout: …`, `spec feature: …`, `spec change: …` — then the shape is your call, not the model's. Each of these is worked end to end, with what comes back and where each command stops, in [Use cases](../../docs/USE-CASES.md).

### A block — a hero, a card, a header

No planning. One subagent call:

```
@react-feature-workflow:block-builder https://figma.com/design/XX/landing?node-id=42-15 into src/widgets/hero
```

Builds the block from shadcn primitives and semantic tokens — flex/grid, no `fixed` — and reports every design value that had no token. Running `spec` on a single block tells you exactly this and stops.

### A page — a landing assembled from blocks

```
/react-feature-workflow:spec layout: build the landing from https://figma.com/design/XX/landing
/react-feature-workflow:plan
```

The interview is short: page name, one Figma node URL **per block** (a block is a section — hero, pricing, footer), which composites repeat, text/i18n, and what "done" means. No API questions — there is no data. Then:

```
/react-feature-workflow:implement
```

Each block goes to `block-builder` — one subagent call per block, so the Figma payloads never touch your session — and the implementer assembles the page. Run `@react-feature-workflow:theme-sync` once beforehand so blocks map onto tokens that match the design.

### A feature — a table, a chat, a checkout: anything with data and state

Four commands, **each in a fresh session**:

```
/react-feature-workflow:spec add comments to articles
```

Claude rates what the request leaves unsaid — data, UX flow, UI states, permissions, persistence, failures, non-functional, done signals — asks at most five questions, one at a time, each with a recommended answer, and records the rest as assumptions. It doesn't ask what it can find out itself and it doesn't ask HOW. It writes `.planning/comments/SPEC.md`: behaviour as `R-` rules, UI states, permissions, failure scenarios, and 3–9 acceptance criteria that cite the rules they prove.

**Read the spec** — it's a normal markdown file, it holds no code, and this is the cheapest point to change your mind. Then:

```
/react-feature-workflow:plan
```

It asks only what the spec and the codebase can't answer (a dependency, a name collision, a HOW the spec left open) and writes two more files to `.planning/comments/`:

- `contract.md` — request/response shapes for the endpoints the spec names, pulled from your OpenAPI spec with `$ref`s resolved;
- `PLAN.md` — modules in build order with what each one serves, types, queries and what they invalidate, form schemas, boundaries, a Coverage table per acceptance criterion, and a readiness check before any code exists.

Then, in fresh sessions:

```
/react-feature-workflow:implement    # builds the plan in order, runs your typecheck
/react-feature-workflow:verify       # every acceptance criterion: verdict + how strong the evidence is
/react-feature-workflow:review       # judges the diff's decisions against the convention skills and the sibling module
```

`verify` then answers each acceptance criterion with a verdict and says how strong the evidence is: `executed` when a command ran and its output is quoted, `static` when a `file:line` in the diff implements it, `manual` when only a human with a browser can settle it — and a fail sends you back to `refine` before review. `implement` reads `SPEC.md` for behaviour and `PLAN.md` for the modules, follows your project's conventions (it reads `CLAUDE.md` and outlines one existing module of the same kind rather than reading it), delegates presentational blocks with a Figma URL to `block-builder`, and finishes by telling you what it built and what it skipped. `review` judges the decisions in the diff — against the convention skill that governs each hunk, the module it should resemble, the placement rules you state, and six questions that find AI slop (was this generality, this helper, this state, this layer, this fallback, this second way of doing things necessary here) — and explains every finding in three parts: what, why not here, fix. It runs your own typecheck, lint and tests and never edits; `refine` applies. Not correctness, not security, not generic simplification — Claude Code's `/code-review`, `/security-review` and `/simplify` cover those. Narrow it with `/react-feature-workflow:review skills` (or `structure`, `sibling`, `slop`).

Saw something wrong before running `review`? `/react-feature-workflow:refine move the filters above the table` applies your corrections against the same plan — and when you changed your mind rather than the implementation missing something, it updates `SPEC.md` (behaviour) or `PLAN.md` (structure) too, so the next stage verifies the current truth. Anything that is really new scope (a new module, endpoint or dependency) it routes back to `spec` or `plan` instead of quietly absorbing it.

### A bug

Skip the workflow entirely:

```
@react-feature-workflow:bug-fixer the comment form submits twice on slow connections
```

A subagent reproduces it, finds the cause and fixes it with the smallest change.

## What's inside

**Commands and agents** — the things you invoke:

| Command | What it does |
|---|---|
| `/react-feature-workflow:spec` | Classifies the request, hunts the gaps it leaves unsaid, writes `SPEC.md`: behaviour, acceptance criteria, assumptions |
| `/react-feature-workflow:plan` | Turns the spec into `PLAN.md` + a trimmed API contract, every module citing the criteria it serves, with a readiness check |
| `/react-feature-workflow:implement` | Builds everything in the plan, in order, and runs your typecheck |
| `/react-feature-workflow:refine` | Applies your corrections to what `implement` built, keeping `SPEC.md` and `PLAN.md` in sync |
| `/react-feature-workflow:verify` | Answers every acceptance criterion — pass, fail or unverifiable — with the evidence tier stated, plus the contract pass; reports, never edits |
| `/react-feature-workflow:review` | Judges the diff's decisions against the convention skills, the sibling module, the structure rules and six slop questions; reports, never edits |
| `/react-feature-workflow:api-contract` | Trims a Swagger/OpenAPI spec to the endpoints you name, standalone |
| `@react-feature-workflow:block-builder` | Builds one presentational block from a Figma node URL |
| `@react-feature-workflow:theme-sync` | Maps a Figma file's variables onto your shadcn tokens, light and dark |
| `@react-feature-workflow:bug-fixer` | Reproduces and fixes one bug |
| a PostToolUse hook | Runs Prettier on every file Claude writes or edits |
| three PreToolUse hooks | Refuse the shortcuts the skills rule out: re-reading the spec a contract was sliced from, reading a source file over 300 lines (1000 under `node_modules`) without a `limit`, dumping source files through the shell. `RFW_GUARDS=off` disables them for a session. |

**Convention skills** — these load themselves when relevant; you never invoke them, and they cost no context until they apply:

| Skill | What it covers |
|---|---|
| `react` | React 19 and the Compiler: state, effects, memoization, Suspense, Actions and `use` |
| `tanstack-query` | Query keys, `enabled` / `select` / `useQueries`, how a mutation touches the cache |
| `ui-conventions` | Semantic tokens instead of raw colors, extending primitives, dark-mode-safe spacing and icons |
| `react-hook-form-zod` | Where schemas live, the `z.input === z.output` rule, the usual resolver errors |
| `code-shape` | Least code, control flow, function and parameter shape, naming |
| `typescript` | Narrowing at the boundary, discriminated unions, `satisfies`, no `enum`/`any` |
| `error-handling` | Where errors live in this stack: query cache, mutation hook, form resolver |

## Theme sync

Run once per design, before building blocks against it:

```
@react-feature-workflow:theme-sync https://www.figma.com/design/XXXX/my-design-system
```

Reads the Figma variables, maps them onto shadcn's semantic tokens by role, writes the light **and** dark palettes into your CSS, and reports every variable that had no counterpart.

## Keeping the context small

- Run `implement` and `review` in **fresh sessions**. Everything they need is in `.planning/<name>/`; the planning conversation adds nothing to the build, and a session reviewing code it just wrote is biased toward approving it.
- Point at the plan by path, don't paste it.
- One `.planning/<name>/` folder per unit of work: `SPEC.md` for behaviour, `PLAN.md` for structure, `contract.md` for shapes.
- Keep the agents as subagents: they read far more than they report.
- One concern per session — a bug fix folded into a feature build produces a diff `review` can't check against the plan.

## Requirements

- The hooks shell out to `node`.
- `theme-sync` and `block-builder` need the [Figma MCP server](https://developers.figma.com/docs/figma-mcp-server/) connected. Without it, `implement` simply builds all UI itself.
- The convention skills assume React; in a non-React project they never load and the workflow runs as-is.

## License

MIT. Part of [React Feature Kit](https://github.com/vadimgaidai/react-feature-kit).
