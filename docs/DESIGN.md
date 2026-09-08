# Design decisions

Why the kit is shaped the way it is. Everything here is about `react-feature-workflow`; FSD enforcement is a separate opt-in, covered at the end.

## What stays out of the context window

The main axis of the design. Five mechanisms, each replacing something that would otherwise be read, generated or pasted into the session:

- **The contract is sliced, not read.** `contract-slice.mjs` cuts the OpenAPI/Swagger spec down to the endpoints the feature names and inlines every `$ref` into `contract.md` — required vs optional, enums, formats, nullability. `/implement` reads that file and never re-fetches the spec.
- **Figma payloads live in subagents.** `block-builder` and `theme-sync` fetch the design context, write the files or the token map, and return a short report. The payload is spent in the subagent's window; the main session receives components, not JSON.
- **Skeletons come from a script.** Where a structure plugin ships a scaffolder, `/analyze` runs it per module: directories, barrels and empty model files appear in one shell call, and generation spends tokens only on the code that differs per feature.
- **Each stage is a fresh session.** The plan and the contract are files, so `/implement` and `/review` start clean and read them from disk. The planning conversation adds nothing to the build, and a session reviewing code it just wrote is biased toward approving it.
- **Formatting costs nothing.** A PostToolUse hook runs Prettier on every file written, so neither the implementer nor the reviewer spends output on formatting. The convention skills (React 19, TanStack Query, shadcn/ui, RHF + Zod) load per layer as Claude writes — none of them occupies context until its layer is being written.

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
