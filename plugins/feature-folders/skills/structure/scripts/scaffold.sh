#!/bin/bash
# Deterministic module/bucket scaffolder
#
# Usage:
#   scaffold.sh <bucket>/<name> [relative-file ...]
#
#   bucket       features | pages | layouts | api
#   name         kebab-case (a feature/page/layout name, or an API resource name)
#   files        optional explicit list (paths relative to the module root),
#                e.g. components/name-card.tsx hooks/use-name.ts
#                Omit to get the default skeleton for the bucket.
#
# Creates folders + placeholder files + empty barrel. Refuses to touch an
# existing module. Prints the resulting tree.
#
# Global single-file buckets (components/, hooks/, providers/, lib/, config/,
# assets/) are not scaffolded here — add one file with Write, there is no
# skeleton to generate.

set -euo pipefail

err() { echo "scaffold: $1" >&2; exit 1; }

[ $# -ge 1 ] || err "usage: scaffold.sh <bucket>/<name> [file ...]"

TARGET="$1"; shift
BUCKET="${TARGET%%/*}"
NAME="${TARGET#*/}"

case "$BUCKET" in
  features|pages|layouts|api) ;;
  *) err "bucket must be features|pages|layouts|api (got '$BUCKET')" ;;
esac
[[ "$NAME" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]] || err "name must be kebab-case (got '$NAME')"

DIR="src/$BUCKET/$NAME"
[ -e "$DIR" ] && err "$DIR already exists — extend it instead of scaffolding"

if [ $# -gt 0 ]; then
  FILES=("$@")
else
  case "$BUCKET" in
    features) FILES=("hooks/use-$NAME.ts" "types.ts" "constants.ts" "index.ts") ;;
    pages)    FILES=("$NAME-page.tsx" "index.ts") ;;
    layouts)  FILES=("$NAME-layout.tsx" "index.ts") ;;
    api)      FILES=("$NAME.api.ts" "$NAME.queries.ts" "$NAME.mutations.ts" "types.ts" "index.ts") ;;
  esac
fi

for f in "${FILES[@]}"; do
  base="$(basename "$f")"
  [[ "$base" =~ ^[a-z0-9][a-z0-9.-]*\.(ts|tsx)$ ]] || err "file '$f' is not kebab-case .ts/.tsx"
  mkdir -p "$DIR/$(dirname "$f")"
  case "$base" in
    types.ts)     echo "// types" > "$DIR/$f" ;;
    constants.ts) echo "// constants" > "$DIR/$f" ;;
    index.ts)     echo "// public API — downstream agents fill exports" > "$DIR/$f" ;;
    *)            : > "$DIR/$f" ;;
  esac
done

echo "Scaffolded $DIR:"
find "$DIR" | sort | sed "s|^|  |"
