# AGENT.md

Developer tooling. Commands run from the repo root.

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

## Claude Code hooks

`.claude/hooks/check-rust.sh` runs from `.claude/settings.json`:
- **PostToolUse** (Edit/Write on `.rs`): `cargo fmt` on the file; a parse error blocks Claude.
- **Stop**: `cargo clippy --all-targets -- -D warnings` before Claude may finish.
