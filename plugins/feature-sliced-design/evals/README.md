# Evals

One case over the claim that separates this plugin from a bare Vite/React project:
every layer, naming, barrel and content rule is a blocking hook, not a sentence in
`structure/SKILL.md` someone has to remember to apply.

| Case | Asserts |
|---|---|
| `hooks-fire` | The four hooks are wired: a new file outside any FSD layer, a new PascalCase file, a new file importing `@/shared/ui` as a barrel, a new UI file whose content defines a domain interface, an as-const map and a zod schema, and a new entity file importing a feature (the wrong direction) are each refused, with the hook's own tag in the trace, and the refused content never lands in the file. |

Unlike `feature-folders`, there is no "legacy edits pass through" case: every write
under `src/` is FSD here, so these hooks check old files and new alike — there is no
file-existence exemption to test.

Not covered by an eval: the `structure` skill's judgment calls (which layer a thing
belongs to, the model-split placement questions). Those are advice, not a hook —
there is no mechanical pass/fail for them, and an `llm` grader on a call like that is
exactly the kind of low-signal check the sibling plugin's suite dropped.

Each case builds its own fixture from the `scaffold.sh` next to its `case.yaml`, so
the suite has no shared fixtures directory.

## Run

```bash
claude plugin eval plugins/feature-sliced-design \
  --scaffold \
  --allow-tools Write Edit Bash
```

`--scaffold` is required — without it there's no fixture and every case fails on a
missing file. Narrow with `--case hooks-fire`, and use `--ablation with-without` to
see the delta against a no-plugin arm: the no-plugin arm should fail every grader
(nothing refuses the writes).

## Availability

`claude plugin eval` is in early access, enabled per organization — see
[`react-feature-workflow`'s evals](../../react-feature-workflow/evals/README.md#availability)
for the self-test.
