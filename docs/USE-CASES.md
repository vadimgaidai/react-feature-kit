# Use cases

Eight situations worked end to end: what you type, what appears on disk, what comes back, and where the kit stops instead of guessing. All commands come from `react-feature-workflow`; the last two scenarios need `feature-sliced-design` and `feature-folders` respectively — never both installed together.

---

## A feature with an API: comments on articles

There is a backend contract, a form, a list, and three UI states nobody has written down yet.

1. `/react-feature-workflow:analyze add comments to articles` — classifies the request as a **feature** and interviews you one question per turn, recommended answer first. It asks for the Swagger URL and the endpoints as `GET /articles/{id}/comments`, `POST /articles/{id}/comments` — never for request or response shapes, because it extracts those itself.
2. The interview ends with two files in `.planning/comments/`:
   - `contract.md` — the named endpoints cut out of the OpenAPI spec by `contract-slice.mjs`: `$ref`s inlined, every field marked `REQUIRED` or `optional`, enums expanded, formats kept. This file, not the spec, is what the implementer reads.
   - `PLAN.md` — modules in build order, queries and what each mutation invalidates, form schema rules, loading/empty/error states per component, and 3–7 acceptance criteria.
3. Read `PLAN.md`. It is a normal markdown file, and this is the cheapest point in the flow to change your mind — no code exists yet.
4. In a **fresh session**: `/react-feature-workflow:implement`. It reads the plan, the contract, `CLAUDE.md` and one existing module of the same kind as a tone reference, builds every module in the plan's order, and runs your typecheck.
5. In a third session: `/react-feature-workflow:review`. It reads the diff with git, runs your typecheck, lint and tests, and asks four sets of questions of each hunk — `skills` (the governing convention skill's `## Reviewing` sentences), `structure` (against the placement rules the project states, when it states any), `sibling` (drift against the module the plan names), `slop` (was this decision necessary: generality, repetition, redundant state, an empty layer, unjustified defence, project mismatch). Every finding is three parts — what, why not here, fix — with a `file:line`, and the report ends with a verdict.

**Where it stops.** `implement` takes every request and response shape from `contract.md`. When the plan and the contract disagree about a field, it follows the contract and says so; a field that is not in the contract does not go into the types. `review` never edits — it writes `REVIEW.md`, and `refine` verifies each item against the code before applying or declining it with evidence; correctness, contract compliance and acceptance criteria are not its job, and the report names `/code-review`, `/security-review` and `/simplify` for what is.

**Why fresh sessions.** Everything the build needs is in the two files, so the planning conversation adds nothing — and a session reviewing code it just wrote is biased toward approving it.

## A landing page from a Figma file

Eight sections, no data, and a design whose palette the app does not have yet.

1. `@react-feature-workflow:theme-sync https://figma.com/design/XX/landing` — once per design. Reads the Figma variables, maps them onto the shadcn token set by role rather than by name, writes both the light and dark palettes into your CSS, and lists every design variable that had no counterpart.
2. `/react-feature-workflow:analyze layout: build the landing from https://figma.com/design/XX/landing` — the `layout:` prefix is your classification, so the shape is settled before the interview starts; without a prefix, `analyze` reads the request and decides the shape itself. The interview is short: page name, one node URL per block (a block is a section — hero, pricing, footer; a page is typically 3–8 of them), which composites repeat across blocks, text/i18n, and what "done" means. No API questions — there is no data.
3. `/react-feature-workflow:implement` — hands each block to the `block-builder` subagent, one call per block, then assembles the page itself. The Figma payloads are fetched and spent inside the subagents; your session receives components and a short report.

**What comes back.** Per block: files written, which shadcn primitives were reused, anything that needs `npx shadcn add`, and every design value that had no token — flagged `NO MATCH`, never silently approximated to the nearest color.

**Why theme-sync first.** A block repeated across the page is planned as one module and built once; but a palette that isn't in the tokens yet makes every block report the same brand colors as `NO MATCH`, and you resolve the same gap eight times.

## One block, straight to the builder

A hero from a frame, into an existing page.

```
@react-feature-workflow:block-builder https://figma.com/design/XX/landing?node-id=42-15 into src/widgets/hero
```

One subagent call. It fetches the design context for that node only — never the siblings — builds the component from shadcn primitives and semantic tokens with flex/grid (never `fixed`: a block must not assume where on the page it lives), downloads the exported icons and images into the repo because Figma's asset URLs expire, and reports what it reused and what had no token.

**Where it stops.** Run `/react-feature-workflow:analyze` on a request this small and its first step — classifying the shape — tells you to call `block-builder` and writes no plan. Prefixing it yourself, `/react-feature-workflow:analyze block: the hero from <node-url>`, gets the same answer without the classification.

## A bug, without the workflow

The comment form submits twice on slow connections.

```
@react-feature-workflow:bug-fixer the comment form submits twice on slow connections
```

The subagent reproduces the bug, names the `file:line` cause before editing anything, and fixes it with the fewest files that kill the cause. If it cannot reproduce the described behavior, it says so instead of fixing a guess.

**Where it stops.** No refactoring, no restyling, no drive-by improvements — adjacent smells are listed under "Not done" and left alone. An optional chain that silences the crash does not count as a fix.

## The design's palette changed

Marketing shipped a rebrand; the app still renders last quarter's colors.

```
@react-feature-workflow:theme-sync https://figma.com/design/XX/design-system
```

The same agent as in the landing scenario, run again. It rewrites the token values in place — `:root` and `.dark` both, always, because a light-only pass leaves dark mode broken — and reports each token's old and new value. Components don't change: they were written against semantic tokens, which is the point of having them.

**Where it stops.** A shadcn token with no design counterpart keeps its current value and is reported as unmapped. Nothing is invented to make the report look complete.

## The types drifted from the API

The backend added a field and made another nullable; the `comments` feature was built three sprints ago.

There is no global contract copy in the repo to refresh, deliberately: a full local copy of a spec that changes every sprint would go stale and lie. The live spec URL stays the source of truth, and the repo holds one small slice per feature, next to its plan. Syncing means re-cutting that feature's slice over the same file:

```
/react-feature-workflow:api-contract re-slice .planning/comments/contract.md
```

The old slice records everything needed to reproduce it — its `Source:` URL at the top and one `## GET /articles/{id}/comments` heading per endpoint — so the re-run takes the same arguments from the file itself. The output is deterministic, byte for byte, which makes the git diff against the committed version the drift report: what appeared, what became nullable, which enum grew. Fix the types against it.

**Where it stops.** One slice at a time. Each feature's `contract.md` stands alone, so when two features use the same endpoint, re-cutting one does not update the other. And if the API's live responses contradict the spec itself, neither shape is silently coded to — both get named, because a stale spec is the backend's bug to own.

## A file lands in the wrong place

Requires `feature-sliced-design`. Claude, mid-task, tries to write `src/utils/format.ts`.

The write is rejected before it reaches disk — `src/utils/` is not an FSD layer — and the rejection message names where the file belongs, so Claude moves it in the same turn instead of you catching it in review. The same hooks reject `UserCard.tsx` (files are kebab-case), a barrel import of `@/shared/ui` (direct sub-path imports only), an `export interface IComment` written into a `ui/*.tsx` file (domain types go in `model/types.ts`), and `src/features/comments` importing from `src/features/auth` (sideways, never allowed).

For a new module, the skeleton is not generated at all: `analyze` runs the plugin's `scaffold.sh`, which creates the directories, barrels and empty model files in one shell call. Generation then spends tokens only on the code that differs per feature. The script refuses to touch an existing module — a refusal means the module exists and should be extended, not recreated.

## A legacy project, not a layered one

Requires `feature-folders`. The project predates any plugin: three years of components under `src/components/`, some feature folders, no layers to speak of. Adding a "restart tour" setting means touching an existing `src/pages/settings/preferences.tsx` and adding one new file.

The edit to `preferences.tsx` is never checked — the placement hook only looks at files that don't exist yet, so years of pre-existing structure are never fought. The new file, a provider for the tour's state, goes through the global-vs-local table: it's mounted in the dashboard layout, so it's global from the start — `src/providers/guided-tour-provider.tsx` — not stashed inside whichever feature folder happened to need it first. Had Claude instead tried `src/features/guided-tour/context.ts`, nothing would have blocked it — the hook only rejects a file outside the recognized top-level buckets, not a judgment call the skill's table already settles case by case.

A second file, `src/utils/format-date.ts`, does get rejected: `utils/` isn't a recognized bucket, and the rejection points straight at `src/lib/format-date.ts` instead.

**Where it stops.** Only new files are steered by the placement and naming hooks; nothing existing is touched, relabeled, or flagged there. The skill's page/layout/feature ladder and its global-vs-local table are followed by Claude's own judgment — they're not hook-enforced — so a promotion call it gets wrong is a review question. `structure/SKILL.md`'s `## Reviewing` section names exactly that split (hook-enforced, script-checkable, judgement) so `review` knows which is which without reading the rest of the skill.
