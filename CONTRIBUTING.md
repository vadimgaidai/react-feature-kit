# Contributing

## Dev loop

```bash
claude --plugin-dir ./plugins/react-feature-workflow
/reload-plugins        # after editing a skill or hook
```

## Checks

```bash
./scripts/check-all.sh
```

Manifests match the marketplace, every skill and agent has frontmatter, hook scripts exist and are executable, markdown links resolve, every `references/` file is mentioned by its skill, every `.sh` and `.mjs` parses, every eval fixture scaffolds. CI runs the same script.

Behaviour is checked by evals:

```bash
claude plugin eval plugins/react-feature-workflow --scaffold --allow-tools Bash Write Edit \
  --ablation none --case review-deslop
```

One `--case` per run. Cases and graders are described in [plugins/react-feature-workflow/evals/README.md](./plugins/react-feature-workflow/evals/README.md).

## Releasing

Bump the version or nothing ships. `claude plugin update` compares `version` with the installed copy and skips the update when they match. The version lives in `plugins/<name>/.claude-plugin/plugin.json` and in `.claude-plugin/marketplace.json`; `check-all.sh` fails when they differ.

## Layout

```
.claude-plugin/marketplace.json   plugins, versions, descriptions
plugins/<name>/
  .claude-plugin/plugin.json      name and version must match the marketplace entry
  skills/<skill>/SKILL.md         frontmatter name must match the directory
  skills/<skill>/references/      worked shapes; each file is linked from its SKILL.md
  agents/*.md                     frontmatter: name and description
  hooks/hooks.json                commands point into hooks/scripts/
  evals/<case>/                   case.yaml, scaffold.sh, graders/
docs/                             getting started, use cases, design
scripts/                          check-all.sh, validate.mjs, test-scripts.sh
```
