#!/bin/bash
# Validates that a NEW file under src/ lands in a recognized top-level bucket, and
# rejects well-known dumping-ground names with a pointer to where that role lives.
#
# Unlike a from-scratch FSD project, a project this plugin targets usually has years
# of existing code outside these buckets. This hook only ever blocks the creation of
# a file that does not exist yet — editing or overwriting a file already on disk
# always passes, whatever its path, so a legacy tree is never fought file by file.

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Skip if no file path, not under src/, or the file already exists (an edit/overwrite).
if [[ -z "$FILE_PATH" ]] || [[ "$FILE_PATH" != *"/src/"* ]] || [[ -e "$FILE_PATH" ]]; then
  exit 0
fi

# Extract the relative path after src/
REL_PATH="${FILE_PATH#*src/}"

# Recognized top-level buckets. See skills/structure/SKILL.md for what each one holds.
ALLOWED="app|pages|layouts|features|components|hooks|providers|lib|config|api|assets"

FIRST_DIR="${REL_PATH%%/*}"

# A file directly in src/ (main.tsx, App.tsx, vite-env.d.ts) is always fine.
[[ "$REL_PATH" == *"/"* ]] || exit 0

if [[ "$FIRST_DIR" =~ ^($ALLOWED)$ ]]; then
  exit 0
fi

# Known anti-patterns get a specific redirect instead of the generic message.
case "$FIRST_DIR" in
  utils|helpers)
    echo "[bucket-placement-validator] Placement violation: 'src/$FIRST_DIR/' is not a recognized bucket" >&2
    echo "Pure, domain-free functions go in src/lib/ instead." >&2
    exit 2
    ;;
  services)
    echo "[bucket-placement-validator] Placement violation: 'src/$FIRST_DIR/' is not a recognized bucket" >&2
    echo "HTTP calls and query/mutation hooks go in src/api/<resource>/ instead." >&2
    exit 2
    ;;
  styles)
    echo "[bucket-placement-validator] Placement violation: 'src/$FIRST_DIR/' is not a recognized bucket" >&2
    echo "Global styles go in src/assets/; component-scoped styling stays beside the component." >&2
    exit 2
    ;;
  constants)
    echo "[bucket-placement-validator] Placement violation: 'src/$FIRST_DIR/' is not a recognized bucket" >&2
    echo "An app-wide constant goes in src/config/; one used by a single module goes in that module's own constants.ts." >&2
    exit 2
    ;;
  types)
    echo "[bucket-placement-validator] Placement violation: 'src/$FIRST_DIR/' is not a recognized bucket" >&2
    echo "A request/response shape goes in src/api/<resource>/types.ts; a module-local type goes in that module's own types.ts." >&2
    exit 2
    ;;
  ui)
    echo "[bucket-placement-validator] Placement violation: 'src/$FIRST_DIR/' is not a recognized bucket" >&2
    echo "shadcn/base primitives go in src/components/ui/; a domain wrapper goes in src/components/ or the owning module's components/." >&2
    exit 2
    ;;
  widgets|entities)
    echo "[bucket-placement-validator] Placement violation: 'src/$FIRST_DIR/' is not a recognized bucket in this plugin" >&2
    echo "This is the feature-folders plugin, not feature-sliced-design — use src/features/ or src/pages/ instead." >&2
    exit 2
    ;;
  *)
    echo "[bucket-placement-validator] Placement violation: 'src/$FIRST_DIR/' is not a recognized bucket" >&2
    echo "Allowed top-level buckets: src/{${ALLOWED//|/,}}/" >&2
    exit 2
    ;;
esac
