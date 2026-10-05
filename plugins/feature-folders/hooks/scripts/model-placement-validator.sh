#!/bin/bash
# Blocks domain content (not file placement) landing in the wrong home: a UI file
# defining a domain type, an enum-like constant, a zod schema, a hook, or calling
# HTTP directly; or any write inside a feature/page's own `api/` folder.
#
# bucket-placement-validator skips edits to files that already exist, because a
# legacy tree is left alone. This hook does not: new content is new slop wherever
# it lands, so it checks every Write and Edit, old file or new.

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
CONTENT=$(echo "$INPUT" | jq -r '.tool_input.new_string // .tool_input.content // empty')

[[ -z "$FILE_PATH" ]] && exit 0

block() {
  echo "[model-placement-validator] Placement violation: $1" >&2
  echo "$2" >&2
  exit 2
}

# HTTP calls never live in a feature's or page's own api/ folder — always
# src/api/<resource>/, keyed by backend resource, from the first call.
if [[ "$FILE_PATH" =~ /(features|pages)/[^/]+/api/ ]]; then
  block "a feature/page has its own 'api/' folder" \
        "HTTP calls live in src/api/<resource>/, keyed by backend resource — never inside a feature or page module."
fi

[[ -z "$CONTENT" ]] && exit 0

case "$FILE_PATH" in
  *.test.tsx|*.test.ts|*.spec.tsx|*.spec.ts|*.stories.tsx) exit 0 ;;
esac

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
        "Domain types go in <module>/types.ts, or src/api/<resource>/types.ts for a request/response shape."
done <<<"$CONTENT"

# 2. An enum-like as-const object (the declaration and its closing brace, on
#    one line or several — a cva() variants object never starts this way).
if echo "$CONTENT" | awk '/^export const [A-Za-z0-9_]+ = \{/{b=1} b&&/\} as const/{f=1} END{exit !f}'; then
  block "an enum-like constant is defined in a UI file" \
        "Move it to <module>/constants.ts (src/config/ if it is app-wide)."
fi

# 3. A zod schema.
if echo "$CONTENT" | grep -qE 'z\.object\(|z\.(string|number|enum)\('; then
  block "a zod schema is defined in a UI file" \
        "Schemas go in <module>/schemas.ts, never inline in a component."
fi

# 4. A hook defined beside the component that uses it.
if echo "$CONTENT" | grep -qE '^export (const|function) use[A-Z]'; then
  block "a hook is defined in a UI file" \
        "Move it to <module>/hooks/use-<name>.ts."
fi

# 5. HTTP called directly from UI.
if echo "$CONTENT" | grep -qE 'httpClient\.|axios\.|fetch\('; then
  block "an HTTP call is made directly in a UI file" \
        "HTTP calls live in src/api/<resource>/, never inline in a component."
fi

exit 0
