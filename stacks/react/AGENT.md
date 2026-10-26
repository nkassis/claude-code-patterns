# AGENT.md

Developer tooling. Commands run from the repo root. Package manager is {{pnpm}}; do not use npm or yarn.

## Setup

```sh
{{pnpm}} install --frozen-lockfile
{{pnpm}} exec playwright install chromium    # first time only
cp .env.example .env.local                   # then fill in the placeholders
```

Node version is pinned in `.nvmrc` / `package.json#engines`; use it.

## Scripts

| Script | What it does |
| --- | --- |
| `{{pnpm}} dev` | Vite dev server with HMR at http://localhost:{{5173}} |
| `{{pnpm}} build` | Typecheck then production build to `dist/` |
| `{{pnpm}} preview` | Serve `dist/` locally |
| `{{pnpm}} typecheck` | `tsc --noEmit` |
| `{{pnpm}} lint` | ESLint, zero warnings allowed |
| `{{pnpm}} format` | Prettier write; `format:check` in CI |
| `{{pnpm}} test` | Vitest, single run; `test:watch` for the loop |
| `{{pnpm}} e2e` | Playwright against a built app; `e2e:ui` to debug |
| `{{pnpm}} check` | typecheck + lint + format:check + test; what CI runs |
| `{{pnpm}} gen:types` | Regenerate `src/api/generated/` from `{{schema source}}`; CI fails on drift |

## Environment

`.env.example` is committed with placeholders; `.env.local` is ignored. Only variables prefixed `VITE_` reach the browser; never put a secret in one. Config is read once in `src/lib/env.ts` through a zod schema, so a missing variable fails at startup, not at first use.

## Testing

- Vitest uses jsdom and `@testing-library/jest-dom` matchers, set up in `test/setup.ts`.
- Network is mocked with MSW; handlers live in `test/msw/` and are shared by unit tests and Storybook (if present).
- Playwright config is `playwright.config.ts`; specs in `test/e2e/`. Specs seed their own data through `{{seed route or fixture}}`; they never depend on order.
- Run one unit file: `{{pnpm}} test src/features/x/Thing.test.tsx`. One e2e spec: `{{pnpm}} e2e test/e2e/flow.spec.ts`.

## Generated types

`src/api/generated/` is produced by `{{pnpm}} gen:types` from `{{OpenAPI | JSON Schema | GraphQL}}` and is read-only. Change the source, regenerate, commit both. The CI drift check runs the generator and fails if the tree changes.

## Pre-commit

`pre-commit install --hook-type pre-commit --hook-type pre-push` once per clone, after `uv tool install pre-commit` once per machine. pre-commit is the hook manager for every stack. Prettier and ESLint run on staged files; `typecheck` runs on push. Do not bypass with `--no-verify`.

## Claude Code hooks

`.claude/hooks/check-react.sh` runs from `.claude/settings.json`:
- **PostToolUse** (Edit/Write): Prettier formats the file, then ESLint lints JS/TS; findings block Claude until fixed.
- **Stop**: `{{pnpm}} typecheck` before Claude may finish.

Needs `pnpm` and an installed `node_modules`; otherwise it warns and skips.

## Troubleshooting

- `Cannot find module` after pulling: `{{pnpm}} install`, then restart the TS server in the editor.
- Playwright `browserType.launch` errors: `{{pnpm}} exec playwright install chromium`.
- Stale generated types: `{{pnpm}} gen:types`.
- Port in use: `{{pnpm}} dev --port 5174`.
