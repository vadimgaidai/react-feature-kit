---
name: analyze
description: Plans a unit of work. Interactive Q&A in the main session (one question per turn, recommended answer first), then writes ONE `.planning/[name]/PLAN.md` covering every module of the request. A `block:` / `layout:` / `feature:` prefix on the request means the user classified it themselves; otherwise classify it from the request. Use when the user wants to plan, spec, scope or start a feature, module or refactor. Never delegate to a subagent — AskUserQuestion does not surface from one.
---

# Analyze

You plan a unit of work and produce **one** file. You write no production code — `/react-feature-workflow:implement` does, reading what you wrote.

**One request = one PLAN.md**, even when it spans several modules. Never split the plan across per-module files: the point is that the implementer reads one document.

## 0 — Shape of the request

The shape is classified by whoever speaks first. A `block:`, `layout:` or `feature:` prefix — `/react-feature-workflow:analyze layout: build the landing from <url>` — means the user classified the request themselves: take that shape as given. If it clearly mismatches the request (a `layout:` request that includes form logic), say so in one line, then follow the prefix anyway — the user chose it.

Without a prefix, classify the shape yourself before asking anything. The shape decides how much interview and plan the work deserves:

| Shape | What it looks like | What happens |
|---|---|---|
| **block** | One presentational block from a design — a hero, a pricing card, a header | No plan. Reply "run `@react-feature-workflow:block-builder <node-url> → <path>`" and stop. Without Figma MCP, treat as a one-module layout. |
| **layout** | A page assembled from blocks — a landing, a marketing page | Short interview, light plan: a block table + an assembly module. |
| **feature** | Behavior — data, forms, state: a table, a chat, a checkout | Full interview, full plan (below). |

A block is a section or a self-contained composite, never an element: a page is typically 3–8 blocks, and buttons or inputs inside a block don't get their own URL. A request that mixes shapes (a landing with a working contact form) is a **feature** — plan the form as a module and the rest as blocks.

For **layout** the interview shrinks to: name, the node URL per block, which composites repeat across blocks (each repeated one becomes its own module, built once), i18n if there is text, and acceptance criteria ("assembled, responsive, matches the frames"). Contract, data layer, roles — n/a; don't ask about them.

## 1 — Q&A (one question per turn)

Do NOT read the codebase at startup. Defer it until the questions are answered.

Use `AskUserQuestion`, one question per turn, never a batch. Two rules:

- **Lead with a recommendation.** The first option is your recommended answer, labeled "(Recommended)", with a one-line rationale. Never a flat menu without an opinion.
- **Never ask what the codebase can answer.** A targeted `Glob`/`Grep`/`Read` that settles the question (does this module exist? which UI primitives are installed? what i18n namespaces are there?) replaces the question. Point lookups only — no bulk reading yet.

Cover, skipping whatever the user already answered:

1. **Name & purpose** — kebab-case name, one sentence.
2. **Modules & structure** — what gets created or changed, and in what order. If a structure skill is loaded (e.g. `feature-sliced-design:structure`), it decides where things go; otherwise mirror the closest existing module in the repo and say which one you mirrored.
3. **Dependencies** — when the work could plausibly be solved by a third-party package (or by replacing or major-upgrading an installed one), the library choice is a **blocking `AskUserQuestion` in this pass**, never a decision the plan makes silently. Present 2–3 candidates — version, React compatibility, bundle cost, last release — and lead with a recommendation. "No new dependency — build on what's installed" is always one of the options. Record the decision in the plan; `implement` may not add what the plan does not name.
4. **API contract** — OpenAPI/Swagger URL or local path + the endpoints as `METHOD /path`. Never ask for request/response shapes; step 2 extracts them.
5. **Design** — Figma frame/node URL(s), or "none". For multi-block UI ask for a node URL **per block**, not one per feature — the implementer hands each block's URL to a builder agent.
6. **UI** — what gets built; forms? lists? wraps an existing primitive?
7. **UI states** — loading / empty / error. Mandatory for anything with UI.
8. **Roles & permissions** — what renders conditionally, or "none".
9. **Acceptance criteria** — 3–7 checkable statements defining "done".
10. **i18n** — namespace and keys, if the project is localized.

Then check for collisions: does a module with this name already exist? If so, ask whether to extend or rename.

## 2 — Slice the contract (skip when there is no API)

Follow the `api-contract` skill. In short:

```bash
node "${CLAUDE_PLUGIN_ROOT}"/skills/api-contract/scripts/contract-slice.mjs \
  <url-or-path> .planning/[name]/contract.md "GET /pet/{petId}" "POST /pet"
```

It writes exact request/response shapes with `$ref`s inlined — required vs optional, enums, formats. The implementer reads that file instead of the raw contract and never guesses a field.

## 2b — Slice the design (skip when there is no Figma link)

When the request carries Figma URL(s), dispatch the `theme-sync` agent in **feature mode** on the frame(s). It writes `.planning/[name]/DESIGN.md` — the design counterpart of `contract.md`: tokens, component map, layout, measurements, saved screenshots.

Two hard rules:

- **You never call Figma MCP tools yourself.** Figma payloads are large; they burn in the subagent, not in the planning session. Every design fact in the plan cites `DESIGN.md`.
- **You never map a design value to a Tailwind class or token yourself.** That mapping is `theme-sync`'s job — it reads the project's `global.css` / `@theme` first, and a class written from memory of default Tailwind may not exist in a project that resets namespaces. The plan's design sections reference `DESIGN.md` rows; they do not restate or re-derive them.

## 3 — Write `.planning/[name]/PLAN.md`

One file. Lists and tables, no prose padding, no code samples.

```markdown
# PLAN: [name]

**Shape:** layout | feature

## Request
The user's original request, verbatim.

## Modules
| # | Path | Role | Depends on |
|---|---|---|---|

Build in this order.

## Conventions to follow
The existing module this work mirrors (`path/to/module`), plus any structure skill that governs it.

## Contract
`.planning/[name]/contract.md` — authoritative for every shape. Source: <url>.
| Method | Path | Used by | Auth |

## Design
`.planning/[name]/DESIGN.md` — authoritative for tokens, spacing, layout and measurements. Plus the node URL per UI block when the design has them (block builders still need those). "none" when there is no design.

## Per module

### `path/to/module`
- **Files**: what gets created
- **Types**: interfaces and unions, derived from the contract
- **Data layer**: queries / mutations, and what each mutation invalidates
- **Schemas**: field rules + defaults (forms only)
- **UI**: components, props, which primitives they wrap; the block's Figma node URL when one exists

*(repeat per module — keep each block this short)*

## UI States
loading / empty / error, per component.

## Roles & Permissions
Rules, or "none".

## i18n
Namespace + key list, or "n/a".

## Acceptance Criteria
- [ ] 3–7 checkable statements. `/react-feature-workflow:review` verifies these.

## Out of scope
Explicit non-goals.

## Open questions
Anything still ambiguous. Empty is a valid answer.
```

## 4 — Scaffold

If a structure skill ships a scaffolder (the `feature-sliced-design` plugin does), run it per module in build order. Otherwise skip — the implementer creates files as it goes.

## 5 — Hand off

State the PLAN.md path and one next step:

- Design present → `DESIGN.md` already exists from step 2b: "Next: `/react-feature-workflow:implement`." A whole-theme pass (`theme-sync` in theme mode) stays a separate, user-initiated run.
- Otherwise → "Next: `/react-feature-workflow:implement`."

## Quality bar

- Unambiguous — the same PLAN produces the same code twice.
- No invented shapes: anything API-shaped points at `contract.md`.
- A block repeated across frames (the same card in two sections) is one module in the plan, built once — per-block builders can't see siblings, so dedup happens here or not at all.
- Never run a full build or lint to answer a planning question.
