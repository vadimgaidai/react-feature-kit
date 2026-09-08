#!/usr/bin/env bash
# Every check CI runs, runnable locally. CI calls this same script, so the two cannot drift.
set -uo pipefail
cd "$(dirname "$0")/.."

fail=0
run() {
  printf '\n\033[1m%s\033[0m\n' "$1"; shift
  if "$@"; then :; else fail=1; printf '  FAILED\n'; fi
}

run "Manifests, frontmatter, hooks and links" node scripts/validate.mjs

run "Shell scripts parse" bash -c '
  status=0
  while IFS= read -r f; do bash -n "$f" || status=1; done \
    < <(find plugins scripts -name "*.sh" -type f)
  exit $status
'

run "Node scripts parse" bash -c '
  status=0
  while IFS= read -r f; do node --check "$f" || status=1; done \
    < <(find plugins scripts -name "*.mjs" -type f)
  exit $status
'

exit $fail
