# React Feature Kit

Two plugins for [Claude Code](https://claude.com/claude-code): a plan → build → review workflow for React features, and Feature-Sliced Design structure enforcement.

## Why

Building a feature in one long chat fails in predictable ways. The kit answers each:

| Problem | What the kit does |
|---|---|
| Quality drops as the context fills, and there is no spec to check the result against | Three commands in **separate short sessions** — plan, build, review — with `PLAN.md` and an API contract on disk as the handoff |
| Figma payloads, OpenAPI specs and bug reproductions eat the context window | Heavy reads go to subagents; only the finding returns to your session |
| Conventions get re-explained in every prompt | Self-loading skills (React 19, TanStack Query, shadcn/ui, forms) and FSD hooks that reject a misplaced file before it is written |

## Install

```bash
/plugin marketplace add vadimgaidai/react-feature-kit
/plugin install feature-workflow@vadimgaidai       # plan / build / review + React conventions + Figma agents
/plugin install feature-sliced-design@vadimgaidai  # FSD structure — only if the project uses FSD
```

`feature-workflow` is the one you need. `feature-sliced-design` is separate on purpose: its hooks actively reject files that don't fit FSD layers — enforcement you opt into per project.

## Which command do I run?

| You want… | Run |
|---|---|
| one block from a Figma frame as a component | `@feature-workflow:block-builder <node-url> → <path>` — no planning needed |
| a landing / marketing page from a Figma file | `@feature-workflow:theme-sync` once, then `/feature-workflow:analyze` |
| a feature with an API, forms or state | `/feature-workflow:analyze` → `/feature-workflow:implement` → `/feature-workflow:review`, each in a fresh session |
| the app theme to match a design | `@feature-workflow:theme-sync <figma-url>` |
| one bug fixed | `@feature-workflow:bug-fixer <describe the bug>` |
| an OpenAPI spec trimmed to the endpoints you use | `/feature-workflow:api-contract` |

Not sure which shape your request is? Run `/feature-workflow:analyze` — classifying the request is its first step. The convention skills and FSD hooks need no commands at all: they apply themselves while Claude writes code.

## The plugins

- **[feature-workflow](./plugins/feature-workflow)** — the three workflow commands, four self-loading React convention skills, and three subagents (`theme-sync`, `block-builder`, `bug-fixer`). Full walkthrough in its README.
- **[feature-sliced-design](./plugins/feature-sliced-design)** — a `structure` skill that answers layer and import-boundary questions, a deterministic scaffolder, and three hooks that reject a misplaced file, a non-kebab-case filename or a barrel import at write time. Needs `jq`.

## Setting it up for a repo

Put the marketplace in the repo's `.claude/settings.json` so everyone who clones it gets the same setup:

```json
{
  "extraKnownMarketplaces": {
    "vadimgaidai": { "source": { "source": "github", "repo": "vadimgaidai/react-feature-kit" } }
  },
  "enabledPlugins": {
    "feature-workflow@vadimgaidai": true,
    "feature-sliced-design@vadimgaidai": true
  }
}
```

This records what the project expects; each person still runs `/plugin install` once. [react-shadcn-ts-template](https://github.com/vadimgaidai/react-shadcn-ts-template) is a working example.

## Third-party skills

This repo contains only original work. Install other people's skills from their own repositories, so they stay attributed and keep updating from source:

```bash
npx skills@latest add shadcn/ui -s shadcn -y
```

## Development

```bash
claude --plugin-dir ./plugins/feature-workflow
/reload-plugins        # re-read the directories after an edit
```

**Bump the version or the change never ships.** `claude plugin update` compares `version` against the installed copy and copies nothing if it matches, ignoring commits entirely. Bump it in both `plugins/<name>/.claude-plugin/plugin.json` and the marketplace entry — `claude plugin tag` refuses a release where the two disagree.

`claude plugin validate plugins/<name>/skills` checks every skill's frontmatter (pointed at the plugin root it reads the manifest only). It won't catch a dead `references/*.md` link or a `name` that doesn't match its directory — `claude plugin eval` (cases under `evals/`) is the real check.

## License

MIT.
