#!/bin/bash
# Fixture for the `format-on-write` eval case: a stub `prettier` that records its arguments
# in `.prettier-ran`, resolvable through `npx --no-install` the way the hook calls it.
set -eu

mkdir -p src node_modules/prettier node_modules/.bin .planning/hello

cat > package.json <<'EOF'
{
  "name": "eval-fixture",
  "private": true,
  "scripts": { "typecheck": "echo 'typecheck: ok'" },
  "devDependencies": { "prettier": "0.0.0-stub" }
}
EOF

cat > CLAUDE.md <<'EOF'
# Conventions

- TypeScript. Source lives under `src/`.
EOF

cat > .planning/hello/PLAN.md <<'EOF'
# PLAN: hello

**Shape:** block

## Request
A `hello()` helper in `src/hello.ts`.
EOF

cat > node_modules/prettier/package.json <<'EOF'
{ "name": "prettier", "version": "0.0.0-stub", "bin": { "prettier": "cli.js" } }
EOF

cat > node_modules/prettier/cli.js <<'EOF'
#!/usr/bin/env node
// Stub: records what the hook asked to format. The real Prettier is not what is under test.
require("fs").appendFileSync(".prettier-ran", process.argv.slice(2).join(" ") + "\n")
EOF
chmod +x node_modules/prettier/cli.js
ln -s ../prettier/cli.js node_modules/.bin/prettier
