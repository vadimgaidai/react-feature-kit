# React Feature Workflow

Spec-driven development for React features in [Claude Code](https://claude.com/claude-code). Six commands, each a stage that writes a file for the next one. Fresh session per stage.

## Install

```bash
claude plugin marketplace add vadimgaidai/react-feature-kit
claude plugin install react-feature-workflow@vadimgaidai --scope project
```

Commit the `.claude/settings.json` it writes. Scope and requirements: [Getting started](../../docs/GETTING-STARTED.md).

## Commands

| Command | Reads | Writes |
|---|---|---|
| `/react-feature-workflow:spec` | your request, point lookups in the code | `.planning/<name>/SPEC.md`: behaviour rules with ids, UI states, permissions, failure cases, acceptance criteria, assumptions |
| `/react-feature-workflow:plan` | `SPEC.md`, `CLAUDE.md`, the structure skill | `PLAN.md`: modules in build order, each citing the criteria it serves; `contract.md` cut from your OpenAPI file; `DESIGN.md` from Figma |
| `/react-feature-workflow:implement` | `SPEC.md`, `PLAN.md`, `contract.md`, `DESIGN.md`, one sibling module outlined | code, then your typecheck |
| `/react-feature-workflow:verify` | `SPEC.md`, the plan's coverage table, the diff | `VERIFY.md`: each criterion pass, fail or unverifiable, with the evidence: a command that ran, a `file:line`, or manual steps |
| `/react-feature-workflow:review` | the diff file by file, the rules the project states, the convention skills | `REVIEW.md`: style violations with the rule and the line, engineering remarks with the argument |
| `/react-feature-workflow:refine` | `VERIFY.md`, `REVIEW.md`, your remarks | code; `SPEC.md` when the behaviour changed, `PLAN.md` when only the structure did |

Nothing edits code except `implement` and `refine`. `verify` and `review` report.

## A feature, end to end

```
/react-feature-workflow:spec add comments to articles
```

Claude rates nine categories against the request (data, flow, UI states, permissions, persistence, failures, non-functional, done signals, scope), asks at most five questions, and writes the rest down as assumptions. Read `SPEC.md` and fix it. It holds no file paths and no code.

```
/react-feature-workflow:plan
```

Asks only what the code cannot answer: a dependency, a name collision, a HOW the spec left open. Refuses to hand off while a criterion has no module or the contract lacks something the behaviour needs.

```
/react-feature-workflow:implement
/react-feature-workflow:verify
/react-feature-workflow:review
```

Each in a fresh session. A failed criterion sends you to `refine` before review. The spec wins over the plan on behaviour; the contract wins over the plan on shapes; both deviations are reported, never silently resolved.

Shapes: `spec` classifies the request as a block, a layout, a feature or a change, or you prefix it (`spec change: …`). A block skips the workflow and goes to `block-builder`. A change gets a delta spec with an "unchanged behaviour" section.

## Convention skills

Load on their own while Claude writes the matching layer. `review` reads their `## Reviewing` sections.

| Skill | What it does |
|---|---|
| `react` | Decides where state lives, when an effect is needed at all, when memoization is worth it, and how a route or a heavy widget is split and wrapped in Suspense. |
| `tanstack-query` | Keeps queries and mutations consistent with the project's shared client: how a key is built, when a query is dependent or derived, what a mutation invalidates. |
| `ui-conventions` | Keeps components on shadcn primitives and semantic tokens so they look right in both themes, and decides when a primitive is extended rather than copied. |
| `react-hook-form-zod` | Builds forms the way the project does: the schema in its own file, the resolver as the only validation, the form values and the schema output kept identical. |
| `code-shape` | Holds the house style for plain code: how much of it there should be, how a function takes its parameters, how branching reads, when a loop is doing repeated work. |
| `typescript` | Keeps types honest: narrowed once at the boundary, derived from the contract instead of written twice, impossible states made unrepresentable. |
| `error-handling` | Assigns each error one owner in this stack and says what a catch is allowed to do with it, so failures are neither duplicated nor swallowed. |

## Agents and hooks

- `@react-feature-workflow:block-builder <node-url> into <path>` builds one presentational block from Figma.
- `@react-feature-workflow:theme-sync <figma-url>` maps Figma variables onto shadcn tokens, light and dark.
- `@react-feature-workflow:bug-fixer <description>` reproduces one bug and fixes it with the smallest change.

Three `PreToolUse` hooks refuse what the skills rule out: reading the raw OpenAPI file a contract was cut from, reading a source file over 300 lines without a `limit`, dumping source files through the shell. `RFW_GUARDS=off` disables them for a session. A `PostToolUse` hook runs Prettier on every file written.

## Requirements

- `node` for the hooks.
- The Figma MCP server for `theme-sync` and `block-builder`. Without it `implement` builds all UI itself.
- A React project for the convention skills. Elsewhere they never load and the workflow runs as is.

MIT. Part of [React Feature Kit](../../README.md).
