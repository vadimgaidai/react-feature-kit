---
name: react-testing
description: What a component or form test should prove and how to review one — real QueryClient over mocked hooks, awaited async UI, pending/failure/retry covered, real assertions over a passing stub. Use when writing a test for a component, hook, form or query state, or reviewing a test file.
---

# React testing

Code shapes: [references/component-and-query.md](references/component-and-query.md),
[references/form-and-unmount.md](references/form-and-unmount.md). This skill does not change
the workflow: `verify` still runs existing tests and writes none; `implement` or the user
writes tests where the project has a runner, and this skill guides what they assert and how
`review` reads them.

Check `package.json` once per session for the runner and the testing library in use (Vitest,
Jest, React Testing Library) — the APIs named below are Testing Library's.

## What a test proves

- A test asserts the observable result of a user action — what is on screen, what request
  body was sent — never an implementation detail: a state variable's value, a call count on a
  function internal to the component under test.
- The behaviour under test is not mocked away. Mock the network boundary (the HTTP client, an
  MSW handler) so the real hook and the real component run; a test that mocks the hook under
  test only proves the mock was called.
- Async UI is awaited through the testing library's own queries (`findBy*`, `waitFor`) — never
  a fixed `setTimeout`/arbitrary sleep, which is both slower than necessary and still racy.
- Pending, failure, and the retry after a failure each get their own test. A suite that only
  covers the happy path proves nothing about what the user sees when the request is slow or
  fails.
- A form test types into the fields, submits, and asserts both the rendered error text and the
  payload the mocked network boundary actually received — not just that `onSubmit` fired.
- A query-backed component is tested through a real `QueryClient` (retries off, so a test
  failure doesn't wait out the retry backoff) — never a mocked `useQuery` return value, which
  stops testing the states `tanstack-query` actually produces.
- Cleanup is tested where it matters: unmount the component and assert the subscription,
  timer or listener it held is actually gone, not just that unmount didn't throw.

## Real evidence, not a stub

A passing check is a real run of the project's runner over real assertions. A script that
prints `PASS` without asserting anything — a fixture this kit's own eval scaffolds use to
stand in for a project's test suite — is a fixture, not evidence; a review of a test file says
which one it is looking at before citing it as a passing check.

## Reviewing

In order of how often it hurts:

- an assertion on an internal state variable or a call count instead of the rendered result
- the component or hook under test itself mocked, rather than only the network boundary
- a fixed sleep/timer instead of `findBy*`/`waitFor` for async UI
- only the happy path tested — no pending, failure or retry-after-failure case
- a form test that checks `onSubmit` fired but not the error text or the sent payload
- `useQuery`/`useMutation` mocked instead of run through a real `QueryClient`
- a subscription or timer never asserted gone after unmount
- a test file whose assertions are actually a `PASS`-printing stub, cited as if it were a run
