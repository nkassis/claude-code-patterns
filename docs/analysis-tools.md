# Analysis tools

The machine-wide tools behind each stack's Analysis section, for anyone setting up a machine to run them.

The tools are named in each stack's `AGENTS.md` under Analysis and never run by a hook or CI. Per-project ones are pinned by the stack's Setup; these go on the machine:

| Tool | For | Install |
| --- | --- | --- |
| `scc` v3.7.0 | line counts and complexity, every stack | `go install github.com/boyter/scc/v3@v3.7.0` |
| Node and `pnpm` | `jscpd` duplication, every stack, run as `pnpm dlx jscpd@5.4.2` | `corepack enable pnpm` |
| `cargo-machete` 0.9.2 | rust dead dependencies | `cargo install cargo-machete --version 0.9.2 --locked` |
| `cppcheck` 2.17+ | cpp unused functions | `sudo apt install cppcheck` or `brew install cppcheck` |
