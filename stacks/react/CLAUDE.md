# {{PROJECT}}

{{One paragraph: what this app is, who uses it, and the one thing it must get right.}}

Read `docs/architecture.md` (if present) before touching `src/`. `AGENT.md` has the tooling commands. When a question is not answered here or there, stop and ask; do not decide silently.

## Stack

- React {{19}}, TypeScript strict, Vite. No class components, no `any`, no `@ts-ignore` (use `@ts-expect-error` with a reason when unavoidable).
- Routing: TanStack Router (file-based routes under `src/routes/`). Server state: TanStack Query. Client state: React state and context first; a store ({{Zustand}}) only when state is shared by unrelated routes.
- Styling: Tailwind CSS. Design tokens live in the Tailwind theme (`{{tokens source}}`); never hard-code a colour, spacing or font value in a component.
- Forms: {{react-hook-form + zod}}. Every external input is validated with a schema at the boundary.
- Types from the backend are generated (`{{command}}`) into `src/api/generated/`; never hand-written, never edited.
- Tests: Vitest + React Testing Library for units; Playwright for the end-to-end flows listed in `docs/user-stories.md` (or `README.md` § Flows).
- Lint and format: ESLint (typescript-eslint strict, react-hooks, jsx-a11y) and Prettier.
- Logging: no `console.log` in shipped code.

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
