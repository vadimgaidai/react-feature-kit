# Design decisions

Why the kit is shaped the way it is. Everything here is about `react-feature-workflow`; FSD enforcement is a separate opt-in, covered at the end.

## What stays out of the context window

The main axis of the design. Six mechanisms, each replacing something that would otherwise be read, generated or pasted into the session:

- **The contract is sliced, not read.** `contract-slice.mjs` cuts the OpenAPI/Swagger spec down to the endpoints the feature names and inlines every `$ref` into `contract.md` — required vs optional, enums, formats, nullability. `/implement` reads that file and never re-fetches the spec.
- **Figma payloads live in subagents.** `block-builder` and `theme-sync` fetch the design context, write the files or the token map, and return a short report. The payload is spent in the subagent's window; the main session receives components, not JSON.
- **Skeletons come from a script.** Where a structure plugin ships a scaffolder, `/plan` runs it per module: directories, barrels and empty model files appear in one shell call, and generation spends tokens only on the code that differs per feature.
- **The tone reference is outlined, not read.** `sibling-outline.sh` prints the module the plan names as its folder shape, its barrel, its short files whole (a signature of a ten-line file saves nothing and costs a `Read`), every exported signature of the longer files at a `path:line`, its key factories and its external imports — a few dozen lines where the module is a few hundred. A range read afterwards is allowed where a signature isn't enough; opening a long file whole is not.
- **Each stage is a fresh session.** The spec, the plan and the contract are files, so `/implement` and `/review` start clean and read them from disk. The planning conversation adds nothing to the build, and a session reviewing code it just wrote is biased toward approving it.
- **Formatting costs nothing.** A PostToolUse hook runs Prettier on every file written, so neither the implementer nor the reviewer spends output on formatting. The convention skills (React 19, TanStack Query, shadcn/ui, RHF + Zod) load per layer as Claude writes — none of them occupies context until its layer is being written.

## Skills guide, hooks enforce

A skill is advice the model can decline, and the eval traces showed it doing exactly that: a baseline run read a whole module through `for f in …; do cat "$f"; done`, invisible to anything counting `Read` calls. So the mechanical half of the rules above is enforced by three `PreToolUse` hooks that exit 2 and hand the reason back — the spec a contract was sliced from is not opened again, by `Read` or by shell, the slicer being the one sanctioned reader; a source file over 300 lines is not read without a `limit`; source files are not dumped through `cat`, `head`, `sed` or `awk`. What a hook cannot check stays with the skill — the contract outranking the plan's prose, a deviation being reported, a folder shape being mirrored — and the eval suite covers both halves, with one case asking for the three shortcuts outright and expecting each refusal. `RFW_GUARDS=off` disables the guards for a session.

Between the two sits the project's own tooling, not ours: `/review` runs the project's typecheck, lint and tests and reports their output under Checks. The kit ships no rule set and no scanner of its own — a second ESLint config would be a second opinion on what the project already decided, and a script that flags a comment, a third argument or a `useMemo` proves nothing about the code. What is formalisable belongs to the project's linter; what needs the context belongs to the model.

## Spec before plan

The behaviour is settled in a file a human reads before any module exists. `/spec` writes `SPEC.md` — the request verbatim, the goal, behaviour as `R-` rules in one constrained grammar, UI states, permissions, persistence, failure scenarios, acceptance criteria that cite the rules they prove, and the guesses it made instead of asking. It holds no file path, no component name and no library: a spec that reads as pseudo-code is the program written twice, and the human gate is worthless if what it gates is implementation.

Gap-finding is a taxonomy, not a fixed interview: nine categories rated Clear, Partial or Missing, the top five by impact × uncertainty asked one question per turn with a recommended answer first, and everything else recorded under `## Assumptions`. A guess written down is cheaper to reverse than a sixth question, and silence in the spec is never read as permission.

`/plan` then writes the HOW and cites the spec rather than copying it: each module carries the `AC-` ids it serves, a Coverage table maps every criterion back to its modules, and a readiness check refuses to hand off while a criterion has no module or the contract has no source for something the behaviour needs. Behaviour lives in one file, so a changed mind has one place to change — `refine` edits `SPEC.md` when the product changes and `PLAN.md` when only the structure does.

## The request is classified before it is specified

`/spec`'s first step sorts the request into one of four shapes, and the shape decides how much process it gets:

- a **block** — a hero, a card, a header — gets no spec at all: one `block-builder` call, done;
- a **layout** — a landing assembled from blocks — gets a light spec (one node URL per block, repeats, i18n, 2–4 criteria) and no taxonomy pass;
- a **feature** — data, forms, state — gets the full spec;
- a **change** — an edit to a module that exists — gets a delta spec plus `## Unchanged behaviour`, so what must keep working is written down before it regresses.

Either side can do the classifying: a `block:` / `layout:` / `feature:` / `change:` prefix on the request means the user did it themselves and the shape is taken as given; the model classifies only when no prefix is present. One request produces one `SPEC.md` and one `PLAN.md` even when it spans six modules, so the implementer reads two documents, not twelve.

## The contract outranks the plan

`contract.md` is authoritative for every request/response shape. Where the plan's prose contradicts it, the contract wins and the deviation is stated; a field absent from the slice does not exist, however plausible. If the API's live behavior contradicts the contract itself, both shapes are named rather than silently coding to either — a stale contract is the backend's bug to own.

## Implement builds in one session

`/implement` builds every layer of every module itself — types, HTTP, queries, schemas, UI share one contract and one set of conventions, and re-reading those per subagent costs more than the parallelism returns. The one exception is a presentational Figma block, delegated to `block-builder` purely to keep the design payload out of the window; UI that is inseparable from data and state is built in-session even when it has a node URL.

## Review answers the conventions

`/review` reads the change with plain `git diff` — the user's range first, else the merge-base with the chosen base, with staged, unstaged and untracked work when the working state is under review — file by file, asking every question of a file's diff once and opening more only for a specific question: the condition above a hunk, a type, a helper's body, a caller, found with `rg` and read in a range. Its four angles are `skills` (is this an instance of a sentence in the governing convention skill's `## Reviewing` section), `structure` (is it where the rules the project states — `CLAUDE.md`, `.claude/rules`, a loaded structure skill — put it; no stated rule, no placement finding), `sibling` (does it solve the same problem differently from the module it should resemble, read only where that comparison helps) and `slop` (was the decision necessary — unneeded generality, a repeat of an existing solution, redundant state, an empty layer, unjustified defence, project mismatch, repeated work over collections). A style violation is reported with the rule and the line; an engineering remark carries its argument; a single caller, an intermediate variable, a long file, a `try/catch`, an optional chain or a fallback is never a finding by itself. Every candidate is checked before the report — about the change, rule applies, concrete cost, no justifying context, fix keeps behaviour — and the verdict speaks only for what was reviewed, never for correctness or security. `review` edits nothing; `refine` takes `REVIEW.md` in, verifies each item against the code and applies or declines with evidence. Correctness, contract compliance and acceptance criteria are out of scope here. Security is deliberately not a pass either: Claude Code ships `/security-review` over the same diff, and half a security review inside a conventions review would be worse than either. Generic simplification is `/simplify`'s.

## FSD enforcement is a separate plugin

Nothing above assumes a folder layout. If the project does use Feature-Sliced Design, the second plugin adds what a skill alone can't: its `Write|Edit` hooks exit 2, so `src/utils/format.ts`, `UserCard.tsx` and a barrel import of `@/shared/ui` never reach disk, and the rejection names the correct form so Claude fixes it in the same turn. Skip the plugin and you lose the blocking, not the workflow. Import direction (an entity importing a feature) is hook-enforced since 0.3.0 — the same hook that catches a domain type, an as-const constant, a schema, a hook or an HTTP call landing in a UI file instead of `model/`. Both structure plugins ship a `## Reviewing` section in `structure/SKILL.md` naming exactly what their hooks already enforce, so `review` never re-reports it and spends its judgment on what's actually a judgment call.

## A third plugin for everything that isn't FSD

Most projects don't have a layered architecture at all — they have a handful of global folders (`components`, `hooks`, `lib`) and a growing pile of feature folders, and the actual failure mode isn't "wrong layer", it's "local or global?" answered differently every time: a component wrapped for one flow ends up in the shared folder, a hook that's really feature-specific gets promoted because something reused it once. `feature-folders` answers that question with one table instead of a skill's judgment call — a mechanical test per role (component, hook, provider, type, constant, function), default always local, promoted only when its row's condition is true. A page/layout/feature ladder answers the other recurring question (is this a route, a route shell, or a capability with its own state?) the same way, three yes/no checks in order.

Its placement and naming hooks enforce only the half that's actually mechanical — a new file's top-level folder name and its case, and only for files that don't exist yet. Editing a file already on disk always passes, which is the point: this plugin is meant to sit on top of years of existing structure that predates it, steering new work into the buckets without refusing to touch the old tree. `feature-sliced-design`'s layer hook, by contrast, assumes the whole `src/` is FSD and blocks any write outside its layers — right for a project built as FSD from the start, wrong for one that wasn't. The two plugins encode different premises about the codebase; install the one that matches, never both. Both plugins' content hook (`model-placement-validator`) is the one exception to "new files only": a domain type, an as-const constant, a schema, a hook or an HTTP call pasted into an old file is still new slop, so that hook checks every write, old file or new.
