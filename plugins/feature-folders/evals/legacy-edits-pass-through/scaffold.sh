#!/bin/bash
# Fixture for the `legacy-edits-pass-through` eval case: a project that predates the
# feature-folders plugin, with three real pre-existing violations of its own buckets
# and naming rule — a dumping-ground `utils/`, a `helpers/`, and a PascalCase component.
# None of them are new files, so none should ever trip a hook.
set -eu

mkdir -p src/utils src/helpers src/components

cat > package.json <<'EOF'
{
  "name": "eval-fixture",
  "private": true,
  "scripts": { "typecheck": "echo 'typecheck: ok'" }
}
EOF

cat > CLAUDE.md <<'EOF'
# Conventions

This app predates the `feature-folders` plugin. New code follows its buckets
(`src/{app,pages,layouts,features,components,hooks,providers,lib,config,api,assets}`);
existing code stays where it is unless a task specifically asks to move it.
EOF

cat > src/utils/format-date.ts <<'EOF'
export const formatDate = (iso: string): string => {
  const date = new Date(iso)
  if (isNaN(date.getTime())) {
    throw new Error(`Invalid date: ${iso}`)
  }
  return date.toLocaleDateString()
}
EOF

cat > src/helpers/slugify.ts <<'EOF'
export const slugify = (input: string): string => {
  return input
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9]+/g, "-")
}
EOF

cat > src/components/OldWidget.tsx <<'EOF'
export const OldWidget = () => <div>Wlecome</div>
EOF
