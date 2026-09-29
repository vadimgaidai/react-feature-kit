---
name: implement
description: Implements a planned unit of work end-to-end in one pass — types, data layer, schemas, UI, wiring — from `.planning/[name]/PLAN.md`. Use when the user wants to build, implement, or execute a plan, feature, module or issue, or points at a `.planning/*/PLAN.md`. Invoke it before reading the plan or exploring the code — it says what to read and in what order. Runs in the main session; do not fan out to subagents.
---

# Implement

You implement a whole unit of work in one pass: every layer of every module in the plan, in build order, in this session.

**Do not delegate layers to subagents.** Types, data layer and UI share one contract and one set of conventions; splitting them across agents means re-reading all of it per agent, which costs far more than it saves.

**One exception — presentational blocks from Figma.** When a module's UI entry carries a Figma node URL, the Figma MCP server is connected, **and the block is presentational** — a landing section, a card, a header, where props are the whole boundary — delegate its markup: pass the node URL, the target path from the plan, and the component's props (from the plan and `contract.md`). This is not splitting a layer — it is keeping the Figma payload out of this session. When the plan has several such blocks and none depends on another's output, launch all their `block-builder` delegations in one message so they run concurrently, then wire them once every report is back. You still own types, data layer, wiring, exports and routes.

UI that is inseparable from data and state — a table's cells, a chat's message list, a multi-step form — you build yourself from the plan and `DESIGN.md`, node URL or not: a delegated static shell of it costs more to rework than it saves. Same when Figma MCP isn't connected or there is no node URL.

## Inputs

- `.planning/[name]/PLAN.md` — the whole brief. Missing? Ask the user to run `/react-feature-workflow:analyze`, or take a direct brief for a small change.
- `.planning/[name]/contract.md` — **authoritative for every request/response shape.** Read it; never open the raw OpenAPI/Swagger file it names as its `Source:` — not with `Read`, not with `cat` or `jq` — and never invent a field it does not list. The slice already carries every field, required flag, enum and format the spec has for these endpoints.
- `.planning/[name]/DESIGN.md` when the plan names a design — **authoritative for tokens, spacing, layout and measurements. Never call Figma MCP for anything it answers; its saved screenshots are read with `Read`, not re-fetched.** The only Figma calls during implementation are `block-builder` delegations — one per presentational block; a static shell needs the real node payload, a slice can't replace it. A value flagged "no match" is a real gap: surface it, don't invent one.

## Learn the conventions before writing

In this order, cheapest first:

1. The project's `CLAUDE.md` and `.claude/rules/` — project facts and machine-enforced rules.
2. Any structure or library skill that applies — `structure` for placement, `tanstack-query` for the data layer, `react-hook-form-zod` for forms, `ui-conventions` and `react` for UI. Load the one that matches the layer you are on, not all of them.
3. **The sibling module the plan names** — outlined, not read:

   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}"/skills/implement/scripts/sibling-outline.sh src/entities/article
   ```

   Run it before opening any file in the sibling. One call prints the folder shape, the barrel verbatim, every short file whole (with `path:line` on every line), every exported signature of the longer files at its `path:line`, the key factories and the external imports — the whole tone reference in a few dozen lines instead of a few hundred. What it printed whole you already have; do not `Read` it again. Read a range (`offset`/`limit`) of a longer file only where a signature is not enough — through `Read`, never `cat`, `sed -n`, `awk` or `tail`, so the cost stays visible — and never read a long sibling file whole or the module file by file. **Its folder shape is part of the convention**: subfolders (`components/`, `hooks/`), where types and constants live, what the barrel exports. Mirroring a sibling's runtime pattern while flattening its structure is a defect. (When a structure skill is loaded, it decides placement instead — the sibling rule is the fallback.)

Read the one thing that matches what you are about to write. Never read a whole conventions library up front.

Three hooks enforce the mechanical half of this — the spec stays closed, a long source file is not read without a `limit`, source files are not dumped through the shell. A refused call is not an obstacle to route around: do what its message says.

## Order (per module, in the plan's build order)

1. Constants and enumerations.
2. Types — derived from `contract.md` exactly: required vs optional, enums, formats, nullability.
3. HTTP layer — one function per endpoint, typed both ways, using the project's existing client.
4. Data layer — queries / mutations, wired to the cache keys the plan names.
5. Validation schemas (forms).
6. UI — every state the plan lists (loading / empty / error) and every role rule. Localized text where the project is localized. A **presentational** block with a Figma node URL goes to `block-builder` — one call per block, props stated in the call; integrate what it wrote, then add the loading/empty/error states and role rules the design could not show it. Logic-bound UI you build yourself (see the exception above).
7. Public exports / barrels.
8. Routes and pages last, once the modules they mount exist.

If the contract disagrees with the plan's prose, **the contract wins** — say so, then follow it.

## Rules

- Domain types, lookup maps and magic constants belong in the module's model layer, not inline in components. Only a component's own props type stays local.
- A file does one thing (fetch / map / render). Extract a sub-component when JSX grows past ~80 lines, a hook when state grows, a helper when logic branches.
- No `any`. No values guessed where a contract, token or existing constant exists.
- Don't restate what machine checks already enforce — formatters and linters own formatting and naming. Never add a lint-disable to get past one.
- Before creating a provider, context, hook or helper **inside** a feature/module folder, ask where the repo already keeps that role: the structure skill's layer rules when one is loaded, an existing top-level bucket (`src/providers/`, `src/contexts/`, `src/hooks/`, …) otherwise. Never invent a second home for a role that has one.
- Never add, replace or major-upgrade a dependency the plan does not name. Needing one mid-implementation is a blocking question to the user, not a `pnpm add`.
- When the plan's prose disagrees with an installed package's own types (`.d.ts`), **the types win** — follow them and report the deviation in the output. Same precedence as `contract.md` over prose.

## Verify

Run the project's typecheck. That is the whole verification. Do not run a full build or lint unless the project has no other check — pre-commit hooks and CI own those. Do not start the dev server, open a browser, or invoke the `run` skill: what the feature does in a browser is checked by `/react-feature-workflow:review` against the plan's acceptance criteria, and by the user. When the typecheck passes, write the report and stop.

## Output

Files created/edited, anything newly required (a package to install, a UI primitive to add), and anything in the plan you did **not** build, with the reason. Then: "Next: `/react-feature-workflow:review`" — or `/react-feature-workflow:refine` first, when what you see needs changing.
