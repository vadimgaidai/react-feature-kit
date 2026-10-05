#!/bin/bash
# Fixture for the `code-shape-conventions` eval case. Runs in the empty workspace before
# the prompt (`--scaffold`).
set -eu

mkdir -p src/entities/badge/ui

cat > package.json <<'EOF'
{
  "name": "eval-fixture",
  "private": true,
  "scripts": { "typecheck": "echo 'typecheck: ok'" }
}
EOF

cat > src/entities/badge/ui/badge.ts <<'EOF'
export interface BadgeProps {
  label: string
  tone: "info" | "warning"
}

export function badgeClass(props: BadgeProps) {
  return props.tone === "warning" ? "badge-warn" : "badge-info"
}
EOF

git init -q
git config user.email eval@example.com
git config user.name Eval
git symbolic-ref HEAD refs/heads/main
git add -A
git commit -qm "baseline: a clean badge module"

git checkout -qb feature/badge-size

cat > src/entities/badge/ui/badge-size.ts <<'EOF'
// computes the pixel size for a badge given its density and whether it is compact
export function badgeSize(density: number, compact: boolean, theme: string) {
  const size = compact ? (density > 2 ? 12 : 16) : 24
  let total = 0
  const rows = [
    [1, 2, 3],
    [4, 5, 6],
  ]
  for (const row of rows) {
    for (const cell of row) {
      total += cell
    }
  }
  return size + total * 42 + theme.length
}
EOF

git add -A
git commit -qm "feat(badge): size helper"
