#!/bin/bash
# Blocks domain content (not file placement) landing in the wrong home: a UI file
# defining a domain type, an enum-like constant, a zod schema, a hook, or calling
# HTTP directly; an entity module reaching for a mutation; or an import that goes
# sideways or upward against the layer order.
#
# fsd-validator skips nothing — every write under src/ is FSD. This hook checks
# content on every Write and Edit, old file or new: a domain interface pasted into
# an existing component is still new slop.

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
CONTENT=$(echo "$INPUT" | jq -r '.tool_input.new_string // .tool_input.content // empty')

[[ -z "$FILE_PATH" ]] && exit 0
[[ -z "$CONTENT" ]] && exit 0

case "$FILE_PATH" in
  *.test.tsx|*.test.ts|*.spec.tsx|*.spec.ts|*.stories.tsx) exit 0 ;;
esac

block() {
  echo "[model-placement-validator] Placement violation: $1" >&2
  echo "$2" >&2
  exit 2
}

# --- layer of the file, if any (for the import-direction and entity checks) ---
LAYER=""
if [[ "$FILE_PATH" =~ /src/(app|pages|widgets|features|entities|shared)/ ]]; then
  LAYER="${BASH_REMATCH[1]}"
fi

rank() {
  case "$1" in
    app) echo 0 ;; pages) echo 1 ;; widgets) echo 2 ;;
    features) echo 3 ;; entities) echo 4 ;; shared) echo 5 ;;
    *) echo "" ;;
  esac
}

# --- import direction: a layer may import only layers strictly below it ---
if [[ -n "$LAYER" && "$LAYER" != "shared" ]]; then
  FILE_RANK=$(rank "$LAYER")
  while IFS= read -r line; do
    [[ "$line" =~ from[[:space:]]+[\"\'][@][/](app|pages|widgets|features|entities|shared)/ ]] || continue
    imported="${BASH_REMATCH[1]}"
    imported_rank=$(rank "$imported")
    if [[ "$imported_rank" -le "$FILE_RANK" ]]; then
      block "src/$LAYER/ imports from src/$imported/, which is the same layer or above it" \
            "A layer may import only layers strictly below it: app -> pages -> widgets -> features -> entities -> shared. An entity must not import another entity; a feature must not import another feature."
    fi
  done <<<"$CONTENT"
fi

# --- an entity reaching for a mutation: entities are read-side only ---
if [[ "$LAYER" == "entities" ]] && echo "$CONTENT" | grep -qE 'useMutation\('; then
  block "an entity module calls useMutation()" \
        "Mutations live in the feature that performs the write, not in the entity it writes to."
fi

# Only .tsx files that render or compose UI carry the content rules below.
[[ "$FILE_PATH" == *.tsx ]] || exit 0
case "$FILE_PATH" in
  */ui/*|*/components/*|*/pages/*|*/layouts/*) ;;
  *) exit 0 ;;
esac

# 1. A domain interface/type defined inline — a component's own Props/State/Ref
#    type is not domain and stays local.
while IFS= read -r line; do
  [[ "$line" =~ ^export\ (interface|type)\ ([A-Za-z0-9_]+) ]] || continue
  name="${BASH_REMATCH[2]}"
  [[ "$name" =~ (Props|State|Ref)$ ]] && continue
  block "a domain type/interface (\"$name\") is defined in a UI file" \
        "Domain types go in model/types.ts."
done <<<"$CONTENT"

# 2. An enum-like as-const object (the declaration and its closing brace, on
#    one line or several — a cva() variants object never starts this way).
if echo "$CONTENT" | awk '/^export const [A-Za-z0-9_]+ = \{/{b=1} b&&/\} as const/{f=1} END{exit !f}'; then
  block "an enum-like constant is defined in a UI file" \
        "Move it to model/constants.ts."
fi

# 3. A zod schema.
if echo "$CONTENT" | grep -qE 'z\.object\(|z\.(string|number|enum)\('; then
  block "a zod schema is defined in a UI file" \
        "Schemas go in model/schemas.ts, never inline in a component."
fi

# 4. A hook defined beside the component that uses it.
if echo "$CONTENT" | grep -qE '^export (const|function) use[A-Z]'; then
  block "a hook is defined in a UI file" \
        "Move it to hooks/use-<name>.ts."
fi

# 5. HTTP called directly from UI.
if echo "$CONTENT" | grep -qE 'httpClient\.|axios\.|fetch\('; then
  block "an HTTP call is made directly in a UI file" \
        "HTTP calls live in api/, never inline in a component."
fi

exit 0
