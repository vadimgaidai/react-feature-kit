# Evals

Two cases over the two claims that separate this plugin from a from-scratch
FSD setup: the hooks fire, and they only ever fire on a **new** file.

| Case | Asserts |
|---|---|
| `hooks-fire` | The three hooks are wired: a new file outside any recognized bucket, a new PascalCase file, and a new file importing `@/components/ui` as a barrel are each refused, with the hook's own `[tag]` in the trace. |
| `legacy-edits-pass-through` | The core claim. A pre-existing `utils/`, `helpers/` and a PascalCase component — none of them new — get real edits, and neither the placement nor the naming hook fires even once across all three. The edits are actually applied, not just attempted. |

Not covered by an eval: the `structure` skill's judgment calls (the page/layout/feature
ladder, the global-vs-local placement table). Those are advice, not a hook — there is no
mechanical pass/fail for "should this have been promoted to `src/hooks/`", and an `llm`
grader on a call like that is exactly the kind of low-signal check the sibling plugin's
suite dropped. They stay a review question, same as import direction does for
`feature-sliced-design`.

Each case builds its own fixture from the `scaffold.sh` next to its `case.yaml`, so the
suite has no shared fixtures directory.

## Run

```bash
claude plugin eval plugins/feature-folders \
  --scaffold \
  --allow-tools Write Edit Bash
```

`--scaffold` is required — without it there's no fixture and every case fails on a
missing file. Narrow with `--case legacy-edits-pass-through`, and use
`--ablation with-without` to see the delta against a no-plugin arm: the no-plugin arm
should fail every `hooks-fire` grader (nothing refuses the writes) while still passing
`legacy-edits-pass-through` (nothing to refuse either way), which is the sanity check
that the cases measure the hooks and not the fixture.

## Availability

`claude plugin eval` is in early access, enabled per organization — see
[`react-feature-workflow`'s evals](../../react-feature-workflow/evals/README.md#availability)
for the self-test.
