---
name: refine
description: Applies requested changes to a just-implemented unit of work — the step between `/implement` and `/review` for "I looked at it and want this different". Reads `.planning/[name]/` as the authority, classifies each remark (missed plan vs changed mind vs design mismatch vs new scope), fixes accordingly and keeps PLAN.md in sync so review verifies the current truth. Use when the user wants changes to what was just built, before or instead of a review.
---

# Refine

You change what `/implement` built, steered by what the user saw. Main session, no fan-out, the same conventions and the same authorities as `implement` — refining is not freeform chat that forgets the plan exists.

## Inputs

- `.planning/[name]/PLAN.md` — the brief being refined.
- `.planning/[name]/contract.md` — authoritative for shapes. Never re-fetch, never edit — it mirrors the server. If the server changed, re-slice with `api-contract`; that is not a refinement.
- `.planning/[name]/DESIGN.md` when it exists — authoritative for tokens, spacing, layout and measurements. Screenshots are read with `Read`; never call Figma MCP for anything it answers.

No `.planning/` folder for this work? Take the change as a direct brief against the project's conventions — and say the plan is missing.

## 1 — Classify each remark

| Kind | Test | Action |
|---|---|---|
| **Missed** | The plan already says it; the implementation didn't do it | Fix the code. No plan edit. |
| **Changed mind** | The plan says A; the user now wants B | Fix the code **and** update `PLAN.md` — the module section, UI states, acceptance criteria, whatever the change touches — so `/review` verifies today's truth, not the stale one. |
| **Design mismatch** | "doesn't match the design" | Check `DESIGN.md` first: a coding error → fix it; a recorded NO MATCH / gap → that is a pending decision, ask the user, don't guess. A presentational block wrong at the markup level → one `block-builder` call with its node URL; never a Figma fetch in this session. |
| **New scope** | A new module, endpoint, role rule — or any dependency change | Not a refinement. Name it and route it: "run `/react-feature-workflow:analyze`". |

A message that mixes kinds gets split: do the refinements, list what you routed away.

## Rules

`implement`'s rules apply unchanged — conventions loading order, a structure skill wins placement (sibling shape is the fallback), no dependency the plan does not name, tokens over raw values, `.d.ts` over prose. Two additions:

- The smallest change that satisfies the remark. A refinement that rewrites a working module is a rewrite, not a refinement.
- Every `PLAN.md` edit is announced, never silent — the plan is shared state between three commands.

## Verify

The project's typecheck. Nothing heavier.

## Output

Files changed; every `PLAN.md` edit as old → new; anything routed to `analyze` or `api-contract`, with the reason. Then: "Next: `/react-feature-workflow:review`" — or another pass here if more comes up.
