#!/bin/bash
# Fixture for the `review-scoped-to-diff` eval case. Runs in the empty workspace before the prompt (`--scaffold`).
set -eu

mkdir -p src/entities/comment/api src/entities/comment/model src/entities/comment/ui \
         .planning/comments

cat > package.json <<'EOF'
{
  "name": "eval-fixture",
  "private": true,
  "scripts": { "typecheck": "echo 'typecheck: ok'" }
}
EOF

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
Show the comments of an article, newest first.

## Modules
| # | Path | Role | Depends on |
|---|---|---|---|
| 1 | `src/entities/comment` | comment entity + list | — |

## Conventions to follow

- `src/entities/article/` — the sibling this module mirrors: folder shape, barrel, key factory.

## Contract
`.planning/comments/contract.md` — authoritative for every shape.

## Design
none

## UI States
`CommentList`: loading, empty, error.

## Roles & Permissions
none

## i18n
n/a

## Acceptance Criteria
- [ ] `Comment` is typed from the contract, with no fields the contract does not list.
- [ ] `CommentList` renders a loading, an empty and an error state.
- [ ] The list is ordered newest first.

## Out of scope
Posting a comment.

## Open questions
None.
EOF

# --- an untouched sibling module: the plan names it as the reference; review may outline it, not read it ---
mkdir -p src/entities/article/api src/entities/article/model
cat > src/entities/article/model/types.ts <<'EOF'
export interface Article {
  id: string
  title: string
  createdAt: string
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
git commit -qm "baseline: plan and contract"

git checkout -qb feature/comments

cat > src/entities/comment/model/types.ts <<'EOF'
export interface Comment {
  id: string
  body: string
  authorName: string
  authorEmail: string
  createdAt: string
}
EOF

cat > src/entities/comment/ui/comment-list.tsx <<'EOF'
import type { Comment } from "../model/types"

interface CommentListProps {
  comments: Comment[]
  isPending: boolean
  isError: boolean
}

export function CommentList({ comments, isPending, isError }: CommentListProps) {
  if (isPending) return <p>Loading…</p>
  if (isError) return <p>Something went wrong.</p>
  if (comments.length === 0) return <p>No comments yet.</p>

  const ordered = [...comments].sort((a, b) => b.createdAt.localeCompare(a.createdAt))

  return (
    <ul>
      {ordered.map((comment, index) => (
        <li key={index}>
          <strong>{comment.authorName}</strong>
          <span>{comment.authorEmail}</span>
          <p>{comment.body}</p>
        </li>
      ))}
    </ul>
  )
}
EOF

cat > src/entities/comment/index.ts <<'EOF'
export type { Comment } from "./model/types"
export { CommentList } from "./ui/comment-list"
EOF

git add -A
git commit -qm "feat(comment): entity and list"
