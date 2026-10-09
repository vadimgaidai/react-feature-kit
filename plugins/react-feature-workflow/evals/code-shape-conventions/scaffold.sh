#!/bin/bash
# Fixture for the `code-shape-conventions` eval case. Runs in the empty workspace before
# the prompt (`--scaffold`). The planted loop is a repeated `find` over `tones` for every
# `row` — repeated work, not a plain nested traversal, which `code-shape` does not forbid.
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
interface ToneWeight {
  tone: string
  weight: number
}

interface BadgeRow {
  tone: string
  count: number
}

// computes the pixel size for a badge given its density and whether it is compact
export function badgeSize(density: number, compact: boolean, rows: BadgeRow[], tones: ToneWeight[]) {
  const size = compact ? (density > 2 ? 12 : 16) : 24
  let total = 0
  for (const row of rows) {
    const tone = tones.find((candidate) => candidate.tone === row.tone)
    total += row.count * (tone?.weight ?? 1)
  }
  return size + total * 42
}
EOF

git add -A
git commit -qm "feat(badge): size helper"
