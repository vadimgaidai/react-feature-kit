# Form lifecycle: an edit form across a refetch

> Canonical code shape. Replace the placeholders (`[entity]` kebab-case, `[Entity]` PascalCase, `I[Entity]`/`T[Entity]` type identifiers) with real names.

One connected scenario: open an edit form, the query that feeds it is also showing a
background refetch, the user is mid-edit, then saves or hits a server error. Every rule below
is a condition this one component has to satisfy at the same time — the shapes are not
independent.

```tsx
const [Feature]EditForm = ({ id }: { id: string }) => {
  const { data: [entity], isPending } = useQuery([entity]Queries.byId(id))
  const { mutateAsync, isPending: isSaving } = use[Entity]UpdateMutation()

  const form = useForm<T[Feature]FormValues>({
    resolver: zodResolver([feature]Schema),
    values: [entity] && to[Feature]FormValues([entity]),
    resetOptions: { keepDirtyValues: true },
  })

  if (isPending) {
    return <[Entity]FormSkeleton />
  }

  const onSubmit = form.handleSubmit(async (values) => {
    try {
      await mutateAsync(to[Feature]Payload(values))
    } catch (error) {
      form.setError("root", { message: t("[feature].saveFailed") })
    }
  })

  return (
    <form onSubmit={onSubmit}>
      <FieldGroup>
        <Field>
          <FieldLabel htmlFor="name">{t("[feature].name")}</FieldLabel>
          <Input id="name" {...form.register("name")} />
          <FieldDescription>{t(form.formState.errors.name?.message)}</FieldDescription>
        </Field>
      </FieldGroup>
      {form.formState.errors.root && (
        <Alert variant="destructive">{t(form.formState.errors.root.message)}</Alert>
      )}
      <SubmitButton isPending={form.formState.isSubmitting || isSaving}>
        {t("actions.save")}
      </SubmitButton>
    </form>
  )
}
```

## Initial values come from the query, once

`values: [entity] && to[Feature]FormValues([entity])` sets the form's values from the query
the moment data exists, and re-synchronizes on every value RHF receives after that — never an
effect calling `form.reset(entity)` on every render, which fights the user's own edits on each
refetch. `resetOptions: { keepDirtyValues: true }` is what makes that safe: a background
refetch updates the fields the user has not touched and leaves the ones they are mid-edit
alone.

## The edited entity changing is a reset, not a refetch

Navigating this same form to a different `id` is a different scenario from a refetch of the
*same* entity — the form should reset completely, including dirty fields, because it is now
editing something else:

```tsx
<[Feature]EditForm key={id} id={id} />
```

The rubric's test for telling these apart: did the identity (`id`) change, or only the data
behind the same identity? A `key` change answers the first; `keepDirtyValues` answers the
second. Confusing them either resets a draft the user is still typing, or keeps stale values
after navigating to a different record.

## `""`, missing, `null` and `0` are four different values

A quantity field means something different in each state, and the schema and payload builder
say which:

```typescript
export const [feature]Schema = z.object({
  quantity: z.string().min(1, "[feature].form.quantityRequired"),
  discountCode: z.string().nullable(),
})
```

`""` on `quantity` is the user having cleared the field — not yet valid, blocks submit. A key
missing from the object altogether means RHF never had a field for it, which only happens
through a `defaultValues` bug. `null` on `discountCode` is an explicit "no value", distinct
from "unanswered" — a nullable select models exactly this. And `0` is a real, valid quantity,
never conflated with "unset". A field whose domain meaning is "not set yet" sends `null` or omits the key in the payload; it
never sends `""` for that meaning, because `""` already means "the user typed nothing, show
the required error."

## `isSubmitting` follows the returned promise

The wrong shape fires the mutation and returns nothing, so `isSubmitting` resolves before the
request does:

```tsx
const onSubmit = form.handleSubmit((values) => {
  mutate(to[Feature]Payload(values))
})
```

The right shape returns the promise, which `handleSubmit` awaits:

```tsx
const onSubmit = form.handleSubmit(async (values) => {
  await mutateAsync(to[Feature]Payload(values))
})
```

`formState.isSubmitting` is `true` for exactly as long as the promise `handleSubmit`'s callback
returns is pending. A callback that fires a mutation and returns `undefined` makes
`isSubmitting` false immediately, so the submit button re-enables before the request finishes.

## Field arrays, server errors, and `useWatch`

`field.id` — React Hook Form's own stable id — is the list key, never the index:

```tsx
const { fields, append, remove } = useFieldArray({ control: form.control, name: "tags" })

{fields.map((field, index) => (
  <Field key={field.id}>
    <Input {...form.register(`tags.${index}.value`)} />
    <Button type="button" onClick={() => remove(index)}>{t("actions.remove")}</Button>
  </Field>
))}
```

A server-side validation error lands per field (`form.setError("tags.0.value", { message })`)
when the response names a field, or on `root` for a whole-form failure — never a second toast
on top of the mutation's own `onError` (`error-handling` skill owns which one fires).

A value only one part of the UI needs to re-render on (a live character count, a dependent
field's visibility) is read with `useWatch`, not by reading `form.watch()` in the component
body — `watch()`'s return value does not subscribe the component to updates, so it renders
the value as of the last unrelated re-render, not the current one.
