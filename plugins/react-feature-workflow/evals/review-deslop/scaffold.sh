#!/bin/bash
# Fixture for the `review-deslop` eval case. Runs in the empty workspace before the prompt
# (`--scaffold`). The feature branch adds one module whose code is plausible line by line
# and wrong as a set of decisions — one planted instance of each of the six slop questions:
#   1 unneeded generality   `createFormatter` factory + options nobody varies
#   2 repeat of existing    `joinName` duplicates `formatName` in src/shared/lib
#   3 redundant state       `fullName` held in state and synced from props by an effect
#   4 empty layer           `useCommentCount` only renames `comments.length`
#   5 unjustified defence   `?? []` and a try/catch around a typed, non-throwing map
#   6 project mismatch      a hand-rolled fetch-in-effect beside the project's query layer
# plus a removed export the review must notice, and a sibling it reads only in ranges.
set -eu

mkdir -p src/shared/lib src/shared/api \
         src/entities/article/api src/entities/article/model src/entities/article/ui \
         src/entities/comment/api src/entities/comment/model src/entities/comment/ui \
         .planning/comments

cat > package.json <<'EOF'
{
  "name": "eval-fixture",
  "private": true,
  "scripts": {
    "typecheck": "echo 'typecheck: ok'",
    "test": "echo 'tests: ok'"
  }
}
EOF

cat > .planning/comments/PLAN.md <<'EOF'
# PLAN: comments

**Shape:** feature

## Conventions to follow
- `src/entities/article/` — the sibling this module mirrors: folder shape, barrel, query layer.

## Modules
- `entities/comment` — list of comments for an article, author shown as "First Last".
EOF

cat > src/shared/lib/format.ts <<'EOF'
export function formatName(first: string, last: string) {
  return `${first} ${last}`
}
EOF

cat > src/shared/api/client.ts <<'EOF'
export async function get<T>(url: string): Promise<T> {
  const res = await fetch(url)
  return res.json() as Promise<T>
}
EOF

# --- untouched sibling: read by the sibling angle only in the ranges a comparison needs ---
cat > src/entities/article/model/types.ts <<'EOF'
export interface Article {
  id: string
  title: string
}
EOF
cat > src/entities/article/api/article.queries.ts <<'EOF'
import { queryOptions, useQuery } from "@tanstack/react-query"
import { get } from "@/shared/api/client"
import type { Article } from "../model/types"

export const articleKeys = {
  all: ["article"] as const,
  detail: (id: string) => [...articleKeys.all, "detail", id] as const,
}

export function useArticle(id: string) {
  return useQuery(queryOptions({ queryKey: articleKeys.detail(id), queryFn: () => get<Article>(`/articles/${id}`) }))
}
EOF
cat > src/entities/article/ui/article-card.tsx <<'EOF'
import type { Article } from "../model/types"

export function ArticleCard({ article }: { article: Article }) {
  return <h2 className="text-lg">{article.title}</h2>
}
EOF
cat > src/entities/article/index.ts <<'EOF'
export type { Article } from "./model/types"
export { articleKeys, useArticle } from "./api/article.queries"
export { ArticleCard } from "./ui/article-card"
EOF

cat > src/entities/comment/model/types.ts <<'EOF'
export interface Comment {
  id: string
  body: string
  author: { first: string; last: string }
}

export const EMPTY_COMMENTS: Comment[] = []
EOF

git init -q
git config user.email eval@example.com
git config user.name Eval
git symbolic-ref HEAD refs/heads/main
git add -A
git commit -qm "baseline: plan, shared lib, untouched sibling, comment types"

git checkout -qb feature/comments

cat > src/entities/comment/model/types.ts <<'EOF'
export interface Comment {
  id: string
  body: string
  author: { first: string; last: string }
}
EOF

mkdir -p src/entities/comment/lib
cat > src/entities/comment/lib/format.ts <<'EOF'
interface FormatterOptions {
  separator?: string
  uppercase?: boolean
}

export function createFormatter(options: FormatterOptions = {}) {
  const separator = options.separator ?? " "
  return (first: string, last: string) => {
    const joined = `${first}${separator}${last}`
    return options.uppercase ? joined.toUpperCase() : joined
  }
}

export const joinName = createFormatter()
EOF

cat > src/entities/comment/model/use-comment-count.ts <<'EOF'
import type { Comment } from "./types"

export function useCommentCount(comments: Comment[]) {
  return comments.length
}
EOF

cat > src/entities/comment/api/comment.api.ts <<'EOF'
import { useEffect, useState } from "react"
import type { Comment } from "../model/types"

export function useComments(articleId: string) {
  const [comments, setComments] = useState<Comment[]>([])
  useEffect(() => {
    fetch(`/articles/${articleId}/comments`)
      .then((r) => r.json())
      .then((data: Comment[]) => setComments(data))
  }, [articleId])
  return comments
}
EOF

cat > src/entities/comment/ui/comment-list.tsx <<'EOF'
import { useEffect, useState } from "react"
import type { Comment } from "../model/types"
import { joinName } from "../lib/format"
import { useCommentCount } from "../model/use-comment-count"

interface CommentListProps {
  comments: Comment[]
  first: string
  last: string
}

export function CommentList({ comments, first, last }: CommentListProps) {
  const [fullName, setFullName] = useState("")
  const count = useCommentCount(comments ?? [])

  useEffect(() => {
    setFullName(joinName(first, last))
  }, [first, last])

  let rows: string[] = []
  try {
    rows = comments.map((comment) => comment.body)
  } catch {
    rows = []
  }

  return (
    <section className="flex flex-col gap-2">
      <h3>{fullName} · {count}</h3>
      <ul>
        {rows.map((body, index) => (
          <li key={index}>{body}</li>
        ))}
      </ul>
    </section>
  )
}
EOF

cat > src/entities/comment/ui/comment-draft.tsx <<'EOF'
import { useState } from "react"
import type { Comment } from "../model/types"

interface CommentDraftProps {
  comment: Comment
  onSave: (body: string) => void
}

export function CommentDraft({ comment, onSave }: CommentDraftProps) {
  const [body, setBody] = useState(comment.body)

  return (
    <form
      onSubmit={(event) => {
        event.preventDefault()
        onSave(body)
      }}
    >
      <textarea value={body} onChange={(event) => setBody(event.target.value)} />
      <button type="submit">Save</button>
    </form>
  )
}

export function CommentEditor({ comment, onSave }: CommentDraftProps) {
  return <CommentDraft key={comment.id} comment={comment} onSave={onSave} />
}
EOF

cat > src/entities/comment/index.ts <<'EOF'
export type { Comment } from "./model/types"
export { useComments } from "./api/comment.api"
export { CommentList } from "./ui/comment-list"
export { CommentEditor } from "./ui/comment-draft"
EOF

git add -A
git commit -qm "feat(comment): list, formatter, count hook, fetch hook"
