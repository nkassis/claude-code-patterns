# {{PROJECT}}

{{One paragraph: what this utility does and who runs it.}}

`AGENT.md` has the tooling commands. When a question is not answered here, stop and ask; do not decide silently.

## Stack

- Rust, edition {{2024}}, toolchain pinned in `rust-toolchain.toml`.
- `clap` (derive) for the CLI, `anyhow` for errors in binaries, `serde` + `serde_json`, `tracing` for logs, `tokio` only when there is I/O.
- No `unwrap()`/`expect()` outside tests and `main` setup; propagate with `?` and context.

## Guardrails (enforced, not optional)

| Rule | Claude hook | pre-commit | CI |
| --- | --- | --- | --- |
| rustfmt | applied on every edit | `cargo fmt --check` | yes |
| Clippy, warnings denied | before Claude stops | yes | yes |
| Tests pass | — | on push | yes |
| No secrets committed | — | trufflehog, detect-private-key | secret-scan |

Fix Clippy findings; do not add `#[allow(...)]` without a comment saying why.

## Done means

`cargo fmt --all -- --check && cargo clippy --all-targets -- -D warnings && cargo test` passes.

## Rules

- Deviating from a global default (a library, tool or pattern)? In an interactive session, ask first; unattended, decide. Either way, add one line to `docs/decisions.md` (date, what, why) and flag it in the PR. Read that file before changing a choice it records.
- Explicit types on public items; flag inferred ones that couldn't be made explicit with `// inferred: …`.
- Unit tests in the same file (`#[cfg(test)] mod tests`); integration tests in `tests/`.
