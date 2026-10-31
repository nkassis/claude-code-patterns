# {{PROJECT}}

{{One paragraph: what this app is, who uses it, and the one thing it must get right.}}

Read `docs/architecture.md` (if present) before touching `src/`. When a question is not answered here or there, stop and ask; do not decide silently.

Commands run from the repo root. Package manager is {{pnpm}}; do not use npm or yarn.

## Stack

- React {{19}}, TypeScript strict, Vite. No class components, no `any`, no `@ts-ignore` (use `@ts-expect-error` with a reason when unavoidable).
- Routing: TanStack Router (file-based routes under `src/routes/`). Server state: TanStack Query. Client state: React state and context first; a store ({{Zustand}}) only when state is shared by unrelated routes.
- Styling: Tailwind CSS. Design tokens live in the Tailwind theme (`{{tokens source}}`); never hard-code a colour, spacing or font value in a component.
- Forms: {{react-hook-form + zod}}. Every external input is validated with a schema at the boundary.
- Types from the backend are generated (`{{command}}`) into `src/api/generated/`; never hand-written, never edited.
- Tests: Vitest + React Testing Library for units; Playwright for the end-to-end flows listed in `docs/user-stories.md` (or `README.md` § Flows).
- Lint and format: ESLint (typescript-eslint strict, react-hooks, jsx-a11y) and Prettier.
- Logging: no `console.log` in shipped code.

## Setup

```sh
{{pnpm}} install --frozen-lockfile
{{pnpm}} exec playwright install chromium    # first time only
{{pnpm}} add -D -E knip@6.44.0               # once, at project start: the Analysis tools below
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

### Analysis

Run by hand or by a skill, never by a hook, pre-commit or CI: findings are leads to check, not failures. `scc` and `jscpd` need the machine tools in this repo's README.

| Command | What it does |
| --- | --- |
| `scc` | Count lines: code, comments and complexity per language; `--by-file --format json` for tooling |
| `{{pnpm}} exec knip` | Find dead code: unused files, exports and dependencies across the project (ESLint sees one file at a time) |
| `pnpm dlx jscpd@5.4.2 --ignore '**/pnpm-lock.yaml' .` | Find duplication: copy-pasted blocks across files (the lockfile is committed, so ignore it by name) |

## Guardrails (enforced, not optional)

| Rule | Claude hook | pre-commit | CI |
| --- | --- | --- | --- |
| Prettier formatting | applied on every edit | yes | `pnpm check` |
| ESLint clean, zero warnings | blocks on every edit | yes | `pnpm check` |
| Typecheck | before Claude stops | on push | `pnpm check` |
| No secrets committed or in `VITE_*` vars | — | trufflehog, detect-private-key | secret-scan |

If a hook blocks you, fix the reported problem; no `eslint-disable` without a comment saying why.

## Layout

```
src/
  routes/          # one file per route; loaders fetch, components render
  components/      # reusable, presentational, no data fetching
  features/<name>/ # route-specific components, hooks and queries, co-located
  api/             # client, generated types, query/mutation definitions
  hooks/           # shared hooks only; a hook used by one feature lives in that feature
  lib/             # pure functions, no React
  styles/          # tokens, global styles
test/              # Playwright specs and shared test utilities
```

A file holds one component. A component is under {{150}} lines; split by behaviour, not by JSX size. Name files after the export: `OrderPrompt.tsx`, `useRunStream.ts`, `formatShipTime.ts`.

## Rules

- Deviating from a global default (a library, tool or pattern)? In an interactive session, ask first; unattended, decide. Either way, add one line to `docs/decisions.md` (date, what, why) and flag it in the PR. Read that file before changing a choice it records.
- **Data flows down, events flow up.** Components receive data and callbacks as props; they do not reach into a store or a query from deep inside unless they are a route or feature root.
- **Server state lives in TanStack Query only.** No copying query results into `useState`. Mutations invalidate; they do not patch local copies.
- **Derive, don't sync.** If a value can be computed from props or state, compute it (useMemo if it is expensive). `useEffect` that sets state from other state is a bug.
- **Effects are for the outside world** (subscriptions, DOM, timers). Every effect has a cleanup. No effects for data fetching; that is a loader or a query.
- **Accessibility is not optional.** Semantic elements first; ARIA only to fill a real gap. Every interactive element is keyboard reachable with a visible focus state. Tests query by role and label, not by test id, except where no accessible name exists (and then add one).
- **Errors are shown, not swallowed.** Every route has an error boundary; every query has an error state the user can see; every mutation reports failure.
- **No premature abstraction.** Two similar components are fine. Extract on the third use, not the second.
- **Performance work needs a measurement.** No `memo`, `useCallback` or virtualisation without a profiler trace or a test that shows the problem.
- **No new dependency without saying why in the PR**, and never one that duplicates something already in `package.json`.

## Testing

- Unit tests sit next to the file (`OrderPrompt.test.tsx`) and test behaviour through the DOM, not implementation. Mock the network at the fetch/MSW boundary, never the hook.
- A bug fix comes with the test that would have caught it.
- Playwright specs are the user stories; each spec names the story it covers. They run against a built app with recorded or seeded data, never against production.
- Coverage is not a target. Untested code paths that matter are the target.
- Vitest uses jsdom and `@testing-library/jest-dom` matchers, set up in `test/setup.ts`.
- Network is mocked with MSW; handlers live in `test/msw/` and are shared by unit tests and Storybook (if present).
- Playwright config is `playwright.config.ts`; specs in `test/e2e/`. Specs seed their own data through `{{seed route or fixture}}`; they never depend on order.
- Run one unit file: `{{pnpm}} test src/features/x/Thing.test.tsx`. One e2e spec: `{{pnpm}} e2e test/e2e/flow.spec.ts`.

## Environment

`.env.example` is committed with placeholders; `.env.local` is ignored. Only variables prefixed `VITE_` reach the browser; never put a secret in one. Config is read once in `src/lib/env.ts` through a zod schema, so a missing variable fails at startup, not at first use.

## Generated types

`src/api/generated/` is produced by `{{pnpm}} gen:types` from `{{OpenAPI | JSON Schema | GraphQL}}` and is read-only. Change the source, regenerate, commit both. The CI drift check runs the generator and fails if the tree changes.

## Pre-commit

`pre-commit install --hook-type pre-commit --hook-type pre-push` once per clone, after `uv tool install pre-commit` once per machine. pre-commit is the hook manager for every stack. Prettier and ESLint run on staged files; `typecheck` runs on push. Do not bypass with `--no-verify`.

## Conventions

- Commit messages: imperative, one line, body only when the why is not obvious.
- One PR per feature or fix. The PR description says what changed, how it was verified, and what is left open.
- Run `{{pnpm}} check` (typecheck, lint, format, unit tests) before calling anything done; run `{{pnpm}} e2e` when a route or a flow changed.
- Generated files, lockfiles and snapshots are committed; build output is not.

## Working with coding agents

- Read the relevant route, feature and test before changing them; match the existing patterns.
- Do not restructure, rename or reformat files you were not asked to change.
- When a design decision is needed (new dependency, new state shape, new route structure), stop and ask; record the answer in `docs/decisions.md`.
- If a test fails after your change, fix the cause; do not delete or skip the test.

## Troubleshooting

- `Cannot find module` after pulling: `{{pnpm}} install`, then restart the TS server in the editor.
- Playwright `browserType.launch` errors: `{{pnpm}} exec playwright install chromium`.
- Stale generated types: `{{pnpm}} gen:types`.
- Port in use: `{{pnpm}} dev --port 5174`.
