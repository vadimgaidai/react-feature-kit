#!/usr/bin/env node
// Finds which structure plugin (if any) this project enables, and where its files
// live, by reading Claude Code's own registries rather than guessing a sibling
// directory — `${CLAUDE_PLUGIN_ROOT}` is only the running plugin's own root.
// Usage: node project-rules.mjs [changed-file ...]
import { existsSync, readFileSync, readdirSync, statSync } from "node:fs";
import { homedir } from "node:os";
import { join, resolve } from "node:path";

const HOME = process.env.RFW_HOME || homedir();
const CWD = process.cwd();
const changed = process.argv.slice(2);

const readJson = (path) => {
  try {
    return JSON.parse(readFileSync(path, "utf8"));
  } catch {
    return null;
  }
};

const frontmatter = (text) => {
  const m = text.match(/^---\n([\s\S]*?)\n---/);
  const fields = {};
  if (!m) return fields;
  for (const line of m[1].split("\n")) {
    const kv = line.match(/^(\w[\w-]*):\s*(.*)$/);
    if (kv) fields[kv[1]] = kv[2];
  }
  return fields;
};

const globMatch = (pattern, filePath) => {
  // "**/" also matches zero directories, so "src/api/**/*.ts" reaches
  // "src/api/article.ts" directly, not only a nested path.
  const escaped = pattern
    .replace(/[.+^${}()|[\]\\]/g, "\\$&")
    .replace(/\*\*\//g, "\u0000")
    .replace(/\*\*/g, "\u0001")
    .replace(/\*/g, "[^/]*")
    .replace(/\u0000/g, "(?:.*/)?")
    .replace(/\u0001/g, ".*");
  const re = new RegExp(`^${escaped}$`);
  return re.test(filePath) || re.test(resolve(filePath));
};

// --- 1. enabled plugins: project settings override/merge over user settings ---
const userSettings = readJson(join(HOME, ".claude", "settings.json")) ?? {};
const projectSettings = readJson(join(CWD, ".claude", "settings.json")) ?? {};
const enabled = {
  ...(userSettings.enabledPlugins ?? {}),
  ...(projectSettings.enabledPlugins ?? {}),
};
const enabledNames = Object.entries(enabled)
  .filter(([, on]) => on)
  .map(([name]) => name);

// --- 2. install path per enabled plugin ---
const installed = readJson(join(HOME, ".claude", "plugins", "installed_plugins.json"));
const installPathFor = (name) => {
  const entries = installed?.plugins?.[name] ?? [];
  const project = entries.find(
    (e) => e.scope === "project" && e.projectPath && resolve(e.projectPath) === CWD
  );
  if (project) return project.installPath;
  return entries.find((e) => e.scope === "user")?.installPath ?? null;
};

// --- 3. the enabled plugin that ships a structure skill ---
let structurePlugin = null;
for (const name of enabledNames) {
  const installPath = installPathFor(name);
  if (!installPath) continue;
  const skillPath = join(installPath, "skills", "structure", "SKILL.md");
  if (existsSync(skillPath)) {
    structurePlugin = { name, installPath, skillPath };
    break;
  }
}

console.log("Enabled plugins:", enabledNames.length ? enabledNames.join(", ") : "(none)");

if (structurePlugin) {
  console.log(`Structure plugin: ${structurePlugin.name}`);
  console.log(`  Reviewing section: ${structurePlugin.skillPath}#reviewing`);
  const scriptsDir = join(structurePlugin.installPath, "hooks", "scripts");
  const scripts = existsSync(scriptsDir) ? readdirSync(scriptsDir) : [];
  console.log(`  hooks/scripts: ${scripts.length ? scripts.join(", ") : "(none)"}`);
} else {
  console.log("Structure plugin: none enabled");
  const srcDir = join(CWD, "src");
  const top = existsSync(srcDir)
    ? new Set(readdirSync(srcDir).filter((f) => statSync(join(srcDir, f)).isDirectory()))
    : new Set();
  if (["entities", "widgets", "shared"].some((d) => top.has(d))) {
    console.log("  Warning: src/ is FSD-shaped, no plugin enabled — hooks did not run, review against the sibling only.");
  } else if (["features", "components", "lib", "config"].some((d) => top.has(d))) {
    console.log("  Warning: src/ is feature-folders-shaped, no plugin enabled — hooks did not run, review against the sibling only.");
  } else if (top.size) {
    console.log("  Warning: src/ does not match a recognized shape — review against the sibling only.");
  }
}

// --- 5. CLAUDE.md and .claude/rules/*.md whose paths: glob matches a changed file ---
console.log("Convention files:");
const claudeMd = join(CWD, "CLAUDE.md");
if (existsSync(claudeMd)) console.log(`  ${claudeMd}`);

const rulesDir = join(CWD, ".claude", "rules");
if (existsSync(rulesDir)) {
  for (const name of readdirSync(rulesDir).filter((f) => f.endsWith(".md"))) {
    const path = join(rulesDir, name);
    const fm = frontmatter(readFileSync(path, "utf8"));
    if (!fm.paths) {
      console.log(`  ${path} (no paths: scope — always applies)`);
      continue;
    }
    const patterns = fm.paths.split(",").map((p) => p.trim().replace(/^["']|["']$/g, ""));
    const applies = changed.length === 0 || changed.some((f) => patterns.some((p) => globMatch(p, f)));
    if (applies) console.log(`  ${path} (paths: ${fm.paths})`);
  }
}
