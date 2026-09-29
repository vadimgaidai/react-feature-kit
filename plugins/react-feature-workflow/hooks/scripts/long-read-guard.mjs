#!/usr/bin/env node
// PreToolUse(Read): a source file longer than RFW_LONG_READ_LINES (default 300) is not
// read whole. Under node_modules the bar is RFW_LONG_READ_DEPS_LINES (default 1000): a
// library's .d.ts has no outline, and a dozen greps cost more than one read. A range (offset/limit), a grep, or an outline of the module it belongs to
// gives what a whole read gives at a fraction of the window. `.planning/` is exempt: the
// plan and the contract are the brief. Exit 2 blocks the call; RFW_GUARDS=off disables it.
import { existsSync, readFileSync, statSync } from "node:fs";
import { extname, relative, resolve, sep } from "node:path";
import { fileURLToPath } from "node:url";

if (process.env.RFW_GUARDS === "off") process.exit(0);

let input = {};
try {
  input = JSON.parse(readFileSync(0, "utf8"));
} catch {
  process.exit(0);
}
if (input.tool_name !== "Read") process.exit(0);
const t = input.tool_input || {};
if (typeof t.file_path !== "string" || t.limit != null) process.exit(0);

const cwd = input.cwd || process.cwd();
const file = resolve(cwd, t.file_path);
const SOURCE = new Set([".ts", ".tsx", ".js", ".jsx", ".mjs", ".cjs", ".mts", ".cts", ".css", ".scss", ".json", ".yaml", ".yml"]);
if (!SOURCE.has(extname(file))) process.exit(0);
if (relative(cwd, file).split(sep).includes(".planning")) process.exit(0);
if (!existsSync(file) || !statSync(file).isFile()) process.exit(0);

const inDeps = relative(cwd, file).split(sep).includes("node_modules");
const max = inDeps
  ? Number(process.env.RFW_LONG_READ_DEPS_LINES) || 1000
  : Number(process.env.RFW_LONG_READ_LINES) || 300;
const text = readFileSync(file, "utf8");
let lines = 0;
for (let i = 0; i < text.length; i++) if (text.charCodeAt(i) === 10) lines++;
if (text.length && !text.endsWith("\n")) lines++;
if (lines <= max) process.exit(0);

const root = fileURLToPath(new URL("../..", import.meta.url)).replace(/\/$/, "");
process.stderr.write(
  `[long-read-guard] \`${t.file_path}\` is ${lines} lines and is not read whole.\n` +
    `Read a range (\`offset\`/\`limit\`) around the symbol you need, or grep for it. ` +
    `If the file belongs to a module you are mirroring, outline the module instead:\n` +
    `  bash "${root}"/skills/implement/scripts/sibling-outline.sh <module-dir>\n`,
);
process.exit(2);
