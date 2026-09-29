#!/bin/bash
# Fixture for the `sibling-outline` eval case. Runs in the empty workspace before the prompt (`--scaffold`).
set -eu

mkdir -p src/shared/api src/entities/article/api src/entities/article/model \
         src/entities/article/ui .planning/comments

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
- Modules live under `src/entities/<name>/`. Mirror the sibling the plan names.
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

cat > src/entities/article/index.ts <<'EOF'
export type { Article, ArticleStatus, ListArticlesParams } from "./model/types"
export { ARTICLE_STATUS_LABELS } from "./model/constants"
export { articleKeys, articleQueries } from "./api/article.queries"
EOF

cat > src/entities/article/api/article.api.ts <<'EOF'
import { httpClient } from "@/shared/api/http-client"
import type { Article, ListArticlesParams } from "../model/types"

export async function getArticle(id: string): Promise<Article> {
  return httpClient.get<Article>(`/articles/${id}`)
}

export async function listArticles(params: ListArticlesParams): Promise<Article[]> {
  return httpClient.get<Article[]>(`/articles?page=${params.page}`)
}
EOF

cat > src/entities/article/api/article.queries.ts <<'EOF'
import { queryOptions } from "@tanstack/react-query"
import { getArticle, listArticles } from "./article.api"
import type { ListArticlesParams } from "../model/types"

export const articleKeys = {
  all: ["article"] as const,
  list: (params: ListArticlesParams) => [...articleKeys.all, "list", params] as const,
  detail: (id: string) => [...articleKeys.all, "detail", id] as const,
}

export const articleQueries = {
  list: (params: ListArticlesParams) =>
    queryOptions({ queryKey: articleKeys.list(params), queryFn: () => listArticles(params) }),
  detail: (id: string) =>
    queryOptions({ queryKey: articleKeys.detail(id), queryFn: () => getArticle(id) }),
}
EOF

cat > src/entities/article/model/constants.ts <<'EOF'
import type { ArticleStatus } from "./types"

export const ARTICLE_STATUS_LABELS: Record<ArticleStatus, string> = {
  draft: "Draft",
  published: "Published",
}
EOF

# Deliberately long: reading it whole is what this case is testing against.
node -e '
  const head = [
    "export type ArticleStatus = \"draft\" | \"published\"",
    "",
    "export interface Article {",
    "  id: string",
    "  title: string",
    "  status: ArticleStatus",
    "}",
    "",
    "export interface ListArticlesParams {",
    "  page: number",
    "}",
    "",
  ]
  const filler = []
  for (let i = 0; i < 400; i++) filler.push("/** legacy shape " + i + ", kept for the migration */")
  require("fs").writeFileSync(
    "src/entities/article/model/types.ts",
    head.concat(filler).join("\n") + "\n"
  )
'

cat > .planning/comments/contract.md <<'EOF'
# API contract — comments

## GET /articles/{id}/comments

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
Mirror `src/entities/article` — folder shape, barrel, key factory and all.

## Contract
`.planning/comments/contract.md` — authoritative for every shape.
| Method | Path | Used by | Auth |
|---|---|---|---|
| GET | /articles/{id}/comments | comment list | none |

## Design
none

## Per module

### `src/entities/comment`
- **Files**: mirror the sibling's layout
- **Types**: `Comment`, derived from the contract
- **Data layer**: a `commentKeys` factory and `commentQueries.list(articleId)`,
  built the same way the sibling builds its own

## UI States
n/a — no UI in this unit of work.

## Roles & Permissions
none

## i18n
n/a

## Acceptance Criteria
- [ ] `src/entities/comment` mirrors the sibling's folder shape.
- [ ] `commentKeys` is a key factory of the same shape as `articleKeys`.
- [ ] The barrel exports the types and the queries.

## Out of scope
UI components.

## Open questions
None.
EOF
