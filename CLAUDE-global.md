# CLAUDE.md — Global conventions

Three kinds of guidance live here. Read the verb.

- **Rules** are checked by a hook, pre-commit or CI. Follow them; there is nothing to decide.
- **Defaults** are what I pick when nothing argues otherwise. Use them unless you have a reason that fits the exit condition written next to the default. When you deviate, record one line in the project's `docs/decisions.md` (what you chose, why) and mention it in your progress comment or PR. In an interactive session, ask before deviating. In an unattended run, decide, record, flag.
- **Taste** is how I like things when it costs nothing. Do it if it's free; never block or argue over it.

A project's own `CLAUDE.md` resolves the defaults into decisions at project start: it says "Logging: stdlib logging (CLI, see decisions.md)", not "Logging: structlog unless...". After that, this file is reference, not an instruction to re-litigate every session.

---

## Rules (enforced)

- Formatting is applied, not debated: Black, Prettier, rustfmt, clang-format, shfmt. Defer to the tool's output.
- Lint is clean with zero warnings: Ruff, ESLint, Clippy `-D warnings`, clang-tidy, shellcheck. No blanket disables; a targeted disable carries a comment saying why that case is safe.
- Type hints on every Python signature. No TypeScript `any`; `@ts-expect-error` with a reason when unavoidable. Explicit types elsewhere; flag inferred ones that could not be made explicit with `// inferred: ...`.
- Never hardcode secrets, API keys or credentials. `.env` holds local defaults, `.env.local` personal overrides; both, and every other `.env*` except `.env.example`, are gitignored. `.env.example` documents every variable with placeholder values. If a secret is staged, flag it; don't silently remove it.
- Never add a dependency without saying why, and never one that duplicates something already present. (Interactive: ask first. Unattended: record in `decisions.md` and flag.)
- Never modify database schemas or migrations, or restructure a build system, without explicit approval. Minor `CMakeLists.txt` edits are fine.
- Package management: UV for Python (never `pip install`), pnpm for JS, cargo for Rust. Tools that need a global install go through `uv tool install` or the platform package manager, never system pip.
- Conventional Commits (`feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `chore:`), one concern per commit, body when the why isn't obvious.
- PR descriptions give a summary of the plan (what changed and why, matching what was agreed before implementation), list which tests changed and why the behaviour changed, and say explicitly when no tests changed.

---

## Defaults (use unless you have a reason; write the reason down)

Each default names when to deviate. If your reason isn't one of those, ask. One exit applies to all of them: a project that already uses something else keeps it; don't migrate as a side effect of other work.

### Python
- **Web framework:** FastAPI. *Deviate:* a non-HTTP service.
- **Logging:** structlog, JSON-renderable. *Deviate:* a CLI or script that only prints to a terminal and whose logs are never shipped or queried; use stdlib `logging` there. Either way, no `print()` for diagnostics.
- **CLI:** Click. *Deviate:* a single-command script where `argparse` is enough and adds no dependency.
- **Config and structured data:** Pydantic + pydantic-settings. *Deviate:* throwaway scripts; never for anything that reads env or user input.
- **Testing:** pytest, pytest-asyncio for async routes, httpx for FastAPI clients. *Deviate:* no pytest-asyncio or httpx when there is no async code or no HTTP API.

### Frontend
- **Framework:** Vite + React + TypeScript strict. *Deviate:* a content site with no app state, where a static generator fits; say which and why.
- **Routing:** TanStack Router (file-based). *Deviate:* a single-view app with no routes.
- **Server state:** TanStack Query. *Deviate:* the API client is Apollo, which owns caching for GraphQL data.
- **Client state:** React state and context first; Zustand only when state is shared by unrelated routes. *Deviate:* the trigger is built in; move state to Zustand when unrelated routes share it, not before.
- **Styling:** Tailwind, tokens in the theme, no hard-coded values in components. *Deviate:* the project consumes a design-system package that brings its own styling.
- **API:** REST for simple CRUD. GraphQL (Apollo + graphql-codegen, types generated from the schema) when the frontend needs complex or nested data. *Deviate:* the backend already dictates one.
- **Logging:** pino for server-side code, if any; never `console.log` in shipped code. *Deviate:* the runtime (e.g. an edge platform) provides its own structured logger.
- **Testing:** Vitest + React Testing Library for units, Playwright for the flows the project names. *Deviate:* skip Playwright only when the project has no user flows to name (a component library uses Vitest alone).

### Rust
- **CLI:** clap (derive). **Errors:** anyhow in binaries, thiserror in libraries. **Serialization:** serde + serde_json. **Async:** tokio, only when there is I/O. **Logging:** tracing.
- *Deviate* on any of these when the crate is a library whose users would inherit the dependency; keep the public surface small and say so.

### C++ (games)
- **Standard:** latest the toolchain supports (C++23). **Build:** CMake + Ninja, `CMAKE_EXPORT_COMPILE_COMMANDS=ON`. **Tests:** Catch2. **ECS:** EnTT. **Windowing and graphics:** SDL3, Vulkan. **UI:** Dear ImGui. **Logging:** spdlog.
- *Deviate:* a target platform or console SDK that requires its own toolchain, graphics API or logging; say which platform forces it. Tools and prototypes outside the game itself may drop EnTT, ImGui or Vulkan when they don't need them.

### Shell
- Bash 5, `#!/usr/bin/env bash`, `set -euo pipefail`, 4-space indent. Scripts source `.env.local` if present; env already set wins. *Deviate:* a POSIX `sh` script that must run on a system without bash; say where.

---

## Taste (free to follow, never worth a fight)

- 4-space indentation everywhere except Go (tabs, per gofmt).
- Small, single-responsibility functions. Modules independently importable and testable; avoid tight coupling.
- Tests sit next to the code they test unless the project layout says otherwise. Coverage is a signal, not a target; prefer meaningful tests over a number.
- Two similar things are fine; extract on the third.
- Prefer targeted edits over rewrites unless a rewrite is clearly better.
- Name files after their main export.

---

## Working with me

- Before changing several files, state the plan. Decide during planning whether tests need to change, not after.
- Write unit tests for complex logic. Every API endpoint and public interface has tests. A bug fix comes with the test that would have caught it.
- When a test fails, diagnose first: application bug, or test outdated against current requirements. Say which before fixing.
- If something is ambiguous, ask rather than assume. If you are running unattended and can't ask, take the most reasonable reading, record it, and flag it at the top of your report.
- When you use a workaround or an inference instead of the ideal solution, say so.
- Deviations from a default go in `docs/decisions.md`, one line each: date, what, why. That file is the memory of the project's choices; read it before proposing a change that touches one of them.
