#!/bin/bash
# Fixture for the `hooks-fire` eval case: a minimal project with the recognized
# buckets already present, so the three disallowed writes have real neighbors to
# be measured against.
set -eu

mkdir -p src/components/ui src/features src/lib src/api src/config

cat > package.json <<'EOF'
{
  "name": "eval-fixture",
  "private": true,
  "scripts": { "typecheck": "echo 'typecheck: ok'" }
}
EOF

cat > CLAUDE.md <<'EOF'
# Conventions

Structure comes from the `feature-folders` plugin's `structure` skill:
`src/{app,pages,layouts,features,components,hooks,providers,lib,config,api,assets}`.
EOF

cat > src/components/ui/button.tsx <<'EOF'
export const Button = (props: React.ComponentProps<"button">) => <button {...props} />
EOF
