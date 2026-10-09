#!/usr/bin/env node
// PreToolUse(Read|Bash): the raw OpenAPI/Swagger spec a contract was sliced from is not
// opened again — not with Read, not through the shell. `.planning/*/contract.md` already
// carries every field, required flag, enum and format for the endpoints the plan names.
// The slicer (contract-slice.mjs) is the one sanctioned reader. Exit 2 blocks the call
// and hands the message back to Claude; RFW_GUARDS=off disables every guard.
import { existsSync, readFileSync, readdirSync } from "node:fs";
import { join, resolve } from "node:path";

if (process.env.RFW_GUARDS === "off") process.exit(0);

let input = {};
try {
  input = JSON.parse(readFileSync(0, "utf8"));
} catch {
  process.exit(0);
}
const tool = input.tool_name;
const cwd = input.cwd || process.cwd();
const t = input.tool_input || {};

const planning = join(cwd, ".planning");
if (!existsSync(planning)) process.exit(0);

const sources = [];
for (const name of readdirSync(planning)) {
  const file = join(planning, name, "contract.md");
  if (!existsSync(file)) continue;
  const m = readFileSync(file, "utf8").match(/^Source:\s*`?([^`\n]+?)`?\s*$/m);
  if (m) sources.push({ src: m[1].trim(), contract: `.planning/${name}/contract.md` });
}
if (!sources.length) process.exit(0);

function block({ src, contract }) {
  process.stderr.write(
    `[contract-source-guard] \`${src}\` is the source of \`${contract}\` and is not opened again.\n` +
      `The slice already carries every field, required flag, enum and format for the endpoints the plan names — read the contract. ` +
      `If it looks stale, re-slice it (/react-feature-workflow:plan, or the contract-slice.mjs command in skills/api-contract) rather than reading the spec.\n`,
  );
  process.exit(2);
}

if (tool === "Read" && typeof t.file_path === "string") {
  const target = resolve(cwd, t.file_path);
  for (const s of sources) {
    if (/^https?:/i.test(s.src)) continue;
    if (resolve(cwd, s.src) === target) block(s);
  }
}

if (tool === "Bash" && typeof t.command === "string") {
  if (/contract-slice\.mjs/.test(t.command)) process.exit(0);
  for (const s of sources) if (t.command.includes(s.src)) block(s);
}

process.exit(0);
