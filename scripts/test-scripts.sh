#!/usr/bin/env bash
# The half of the eval suite that runs without `claude plugin eval`: the kit's own
# scripts, and every eval case's scaffold. A broken fixture fails CI here even where
# the graded runs are not available. Called by check-all.sh.
set -uo pipefail
cd "$(dirname "$0")/.."

ROOT="$PWD"
fail=0
ok()   { printf '  ok    %s\n' "$1"; }
bad()  { printf '  FAIL  %s\n' "$1"; fail=1; }
have() { grep -qE "$2" "$1" && ok "$3" || bad "$3"; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# --- sibling-outline.sh over a generated module ---
OUTLINE="$ROOT/plugins/react-feature-workflow/skills/implement/scripts/sibling-outline.sh"
FIX="$WORK/fixture"
mkdir -p "$FIX/src/entities/article/api" "$FIX/src/entities/article/model"

cat > "$FIX/src/entities/article/index.ts" <<'EOF'
export type { Article } from "./model/types"
export { articleKeys } from "./api/article.queries"
EOF

cat > "$FIX/src/entities/article/api/article.queries.ts" <<'EOF'
import { queryOptions } from "@tanstack/react-query"

export const articleKeys = {
  all: ["article"] as const,
  detail: (id: string) => [...articleKeys.all, "detail", id] as const,
}

export const articleQueries = {
  detail: (id: string) => queryOptions({ queryKey: articleKeys.detail(id) }),
}
EOF

{
  echo 'export interface Article {'
  echo '  id: string'
  echo '}'
  i=0
  while [ "$i" -lt 400 ]; do echo "// filler $i"; i=$((i + 1)); done
} > "$FIX/src/entities/article/model/types.ts"

cat > "$FIX/src/entities/article/model/types.test.ts" <<'EOF'
export const shouldBeSkipped = true
EOF

printf '\nsibling-outline.sh\n'
OUT="$WORK/outline.txt"
if (cd "$FIX" && bash "$OUTLINE" src/entities/article) > "$OUT" 2>&1; then
  ok "exits 0"
else
  bad "exits 0"
  cat "$OUT"
fi

have "$OUT" '^src/entities/article — 3 files, [0-9]+ lines$' "header counts files and lines"
have "$OUT" '^  model/types\.ts +40[0-9]$'                    "file sizes listed"
have "$OUT" 'export type \{ Article \}'                        "barrel printed verbatim"
have "$OUT" 'article\.queries\.ts:[0-9]+  +detail: \(id: string\) => queryOptions' "short file printed whole with path:line"
have "$OUT" 'model/types\.ts:1  export interface Article'      "long file reduced to exported signatures"
have "$OUT" 'all: \["article"\] as const'                      "key factory body printed"
grep -q 'filler' "$OUT" && bad "long file body not printed" || ok "long file body not printed"
have "$OUT" '^  @tanstack/react-query$'                        "external imports collected"
grep -q 'shouldBeSkipped' "$OUT" && bad "test files excluded" || ok "test files excluded"

SRC_LINES=$(cat "$FIX"/src/entities/article/api/*.ts "$FIX"/src/entities/article/model/types.ts \
  "$FIX"/src/entities/article/index.ts | wc -l | tr -d ' ')
OUT_LINES=$(wc -l < "$OUT" | tr -d ' ')
if [ "$OUT_LINES" -lt $((SRC_LINES / 5)) ]; then
  ok "outline is ${OUT_LINES} lines against ${SRC_LINES} of source"
else
  bad "outline is ${OUT_LINES} lines against ${SRC_LINES} of source — no longer a slice"
fi

# Captured first, not piped: `grep -q` would close the pipe early and pipefail would
# report the script's SIGPIPE as a failure.
NOTMP="$(cd "$FIX" && TMPDIR=/nonexistent/denied bash "$OUTLINE" src/entities/article 2>/dev/null)" || NOTMP=""
if printf '%s\n' "$NOTMP" | grep -q '^src/entities/article — 3 files'; then
  ok "runs with an unwritable TMPDIR (no mktemp, no here-documents)"
else
  bad "runs with an unwritable TMPDIR — sandboxed shells deny mktemp"
fi

if bash "$OUTLINE" "$WORK/does-not-exist" >/dev/null 2>&1; then
  bad "missing directory exits non-zero"
else
  ok "missing directory exits non-zero"
fi

# --- guard hooks: refuse the three shortcuts, let everything else through ---
printf '\nguard hooks\n'
HOOKS="$ROOT/plugins/react-feature-workflow/hooks/scripts"
HFIX="$WORK/hookfix"
mkdir -p "$HFIX/.planning/comments" "$HFIX/api" "$HFIX/src/entities/article/model" "$HFIX/docs"
printf 'Source: `api/openapi.json`\n' > "$HFIX/.planning/comments/contract.md"
echo '{"openapi":"3.0.0"}' > "$HFIX/api/openapi.json"
cp "$FIX/src/entities/article/model/types.ts" "$HFIX/src/entities/article/model/types.ts"
echo 'export {}' > "$HFIX/src/entities/article/index.ts"
seq 1 400 | sed 's/^/line /' > "$HFIX/docs/long.md"

hook_run() { printf '%s' "$2" | node "$HOOKS/$1" >/dev/null 2>"$WORK/hook-err"; echo $?; }
refuses() {  # <script> <json> <tag> <label>
  local code; code="$(hook_run "$1" "$2")"
  if [ "$code" = 2 ] && grep -q "\[$3\]" "$WORK/hook-err"; then ok "$4"; else bad "$4 (exit $code)"; fi
}
allows() {   # <script> <json> <label>
  local code; code="$(hook_run "$1" "$2")"
  if [ "$code" = 0 ]; then ok "$3"; else bad "$3 (exit $code: $(head -c 80 "$WORK/hook-err"))"; fi
}
rd() { printf '{"tool_name":"Read","cwd":"%s","tool_input":{"file_path":"%s/%s"%s}}' "$HFIX" "$HFIX" "$1" "${2:-}"; }
sh() { printf '{"tool_name":"Bash","cwd":"%s","tool_input":{"command":"%s"}}' "$HFIX" "$1"; }

refuses long-read-guard.mjs "$(rd src/entities/article/model/types.ts)"              long-read-guard "long source file, no limit: refused"
allows  long-read-guard.mjs "$(rd src/entities/article/model/types.ts ',"limit":40')"                 "long source file with a limit: allowed"
allows  long-read-guard.mjs "$(rd src/entities/article/index.ts)"                                     "short source file: allowed"
allows  long-read-guard.mjs "$(rd docs/long.md)"                                                      "long markdown: allowed (not source)"
allows  long-read-guard.mjs "$(rd .planning/comments/contract.md)"                                    "planning folder: allowed"
mkdir -p "$HFIX/node_modules/lib/dist"
seq 1 750  | sed 's/^/export declare const d/' > "$HFIX/node_modules/lib/dist/index.d.mts"
seq 1 1200 | sed 's/^/export declare const e/' > "$HFIX/node_modules/lib/dist/huge.d.ts"
allows  long-read-guard.mjs "$(rd node_modules/lib/dist/index.d.mts)"                                 "750-line library types: allowed (deps bar is 1000)"
refuses long-read-guard.mjs "$(rd node_modules/lib/dist/huge.d.ts)"                     long-read-guard "1200-line library types: refused"

refuses shell-read-guard.mjs "$(sh 'cat src/entities/article/model/types.ts')"                shell-read-guard "cat on a source file: refused"
refuses shell-read-guard.mjs "$(sh 'for f in src/a.ts src/b.ts; do cat \"$f\"; done')"     shell-read-guard "for-loop cat: refused"
refuses shell-read-guard.mjs "$(sh 'awk NR>=30 src/a.ts && tail -20 src/a.ts')"             shell-read-guard "awk and tail on a source file: refused"
allows  shell-read-guard.mjs "$(sh 'cat > src/new.ts <<EOF')"                                                  "heredoc write: allowed"
allows  shell-read-guard.mjs "$(sh 'bash /r/skills/implement/scripts/sibling-outline.sh src/entities/article')" "outline script: allowed"
allows  shell-read-guard.mjs "$(sh 'pnpm typecheck 2>&1 | tail -20')"                                          "tail on command output: allowed"
allows  shell-read-guard.mjs "$(sh 'grep -n Article src/entities/article/model/types.ts')"                      "grep on a source file: allowed"
allows  shell-read-guard.mjs "$(sh 'grep -n Sheet src/components/ui/sidebar.tsx | head -40')"                    "grep piped into head: allowed (head trims output)"
allows  shell-read-guard.mjs "$(sh 'grep -n Compass node_modules/lucide-react/dist/lucide-react.d.ts 2>/dev/null | head -5')" "grep on a .d.ts piped into head: allowed"
allows  shell-read-guard.mjs "$(sh 'cat <<EOF > src/new.ts')"                                                  "heredoc write, cat first: allowed"
allows  shell-read-guard.mjs "$(sh 'tail -f logs/server.js.log')"                                              "tail on a .js.log: allowed (not a source file)"
refuses shell-read-guard.mjs "$(sh 'head -50 src/entities/article/model/types.ts')"                 shell-read-guard "head on a source file: refused"
refuses shell-read-guard.mjs "$(sh 'cd src && cat entities/article/index.ts')"                      shell-read-guard "cat after &&: refused"
refuses shell-read-guard.mjs "$(sh 'echo $(cat src/a.ts)')"                                         shell-read-guard "cat inside command substitution: refused"
refuses shell-read-guard.mjs "$(sh 'find src -name *.ts -exec cat {} \\;')"                          shell-read-guard "find -exec cat: refused"
refuses shell-read-guard.mjs "$(sh 'find src -name *.ts | xargs cat | wc -l')"                     shell-read-guard "xargs cat: refused"

refuses contract-source-guard.mjs "$(rd api/openapi.json)"                        contract-source-guard "Read of the contract source: refused"
refuses contract-source-guard.mjs "$(sh 'jq . api/openapi.json')"                  contract-source-guard "shell on the contract source: refused"
allows  contract-source-guard.mjs "$(sh 'node /r/skills/api-contract/scripts/contract-slice.mjs api/openapi.json GET /a')" "the slicer: allowed"
allows  contract-source-guard.mjs "$(rd .planning/comments/contract.md)"                                                  "the contract itself: allowed"
allows  contract-source-guard.mjs "$(printf '{"tool_name":"Read","cwd":"%s","tool_input":{"file_path":"%s/api/openapi.json"}}' "$FIX" "$FIX")" "no contract.md in the project: allowed"

if [ "$(RFW_GUARDS=off hook_run long-read-guard.mjs "$(rd src/entities/article/model/types.ts)")" = 0 ]; then
  ok "RFW_GUARDS=off disables a guard"
else
  bad "RFW_GUARDS=off disables a guard"
fi

# --- project-rules.mjs: discovery from Claude Code's own registries ---
printf '\nproject-rules.mjs\n'
PR="$ROOT/plugins/react-feature-workflow/skills/review/scripts/project-rules.mjs"
PRHOME="$WORK/prhome"
PRPROJ="$(cd "$(mktemp -d "$WORK/prproj.XXXX")" && pwd -P)"
mkdir -p "$PRHOME/.claude/plugins" "$PRPROJ/.claude/rules" "$PRPROJ/src/entities"
INSTALL="$PRHOME/cache/vadimgaidai/feature-sliced-design/0.2.0"
mkdir -p "$INSTALL/skills/structure" "$INSTALL/hooks/scripts"
echo '## Reviewing' > "$INSTALL/skills/structure/SKILL.md"
touch "$INSTALL/hooks/scripts/fsd-validator.sh" "$INSTALL/hooks/scripts/model-placement-validator.sh"
cat > "$PRHOME/.claude/settings.json" <<EOF
{"enabledPlugins": {"feature-sliced-design@vadimgaidai": true}}
EOF
cat > "$PRHOME/.claude/plugins/installed_plugins.json" <<EOF
{"version":2,"plugins":{"feature-sliced-design@vadimgaidai":[{"scope":"project","projectPath":"$PRPROJ","installPath":"$INSTALL"}]}}
EOF
cat > "$PRPROJ/.claude/rules/api.md" <<'EOF'
---
paths: src/api/**/*.ts
---
Rule body
EOF
echo '# conventions' > "$PRPROJ/CLAUDE.md"

PROUT="$WORK/pr-out"
(cd "$PRPROJ" && RFW_HOME="$PRHOME" node "$PR" src/api/article.ts) > "$PROUT" 2>&1
have "$PROUT" '^Structure plugin: feature-sliced-design@vadimgaidai$'       "finds the enabled structure plugin via installed_plugins.json"
have "$PROUT" 'SKILL\.md#reviewing$'                                       "prints the Reviewing section path"
have "$PROUT" 'fsd-validator\.sh, model-placement-validator\.sh$'          "lists the plugin's hook scripts"
have "$PROUT" '\.claude/rules/api\.md \(paths: src/api/\*\*/\*\.ts\)$'     "a changed file matching paths: is reported"

PROUT2="$WORK/pr-out2"
(cd "$PRPROJ" && RFW_HOME="$PRHOME" node "$PR" src/entities/article/ui/card.tsx) > "$PROUT2" 2>&1
grep -q 'rules/api\.md' "$PROUT2" && bad "a changed file not matching paths: is omitted" || ok "a changed file not matching paths: is omitted"

echo '{}' > "$PRHOME/.claude/settings.json"
PROUT3="$WORK/pr-out3"
(cd "$PRPROJ" && RFW_HOME="$PRHOME" node "$PR") > "$PROUT3" 2>&1
have "$PROUT3" 'FSD-shaped, no plugin enabled' "falls back to a shape warning when no structure plugin is enabled"

# --- review lint config: one violation per rule fires, a clean fixture shows nothing ---
printf '\nreview lint config\n'
LINTROOT="$ROOT/plugins/react-feature-workflow/skills/review"
LINTFIX="$WORK/lintfix"
mkdir -p "$LINTFIX/src"
cat > "$LINTFIX/package.json" <<'EOF'
{"name":"lintfix","private":true}
EOF
cat > "$LINTFIX/tsconfig.json" <<'EOF'
{"compilerOptions":{"target":"ES2022","module":"ESNext","jsx":"react-jsx","strict":true,"skipLibCheck":true},"include":["src/**/*.ts","src/**/*.tsx"]}
EOF

if (cd "$LINTFIX" && npm install --no-audit --no-fund --silent \
  eslint typescript-eslint eslint-plugin-react-hooks eslint-plugin-react typescript \
  >/dev/null 2>"$WORK/lint-install-err"); then
  ESLINT="$LINTFIX/node_modules/.bin/eslint"

  cat > "$LINTFIX/src/violations.ts" <<'EOF'
export function pick(a: number, b: boolean) {
  const x = b ? (a > 0 ? "pos" : "neg") : "zero"
  return x
}

export function maybeReturn(flag: boolean) {
  if (flag) {
    return 1
  }
}

export function withMagic(n: number) {
  return n * 42
}

export function badCast(value: unknown) {
  return (value as any).foo
}

export function nonNull(value: string | null) {
  return value!.length
}

export async function loopAwait(items: string[]) {
  for (const item of items) {
    await fetch(item)
  }
}

export function threeParams(a: number, b: number, c: number) {
  return a + b + c
}
EOF

  OUT="$WORK/lint-out.txt"
  (cd "$LINTFIX" && "$ESLINT" --config "$LINTROOT/review.eslint.config.mjs" src/violations.ts) \
    > "$OUT" 2>&1 || true
  for rule in no-nested-ternary consistent-return no-magic-numbers \
    "@typescript-eslint/no-explicit-any" "@typescript-eslint/no-non-null-assertion" \
    no-await-in-loop max-params "@typescript-eslint/consistent-type-assertions"; do
    have "$OUT" "$rule" "violation fixture flags $rule"
  done

  cat > "$LINTFIX/src/clean.ts" <<'EOF'
export interface Article {
  id: string
  title: string
  createdAt: string
}

export function formatTitle(title: string, maxLength: number) {
  if (title.length <= maxLength) return title
  return `${title.slice(0, maxLength)}…`
}
EOF

  CLEAN_OUT="$WORK/lint-clean.txt"
  if (cd "$LINTFIX" && "$ESLINT" --config "$LINTROOT/review.eslint.config.mjs" src/clean.ts) \
    > "$CLEAN_OUT" 2>&1; then
    ok "clean fixture: zero findings"
  else
    bad "clean fixture: zero findings"
    cat "$CLEAN_OUT"
  fi
else
  ok "review lint config: skipped (no network or eslint unavailable)"
fi

# --- every eval case scaffolds cleanly ---
printf '\neval scaffolds\n'
for case_file in plugins/*/evals/*/case.yaml; do
  [ -e "$case_file" ] || continue
  case_dir="$(dirname "$case_file")"
  case_name="$(basename "$case_dir")"
  rel="$(sed -nE 's/^  scaffold_script:[[:space:]]*//p' "$case_file" | head -n 1)"
  if [ -z "$rel" ]; then
    ok "$case_name: no scaffold_script"
    continue
  fi
  script="$ROOT/$case_dir/$rel"
  if [ ! -f "$script" ]; then
    bad "$case_name: scaffold_script '$rel' is not a file in the case directory"
    continue
  fi
  if ! bash -n "$script" 2>"$WORK/err"; then
    bad "$case_name: scaffold parses"
    sed 's/^/        /' "$WORK/err"
    continue
  fi
  sandbox="$WORK/run-$case_name"
  mkdir -p "$sandbox"
  if (cd "$sandbox" && bash "$script") >"$WORK/err" 2>&1; then
    # A scaffold that creates .planning/ (react-feature-workflow's fixtures) must put a
    # PLAN.md in it — that's the file `implement`/`review` read. A scaffold for a plugin
    # with no planning workflow (e.g. feature-folders, testing hooks only) has no
    # .planning/ at all, and running cleanly is the whole bar for it.
    if [ -d "$sandbox/.planning" ]; then
      if ls "$sandbox"/.planning/*/PLAN.md >/dev/null 2>&1; then
        ok "$case_name: scaffold runs and writes a PLAN.md"
      else
        bad "$case_name: scaffold ran but wrote no .planning/*/PLAN.md"
      fi
    else
      ok "$case_name: scaffold runs"
    fi
  else
    bad "$case_name: scaffold runs"
    sed 's/^/        /' "$WORK/err"
  fi
done

exit $fail
