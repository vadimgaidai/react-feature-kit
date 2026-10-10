---
name: react-hook-form-zod
description: Repo-specific React Hook Form + Zod patterns — zodResolver, Field/FieldGroup layout, z.input === z.output rule. Use when building or fixing forms, validation schemas, resolver type errors, or multi-step/field-array forms.
---

# React Hook Form + Zod — repo quick reference

How forms are built **in my projects**. Canonical schema shape: [references/schemas.md](references/schemas.md). The full edit-form lifecycle — initial values from a query, a background refetch mid-edit, dirty fields, submit state: [references/lifecycle.md](references/lifecycle.md). Placement and naming — where the schema file and the form component live, one form per file — is the structure skill loaded in this project. Zod 3 and 4 differ in small ways (`z.coerce`'s inferred input type, `.default()` placement, the resolver package's generics); check `package.json` once in the session before applying a version-bound rule here. For anything this file does not cover, fetch the current upstream docs via the `context7` MCP server (`/react-hook-form/react-hook-form`, `/colinhacks/zod`) rather than guessing.

## The form recipe

```tsx
const form = useForm<TFooFormValues>({
  resolver: zodResolver(fooSchema),
  defaultValues: { email: "", password: "" }, // ALWAYS provide — avoids uncontrolled→controlled warnings
})
```

- Layout: `FieldGroup` + `Field` + `FieldLabel` + `FieldDescription` — never raw `div`s, never legacy `Form`/`FormField`/`FormItem`. Array rows (tags, photo URLs) are still `Field`s.
- `register` for plain inputs; `Controller` for Select/Combobox/DatePicker.
- Errors via `FieldDescription` driven by `t(errors.[field]?.message)` — schema messages are translation keys, never text. Let RHF + Zod validate — no manual `onChange` validation.
- Submit button: `disabled={isSubmitting || mutation.isPending}` + `Spinner` with `data-icon="inline-start"` — never just swap the label.
- Submit target is a mutation hook from the module's mutations file (`ui-conventions` owns the form's visual layout beyond `Field`; this skill owns the submit wiring).
- Multi-step → step components sharing state via `FormProvider`.
- An edit form's initial values come from a query via `values` (or `defaultValues` once, never
  a `reset` effect on every render); `resetOptions: { keepDirtyValues: true }` keeps a
  background refetch from erasing an in-progress edit, while a changed entity still resets
  fully through `key` — [references/lifecycle.md](references/lifecycle.md) has the scenario.
- `isSubmitting` is only accurate when `handleSubmit`'s callback awaits or returns the
  mutation's promise.
- `""`, a missing field, `null` and `0` are four distinct values; the schema and the payload
  builder say which one a given state means — never send `""` for "not set."

The reference files use placeholders — `[entity]` kebab-case, `[Entity]` PascalCase, `I[Entity]`/`T[Entity]` type identifiers. Real infrastructure (`httpClient`, primitives under `@/shared/ui/`) keeps its real name.

## Never do

- **Never let `z.input` diverge from `z.output`** on a form schema. A form schema round-trips the form's own values — see [references/schemas.md](references/schemas.md) for how a coerced number field is reconciled with this rule rather than exempted from it.
- Never introduce a schema pattern with no precedent in [references/schemas.md](references/schemas.md) or in the repo.
- Never duplicate an inferred type as a hand-written interface — `z.infer` is the source of truth.
- **Never put a React 19 form action on an RHF form.** `<form action={...}>`/`useActionState` and `handleSubmit` are two handlers for the same submit event — whichever React invokes first wins, in practice the action, so `zodResolver` never runs and invalid values reach `mutationFn`. `useFormStatus().pending` reads a status this form never sets, since the action path RHF uses never calls the mechanism `useFormStatus` watches; `formState.isSubmitting` is the real flag, already in scope. This holds for one-field forms too; there is no size below which a second form pattern is worth it.

## Reviewing

In order of how often it hurts:

- a hand-written interface duplicating `z.infer`
- `z.input` diverging from `z.output` on a form schema (a `.transform`/`.preprocess`, or an unreconciled `z.coerce` field)
- a `<form action>` / `useActionState` / `useFormStatus` on an RHF form
- manual `onChange` validation instead of letting the resolver run
- a raw `div` in place of `Field`/`FieldGroup`/`FieldLabel`/`FieldDescription`
- an error message that is literal text instead of a `t()` key
- a submit button that swaps its label instead of keeping it and showing a `Spinner`
- `reset()` called from an effect on every refetch, erasing fields the user is mid-edit on,
  instead of `values` + `keepDirtyValues` (and a `key` change when the edited entity changes)
- `isSubmitting` read from a submit handler that does not await or return the mutation's promise
- `""` sent for a field that means "not set" — `null` or an omitted key was meant
- a field array keyed by index instead of `useFieldArray`'s own `field.id`
- a server-side field error surfaced as a second toast instead of `setError`
- `form.watch()` read in the component body where `useWatch` was meant, missing re-renders
- no `defaultValues` on a controlled field, risking an uncontrolled→controlled warning
