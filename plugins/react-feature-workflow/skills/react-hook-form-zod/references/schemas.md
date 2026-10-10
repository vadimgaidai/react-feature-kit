# Validation Schemas (`schemas.ts`)

> Canonical code shape. Replace the placeholders (`[entity]` kebab-case, `[Entity]` PascalCase, `I[Entity]`/`T[Entity]` type identifiers) with real names.

Placement and filename: the structure skill loaded in this project. Do **not** inline schemas inside components or API files, regardless of where the structure skill puts the file.

### Defining a schema + inferring the type

```typescript
// features/[feature]/model/schemas.ts
import { z } from "zod"

export const [feature]Schema = z.object({
  email: z.string().email("[feature].form.emailInvalid"),
  password: z.string().min(8, "[feature].form.passwordTooShort"),
})

export const [feature]ExtendedSchema = [feature]Schema.extend({
  name: z.string().min(2, "[feature].form.nameTooShort"),
})

export type T[Feature]FormValues = z.infer<typeof [feature]Schema>
export type T[Feature]ExtendedFormValues = z.infer<typeof [feature]ExtendedSchema>
```

A message is a translation key, never text: the field renders `t(error.message)`, so the
schema stays locale-free and the key lives next to the other `[feature]` strings.

### Coercing a number from input

`z.coerce.number()` makes `z.input` for that field `unknown` while `z.output` is `number` —
exactly the divergence the "never do" rule forbids on a form schema, because `zodResolver`
types the form against `z.output` while `useForm` defaults and `register` work against
`z.input`. Keep the field a string in the schema and convert in `onSubmit`, where the payload
is built anyway:

```typescript
export const [feature]Schema = z.object({
  quantity: z.string().refine((value) => !Number.isNaN(Number(value)), "[feature].form.quantityInvalid"),
})

export type T[Feature]FormValues = z.infer<typeof [feature]Schema>
```

```typescript
const onSubmit = (values: T[Feature]FormValues) => {
  mutate({ ...values, quantity: Number(values.quantity) })
}
```

`z.input` and `z.output` stay identical (`string`), so `useForm<T[Feature]FormValues>` and
`zodResolver([feature]Schema)` agree, and the numeric payload is built once, at the one place
that already assembles the payload.

### Reference: env validation (`src/shared/config/env/schema.ts`)

```typescript
import { z } from "zod"

const envSchema = z.object({
  MODE: z.enum(["development", "production"]).default("development"),
  VITE_API_URL: z.string().url(),
  VITE_APP_NAME: z.string().default("React App"),
  VITE_ENABLE_DEVTOOLS: z
    .string()
    .default("false")
    .transform((val) => val === "true"),
})

export type TEnv = z.infer<typeof envSchema>
export { envSchema }
```

### Using a schema with React Hook Form

```tsx
import { zodResolver } from "@hookform/resolvers/zod"
import { useForm } from "react-hook-form"

import { [feature]Schema, type T[Feature]FormValues } from "../model/schemas"

const form = useForm<T[Feature]FormValues>({
  resolver: zodResolver([feature]Schema),
  defaultValues: { email: "", password: "" },
})
```

Rules:

- Always `export type X = z.infer<typeof xSchema>` next to the schema — no manual duplicate interfaces.
- Import path for schemas and their inferred types: the structure skill loaded in this project.

