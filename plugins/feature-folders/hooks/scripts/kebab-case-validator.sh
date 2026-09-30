#!/bin/bash
# Validates that a NEW file under src/ follows kebab-case naming.
# Allows: kebab-case.tsx, kebab-case.ts, index.ts
# Blocks: MyComponent.tsx, camelCase.ts, PascalCase.tsx
#
# Editing or overwriting a file that already exists always passes, whatever its
# name — a legacy tree with its own naming predates this plugin and is never
# fought file by file; only a newly created file is checked.

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [[ -z "$FILE_PATH" ]] || [[ "$FILE_PATH" != *"/src/"* ]] || [[ -e "$FILE_PATH" ]]; then
  exit 0
fi

FILENAME=$(basename "$FILE_PATH")

# Remove extension for validation
NAME="${FILENAME%.*}"

# Allow index files
if [[ "$NAME" == "index" ]]; then
  exit 0
fi

# Portable kebab-case suggestion (no GNU sed \L — plain bash + tr, works on macOS's bash 3.2 too)
to_kebab() {
  local input="$1" out="" c lc i
  for (( i = 0; i < ${#input}; i++ )); do
    c="${input:$i:1}"
    if [[ "$c" =~ [A-Z] ]]; then
      lc=$(printf '%s' "$c" | tr '[:upper:]' '[:lower:]')
      [[ $i -gt 0 ]] && out+="-"
      out+="$lc"
    else
      out+="$c"
    fi
  done
  printf '%s' "$out"
}

# Check for uppercase letters (not kebab-case)
if [[ "$NAME" =~ [A-Z] ]]; then
  echo "[kebab-case-validator] Naming violation: '$FILENAME' is not kebab-case" >&2
  echo "Expected: '$(to_kebab "$NAME")'" >&2
  exit 2
fi

# Check for underscores (should use hyphens)
if [[ "$NAME" =~ _ ]]; then
  echo "[kebab-case-validator] Naming violation: '$FILENAME' uses underscores instead of hyphens" >&2
  echo "Expected: '$(echo "$NAME" | tr '_' '-')'" >&2
  exit 2
fi

exit 0
