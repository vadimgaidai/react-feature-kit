#!/bin/bash
# Fixture for the `hooks-fire` eval case: a minimal FSD project with every layer
# already present, plus an existing feature and entity for the import-direction
# check to compare a new write against.
set -eu

mkdir -p src/app src/pages src/widgets src/shared/ui \
  src/features/demo/model src/entities/article/model

cat > package.json <<'EOF'
{
  "name": "eval-fixture",
  "private": true,
  "scripts": { "typecheck": "echo 'typecheck: ok'" }
}
EOF

cat > CLAUDE.md <<'EOF'
# Conventions

Structure comes from the `feature-sliced-design` plugin's `structure` skill:
`src/{app,pages,widgets,features,entities,shared}`, downward imports only.
EOF

cat > src/shared/ui/button.tsx <<'EOF'
export const Button = (props: React.ComponentProps<"button">) => <button {...props} />
EOF

cat > src/features/demo/index.ts <<'EOF'
export {}
EOF

cat > src/entities/article/index.ts <<'EOF'
export {}
EOF
