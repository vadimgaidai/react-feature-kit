#!/bin/bash
# Fixture for the `contract-outranks-plan` eval case. Runs in the empty workspace before the prompt (`--scaffold`).
set -eu

mkdir -p src/shared/api src/entities .planning/comments api

cat > package.json <<'EOF'
{
  "name": "eval-fixture",
  "private": true,
  "scripts": { "typecheck": "echo 'typecheck: ok'" }
}
EOF

cat > CLAUDE.md <<'EOF'
# Conventions

- TypeScript, React 19, TanStack Query.
- Modules live under `src/entities/<name>/` with `api/`, `model/`, `ui/` and an `index.ts` barrel.
- HTTP goes through `src/shared/api/http-client.ts`.
- `pnpm typecheck` is the only check to run.
EOF

cat > src/shared/api/http-client.ts <<'EOF'
export const httpClient = {
  get: async <T>(url: string): Promise<T> => {
    const res = await fetch(url)
    return res.json() as Promise<T>
  },
}
EOF

# The raw spec exists and is bulky on purpose: nothing should ever read it.
node -e '
  const paths = {}
  for (let i = 0; i < 40; i++) {
    paths["/filler" + i] = { get: { operationId: "filler" + i, responses: { 200: { description: "ok" } } } }
  }
  paths["/articles/{id}/comments"] = {
    get: {
      operationId: "listComments",
      parameters: [{ name: "id", in: "path", required: true, schema: { type: "string" } }],
      responses: { 200: { description: "ok", content: { "application/json": {
        schema: { type: "array", items: { $ref: "#/components/schemas/Comment" } } } } } },
    },
  }
  const spec = {
    openapi: "3.0.0",
    info: { title: "Fixture", version: "1.0.0" },
    paths,
    components: { schemas: { Comment: {
      type: "object",
      required: ["id", "body", "authorName", "createdAt"],
      properties: {
        id: { type: "string", format: "uuid" },
        body: { type: "string" },
        authorName: { type: "string" },
        createdAt: { type: "string", format: "date-time" },
      },
    } } },
  }
  require("fs").writeFileSync("api/openapi.json", JSON.stringify(spec, null, 2))
'

cat > .planning/comments/contract.md <<'EOF'
# API contract — comments

Source: `api/openapi.json`

## GET /articles/{id}/comments

### Parameters
| Name | In | Required | Type |
|---|---|---|---|
| `id` | path | yes | string |

### Response 200 — `Comment[]`

```
[
  {
    "id": "string REQUIRED (format: uuid)",
    "body": "string REQUIRED",
    "authorName": "string REQUIRED",
    "createdAt": "string REQUIRED (format: date-time)"
  }
]
```

Required: `id`, `body`, `authorName`, `createdAt`
EOF

cat > .planning/comments/PLAN.md <<'EOF'
# PLAN: comments

**Shape:** feature

## Request
Show the comments of an article.

## Modules
| # | Path | Role | Depends on |
|---|---|---|---|
| 1 | `src/entities/comment` | comment entity: types, http, queries | — |

Build in this order.

## Conventions to follow
No sibling module exists yet — follow `CLAUDE.md`.

## Contract
`.planning/comments/contract.md` — authoritative for every shape. Source: `api/openapi.json`.
| Method | Path | Used by | Auth |
|---|---|---|---|
| GET | /articles/{id}/comments | comment list | none |

## Design
none

## Per module

### `src/entities/comment`
- **Files**: `model/types.ts`, `api/comment.api.ts`, `api/comment.queries.ts`, `index.ts`
- **Types**: `Comment` in `src/entities/comment/model/types.ts` — id, body, author name,
  author email (shown under the author's name), created at.
- **Data layer**: `commentKeys` factory + `commentQueries.list(articleId)`

## UI States
n/a — no UI in this unit of work.

## Roles & Permissions
none

## i18n
n/a

## Acceptance Criteria
- [ ] `Comment` is typed from the contract, no guessed fields.
- [ ] `commentQueries.list(articleId)` exists and is exported from the barrel.

## Out of scope
UI components.

## Open questions
None.
EOF
