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
- **Collections by meaning.** `map`/`filter`/`find`/`some`/`every` where they say the
  operation and keep behaviour; a loop that reads is not rewritten. What goes is repeated
  work: a search over one collection repeated for each element of another, a value
  recomputed per iteration, an intermediate array nobody reads. A `Map`/`Set` or a value
  computed once replaces it when the task warrants — with order, duplicates, missing values
  and side effects checked (`find` returns the first match; filling a `Map` keeps the last).
  `map` with `find` inside, or the inner loop moved into a helper, is the same repetition.
  A task that must visit every pair keeps its nested traversal.
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

Two kinds of finding. A **style violation** is reported with the rule and the line; that is
enough. An **engineering remark** carries the argument — what the construct fails to name,
own or simplify at this spot; the data that already determines the value; the work repeated
per element. "Longer" alone is not a finding.

Style violations, in order of how often they hurt:

- any comment that is not `TODO:` / `!` / a directive
- nested ternary, or a ternary choosing between behaviours
- a third positional parameter in a function of ours (an external API signature or a
  required callback keeps its shape)
- a one-line `if (…) return` or braceless `if`
- a branching body with a bare `return`, an implicit return type or a branch returning a
  different type
- a boolean flag parameter

Engineering remarks, each with its argument:

- a wrapper that only forwards, a re-export that only renames, a variable that only repeats
  the returned expression, a default branch for a state the input is guaranteed never to
  hold — with the guarantee named
- a search over a second collection repeated per element, a value recomputed per iteration,
  an intermediate array nobody reads — with the repetition named and the replacement's
  equivalence checked (order, duplicates, missing values, side effects)
- depth past two levels where inverting a condition would flatten it
- a generic or type-named identifier
- a function that only forwards or exists to shorten its parent — why the name adds nothing
- a magic number with a domain meaning

Never a finding by itself: a single caller, an intermediate variable, a long file, a
`try/catch`, an optional chain, a fallback, a loop. Each needs the argument above.

## Overlap with the project's lint

A line the project's own lint reported in this review session goes under Checks and is
not re-derived. A rule merely present in the config is not proof it ran: without that
diagnostic in hand, the finding stands.
