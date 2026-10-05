#!/bin/bash
# Fixture for the `typescript-conventions` eval case. Runs in the empty workspace before
# the prompt (`--scaffold`).
set -eu

mkdir -p src/entities/invite/model

cat > package.json <<'EOF'
{
  "name": "eval-fixture",
  "private": true,
  "scripts": { "typecheck": "echo 'typecheck: ok'" }
}
EOF

cat > src/entities/invite/model/types.ts <<'EOF'
export type InviteStatus = "pending" | "accepted" | "revoked"

export interface Invite {
  id: string
  status: InviteStatus
}
EOF

git init -q
git config user.email eval@example.com
git config user.name Eval
git symbolic-ref HEAD refs/heads/main
git add -A
git commit -qm "baseline: invite entity"

git checkout -qb feature/invite-label

cat > src/entities/invite/model/label.ts <<'EOF'
import type { Invite, InviteStatus } from "./types"

export interface InviteView {
  id?: string
  status?: InviteStatus
  label?: string
}

export function describeInvite(payload: unknown) {
  const invite = payload as Invite
  return invite.id
}

export function statusLabel(status: InviteStatus) {
  switch (status) {
    case "pending":
      return "Pending"
    case "accepted":
      return "Accepted"
  }
}

export function ownerName(owner: { name: string } | null) {
  return owner!.name
}

export function rawPayload(payload: any) {
  return payload.id
}
EOF

git add -A
git commit -qm "feat(invite): label helpers"
