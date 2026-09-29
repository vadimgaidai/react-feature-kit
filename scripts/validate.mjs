#!/usr/bin/env node
// Structural checks for the marketplace and both plugins. Run via ./scripts/check-all.sh.
import { readFileSync, readdirSync, existsSync, statSync } from "node:fs";
import { basename, dirname, join, resolve, sep } from "node:path";

const root = resolve(dirname(new URL(import.meta.url).pathname), "..");
let failures = 0;
const fail = (msg) => {
  failures++;
  console.error(`  FAIL ${msg}`);
};

const readJson = (path) => {
  try {
    return JSON.parse(readFileSync(join(root, path), "utf8"));
  } catch (e) {
    fail(`${path}: ${e.message}`);
    return null;
  }
};

const frontmatter = (path) => {
  const text = readFileSync(join(root, path), "utf8");
  const m = text.match(/^---\n([\s\S]*?)\n---/);
  if (!m) return null;
  const fields = {};
  for (const line of m[1].split("\n")) {
    const kv = line.match(/^(\w[\w-]*):\s*(.*)$/);
    if (kv) fields[kv[1]] = kv[2];
  }
  return fields;
};

// --- marketplace.json parses and matches each plugin.json ---
console.log("marketplace ↔ plugin manifests");
const marketplace = readJson(".claude-plugin/marketplace.json");
if (marketplace) {
  for (const entry of marketplace.plugins ?? []) {
    const dir = entry.source.replace(/^\.\//, "");
    if (!existsSync(join(root, dir))) {
      fail(`marketplace entry "${entry.name}": source ${entry.source} does not exist`);
      continue;
    }
    const manifest = readJson(`${dir}/.claude-plugin/plugin.json`);
    if (!manifest) continue;
    for (const field of ["name", "version", "description"]) {
      if (manifest[field] !== entry[field])
        fail(`${entry.name}: ${field} differs between marketplace.json and plugin.json`);
    }
  }
}

// --- every SKILL.md and agent has frontmatter; skill name matches its directory ---
console.log("skill and agent frontmatter");
const plugins = readdirSync(join(root, "plugins")).filter((p) =>
  statSync(join(root, "plugins", p)).isDirectory()
);
for (const plugin of plugins) {
  const skillsDir = join(root, "plugins", plugin, "skills");
  if (existsSync(skillsDir)) {
    for (const skill of readdirSync(skillsDir)) {
      const path = `plugins/${plugin}/skills/${skill}/SKILL.md`;
      if (!existsSync(join(root, path))) {
        fail(`${path} is missing`);
        continue;
      }
      const fm = frontmatter(path);
      if (!fm) fail(`${path}: no frontmatter block`);
      else {
        if (!fm.name) fail(`${path}: frontmatter has no name`);
        else if (fm.name !== skill) fail(`${path}: name "${fm.name}" != directory "${skill}"`);
        if (!fm.description) fail(`${path}: frontmatter has no description`);
      }
    }
  }
  const agentsDir = join(root, "plugins", plugin, "agents");
  if (existsSync(agentsDir)) {
    for (const agent of readdirSync(agentsDir).filter((f) => f.endsWith(".md"))) {
      const path = `plugins/${plugin}/agents/${agent}`;
      const fm = frontmatter(path);
      if (!fm?.name || !fm?.description) fail(`${path}: frontmatter needs name and description`);
    }
  }
}

// --- hooks.json parses; every command's script exists and is executable ---
console.log("hook scripts exist and are executable");
for (const plugin of plugins) {
  const hooksPath = `plugins/${plugin}/hooks/hooks.json`;
  if (!existsSync(join(root, hooksPath))) continue;
  const hooks = readJson(hooksPath);
  if (!hooks) continue;
  const commands = [];
  const collect = (node) => {
    if (Array.isArray(node)) node.forEach(collect);
    else if (node && typeof node === "object") {
      if (typeof node.command === "string") commands.push(node.command);
      Object.values(node).forEach(collect);
    }
  };
  collect(hooks);
  if (!commands.length) fail(`${hooksPath}: no commands found`);
  const evalsDir = join(root, "plugins", plugin, "evals");
  // only case files count — a README mention is documentation, not coverage
  const evalText = existsSync(evalsDir)
    ? listFiles(evalsDir)
        .filter((f) => !f.includes(`${sep}results${sep}`) && !f.endsWith("README.md") && /\.(md|yaml|yml)$/.test(f))
        .map((f) => readFileSync(f, "utf8"))
        .join("\n")
    : null;
  for (const cmd of commands) {
    const rel = cmd.replaceAll('"', "").replace("${CLAUDE_PLUGIN_ROOT}", "");
    const script = join(root, "plugins", plugin, rel);
    if (!existsSync(script)) fail(`${hooksPath}: ${rel} does not exist`);
    else if (!(statSync(script).mode & 0o111)) fail(`plugins/${plugin}${rel} is not executable`);
    // a hook that is wired wrong fails silently — every script must be exercised by an eval case
    const stem = basename(rel).replace(/\.[^.]+$/, "");
    if (evalText !== null && !evalText.includes(stem))
      fail(`${hooksPath}: ${basename(rel)} is not named (as "${stem}") in any eval case under plugins/${plugin}/evals/`);
  }
}

function listFiles(dir) {
  const out = [];
  for (const name of readdirSync(dir)) {
    const p = join(dir, name);
    if (statSync(p).isDirectory()) out.push(...listFiles(p));
    else out.push(p);
  }
  return out;
}

// --- eval cases: a case file, graders, and a known grader type on each ---
console.log("eval cases are well-formed");
const GRADER_TYPES = new Set(["regex", "tool_order", "tool_used", "file_exists", "llm", "baseline"]);
for (const plugin of plugins) {
  const evalsDir = join(root, "plugins", plugin, "evals");
  if (!existsSync(evalsDir)) continue;
  for (const name of readdirSync(evalsDir)) {
    if (name === "results" || name === "README.md") continue;
    if (!statSync(join(evalsDir, name)).isDirectory()) continue;
    const base = `plugins/${plugin}/evals/${name}`;
    const hasCase = existsSync(join(root, base, "case.yaml"));
    if (!hasCase && !existsSync(join(root, base, "prompt.md"))) {
      fail(`${base}: needs a case.yaml or a prompt.md`);
      continue;
    }
    if (hasCase) {
      const text = readFileSync(join(root, base, "case.yaml"), "utf8");
      if (!/^schema_version:/m.test(text)) fail(`${base}/case.yaml: no schema_version`);
      const named = text.match(/^name:\s*(\S+)/m);
      if (!named) fail(`${base}/case.yaml: no name`);
      else if (named[1] !== name)
        fail(`${base}/case.yaml: name "${named[1]}" != directory "${name}"`);
      // scaffold_script and history_file are paths relative to the case directory —
      // an inline block is read as a file name and fails at run time with ENAMETOOLONG
      for (const key of ["scaffold_script", "history_file"]) {
        const m = text.match(new RegExp(`^\\s+${key}:[ \\t]*(.*)$`, "m"));
        if (!m) continue;
        const value = m[1].trim().replace(/^["']|["']$/g, "");
        if (value === "" || value === "|" || value === ">" || value.startsWith("|") || value.startsWith(">"))
          fail(`${base}/case.yaml: ${key} must be a file in the case directory, not an inline block`);
        else if (!existsSync(join(root, base, value)))
          fail(`${base}/case.yaml: ${key} "${value}" does not exist in the case directory`);
      }
    }
    const gradersDir = join(root, base, "graders");
    if (!existsSync(gradersDir)) {
      fail(`${base}: no graders/ directory`);
      continue;
    }
    const graders = readdirSync(gradersDir).filter((f) => f.endsWith(".md"));
    if (!graders.length) fail(`${base}/graders: no .md graders`);
    for (const g of graders) {
      const path = `${base}/graders/${g}`;
      const fm = frontmatter(path);
      if (!fm) {
        fail(`${path}: no frontmatter block`);
        continue;
      }
      // a stray quote inside a single-quoted value silently truncates the pattern
      const block = readFileSync(join(root, path), "utf8").split(/^---$/m)[1] ?? "";
      for (const line of block.split("\n")) {
        const m = line.match(/^\w+:\s*'(.*)$/);
        if (!m) continue;
        const rest = m[1];
        if (!rest.endsWith("'") || rest.slice(0, -1).replace(/''/g, "").includes("'"))
          fail(`${path}: malformed single-quoted value: ${line.trim()}`);
      }
      if (!fm.type) fail(`${path}: frontmatter has no type`);
      else if (!GRADER_TYPES.has(fm.type))
        fail(`${path}: unknown grader type "${fm.type}" (${[...GRADER_TYPES].join(" | ")})`);
      if (fm.type === "llm" && !fm.criteria) fail(`${path}: an llm grader needs criteria`);
      if (fm.type === "regex" && !fm.pattern) fail(`${path}: a regex grader needs a pattern`);
      if (fm.type === "file_exists" && !fm.path) fail(`${path}: a file_exists grader needs a path`);
      if (fm.type === "tool_used" && !fm.tool) fail(`${path}: a tool_used grader needs a tool`);
    }
  }
}

// --- relative markdown links resolve; no orphaned references/ files ---
console.log("markdown links resolve, references/ files are used");
const mdFiles = ["README.md", "CONTRIBUTING.md"].filter((f) => existsSync(join(root, f)));
const walk = (dir) => {
  for (const name of readdirSync(join(root, dir))) {
    const rel = `${dir}/${name}`;
    if (statSync(join(root, rel)).isDirectory()) walk(rel);
    else if (name.endsWith(".md")) mdFiles.push(rel);
  }
};
walk("plugins");
if (existsSync(join(root, "docs"))) walk("docs");
for (const file of mdFiles) {
  const text = readFileSync(join(root, file), "utf8");
  for (const [, target] of text.matchAll(/\]\(([^)\s]+)\)/g)) {
    if (/^(https?:|mailto:|#)/.test(target)) continue;
    const path = resolve(join(root, dirname(file)), target.split("#")[0]);
    if (!existsSync(path)) fail(`${file}: broken link ${target}`);
  }
}
for (const plugin of plugins) {
  const skillsDir = join(root, "plugins", plugin, "skills");
  if (!existsSync(skillsDir)) continue;
  for (const skill of readdirSync(skillsDir)) {
    const refsDir = join(skillsDir, skill, "references");
    if (!existsSync(refsDir)) continue;
    const skillText = readFileSync(join(skillsDir, skill, "SKILL.md"), "utf8");
    for (const ref of readdirSync(refsDir)) {
      if (!skillText.includes(`references/${ref}`))
        fail(`plugins/${plugin}/skills/${skill}/references/${ref} is never mentioned in SKILL.md`);
    }
  }
}

if (failures) {
  console.error(`\n${failures} failure(s)`);
  process.exit(1);
}
console.log("\nall checks passed");
