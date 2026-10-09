---
name: refine
description: Applies requested changes to a just-implemented unit of work — the step between `/implement` and `/review` for "I looked at it and want this different". Reads `.planning/[name]/` as the authority, classifies each remark (missed plan vs changed mind vs design mismatch vs new scope), fixes accordingly and keeps PLAN.md in sync so review verifies the current truth. Use when the user wants changes to what was just built, before or instead of a review.
---

# Refine

You change what `/implement` built, steered by what the user saw. Main session, no fan-out, the same conventions and the same authorities as `implement` — refining is not freeform chat that forgets the plan exists.

## Inputs

- `.planning/[name]/SPEC.md` when it exists — authoritative for behaviour and acceptance criteria. A remark that changes what the product does changes this file first.
- `.planning/[name]/PLAN.md` — the HOW being refined: modules, boundaries, decisions.
- `.planning/[name]/contract.md` — authoritative for shapes. Never re-fetch, never edit — it mirrors the server. If the server changed, re-slice with `api-contract`; that is not a refinement.
- `.planning/[name]/DESIGN.md` when it exists — authoritative for tokens, spacing, layout and measurements. Screenshots are read with `Read`; never call Figma MCP for anything it answers.

- `.planning/[name]/REVIEW.md` when it exists — `review`'s CONFIRMED findings as `- [ ]` items, each in three parts (what, why not here, fix), and its PLAUSIBLE ones under `## Open questions`. The first are taken in as below, never applied blind; the second are questions to settle with the user or the code, never tasks.

No `.planning/` folder for this work? Take the change as a direct brief against the project's conventions — and say the spec and plan are missing.

## 0 — Taking in REVIEW.md

A review item is a claim about the code, not an instruction. For each open box, in order:

1. **Read the whole item** before touching anything — the three parts are one argument.
2. **Verify it against the code as it is now.** Open the `file:line`; confirm the complication is there and the "why not here" still holds (the helper it names exists, the second caller it says is missing is missing, the contract line it cites says that). An item the code refutes is marked `[x] refuted — <the line that proves it>` and left alone.
3. **Apply the fix**, one item at a time, the smallest change that keeps the behaviour; run the typecheck after each. Tick the box with one line naming what changed.
4. **Push back with evidence, not comfort.** An item that would break behaviour, remove a designed state or contradict `PLAN.md` / `contract.md` is not applied: mark it `[x] declined — <reason, with the file:line or plan line>`. No "good catch", no "you're right" — the diff is the acknowledgement.
5. **Unclear item → stop and ask** before applying any of the others; items can depend on each other, and half an understanding is a wrong edit.

Blocking items (a red check, a contract violation) first, then simple ones, then the ones that restructure. An open question is answered — by a line of code you can quote, or by asking — and recorded under it; it is never turned into an edit on its own. Set the frontmatter `status` to `done` when every box is ticked, `partial` when any is left open with a reason.

## 1 — Classify each remark (the user's)

| Kind | Test | Action |
|---|---|---|
| **Missed** | The plan already says it; the implementation didn't do it | Fix the code. No plan edit. |
| **Changed mind, behaviour** | The spec says A; the user now wants B on screen | Fix the code **and** update `SPEC.md` — the `R-` rule, the UI state, the permission, the affected `AC-` — plus the plan's Coverage row when the mapping moves. |
| **Changed mind, structure** | The behaviour stands; the plan's HOW changes | Fix the code **and** update `PLAN.md` only — the module section, boundary or decision the change touches. |
| **Design mismatch** | "doesn't match the design" | Check `DESIGN.md` first: a coding error → fix it; a recorded NO MATCH / gap → that is a pending decision, ask the user, don't guess. A presentational block wrong at the markup level → one `block-builder` call with its node URL; never a Figma fetch in this session. |
| **New scope** | A new module, endpoint, role rule — or any dependency change | Not a refinement. Name it and route it: new behaviour → "run `/react-feature-workflow:spec`"; a new module for behaviour the spec already has → "run `/react-feature-workflow:plan`". |

A message that mixes kinds gets split: do the refinements, list what you routed away.

## Rules

`implement`'s rules apply unchanged — conventions loading order, a structure skill wins placement (sibling shape is the fallback), no dependency the plan does not name, tokens over raw values, `.d.ts` over prose. Two additions:

- The smallest change that satisfies the remark. A refinement that rewrites a working module is a rewrite, not a refinement.
- Every `SPEC.md` and `PLAN.md` edit is announced as old → new, never silent — both are shared state between the commands.

## Verify

The project's typecheck. Nothing heavier.

## Output

Files changed; every `SPEC.md` and `PLAN.md` edit as old → new; anything routed to `spec`, `plan` or `api-contract`, with the reason. Then: "Next: `/react-feature-workflow:review`" — or another pass here if more comes up.
