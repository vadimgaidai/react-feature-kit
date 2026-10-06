---
name: code-shape
description: Less code, control flow, function and parameter shape, naming — the slop a linter can't decide. Use when writing or reviewing any .ts/.tsx with branching logic, a helper, or a utility.
---

# Code shape

House style, not laws of programming. Every rule with the shape it replaces:
[references/shapes.md](references/shapes.md).

- **The least code that does the job.** Reuse the primitive, library call or idiom that
  already exists. Delete a wrapper that only forwards a call, a re-export that only renames,
  a variable that only repeats the expression `return`ed on the next line, a default branch
  for a state the input is guaranteed never to hold, a parameter nothing passes yet. A single
  use does not make a variable redundant, and a wrapper that owns a boundary (the API module,
  the adapter around a dependency) stays. A diff well past its sibling's size for the same
  role is a reason to look for these, not a finding by itself.
- **No comments.** Two exceptions: `// TODO: <what is left>` for deferred work and
  `// ! <note>` for a reason or constraint the code cannot show. Directives with a reason
  (`eslint-disable`, `@ts-expect-error`) are not comments. Restating the line, step
  narration and section headers like `// Handle errors` go.
- **Two parameters is the ceiling.** A third becomes a typed options object.
- **Guard clauses first.** Exit cases return at the top; the happy path is unindented.
  Nesting past two levels inverts the conditions first; extract only when the inner block is
  an operation with a name.
- **A `return` is a block.** Never `if (x) return y` on one line — the `return` sits on its
  own line inside braces. Same for a single-statement `if`.
- **Ternaries choose values, never behaviours, never nest.** A second condition is a named
  boolean, a named value, a lookup map or a sub-component.
- **No scan inside a loop.** A `find`/`filter` over a second collection inside a loop is a
  lookup map built once. Moving the inner loop into a helper does not change the algorithm.
- **Return explicitly when the body branches.** Implicit arrow returns are for one
  expression. A branching body writes the value in every `return` and annotates the type.
- **No boolean parameters.** Split the function, or fold the flag into the options object.
- **Names say the domain, not the type.** `comments` not `data`, `isOwner` not `flag`,
  `submitComment` not `handleClick`. No `Helper`/`Manager`/`Utils`/`Service` suffix, no `2`
  suffix — grep first.
- **Extract for a name, not for size.** A function earns its place by naming an operation or
  owning a responsibility (a hook owns its state), one caller or ten. A chunk that only
  forwards, or was cut out to shorten the parent, is inlined.

## Reviewing

Each check is one rule above; the fix removes exactly what the check names. Where the rule
needs judgement (a wrapper, a variable, a one-caller function, a default branch), the finding
says what the construct complicates at this spot — "longer" alone is not a finding.

In order of how often it hurts:

- any comment that is not `TODO:` / `!` / a directive
- a wrapper that only forwards, a re-export that only renames, a variable that only repeats
  the returned expression, a default branch for a state the input is guaranteed never to
  hold — with the guarantee named
- a third positional parameter
- a one-line `if (…) return` or braceless `if`
- nested ternary
- depth past two levels where inverting a condition would flatten it
- a scan over a second collection inside a loop
- a branching body with a bare `return`, an implicit return type or a branch returning a
  different type
- a boolean flag parameter
- a generic or type-named identifier
- a function that only forwards or exists to shorten its parent
- a magic number with a domain meaning

The report header carries `+added / −removed` for the diff and the sibling's size for the
same role. The number says where to look; the finding still names the shape.

## The project's lint owns

Whatever the project's own ESLint config already errors on — typically `no-nested-ternary`,
`max-depth`, `complexity`, `consistent-return`, `max-params`, `no-magic-numbers`,
`no-else-return`. `review` reports its output under Checks and never re-derives those
lines.
