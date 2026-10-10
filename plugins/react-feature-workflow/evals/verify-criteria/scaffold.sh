#!/bin/bash
# Fixture for the `verify-criteria` eval case. A finished spec with four acceptance
# criteria and a branch that satisfies two of them, breaks one, and leaves one that no
# static read can settle:
#   AC-1 oldest first      — satisfied, and the stub test suite covers it (executed tier)
#   AC-2 submit disabled   — satisfied in the form (static tier)
#   AC-3 conflict message  — missing: nothing handles 409 (fail)
#   AC-4 offline retry     — needs a browser offline (unverifiable, manual steps)
# plus a contract violation: the type carries `authorAvatarUrl`, which the slice never lists.
set -eu

mkdir -p src/entities/article/api src/entities/article/model \
         src/entities/comment/api src/entities/comment/model src/entities/comment/ui \
         .planning/comments

cat > package.json <<'EOF'
{
  "name": "eval-fixture",
  "private": true,
  "scripts": {
    "typecheck": "echo 'typecheck: ok'",
    "test": "echo 'comment-order.test.ts: oldest first PASS' && echo 'Tests 1 passed'"
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
R-2 WHEN a comment is submitted THE UI SHALL disable the submit control until the server answers
R-3 IF the server answers 409 THEN THE UI SHALL show a conflict message and keep the text
R-4 IF the network is unavailable on submit THEN THE UI SHALL keep the text and offer a retry

## UI states
Article page: loading skeleton, empty state, error with retry.

## Permissions
Signed-out reader sees the list and no form.

## Persistence
None.

## Failure scenarios
409 from the server: the comment is not posted and the text stays in the form.
Network failure on submit: the form keeps the text and shows a retry.

## Non-functional
i18n namespace `comment`.

## Data sources
GET /articles/{id}/comments
POST /articles/{id}/comments

## Design
none

## Acceptance criteria
AC-1 The comment list renders oldest first (R-1)
AC-2 The submit control is disabled while the request is in flight (R-2)
AC-3 A 409 answer shows a conflict message and keeps the typed text (R-3)
AC-4 With the network offline, submitting keeps the text and offers a retry (R-4)

## Out of scope
Editing and deleting a comment.

## Assumptions
Comments are plain text.

## Open questions
None.
EOF

cat > .planning/comments/PLAN.md <<'EOF'
# PLAN: comments

**Spec:** `.planning/comments/SPEC.md` — authoritative for behaviour and acceptance criteria.

## Modules
| # | Path | Role | Depends on | Serves |
|---|---|---|---|---|
| 1 | src/entities/comment | types, api, queries | — | AC-1 |
| 2 | src/entities/comment/ui | list and form | 1 | AC-2, AC-3, AC-4 |

Build in this order.

## Conventions to follow
- `src/entities/article/` — the module this work mirrors.

## Contract
`.planning/comments/contract.md` — authoritative for every shape.

## Coverage
| AC | Modules | Evidence `verify` should expect |
|---|---|---|
| AC-1 | 1, 2 | executed: the order test |
| AC-2 | 2 | static: the submit control |
| AC-3 | 2 | static: the 409 branch |
| AC-4 | 2 | manual: offline submit |

## Decisions
The list refetches after a successful post rather than updating optimistically.

## Out of scope
Editing and deleting a comment.
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

# --- untouched module: verify has no reason to open it ---
cat > src/entities/article/model/types.ts <<'EOF'
export interface Article {
  id: string
  title: string
  slugUniqueToken: string
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

git init -q
git config user.email eval@example.com
git config user.name Eval
git symbolic-ref HEAD refs/heads/main
git add -A
git commit -qm "baseline: spec, plan, contract, untouched article module"

git checkout -qb feature/comments

cat > src/entities/comment/model/types.ts <<'EOF'
export interface Comment {
  id: string
  body: string
  createdAt: string
  authorName: string
  authorAvatarUrl: string
}
EOF

cat > src/entities/comment/api/comment.queries.ts <<'EOF'
import { queryOptions, useMutation, useQuery, useQueryClient } from "@tanstack/react-query"
import type { Comment } from "../model/types"

export const commentKeys = {
  all: ["comment"] as const,
  list: (articleId: string) => [...commentKeys.all, "list", articleId] as const,
}

async function getComments(articleId: string): Promise<Comment[]> {
  const res = await fetch(`/articles/${articleId}/comments`)
  const comments: Comment[] = await res.json()
  return [...comments].sort((a, b) => a.createdAt.localeCompare(b.createdAt))
}

export const commentQueries = {
  list: (articleId: string) =>
    queryOptions({ queryKey: commentKeys.list(articleId), queryFn: () => getComments(articleId) }),
}

export function useComments(articleId: string) {
  return useQuery(commentQueries.list(articleId))
}

export function usePostComment(articleId: string) {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async (body: string) => {
      const res = await fetch(`/articles/${articleId}/comments`, {
        method: "POST",
        body: JSON.stringify({ body }),
      })
      return res.json() as Promise<Comment>
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: commentKeys.list(articleId) }),
  })
}
EOF

cat > src/entities/comment/ui/comment-list.tsx <<'EOF'
import { useComments } from "../api/comment.queries"

export function CommentList({ articleId }: { articleId: string }) {
  const { data, isPending, isError } = useComments(articleId)

  if (isPending) {
    return <p>loading</p>
  }

  if (isError) {
    return <p>error</p>
  }

  if (data.length === 0) {
    return <p>no comments yet</p>
  }

  return (
    <ul>
      {data.map((comment) => (
        <li key={comment.id}>{comment.body}</li>
      ))}
    </ul>
  )
}
EOF

cat > src/entities/comment/ui/comment-form.tsx <<'EOF'
import { useState } from "react"
import { usePostComment } from "../api/comment.queries"

export function CommentForm({ articleId }: { articleId: string }) {
  const [body, setBody] = useState("")
  const { mutate, isPending } = usePostComment(articleId)

  return (
    <form
      onSubmit={(event) => {
        event.preventDefault()
        mutate(body)
      }}
    >
      <textarea value={body} onChange={(event) => setBody(event.target.value)} />
      <button type="submit" disabled={isPending}>
        send
      </button>
    </form>
  )
}
EOF

cat > src/entities/comment/index.ts <<'EOF'
export type { Comment } from "./model/types"
export { commentKeys, commentQueries, useComments, usePostComment } from "./api/comment.queries"
export { CommentList } from "./ui/comment-list"
export { CommentForm } from "./ui/comment-form"
EOF

git add -A
git commit -qm "feat(comment): list, form, queries"
