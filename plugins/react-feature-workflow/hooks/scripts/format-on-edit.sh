#!/bin/bash
# PostToolUse(Edit|Write): auto-formats the touched file with the project's own Prettier.
# Agents never spend tokens on formatting; the reviewer never checks it.

INPUT=$(cat)
FILE=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty')

[ -z "$FILE" ] && exit 0

PRETTIER="${CLAUDE_PROJECT_DIR:-.}/node_modules/.bin/prettier"

case "$FILE" in
  */node_modules/*|*/dist/*|*/.git/*) exit 0 ;;
  *.ts|*.tsx|*.js|*.jsx|*.json|*.css|*.scss|*.html)
    if [ -f "$FILE" ] && [ -x "$PRETTIER" ]; then
      "$PRETTIER" --write "$FILE" >/dev/null 2>&1 || true
    fi
    ;;
esac

exit 0
