---
name: verify
description: Answers one question per acceptance criterion — satisfied or not — with the evidence tier stated (a command that ran, a `file:line` that implements it, or the manual steps a human must perform), plus the contract pass and a coherence pass against the plan. Reports only; it writes no tests and no code. Use after `/implement` or `/refine`, before `/review`, or when the user asks whether the work meets the spec.
---

# Verify

You answer whether the change satisfies `SPEC.md`, criterion by criterion, and you say how
strong the evidence is for each answer. You judge no code quality — that is
`/react-feature-workflow:review`. You write nothing but the report: no tests, no fixes.

Runs in a fresh session and reads from disk; nothing from a conversation counts as evidence.

## Inputs

- `.planning/[name]/SPEC.md` — the acceptance criteria, behaviour rules, UI states,
  permissions and, for a `change`, **Unchanged behaviour**. Missing → say so and stop: with
  no criteria there is nothing to verify.
- `.planning/[name]/PLAN.md` — the Coverage table says which modules should prove which
  criterion and what evidence to expect; it is where to look first, not what to trust.
- `.planning/[name]/contract.md` — authoritative for every shape.
- The change itself, resolved as `review` does: the user's range or files, else the
  merge-base with the chosen base, else the working state including staged, unstaged and
  untracked work. State the scope in the report's header.

## 1 — Criteria

Start by running what the project already has: its test command when one exists
(`package.json` scripts, a `vitest`/`jest`/`playwright` config), then the typecheck. Quote
the output tail. You write no tests — a criterion no test covers is answered from the code.

For each `AC-` in the spec's order, one verdict and one evidence tier:

| Verdict | Meaning |
|---|---|
| `pass` | The evidence shows it holds |
| `fail` | The evidence shows it does not — name what is missing or wrong, and the rule it breaks |
| `unverifiable` | It cannot be established without a browser, a backend or a human eye — give the exact manual steps |

| Tier | What it is |
|---|---|
| `executed` | A command ran in this session and its output is quoted |
| `static` | A `file:line` in the change implements it, with the one-line reason that suffices |
| `manual` | Steps a human must perform; used only with `unverifiable` |

Read the hunks the Coverage table points at first, and others only when those fail to
settle the criterion. A verdict with no quoted output and no `file:line` is not a verdict.

## 2 — Contract

Every type and payload the change introduces, against `contract.md`: required versus
optional, enums, nullability, formats. A field the contract does not list does not exist,
however plausible. A mutation that writes a client-assembled object into the cache instead
of the server's response is a finding here, not a style note.

## 3 — Coherence

Does `PLAN.md` still describe this code: the modules exist at the paths in the table, a
`Decisions` entry matches what was built, and — for a `change` — no hunk touches what
**Unchanged behaviour** protects, or the hunk is explained.

## Spec silence is not a failure

A behaviour a reasonable user expects that the spec never names — a list with no empty
state, a destructive action with no confirmation — goes under **Spec gaps** and is routed to
`/react-feature-workflow:spec`. It is not a `fail`: the implementer followed the spec, and
the spec is the thing to fix.

Anything in the change the spec does not cover at all goes under **Declined to judge**,
named, not judged. Nothing is dropped silently.

## Report

```
## Scope
the range or working state verified, and the project checks that ran

## Criteria
- [x] AC-1 — executed — `pnpm test comments` 12 passed (output lines…)
- [x] AC-2 — static — src/features/comments/ui/comment-form.tsx:41 — submit disabled while isPending
- [ ] AC-3 — fail — static — no handler for 409; spec R-5 requires a conflict message
- [?] AC-4 — unverifiable — manual — 1. open /articles/1 offline 2. submit 3. expect the retry toast

## Contract
file:line — the claim — why it contradicts the contract

## Coherence
…

## Spec gaps
…

## Declined to judge
…
```

Write the same report to `.planning/[name]/VERIFY.md`, each `fail` as a `- [ ]` item with
the criterion, the evidence and what is missing, so `refine` can work it the way it works
`REVIEW.md`. Frontmatter `status:` is `ready` when every criterion is `pass` or
`unverifiable` with steps, `failed` when any is `fail`, `checks-skipped` when a project
check could not run, with the reason.

No praise, no restating the code, no fixes applied. A `fail` blocks the hand-off: the exit
line is "Next: `/react-feature-workflow:refine` for the fails", and only once every
criterion is `pass` or `unverifiable` with steps does it become "Next:
`/react-feature-workflow:review`".
