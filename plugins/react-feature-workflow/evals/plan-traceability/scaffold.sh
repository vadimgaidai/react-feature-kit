#!/bin/bash
# Fixture for the `plan-traceability` eval case. A finished SPEC.md with four acceptance
# criteria, a contract slice that covers every endpoint the spec names but carries no source
# for one field the spec's behaviour needs, and the raw OpenAPI file that must stay closed.
set -eu

mkdir -p src/entities/article/api src/entities/article/model .planning/comments api

cat > package.json <<'EOF'
{
  "name": "eval-fixture",
  "private": true,
  "scripts": { "typecheck": "echo 'typecheck: ok'" }
}
EOF

cat > api/openapi.json <<'EOF'
{
  "openapi": "3.0.0",
  "info": { "title": "rawSpecUniqueToken", "version": "1.0.0" },
  "paths": {
    "/articles/{id}/comments": {
      "get": { "summary": "rawSpecUniqueToken list" },
      "post": { "summary": "rawSpecUniqueToken create" }
    }
  }
}
EOF

cat > .planning/comments/SPEC.md <<'EOF'
# SPEC: comments
**Shape:** feature

## Request
Add comments to an article: a list under the article and a form to post one.

## Goal
A reader can read the comments on an article and post one.

## Behaviour
R-1 WHEN the article page opens THE UI SHALL show the comments oldest first
R-2 WHEN the comment list is empty THE UI SHALL show an empty state with an invitation to write
R-3 WHEN a comment is submitted THE UI SHALL disable the submit control until the server answers
R-4 WHEN a comment is submitted THE UI SHALL show the new comment at the end of the list
R-5 WHILE a comment is rendered THE UI SHALL show the author avatar beside the body

## UI states
Article page: loading skeleton, empty state, error with retry.

## Permissions
Signed-out reader sees the list and no form. Signed-in reader sees both.

## Persistence
None.

## Failure scenarios
Network failure on submit: the form keeps the text and shows a retry.

## Non-functional
i18n namespace `comment`. List is capped at 50 and paginates after that.

## Data sources
GET /articles/{id}/comments
POST /articles/{id}/comments
OpenAPI: api/openapi.json

## Design
none

## Acceptance criteria
AC-1 The comment list renders oldest first under the article (R-1)
AC-2 An article with no comments shows the empty state (R-2)
AC-3 The submit control is disabled while the request is in flight (R-3)
AC-4 A posted comment appears at the end of the list without a reload (R-4)

## Out of scope
Editing and deleting a comment. Replies.

## Assumptions
Comments are plain text, no markdown.

## Open questions
None.
EOF

cat > .planning/comments/contract.md <<'EOF'
# API contract — comments

Source: `api/openapi.json`

## GET /articles/{id}/comments

Response `200`:

```
[
  {
    "id": "string REQUIRED",
    "body": "string REQUIRED",
    "createdAt": "string(date-time) REQUIRED",
    "authorName": "string REQUIRED"
  }
]
```

Required: id, body, createdAt, authorName

## POST /articles/{id}/comments

Request body:

```
{
  "body": "string REQUIRED"
}
```

Response `201`:

```
{
  "id": "string REQUIRED",
  "body": "string REQUIRED",
  "createdAt": "string(date-time) REQUIRED",
  "authorName": "string REQUIRED"
}
```

Required: id, body, createdAt, authorName
EOF

cat > src/entities/article/model/types.ts <<'EOF'
export interface Article {
  id: string
  title: string
}
EOF

cat > src/entities/article/api/article.queries.ts <<'EOF'
import { queryOptions } from "@tanstack/react-query"

export const articleKeys = {
  all: ["article"] as const,
  detail: (id: string) => [...articleKeys.all, "detail", id] as const,
}

export const articleQueries = {
  detail: (id: string) => queryOptions({ queryKey: articleKeys.detail(id) }),
}
EOF

cat > src/entities/article/index.ts <<'EOF'
export type { Article } from "./model/types"
export { articleKeys, articleQueries } from "./api/article.queries"
EOF

git init -q
git config user.email eval@example.com
git config user.name Eval
git symbolic-ref HEAD refs/heads/main
git add -A
git commit -qm "baseline: spec, contract slice, raw spec, article sibling"
