# Evals

Six cases over the claims in [docs/DESIGN.md](../../../docs/DESIGN.md) — the ones that
are behaviour, not documentation, and that a regression would break silently.

| Case | Asserts |
|---|---|
| `contract-outranks-plan` | The raw OpenAPI spec is never read — not with `Read`, not through the shell — and a field the plan's prose asks for but the contract does not define is left out and reported. |
| `sibling-outline` | The tone reference is outlined with `sibling-outline.sh`, not read whole — at most two targeted `Read`s in the module, none through the shell, never an unbounded read of its 400-line type file — and the new module mirrors its folder shape and key factory. |
| `review-scoped-to-diff` | `/review` returns every acceptance criterion as `[x]`/`[ ]` with a `file:line`, catches both defects planted in the diff, and never opens the untouched sibling module file by file. |
| `hooks-block-shortcuts` | The three guard hooks are wired and fire: the prompt asks outright to `cat` the sliced spec, `Read` a 400-line type file whole and `cat` a sibling source file, and each is refused, with neither body entering the window. |
| `format-on-write` | The Prettier hook is wired: a stub `prettier` in the fixture records the `--write` call the hook makes after Claude writes a file. |
| `cross-cutting-feature` | Modeled on a real run, a guided tour across a dashboard app: one new folder-shaped context mirroring a five-file sibling, edits to five existing files, a plan-approved library already installed. Asserts the outline replaces reading the sibling, the existing files are edited in place, the 340-line catalogue and the 750-line `.d.ts` are not read whole or grepped a dozen times, typecheck runs, and neither the dev server nor the `run` skill is started — the two things the real session got wrong. |

No `llm` graders are left: the two the review case had asked whether a named field and a
named defect appear in the report, which a regex answers without a judge. Three judge votes
at temperature zero are one vote, and all three once failed a report whose first finding
was the exact sentence the criteria asked for.

Two kinds of grader, and the split matters once hooks are in play. A `tool_used` grader counts
attempts, and a call the hook refuses is still an attempt — so those graders tolerate one.
The hard check is a `regex` grader over the trace for a string that exists only inside the
forbidden file (`match: not_contains`): whatever the model tried, the body never entered the
window. `hooks-block-shortcuts` adds the third kind — the hook's own tag in the trace — which
is what proves a `hooks.json` typo would be caught.

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

`analyze` (the interview needs `AskUserQuestion`, which has no counterpart in a headless
run), `block-builder` and `theme-sync` (both need the Figma MCP server), Prettier itself
(`format-on-write` proves the hook calls it, with a stub standing in), and
`contract-slice.mjs` itself — the cases hand-write the `contract.md` a real run would
slice, so they test what `implement` does with a contract rather than how it was cut.
