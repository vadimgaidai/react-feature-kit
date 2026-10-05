---
name: code-shape
description: Less code, control flow, function and parameter shape, naming — the slop a linter can't decide. Use when writing or reviewing any .ts/.tsx with branching logic, a helper, or a utility.
---

# Code shape

Every rule with the shape it replaces: [references/shapes.md](references/shapes.md).

- **The least code that does the job.** Reuse the primitive, library call or idiom that
  already exists. No wrapper that forwards, re-export that renames, variable used once,
  default branch for a state the type rules out, parameter "for later". A diff twice the
  sibling's size for the same role is a finding by itself.
- **No comments.** Two exceptions: `// TODO: <what is left>` for deferred work and
  `// ! <note>` for a constraint a reader would otherwise break. Directives with a reason
  (`eslint-disable`, `@ts-expect-error`) are not comments.
- **Two parameters is the ceiling.** A third becomes a typed options object.
- **Guard clauses first.** Exit cases return at the top; the happy path is unindented.
  Nesting past two levels extracts or inverts.
- **A `return` is a block.** Never `if (x) return y` on one line — the `return` sits on its
  own line inside braces. Same for a single-statement `if`.
- **Ternaries choose values, never behaviours, never nest.** A second condition is a named
  boolean, a lookup map or a sub-component.
- **One loop per function body.** A loop inside a loop is a lookup map built once, or a helper.
- **Return explicitly when the body branches.** Implicit arrow returns are for one expression.
- **No boolean parameters.** Split the function, or fold the flag into the options object.
- **Names say the domain, not the type.** `comments` not `data`, `isOwner` not `flag`,
  `submitComment` not `handleClick`. No `Helper`/`Manager`/`Utils`/`Service` suffix, no `2`
  suffix — grep first.
- **Extract on a second caller, not on principle.** A one-caller helper is inlined until a
  second caller exists or the chunk owns its own state.

## Reviewing

In order of how often it hurts:

- any comment that is not `TODO:` / `!` / a directive
- a longer form where a shorter idiom exists — a wrapper, a renaming re-export, a once-used
  variable, an impossible default branch
- a third positional parameter
- a one-line `if (…) return` or braceless `if`
- nested ternary
- depth past two levels
- loop inside a loop
- a function with two return shapes
- a boolean flag parameter
- a generic or type-named identifier
- a one-caller helper
- a magic number with a domain meaning

The report header carries `+added / −removed` for the diff and the sibling's size for the
same role, so "too much code" is a number, not a feeling.

## Lint owns

`no-nested-ternary`, `max-depth`, `complexity`, `consistent-return`, `max-params`,
`no-magic-numbers`, `no-else-return`, and the comment regex in `slop-scan.mjs` — don't
re-report any of these.
