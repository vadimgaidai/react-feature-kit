# Evals

Seventeen cases over the claims in [docs/DESIGN.md](../../../docs/DESIGN.md) — the ones that
are behaviour, not documentation, and that a regression would break silently.

| Case | Asserts |
|---|---|
| `spec-feature` | `/spec` writes `.planning/comments/SPEC.md` and nothing else: EARS-lite `R-` rules, acceptance criteria citing them, what the request left unsaid under `## Assumptions`, no module path or library name in the file, at most two source files opened. |
| `spec-change` | A request against a module that already exists gets the `change` shape and an `## Unchanged behaviour` section — the half of a change nobody writes down. |
| `plan-traceability` | `/plan` turns the spec into modules with a `Serves` column and a Coverage table, names the one thing the spec needs and the contract has no source for (the author avatar), never copies the spec's rules into the plan, never opens the raw OpenAPI file, writes no code. |
| `verify-criteria` | `/verify` answers all four acceptance criteria with a verdict and an evidence tier — the order criterion from the test command it ran, the disabled submit from a `file:line`, the missing 409 branch as a fail, the offline retry as unverifiable with manual steps — catches the field the types carry and the contract never lists, edits nothing, writes `VERIFY.md`. |
| `contract-outranks-plan` | The raw OpenAPI spec is never read — not with `Read`, not through the shell — and a field the plan's prose asks for but the contract does not define is left out and reported. |
| `sibling-outline` | The tone reference is outlined with `sibling-outline.sh`, not read whole — at most two targeted `Read`s in the module, none through the shell, never an unbounded read of its 400-line type file — and the new module mirrors its folder shape and key factory. |
| `review-skill-conformance` | `review`'s `skills` angle finds five planted violations by reading each governing skill's own `## Reviewing`/`## Never` section and the project's `.claude/rules` — a redundant effect, a hand-written query key, a `dark:` override, a `space-y-*` in a flex, a schema inline in a component — never reads the comparison module whole, edits nothing, writes `REVIEW.md`. |
| `review-deslop` | `/review` judges a module that is plausible line by line and wrong as a set of decisions — one planted instance of each of the six slop questions, a removed export, an index key. Every finding in three parts (what, why not here, fix) at a `file:line`; the comparison module read only in the ranges a comparison needs; nothing edited; a verdict inside the review's scope; the report in `REVIEW.md`. |
| `hooks-block-shortcuts` | The three guard hooks are wired and fire: the prompt asks outright to `cat` the sliced spec, `Read` a 400-line type file whole and `cat` a sibling source file, and each is refused, with neither body entering the window. |
| `format-on-write` | The Prettier hook is wired: a stub `prettier` in the fixture records the `--write` call the hook makes after Claude writes a file. |
| `cross-cutting-feature` | Modeled on a real run, a guided tour across a dashboard app: one new folder-shaped context mirroring a five-file sibling, edits to five existing files, a plan-approved library already installed. Asserts the outline replaces reading the sibling, the existing files are edited in place, the 340-line catalogue and the 750-line `.d.ts` are not read whole or grepped a dozen times, typecheck runs, and neither the dev server nor the `run` skill is started — the two things the real session got wrong. |
| `code-shape-conventions` | `review` catches the `code-shape` slop planted on a feature branch: a narrative comment, a third positional parameter, a nested ternary, a `find` over a second collection repeated per row, a boolean flag parameter, a magic number. |
| `typescript-conventions` | `review` catches the `typescript` slop planted on a feature branch: an `as` cast outside a boundary, `any`, a non-null assertion, an optional-everything interface, a non-exhaustive switch over a union. |
| `error-handling-conventions` | `review` catches the `error-handling` slop planted on a feature branch: a catch that logs and continues, a try/catch in a component body, a duplicated `onError`, a fallback that silences a required field, a generic toast for every failure. |
| `routing-conventions` | `review` catches the `routing` slop planted on a feature branch: a filter kept in `useState` instead of the URL, a search-param update that drops the others, a loader holding its own copy of data instead of prefetching into the query cache, a hand-rolled navigation-pending flag, a layout that blanks its chrome while a child route loads. |
| `react-testing-conventions` | `review` catches the `react-testing` slop planted on a feature branch: a test that mocks the component under test, and an arbitrary `setTimeout` standing in for a testing-library query. |
| `review-pairs` | `review` finds four defects and leaves their legitimate twins alone, each pair in separate files: props sorted in place / a local copy sorted; a compound part with its own copy of `Root`'s state / a part reading context; `reset` on every refetch / reset on entity change with `keepDirtyValues`; an infinite query on the list key / its own `infinite(filters)` entry. `review-deslop` and `code-shape-conventions` carry the other two twins (an editable draft reset by `key`, a necessary pair-wise loop). |

No `llm` graders are left: the two the retired `review-scoped-to-diff` case had asked whether
a named field and a named defect appear in the report, which a regex answers without a judge. Three judge votes
at temperature zero are one vote, and all three once failed a report whose first finding
was the exact sentence the criteria asked for.

Two kinds of grader, and the split matters once hooks are in play. A `tool_used` grader counts
attempts, and a call the hook refuses is still an attempt — so those graders tolerate one.
The hard check is a `regex` grader over the trace for a string that exists only inside the
forbidden file (`match: not_contains`): whatever the model tried, the body never entered the
window. `hooks-block-shortcuts` adds the third kind — the hook's own tag in the trace — which
is what proves a `hooks.json` typo would be caught.

`typecheck` and `test` in the fixtures are `echo`: a grader can prove the command ran,
never that the code is good, so no grader reads their output as quality evidence.

The `review` cases bind a finding to its evidence, not to a token: `joinName` has to appear
near `formatName` (the existing helper the finding must name), `fullName` near "derived" or
"determined by", the fetch-in-effect at its `file:line` near the project's query layer — a
report that mentions `useEffect` in passing is not a finding. `tool_used` graders with
`max: 0` prove the negatives: no `Edit`, no `Write` under `src/`, no whole-file `Read` of the
comparison module (a ranged read with `limit`/`offset` is the sanctioned kind).

`AskUserQuestion` has no counterpart in a headless run, so the three planning cases answer
the interview inline in the prompt and measure the file that comes out of answers the skill
already has. What they cannot measure is the question-ranking itself; the `plan` case keeps a
cap of two `AskUserQuestion` calls so a pass that blocks on a pre-decided dependency fails.

The two `implement` cases name the skill in the prompt. A plain-language "build the plan"
request fired it in 2 of 6 runs, and only after the model had read the plan
and every sibling file — by then the behaviour under test had already happened. Naming the
skill measures what `implement` does when used the way the README says to use it; the
`implement-fired` grader stays as a sanity check.

Each case builds its own fixture project from the `scaffold.sh` next to its `case.yaml`
(`context.scaffold_script` is a path, not a script body), so the suite has no shared
fixtures directory and no network dependency. `typecheck` in those fixtures is `echo` — the cases test the
workflow, not TypeScript.

## Run

```bash
claude plugin eval plugins/react-feature-workflow \
  --scaffold \
  --allow-tools Bash Write Edit
```

`--scaffold` is required: without it the fixture is never created and every case fails on
a missing `PLAN.md`. `--allow-tools` is required because `Bash`, `Write` and `Edit` are
gated inside eval runs. Narrow with `--case contract-outranks-plan`, and use
`--ablation with-without` to see the delta against a no-plugin arm.

How to read a result: a with-arm below 1.00 is a regression, and a Δ near zero means the
case stopped measuring the plugin. A full run is about $10 and five minutes at `-j 3`.

Results land in `evals/results/<timestamp>/` (gitignored) plus an HTML report. The report
is also published to claude.ai when the account allows it; `--no-publish` keeps it local.

## Availability

`claude plugin eval` is in early access, enabled per organization. Where it is not
enabled the command prints `` `plugin eval` is currently in early access `` and exits 1.
Self-test: run `claude plugin eval --trust-plugin` in an empty directory — `No eval cases found` means
it is enabled here.

The half of the suite that runs everywhere is `scripts/test-scripts.sh`: it exercises
`sibling-outline.sh` against a generated module and runs every case's `scaffold_script`,
so a broken fixture fails CI even where the graded runs cannot.

## Not covered

The question-asking itself (`AskUserQuestion` has no counterpart in a headless run, so the
planning cases pre-answer it), `block-builder` and `theme-sync` (both need the Figma MCP server), Prettier itself
(`format-on-write` proves the hook calls it, with a stub standing in), and
`contract-slice.mjs` itself — the cases hand-write the `contract.md` a real run would
slice, so they test what `implement` does with a contract rather than how it was cut.
