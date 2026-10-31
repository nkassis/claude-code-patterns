# {{PROJECT}}

{{One paragraph: what this utility does and who runs it.}}

When a question is not answered here, stop and ask; do not decide silently. Commands run from the repo root.

## Stack

- Rust, edition {{2024}}, toolchain pinned in `rust-toolchain.toml`.
- `clap` (derive) for the CLI, `anyhow` for errors in binaries, `serde` + `serde_json`, `tracing` for logs, `tokio` only when there is I/O.
- No `unwrap()`/`expect()` outside tests and `main` setup; propagate with `?` and context.

## Setup

```sh
rustup show                       # installs the toolchain from rust-toolchain.toml
rustup component add rustfmt clippy
pre-commit install --hook-type pre-commit --hook-type pre-push   # pre-commit itself: `uv tool install pre-commit`, once per machine
```

## Commands

| Command | What it does |
| --- | --- |
| `cargo fmt --all` | Format (`-- --check` in CI) |
| `cargo clippy --all-targets -- -D warnings` | Lint |
| `cargo test` | Tests |
| `cargo run -- <args>` | Run the CLI |

### Analysis

Run by hand or by a skill, never by a hook, pre-commit or CI: findings are leads to check, not failures. Each tool is a machine tool in this repo's README.

| Command | What it does |
| --- | --- |
| `scc` | Count lines: code, comments and complexity per language; `--by-file --format json` for tooling |
| `cargo machete` | Find dead code: unused crates in `Cargo.toml` (Clippy with `-D warnings` already rejects dead private code) |
| `pnpm dlx jscpd@5.4.2 .` | Find duplication: copy-pasted blocks across files |

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
