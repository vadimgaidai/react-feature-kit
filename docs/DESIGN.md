# Design decisions

Why the kit is shaped the way it is. Everything here is about `react-feature-workflow`; FSD enforcement is a separate opt-in, covered at the end.

## What stays out of the context window

The main axis of the design. Six mechanisms, each replacing something that would otherwise be read, generated or pasted into the session:

- **The contract is sliced, not read.** `contract-slice.mjs` cuts the OpenAPI/Swagger spec down to the endpoints the feature names and inlines every `$ref` into `contract.md` — required vs optional, enums, formats, nullability. `/implement` reads that file and never re-fetches the spec.
- **Figma payloads live in subagents.** `block-builder` and `theme-sync` fetch the design context, write the files or the token map, and return a short report. The payload is spent in the subagent's window; the main session receives components, not JSON.
- **Skeletons come from a script.** Where a structure plugin ships a scaffolder, `/analyze` runs it per module: directories, barrels and empty model files appear in one shell call, and generation spends tokens only on the code that differs per feature.
- **The tone reference is outlined, not read.** `sibling-outline.sh` prints the module the plan names as its folder shape, its barrel, its short files whole (a signature of a ten-line file saves nothing and costs a `Read`), every exported signature of the longer files at a `path:line`, its key factories and its external imports — a few dozen lines where the module is a few hundred. A range read afterwards is allowed where a signature isn't enough; opening a long file whole is not.
- **Each stage is a fresh session.** The plan and the contract are files, so `/implement` and `/review` start clean and read them from disk. The planning conversation adds nothing to the build, and a session reviewing code it just wrote is biased toward approving it.
- **Formatting costs nothing.** A PostToolUse hook runs Prettier on every file written, so neither the implementer nor the reviewer spends output on formatting. The convention skills (React 19, TanStack Query, shadcn/ui, RHF + Zod) load per layer as Claude writes — none of them occupies context until its layer is being written.

## Skills guide, hooks enforce

A skill is advice the model can decline, and the eval traces showed it doing exactly that: a baseline run read a whole module through `for f in …; do cat "$f"; done`, invisible to anything counting `Read` calls. So the mechanical half of the rules above is enforced by three `PreToolUse` hooks that exit 2 and hand the reason back — the spec a contract was sliced from is not opened again, by `Read` or by shell, the slicer being the one sanctioned reader; a source file over 300 lines is not read without a `limit`; source files are not dumped through `cat`, `head`, `sed` or `awk`. What a hook cannot check stays with the skill — the contract outranking the plan's prose, a deviation being reported, a folder shape being mirrored — and the eval suite covers both halves, with one case asking for the three shortcuts outright and expecting each refusal. `RFW_GUARDS=off` disables the guards for a session.

## The request is classified before it is planned

`/analyze`'s first step sorts the request into one of three shapes, and the shape decides how much process it gets:

- a **block** — a hero, a card, a header — gets no plan at all: one `block-builder` call, done;
- a **layout** — a landing assembled from blocks — gets a short interview (one node URL per block, repeats, i18n) and a light plan, with no API questions;
- a **feature** — data, forms, state — gets the full interview and the full plan.

Either side can do the classifying: a `block:` / `layout:` / `feature:` prefix on the request means the user did it themselves and the shape is taken as given; the model classifies only when no prefix is present. The interview runs one question per turn with a recommended answer first, and never asks what the codebase can answer. One request produces one `PLAN.md` even when it spans six modules, so the implementer reads one document; `/review` later returns each acceptance criterion as `[x]`/`[ ]` with a `file:line` behind the verdict.

## The contract outranks the plan

`contract.md` is authoritative for every request/response shape. Where the plan's prose contradicts it, the contract wins and the deviation is stated; a field absent from the slice does not exist, however plausible. If the API's live behavior contradicts the contract itself, both shapes are named rather than silently coding to either — a stale contract is the backend's bug to own.

## Implement builds in one session

`/implement` builds every layer of every module itself — types, HTTP, queries, schemas, UI share one contract and one set of conventions, and re-reading those per subagent costs more than the parallelism returns. The one exception is a presentational Figma block, delegated to `block-builder` purely to keep the design payload out of the window; UI that is inseparable from data and state is built in-session even when it has a node URL.

## Review is scoped to the diff

`/review` reads hunks, not the modules they touch, and skips whatever a machine already guarantees — formatting, naming, lint rules like query-key completeness. Security is deliberately not a pass: Claude Code ships `/security-review` over the same diff, and half a security review inside a conventions review would be worse than either.

## FSD enforcement is a separate plugin

Nothing above assumes a folder layout. If the project does use Feature-Sliced Design, the second plugin adds what a skill alone can't: its `Write|Edit` hooks exit 2, so `src/utils/format.ts`, `UserCard.tsx` and a barrel import of `@/shared/ui` never reach disk, and the rejection names the correct form so Claude fixes it in the same turn. Skip the plugin and you lose the blocking, not the workflow. Import direction (an entity importing a feature) is documented but not hook-enforced — that class of mistake is caught in review.

## A third plugin for everything that isn't FSD

Most projects don't have a layered architecture at all — they have a handful of global folders (`components`, `hooks`, `lib`) and a growing pile of feature folders, and the actual failure mode isn't "wrong layer", it's "local or global?" answered differently every time: a component wrapped for one flow ends up in the shared folder, a hook that's really feature-specific gets promoted because something reused it once. `feature-folders` answers that question with one table instead of a skill's judgment call — a mechanical test per role (component, hook, provider, type, constant, function), default always local, promoted only when its row's condition is true. A page/layout/feature ladder answers the other recurring question (is this a route, a route shell, or a capability with its own state?) the same way, three yes/no checks in order.

Its hook enforces only the half that's actually mechanical — a new file's top-level folder name, and only for files that don't exist yet. Editing a file already on disk always passes, which is the point: this plugin is meant to sit on top of years of existing structure that predates it, steering new work into the buckets without refusing to touch the old tree. `feature-sliced-design`'s hook, by contrast, assumes the whole `src/` is FSD and blocks any write outside its layers — right for a project built as FSD from the start, wrong for one that wasn't. The two plugins encode different premises about the codebase; install the one that matches, never both.
