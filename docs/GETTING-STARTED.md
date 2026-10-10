# Getting started

## Install

```bash
claude plugin marketplace add vadimgaidai/react-feature-kit
claude plugin install react-feature-workflow@vadimgaidai --scope project
claude plugin install feature-sliced-design@vadimgaidai --scope project   # FSD projects only
claude plugin install feature-folders@vadimgaidai --scope project         # any other React project
```

Inside a session, `/plugin` opens a picker. Choose "Install for all collaborators on this repository (project scope)".

## Scope

Without `--scope project` the install defaults to `user` scope and the plugins load in every repository you open. For `feature-sliced-design` that means its hooks block `src/components/button.tsx` in a project that is not FSD. `marketplace add` has no scope flag; the project-scope install records the marketplace in the repository.

The install writes this to `.claude/settings.json`:

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

Commit it. Teammates then see the plugins as "not installed" and run the install lines once. [react-shadcn-ts-template](https://github.com/vadimgaidai/react-shadcn-ts-template) is a repository set up this way.

## Requirements

- `jq` for the structure plugins. Without it their hooks exit silently and block nothing.
- One structure plugin per project. They disagree on what `src/` should look like.
- The Figma MCP server for `theme-sync` and `block-builder`.

## First run

```
/react-feature-workflow:spec add comments to articles
```

Read `.planning/comments/SPEC.md`, fix it, then `plan`, `implement`, `verify`, `review`, each in a fresh session. A request that is one block goes straight to `block-builder`; `spec` says so and stops. Prefix the request with `block:`, `layout:`, `feature:` or `change:` to set the shape yourself.

The convention skills and the structure hooks need no command. They apply while Claude writes.
