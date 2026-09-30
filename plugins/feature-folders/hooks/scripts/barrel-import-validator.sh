#!/bin/bash
# Blocks barrel imports from @/components/ui — must import by direct path
# Allowed: import { Button } from "@/components/ui/button"
# Blocked: import { Button } from "@/components/ui"

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
CONTENT=$(echo "$INPUT" | jq -r '.tool_input.new_string // .tool_input.content // empty')

if [[ -z "$FILE_PATH" ]] || [[ -z "$CONTENT" ]]; then
  exit 0
fi

# Only source files can contain imports — skip docs, configs, etc.
if [[ "$FILE_PATH" != *.ts && "$FILE_PATH" != *.tsx && "$FILE_PATH" != *.js && "$FILE_PATH" != *.jsx ]]; then
  exit 0
fi

# Skip files inside components/ui itself (barrel exports, if any, are fine there)
if [[ "$FILE_PATH" == *"/components/ui/"* ]]; then
  exit 0
fi

# Check for barrel import from @/components/ui (without a sub-path)
if echo "$CONTENT" | grep -qE 'from\s+["\x27]@/components/ui["\x27]'; then
  echo "[barrel-import-validator] Import violation: barrel import from '@/components/ui' is not allowed" >&2
  echo "Import directly: '@/components/ui/button', '@/components/ui/card', etc." >&2
  exit 2
fi

exit 0
