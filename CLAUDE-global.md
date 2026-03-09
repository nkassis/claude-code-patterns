# CLAUDE.md — Project Conventions & Preferences

## Languages & Stacks

### C++ (Games)
- **Standard:** Latest available (C++23 or newer if supported by the toolchain)
- **Build:** CMake + Ninja
- **Testing:** Catch2
- **ECS:** EnTT
- **Graphics/Windowing:** Vulkan, SDL3
- **In-game UI:** Dear ImGui
- **Logging:** spdlog (fast, header-only, suitable for real-time game loops)
- **Linting:** clang-tidy
- Design modules to be independently unit-testable with Catch2

### Python (Scripts & Backend)
- **Package manager:** UV (never pip install directly)
- **Web framework:** FastAPI
- **Formatter:** Black (defer to Black's output, don't hand-format)
- **Linting:** Ruff (replaces flake8/isort, run alongside Black)
- **Logging:** structlog (structured output, JSON-compatible)
- **Testing:** pytest (with pytest-asyncio for async routes, httpx for FastAPI test client)
- Type hints required on all function signatures
- Structure code so modules are independently importable and testable

### Frontend
- **Framework:** Next.js (App Router), React
- **Styling:** Tailwind CSS
- **Client state:** Zustand
- **Server/async state:** TanStack Query
- **GraphQL:** Apollo Client + graphql-codegen (auto-generate TypeScript types from schema)
- **Linting:** ESLint (Next.js recommended config)
- **Logging:** pino (server-side); never use `console.log` in production code
- **Testing:** Playwright (E2E), Vitest + React Testing Library (unit/component)
- Prefer server components by default; use client components only when necessary
- Use REST for simple CRUD APIs; prefer GraphQL when using frontend apps with complex/nested data needs

### Rust (Utilities)
- **CLI:** clap
- **Error handling:** anyhow (for binaries)
- **Serialization:** serde + serde_json
- **Async:** tokio (when I/O is involved)
- **Logging:** tracing
- **Linting:** Clippy (`cargo clippy` must pass before committing)

---

## Code Style

- **Indentation:** 4 spaces across all languages, **except Go** which uses tabs (per `gofmt` convention)
- **Types:** Always prefer explicit types. If type inference is used, add a comment flagging it — e.g. `// inferred: could not be made explicit`
- **TypeScript:** Never use `any`. If unavoidable, highlight it explicitly and explain why
- Keep functions small and single-responsibility to aid testability

---

## Testing Philosophy

- Write unit tests for all complex logic
- All API endpoints and public interfaces must have tests
- Design modules to be unit-testable in isolation (avoid tight coupling)
- Use best practices for the relevant test framework (Catch2 / pytest / Vitest)
- Coverage is a useful signal, not the primary goal — prefer meaningful tests over hitting a number
- Tests live alongside the code they test unless the project structure dictates otherwise

---

## Git Commits

- Use **Conventional Commits**: `feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `chore:`
- Commit at a logical granularity — one concern per commit
- Write descriptive commit bodies when the change is non-obvious

## Pull Requests

PR descriptions must include:
- **Summary of the plan** — what was changed and why, matching the plan agreed before implementation
- **Test changes** — explicitly list any tests that were modified to reflect new or changed behaviour, with a brief explanation of *why* the behaviour changed (not just what changed)
- If no tests were modified, state that explicitly so it's a conscious acknowledgement, not an oversight

---

## Secrets & Environment

- **Never hardcode secrets, API keys, or credentials** in source files
- Use `.env` for local defaults, `.env.local` for personal overrides (Next.js), `.env` for Python/other
- All `.env*` files (except `.env.example`) must be in `.gitignore` — always verify before committing
- Provide a `.env.example` with placeholder values to document required variables
- If a secret is accidentally staged, flag it immediately rather than silently removing it

---

## Hard Rules (Never Do Without Asking)

- **Dependencies:** Never install a new package or library without asking first
- **DB schema:** Never modify database schemas or migrations without explicit approval
- **CMakeLists:** Minor edits are fine; flag and seek review before any significant restructuring
- **TypeScript `any`:** Avoid entirely. If truly unavoidable, surface it and justify it

---

## Claude Behaviour Preferences

- Before making changes across multiple files, state the plan first
- **During planning:** Explicitly determine whether existing tests need to be updated or new tests written to reflect the new requirements — this must be decided before implementation begins, not after
- **When a test fails:** First evaluate whether the failure is an application bug or the test itself is incorrect/outdated given the current requirements — state the diagnosis clearly before fixing anything
- If something is ambiguous, ask rather than assume
- When inference or a workaround is used instead of an ideal solution, say so
- Prefer targeted edits over large rewrites unless a rewrite is clearly better
