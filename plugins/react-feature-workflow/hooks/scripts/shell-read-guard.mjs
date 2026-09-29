#!/usr/bin/env node
// PreToolUse(Bash): source files are not dumped through the shell. `cat src/a.ts`,
// `head -50 src/a.tsx`, `sed -n 1,40p src/b.ts` hide how much entered the window; Read
// (with offset/limit for a range) keeps it visible, and a module is outlined, not catted.
//
// What counts as reading: a reader command (cat, head, tail, sed, awk …) whose OWN
// arguments name a source file. `grep foo src/a.ts | head -40` is not — there `head`
// trims grep's output, which is the cheap direction. Writing through a heredoc
// (`cat > file <<EOF`, `cat <<EOF > file`) is not reading either. The loop and xargs
// shapes that hide the file name from the reader (`for f in *.ts; do cat "$f"`,
// `find … -exec cat`, `xargs cat`) are caught on the whole command.
// Exit 2 blocks the call; RFW_GUARDS=off disables it.
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";

if (process.env.RFW_GUARDS === "off") process.exit(0);

let input = {};
try {
  input = JSON.parse(readFileSync(0, "utf8"));
} catch {
  process.exit(0);
}
if (input.tool_name !== "Bash") process.exit(0);
const cmd = (input.tool_input || {}).command;
if (typeof cmd !== "string") process.exit(0);

const SOURCE_FILE = /\.[cm]?[jt]sx?(?![\w.])/; // .ts .tsx .js .jsx .mjs .cjs .mts .cts — not .js.log
if (!SOURCE_FILE.test(cmd)) process.exit(0);

const READERS = "cat|head|tail|sed|awk|less|more|bat|nl|tac";
// a reader at the start of its own pipeline segment, followed by arguments that name a source file
const SEGMENT = new RegExp(
  `(?:^|[|;&\\n(\`]|\\$\\()\\s*(?:[A-Za-z_][A-Za-z0-9_]*=\\S*\\s+)*(?:${READERS})\\b(?!\\s*>)(?!\\s*<<)[^|;&\\n]*?${SOURCE_FILE.source}`,
);
// shapes that hide the file name from the reader
const LOOP = new RegExp(`\\bdo\\s+(?:${READERS})\\b`);
const XARGS = new RegExp(`\\bxargs\\s+(?:-\\S+\\s+)*(?:${READERS})\\b`);
const EXEC = new RegExp(`-exec(?:dir)?\\s+(?:${READERS})\\b`);

if (!(SEGMENT.test(cmd) || LOOP.test(cmd) || XARGS.test(cmd) || EXEC.test(cmd))) process.exit(0);

const root = fileURLToPath(new URL("../..", import.meta.url)).replace(/\/$/, "");
process.stderr.write(
  `[shell-read-guard] Source files are not dumped through the shell (cat, head, tail, sed, awk …) — how much entered the window has to stay visible.\n` +
    `Use Read, with \`offset\`/\`limit\` for a range, or grep for the symbol (piping grep into head is fine). A module you are mirroring is outlined, not catted:\n` +
    `  bash "${root}"/skills/implement/scripts/sibling-outline.sh <module-dir>\n` +
    `Edits go through Edit, not sed -i.\n`,
);
process.exit(2);
