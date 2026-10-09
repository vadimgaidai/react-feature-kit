#!/bin/bash
# Fixture for the `spec-feature` eval case. Runs in the empty workspace before the prompt
# (`--scaffold`). The prompt answers the taxonomy inline, because `AskUserQuestion` has no
# counterpart in a headless run — what is measured is the file `spec` writes from answers
# it already has, and that everything it was not told becomes a recorded assumption.
set -eu

mkdir -p src/entities/article/api src/entities/article/model src/entities/article/ui

cat > package.json <<'EOF'
{
  "name": "eval-fixture",
  "private": true,
  "scripts": { "typecheck": "echo 'typecheck: ok'" }
}
EOF

cat > CLAUDE.md <<'EOF'
# Project

React + TypeScript SPA. Data through TanStack Query. Text through `t()`; namespace per entity.
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

cat > src/entities/article/ui/article-card.tsx <<'EOF'
import type { Article } from "../model/types"

export function ArticleCard({ article }: { article: Article }) {
  return <h2>{article.title}</h2>
}
EOF

git init -q
git config user.email eval@example.com
git config user.name Eval
git symbolic-ref HEAD refs/heads/main
git add -A
git commit -qm "baseline: an article entity and the project conventions"
