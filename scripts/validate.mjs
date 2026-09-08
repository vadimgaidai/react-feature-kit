#!/usr/bin/env node
// Structural checks for the marketplace and both plugins. Run via ./scripts/check-all.sh.
import { readFileSync, readdirSync, existsSync, statSync } from "node:fs";
import { join, dirname, resolve } from "node:path";

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
  for (const cmd of commands) {
    const rel = cmd.replaceAll('"', "").replace("${CLAUDE_PLUGIN_ROOT}", "");
    const script = join(root, "plugins", plugin, rel);
    if (!existsSync(script)) fail(`${hooksPath}: ${rel} does not exist`);
    else if (!(statSync(script).mode & 0o111)) fail(`plugins/${plugin}${rel} is not executable`);
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
