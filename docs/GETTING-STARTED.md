# Getting started

## Install

```bash
# from the repository root
claude plugin marketplace add vadimgaidai/react-feature-kit
claude plugin install react-feature-workflow@vadimgaidai --scope project
claude plugin install feature-sliced-design@vadimgaidai --scope project  # only if the project uses FSD
claude plugin install feature-folders@vadimgaidai --scope project       # otherwise — global buckets + feature/page/layout modules
```

From a running Claude Code session the equivalent is `/plugin`: it opens an interactive picker and asks for the scope — choose **"Install for all collaborators on this repository (project scope)"**.

## Why `--scope project`

`claude plugin install` defaults to `user` scope when `--scope` is omitted, which loads the plugin in **every** project you open. That matters most for `feature-sliced-design`: its hooks reject any write outside FSD layers, and `src/components/button.tsx` is a perfectly correct path in a non-FSD project. Keep the kit scoped to the repositories that expect its rules.

`marketplace add` takes no `--scope` flag — it is the project-scope *install* that records the marketplace in the repo's settings.

Scope reference: [Claude Code plugin docs](https://code.claude.com/docs/en/discover-plugins).

## What the install writes

The project-scope installs add this to the repo's `.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "vadimgaidai": { "source": { "source": "github", "repo": "vadimgaidai/react-feature-kit" } }
  },
  "enabledPlugins": {
    "react-feature-workflow@vadimgaidai": true,
    "feature-sliced-design@vadimgaidai": true
  }
}
```

Commit it. It records what the project expects but installs nothing by itself: teammates who clone the repo see the plugins as "not installed" and run the `claude plugin install` lines once — the marketplace and the enabled set they inherit for free.

[react-shadcn-ts-template](https://github.com/vadimgaidai/react-shadcn-ts-template) is a working example of a repo set up this way.

## Requirements

- **`feature-sliced-design` and `feature-folders` need `jq`.** Their hooks shell out to `jq`; without it they exit quietly instead of blocking a bad write, so the checks look live when they aren't. `brew install jq` / `apt install jq` before enabling either plugin.
- **Install one architecture plugin, not both.** `feature-sliced-design` enforces FSD's layers and import direction; `feature-folders` is for everything else and only blocks new files, never edits. They disagree on what `src/` should look like.
- The Figma agents (`theme-sync`, `block-builder`) need the Figma MCP server connected in the target project.

## First run

Not sure which command fits your request? Run `/react-feature-workflow:spec` — classifying the request (a block, a page, a feature, or a change to something that exists) is its first step, and a request it classifies as a single block gets sent to `block-builder` instead of a spec. A `block:` / `layout:` / `feature:` / `change:` prefix on the request sets the shape yourself instead. The command order is `spec` → `plan` → `implement` → `review`, each in a fresh session. The convention skills and FSD hooks need no commands at all: they apply themselves while Claude writes code.
