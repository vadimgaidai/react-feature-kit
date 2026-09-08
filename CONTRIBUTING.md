# Contributing

## Dev loop

```bash
claude --plugin-dir ./plugins/react-feature-workflow
/reload-plugins        # re-read the directories after an edit
```

## Checks

```bash
./scripts/check-all.sh
```

Runs everything CI runs: manifest ↔ marketplace consistency, skill/agent frontmatter, hook scripts exist and are executable, relative markdown links resolve, no orphaned `references/` files, and every `.sh`/`.mjs` parses. CI (`.github/workflows/checks.yml`) calls the same script, so the two cannot drift.

`claude plugin validate plugins/<name>` covers the manifest only; `claude plugin eval` (cases under `evals/`) is the behavioral check.

## Releasing

**Bump the version or the change never ships.** `claude plugin update` compares `version` against the installed copy and copies nothing if it matches, ignoring commits entirely. Bump it in both `plugins/<name>/.claude-plugin/plugin.json` and the marketplace entry — `claude plugin tag` refuses a release where the two disagree, and `check-all.sh` fails on the mismatch too.

## Layout

```
.claude-plugin/marketplace.json   # the marketplace: both plugins, versions, descriptions
plugins/<name>/
  .claude-plugin/plugin.json      # plugin manifest (name/version must match the marketplace entry)
  skills/<skill>/SKILL.md         # frontmatter name must match the directory
  skills/<skill>/references/      # every file here must be mentioned in its SKILL.md
  agents/*.md                     # frontmatter needs name + description
  hooks/hooks.json                # commands point into hooks/scripts/, scripts stay executable
docs/                             # user-facing docs beyond the README
scripts/                          # check-all.sh + validate.mjs
```
