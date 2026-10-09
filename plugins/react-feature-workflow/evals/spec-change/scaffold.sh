#!/bin/bash
# Fixture for the `spec-change` eval case: an existing comments module the request edits,
# so the spec is a delta and owes an `## Unchanged behaviour` section.
set -eu

mkdir -p src/entities/comment/api src/entities/comment/model src/entities/comment/ui

cat > package.json <<'EOF'
{
  "name": "eval-fixture",
  "private": true,
  "scripts": { "typecheck": "echo 'typecheck: ok'" }
}
EOF

cat > src/entities/comment/model/types.ts <<'EOF'
export interface Comment {
  id: string
  body: string
  createdAt: string
}
EOF

cat > src/entities/comment/ui/comment-list.tsx <<'EOF'
import type { Comment } from "../model/types"

export function CommentList({ comments }: { comments: Comment[] }) {
  return (
    <ul>
      {comments.map((comment) => (
        <li key={comment.id}>{comment.body}</li>
      ))}
    </ul>
  )
}
EOF

git init -q
git config user.email eval@example.com
git config user.name Eval
git symbolic-ref HEAD refs/heads/main
git add -A
git commit -qm "baseline: a comments module that already lists and renders"
