---
name: review
description: Judges the engineering decisions in a diff — against the convention skill that governs each hunk, the rules the project states, the module it should resemble, and six questions that find AI slop — and backs every finding with evidence. Reports only; fixes are a separate request through `refine`. Takes an optional angle argument (`skills`, `structure`, `sibling`, `slop`) and a git range. Use before opening a PR, or when the user asks to review changes.
---

# Review

A code-quality stage over AI-written code, scoped to **the change under review**. You judge
what no tool can — whether a decision was necessary, how complex it is, whether it fits
this project — and you prove each claim. The project's typecheck, lint and tests stay the
project's checks. Not this skill's job: correctness bugs (`/code-review`), security
(`/security-review`), generic simplification (`/simplify`) — the report says so, and the
verdict never speaks for them.

## 1 — Define the scope, then get all of it

Say what is under review before reading a line. Default: everything that differs from the
default branch, committed or not. The user may name a range or a path instead.

```bash
base=$(git merge-base HEAD origin/HEAD 2>/dev/null || git merge-base HEAD main)
git diff "$base"                               # committed + staged + unstaged, against the base
git ls-files --others --exclude-standard       # untracked files: read each one whole
```

`git diff "$base"` alone misses untracked files; `git diff` alone misses staged and
committed work. Both lines, every time, and the report's header states the scope used. A
removed line is as much the change as an added one — a dropped guard, a deleted export, a
renamed file each get a verdict.

Argument: `review [angles] [range|path]`. Angles are `skills`, `structure`, `sibling`,
`slop`; none means all four. A focused run is a shorter report, never a narrower scope.

## 2 — Find the rules that apply

Only rules the project or this kit **states**; never an architecture inferred from folder
names.

- `CLAUDE.md`, and every `.claude/rules/*.md` — read each one's frontmatter; a rule applies
  when its `paths:` (a string or a list) matches a changed file, or it has no `paths:`.
- A structure skill, if one is loaded (`feature-sliced-design`, `feature-folders`, or the
  project's own): its `## Reviewing` section is the placement rubric, and a check script it
  names (`structure-check.sh <changed files>`) is run and its lines go under **Checks**.
  Rules written in `CLAUDE.md` or docs count the same way; an installed plugin is not a
  precondition for checking placement. No stated structure rules → the `structure` angle
  says so and makes no placement finding.
- The convention skill that governs each hunk, chosen by what the hunk does: an effect,
  state, memo, context or JSX → `react` (and `ui-conventions` for `className`); a query
  key, `useQuery`, mutation or invalidation → `tanstack-query`; a schema or form →
  `react-hook-form-zod`; `try`/`catch`, `onError`, a toast, `??`/`?.` on data →
  `error-handling`; a type, cast, narrowing or `switch` on a union → `typescript`; any
  branching, helper or utility → `code-shape`. Read that skill's `## Reviewing` (or
  `## Never`) section; open more of it only when a sentence there needs its context.
- A module to compare against: the one `.planning/<name>/PLAN.md` names, or, without a
  plan, the obvious neighbour — same layer, same role, same folder. Start from
  `bash "${CLAUDE_PLUGIN_ROOT}"/skills/implement/scripts/sibling-outline.sh <path>`; read
  the specific part the comparison needs (its error handling, its query file) when the
  outline is not enough. Say which module and why. None fits → the `sibling` angle says so.
- The project's checks, as `package.json` defines them: typecheck, lint, tests. Run them;
  record pass / fail and the output tail. Their findings go under **Checks** and are never
  re-derived in an angle. A failing check is a finding and sets the verdict (step 4); it
  does not stop the review.

Read any further code a question needs — the caller of a new helper, the type a fallback
guards, the place data is validated — and say in the finding what you opened and why. The
limit is purpose, not a byte count: a file is never opened because it is nearby, and a
pre-existing issue outside the scope is never a finding.

## 3 — Ask the questions

Four angles, in-session, sequentially: one angle over every hunk, then the next. Each is a
set of questions asked of a hunk, not a pattern matched against it; "yes, and it costs
something here" makes a candidate. Record every candidate — there is no cap at this
stage; the cap is on what the report shows, after verification.

**`skills` — is this hunk an instance of a sentence in its governing skill's `## Reviewing`?**
For each sentence there, ask whether the hunk does that. A candidate quotes the sentence
and the hunk's line. No sentence applies → no finding; there is no spirit of the skill.
The applicable `CLAUDE.md` / rules files are read the same way, and a finding from them
quotes the rule.

**`structure` — is this where the stated rules put it?** Only against rules found in
step 2. Ask the rubric's questions of each hunk — is this local thing used by a second
module yet, is this page holding logic, does this module's anatomy match the layer's
skeleton, does this import go against the declared direction — and quote the row or
sentence applied.

**`sibling` — does this look like the module it should resemble?** Against the outline
and whatever part of it you read on purpose: how data is fetched, how errors are shaped,
folder layout, barrel exports, what the same roles are called. A candidate is a structural
mismatch you cannot account for — the baseline is this project's code, not a universal
rule.

**`slop` — was this decision necessary?** Six questions of every hunk. Each names a cost;
the candidate must say what the cost is *here*, and what you checked to know.

1. **Unneeded generality.** A configuration, strategy, factory, generic parameter or
   option nobody passes — for one operation the task and the existing code never vary?
   Check the callers before saying "nobody".
2. **Repeat of an existing solution.** Does this helper, hook or type do what one the
   project already has does? Look — grep for the verb or the noun, check the comparison
   module — and name what you found, or that you found nothing.
3. **Redundant state.** A value stored and then synchronised — an effect setting state
   from props, a copy of a server-cache value — when data already in scope determines it?
4. **Empty layer.** A function or hook that only renames a call, forwards arguments or
   wraps one expression, owning no state and no boundary? One caller alone does not make it
   redundant — a boundary can have one caller; say what it fails to own.
5. **Unjustified defence.** A `try`/`catch`, fallback, `??`, optional chain or default
   branch for a state that cannot occur? A TypeScript type is not a runtime guarantee for
   external data: before calling a guard unnecessary, find where the data is validated or
   produced and name that guarantee. No guarantee found → at most PLAUSIBLE.
6. **Project mismatch.** For an ordinary task, a second way to organise a query, a form, a
   component or a module? The diff owes no explanation; a missing one is uncertainty, not
   proof. Look for the reason — a constraint in the plan, a comment, a difference in the
   data — and only a found absence confirms.

Questions, not violations. A one-line wrapper can be a real boundary; a fallback can be
the designed empty state. The finding is the argument, not the pattern.

## 4 — Verify, then report

Dedup candidates by `file:line` and mechanism. Re-open each hunk and decide:

- **CONFIRMED** — the cost is real here and you checked what makes it so; one clause says
  what.
- **PLAUSIBLE** — the mechanism is real, an exception is possible or a fact is unverified;
  say exactly what would settle it (a caller, a validation site, a plan line).
- **REFUTED** — guarded elsewhere, pre-existing, a style preference, or the project's own
  lint already reports it — quote the line that proves it, and drop it.

Then one sweep over the whole change with the confirmed list in view, for what is not
there yet.

Every finding has three parts; one missing a part is not reported:

1. **What** — the complication or violation at `file:line`, line quoted, with the rule or
   question it answers to (the skill's sentence, the structure row, the slop question by
   number).
2. **Why not here** — the evidence: the data that already determines the value, the helper
   that already exists (named), the validation site that makes the guard dead, the callers
   you checked, the file you opened to know.
3. **Fix** — what to change, why that resolves the problem named in 1, and what behaviour
   must stay the same. A fix is not necessarily shorter: a convention or placement finding
   is resolved by the right shape, not by fewer lines.

"Found a `useEffect` — slop" is not a finding. "`fullName` is fully determined by `firstName`
and `lastName` (`CommentPanel` props, both required); storing it adds a sync and a second
render; derive it during render — the rendered text stays identical" is.

Layout:

- **Header** — the scope as defined in step 1, `+added / −removed`, and each new module's
  line count beside the comparison module's for the same role.
- **Checks** — each project check with pass / fail and its output tail as run in this
  session; a claim with no command output behind it is not made. The structure check's
  lines, when one ran.
- **Findings** — CONFIRMED first, grouped by angle, three parts each. Then **Open
  questions**: the PLAUSIBLE candidates, each with what would settle it. The report shows
  12 findings in full; beyond that, one line each (`file:line` — what) so nothing found is
  lost.
- **Verdict** — one line, inside this review's scope only: *no findings in scope* /
  *findings to take to `refine`* / *a project check is red* — never "ready to merge";
  correctness and security were not reviewed here.
- **Not this skill's job** — one line: `/code-review`, `/security-review`, `/simplify`.

Write the same report to `.planning/<name>/REVIEW.md` when a `.planning/<name>/` folder
exists for this work. Frontmatter `status:` is `ready` only when every project check was
run and passed; `checks-failed` when one is red; `checks-skipped` when one could not run,
with the reason. CONFIRMED findings are `- [ ]` items with their three parts and a fenced
`code` block where the fix is exact enough to paste; PLAUSIBLE ones sit under
`## Open questions` as plain bullets — `refine` treats the first as work and the second as
questions to settle, never as tasks.

## 5 — Fixing is a separate request

`review` edits nothing — not even an obvious one-liner; a reviewer that edits is a second
implementer. When the user asks for the fixes, that is `/react-feature-workflow:refine`:
it reads `REVIEW.md`, verifies each item against the code as it is now, applies the fix
one item at a time with the typecheck after each, and declines with evidence what would
break behaviour or contradict the plan.
