#!/bin/bash
# Fixture for the `review-skill-conformance` eval case. Runs in the empty workspace before
# the prompt (`--scaffold`).
set -eu

mkdir -p src/entities/comment/api src/entities/comment/model src/entities/comment/ui \
         src/entities/article/api src/entities/article/model \
         .claude/rules .planning/comments

cat > package.json <<'EOF'
{
  "name": "eval-fixture",
  "private": true,
  "scripts": { "typecheck": "echo 'typecheck: ok'" }
}
EOF

cat > .claude/rules/forms.md <<'EOF'
---
paths: src/**/ui/**/*.tsx
---
Schemas go in `<module>/schemas.ts`, never inline in a component.
EOF

cat > .planning/comments/PLAN.md <<'EOF'
# PLAN: comments

**Shape:** feature

## Conventions to follow
- `src/entities/article/` — the sibling this module mirrors: folder shape, barrel, key factory.

## Acceptance Criteria
- [ ] `CommentPanel` shows a running total of comments.
EOF

# --- untouched sibling: review may outline it, never read it file by file ---
cat > src/entities/article/model/types.ts <<'EOF'
export interface Article {
  id: string
  title: string
}
EOF
cat > src/entities/article/api/article.queries.ts <<'EOF'
import { queryOptions, useQuery } from "@tanstack/react-query"

export const articleKeys = {
  all: ["article"] as const,
  detail: (id: string) => [...articleKeys.all, "detail", id] as const,
}

export function useArticle(id: string) {
  return useQuery(queryOptions({ queryKey: articleKeys.detail(id), queryFn: () => fetchArticleUniqueToken(id) }))
}

function fetchArticleUniqueToken(id: string) {
  return fetch(`/articles/${id}`).then((r) => r.json())
}
EOF
cat > src/entities/article/index.ts <<'EOF'
export type { Article } from "./model/types"
export { articleKeys, useArticle } from "./api/article.queries"
EOF

git init -q
git config user.email eval@example.com
git config user.name Eval
git symbolic-ref HEAD refs/heads/main
git add -A
git commit -qm "baseline: plan, rules, untouched sibling"

git checkout -qb feature/comments

cat > src/entities/comment/model/types.ts <<'EOF'
export interface Comment {
  id: string
  body: string
}
EOF

cat > src/entities/comment/api/comment.queries.ts <<'EOF'
import { useQuery } from "@tanstack/react-query"

async function getComment(id: string) {
  const res = await fetch(`/comments/${id}`)
  return res.json()
}

export function useComment(id: string) {
  return useQuery({ queryKey: ["comment", id], queryFn: () => getComment(id) })
}
EOF

cat > src/entities/comment/ui/comment-panel.tsx <<'EOF'
import { useEffect, useState } from "react"
import { z } from "zod"
import type { Comment } from "../model/types"

const commentSchema = z.object({ body: z.string().min(1) })

interface CommentPanelProps {
  comments: Comment[]
}

export function CommentPanel({ comments }: CommentPanelProps) {
  const [total, setTotal] = useState(0)

  useEffect(() => {
    setTotal(comments.length)
  }, [comments])

  return (
    <div className="flex dark:bg-slate-900 space-y-2">
      <span>{total} comments</span>
      <ul>
        {comments.map((comment) => (
          <li key={comment.id}>{comment.body}</li>
        ))}
      </ul>
    </div>
  )
}

export const commentSchemaForPanel = commentSchema
EOF

cat > src/entities/comment/index.ts <<'EOF'
export type { Comment } from "./model/types"
export { useComment } from "./api/comment.queries"
export { CommentPanel } from "./ui/comment-panel"
EOF

git add -A
git commit -qm "feat(comment): panel, queries"
