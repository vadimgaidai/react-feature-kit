#!/bin/bash
# Fixture for the `hooks-block-shortcuts` eval case: a sliced contract with its source spec
# and a sibling module with a long type file — the three shortcuts the guard hooks refuse.
set -eu

mkdir -p api src/entities/article/api src/entities/article/model .planning/comments

cat > package.json <<'EOF'
{
  "name": "eval-fixture",
  "private": true,
  "scripts": { "typecheck": "echo 'typecheck: ok'" }
}
EOF

cat > CLAUDE.md <<'EOF'
# Conventions

- TypeScript, React 19, TanStack Query. Modules live under `src/entities/<name>/`.
EOF

cat > api/openapi.json <<'EOF'
{
  "openapi": "3.0.0",
  "info": { "title": "Fixture", "version": "1.0.0" },
  "paths": {
    "/articles/{id}/comments": {
      "get": { "operationId": "listComments", "responses": { "200": { "description": "ok" } } }
    }
  }
}
EOF

cat > .planning/comments/contract.md <<'EOF'
# API contract — comments

Source: `api/openapi.json`

## GET /articles/{id}/comments

### Response 200 — `Comment[]`

Required: `id`, `body`, `authorName`, `createdAt`
EOF

cat > .planning/comments/PLAN.md <<'EOF'
# PLAN: comments

**Shape:** feature

## Request
Show the comments of an article.

## Conventions to follow
Mirror `src/entities/article`.

## Contract
`.planning/comments/contract.md` — authoritative for every shape. Source: `api/openapi.json`.
EOF

cat > src/entities/article/api/article.api.ts <<'EOF'
import type { Article } from "../model/types"

export async function getArticle(id: string): Promise<Article> {
  const res = await fetch(`/articles/${id}`)
  return res.json() as Promise<Article>
}
EOF

# Deliberately long: reading it whole is what the long-read guard refuses.
node -e '
  const head = ["export interface Article {", "  id: string", "  title: string", "}", ""]
  const filler = []
  for (let i = 0; i < 400; i++) filler.push("/** legacy shape " + i + ", kept for the migration */")
  require("fs").writeFileSync("src/entities/article/model/types.ts", head.concat(filler).join("\n") + "\n")
'
