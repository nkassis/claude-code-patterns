# {{PROJECT}}

{{One paragraph: what this site is, who reads it, and the one thing it must get right.}}

When a question is not answered here, stop and ask; do not decide silently. Commands run from the repo root. Package manager is pnpm; do not use npm or yarn.

## Stack

- Astro {{7}}, static output, TypeScript strict (`astro/tsconfigs/strict`).
- TypeScript stays on 6.0.x until `astro check` and typescript-eslint support 7: `astro check` refuses 7, and typescript-eslint needs below 6.1.
- Prettier with `prettier-plugin-astro`, ESLint with `eslint-plugin-astro`.
- Node version is pinned in `.nvmrc`; pnpm in `package.json#packageManager`.

## Setup

```sh
pnpm install --frozen-lockfile
pnpm add -D -E knip@6.44.0   # once, at project start: the Analysis tools below
pre-commit install --hook-type pre-commit --hook-type pre-push   # pre-commit itself: `uv tool install pre-commit`, once per machine
```

At project start the scaffold adds these, which the hooks and CI rely on:

```sh
pnpm add -D -E astro@7.4.8 @astrojs/check@0.9.12 typescript@6.0.3 prettier@3.9.10 prettier-plugin-astro@1.1.2 eslint@10.14.0 eslint-plugin-astro@3.2.1 typescript-eslint@8.72.1
```

- `.prettierrc`: `{ "plugins": ["prettier-plugin-astro"], "overrides": [{ "files": "*.astro", "options": { "parser": "astro" } }] }`
- `eslint.config.mjs`: ignores `dist/` and `.astro/`, then spreads `tseslint.configs.recommended` and `eslintPluginAstro.configs.recommended`.

A site in a subdirectory: the Claude hook finds it on its own; point the `.pre-commit-config.yaml` entries and the CI steps at that directory.

## Scripts

A project must define `check` and `build`. The Stop hook warns and skips if `check` is absent.

| Script | What it does |
| --- | --- |
| `pnpm check` | `astro check && tsc --noEmit`; what the Stop hook, pre-commit and CI run |
| `pnpm build` | `astro build`, to `dist/` |
| `pnpm dev` | Dev server |

### Analysis

Run by hand or by a skill, never by a hook, pre-commit or CI: findings are leads to check, not failures. `scc` and `jscpd` need the machine tools in this repo's README.

| Command | What it does |
| --- | --- |
| `scc` | Count lines: code, comments and complexity per language; `--by-file --format json` for tooling |
| `pnpm exec knip` | Find dead code: unused files, exports and dependencies across the project (ESLint sees one file at a time) |
| `pnpm dlx jscpd@5.4.2 --ignore '**/pnpm-lock.yaml' .` | Find duplication: copy-pasted blocks across files (the lockfile is committed, so ignore it by name) |

## Guardrails (enforced, not optional)

| Rule | Claude hook | pre-commit | CI |
| --- | --- | --- | --- |
| Prettier formatting | applied on every edit | — | — |
| ESLint clean, zero warnings | blocks on every edit | — | — |
| `astro check` and `tsc` clean | before Claude stops | `pnpm check` | `pnpm check` |
| The site builds | — | `pnpm build` on push | `pnpm build` |
| Internal links in `dist/` resolve | — | — | lychee, offline |
| No secrets committed | — | trufflehog, detect-private-key | secret-scan |

If a hook blocks you, fix the reported problem; no `eslint-disable` without a comment saying why.

## Done means

`pnpm check` and `pnpm build` pass.

## Rules

- Deviating from a global default (a library, tool or pattern)? In an interactive session, ask first; unattended, decide. Either way, add one line to `docs/decisions.md` (date, what, why) and flag it in the PR. Read that file before changing a choice it records.
- **Static output.** No adapter, no SSR, no API routes unless asked.
- **Zero client JavaScript by default.** React (or other framework) components render at build time with no `client:*` directive; adding an island needs asking first.
- **Content lives in content collections with a typed schema**; a schema error fails the build.
- **Images go through `astro:assets`.**
- **Every page gets a title, description and canonical from the layout; one `h1` per page.**
- Never hardcode secrets. Anything in a `PUBLIC_` variable ships to the browser.
