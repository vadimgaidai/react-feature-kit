// Review-only lint: rules too opinionated for CI but exactly right for reviewing a model's
// output. `review` runs this with `--config` over changed files, never adds it to the
// project's own config. Opinionated picks are fixed (max-params, magic numbers, comments via
// slop-scan.mjs); depth/complexity/size are tunable in this file only.
import { createRequire } from "node:module";
import { existsSync } from "node:fs";
import { join } from "node:path";

// ! resolve against the reviewed project's node_modules, not this file's own location —
// the config ships inside the plugin, far from any project that installs these packages.
const req = createRequire(join(process.cwd(), "package.json"));
const need = (name) => {
  try {
    return req(name);
  } catch {
    return null;
  }
};

const tseslint = need("typescript-eslint");
const reactHooks = need("eslint-plugin-react-hooks");
const react = need("eslint-plugin-react");
if (!tseslint) throw new Error("review.eslint.config.mjs needs typescript-eslint installed");

const hasTsconfig = existsSync(join(process.cwd(), "tsconfig.json"));

const base = {
  files: ["**/*.ts", "**/*.tsx"],
  plugins: {
    ...(reactHooks ? { "react-hooks": reactHooks } : {}),
    ...(react ? { react } : {}),
  },
  rules: {
    "no-nested-ternary": "error",
    "max-depth": ["error", 2],
    complexity: ["error", 10],
    "consistent-return": "error",
    "arrow-body-style": ["error", "as-needed"],
    "max-params": ["error", 2],
    "max-lines-per-function": ["error", { max: 60, skipBlankLines: true, skipComments: true }],
    "max-lines": ["error", { max: 300, skipBlankLines: true, skipComments: true }],
    "no-magic-numbers": [
      "error",
      { ignore: [0, 1, -1], ignoreArrayIndexes: true, enforceConst: true, ignoreEnums: true },
    ],
    "no-else-return": "error",
    "no-lonely-if": "error",
    "no-negated-condition": "error",
    "no-unneeded-ternary": "error",
    "no-extra-boolean-cast": "error",
    "@typescript-eslint/no-explicit-any": "error",
    "@typescript-eslint/no-non-null-assertion": "error",
    "@typescript-eslint/ban-ts-comment": ["error", { minimumDescriptionLength: 10 }],
    "@typescript-eslint/consistent-type-assertions": ["error", { assertionStyle: "never" }],
    "no-await-in-loop": "error",
    "require-await": "error",
    "no-unused-vars": "off",
    "@typescript-eslint/no-unused-vars": "error",
    "no-unreachable": "error",
    "no-useless-return": "error",
    ...(reactHooks ? { "react-hooks/exhaustive-deps": "error" } : {}),
    ...(react
      ? { "react/jsx-no-useless-fragment": "error", "react/no-array-index-key": "error" }
      : {}),
  },
};

const typed = hasTsconfig
  ? {
      files: ["**/*.ts", "**/*.tsx"],
      languageOptions: { parserOptions: { projectService: true, tsconfigRootDir: process.cwd() } },
      rules: {
        "@typescript-eslint/no-unnecessary-condition": "error",
        "@typescript-eslint/prefer-nullish-coalescing": "error",
        "@typescript-eslint/prefer-optional-chain": "error",
        "@typescript-eslint/switch-exhaustiveness-check": "error",
        "@typescript-eslint/no-floating-promises": "error",
        "@typescript-eslint/return-await": "error",
      },
    }
  : { files: ["**/*.never-matches"] };

export default tseslint.config(
  { ignores: ["**/*.test.*", "**/*.spec.*", "**/dist/**", "**/node_modules/**"] },
  ...tseslint.configs.recommended,
  base,
  typed
);
