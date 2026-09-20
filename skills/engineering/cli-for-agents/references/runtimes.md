# Runtimes and parsers

The shared constraints in `SKILL.md` are language-neutral. This file maps them onto common implementations. Pick the section that matches the code that will ship. Do not switch language to get a “better” parser unless the user asked.

If the user did not name a language, ask once. Do not default to Python.

## How to choose

| Situation | Prefer |
|---|---|
| Glue, wrappers, one-host ops, no extra runtime | POSIX `sh` or `bash` |
| Data transforms, JSON payloads, packaging on PyPI | Python |
| Single static binary, subcommand trees | Go (`cobra`) or Rust (`clap`) |
| Existing Node toolchain | Node (`commander` / `oclif`) |
| Already-chosen language in the repo | Stay on that language |

A shell script that execs a Python module is two CLIs. Apply this file to the binary the agent will actually invoke (the one on `PATH`).

## POSIX shell / bash

Parser of record: explicit `case` on `$1` plus a small flag loop, or `getopts` for short flags only. Do not pretend `getopts` covers long options.

Must handle in the script itself:

- TTY tests: `[ -t 0 ]` for stdin, `[ -t 1 ]` for stdout. Gate `read -p`, `less`, `tput`, and color on those checks.
- `set -euo pipefail` at the top of bash scripts. For strict POSIX `sh`, `set -eu` and be explicit about pipelines.
- Help is a function. `cmd -h`, `cmd --help`, and `cmd help` all call it, exit 0, write stdout.
- Unknown flag or unknown subcommand: message on stderr, point at `--help`, exit 2.
- JSON: either emit it with a quoted here-doc you control, or call `jq` only after checking it exists. Missing `jq` is a clear error, not a hang. Do not print banners before JSON.
- Color: test stdout TTY and `NO_COLOR` / `TERM=dumb` before any escape.
- Secrets: read from a file or stdin (`read -r TOKEN < "$token_file"`). Never `$1` for a token.
- Dry-run: a `DRY_RUN=0` flag that prints the would-be command on stderr and skips the mutation.
- Timeouts on network: `curl --max-time`, not bare `curl`.
- Subcommands: `case $1 in list|get|create|…)`. Each branch can `shift` and parse its own flags. Root help lists every branch.

Avoid:

- `read -p` as the only way to supply a value.
- Piping help into `less` / `more`.
- `echo` for data that may contain escapes; prefer `printf`.
- Depending on bash arrays if the shebang is `#!/bin/sh`.

Inventory for Mode B: grep `case`, `getopts`, and every `shift` loop. That is the command tree.

## Python

Parser of record: `argparse` or `click` / `typer`. Prefer one library for the whole tree.

`argparse` defaults that violate this skill:

- `allow_abbrev=True` — set `allow_abbrev=False`.
- No suggestion on bad choice — set `suggest_on_error=True` where the runtime has it (3.14+), otherwise write the hint yourself.
- Help on stderr in some paths — keep requested help on stdout, exit 0.

Also:

- Detect TTY with `sys.stdin.isatty()` / `sys.stdout.isatty()`, not with colorama defaults alone.
- JSON via `json.dump(..., sys.stdout)` and nothing else on stdout in `--output json`.
- Exit codes: `SystemExit(2)` for usage; other non-zero for runtime. Do not `sys.exit(0)` after a caught failure.
- Secrets: `argparse.FileType` or a path flag, not `type=str` for tokens.
- Schema: generate JSON from the same `ArgumentParser` / Click command object. Do not hand-write a second tree.

Click / Typer: disable prompts unless stdin is a TTY (`prompt` only behind an isatty guard, or require the option). `@click.confirmation_option` is `--yes` — pair severe commands with `--confirm=NAME` instead.

Inventory for Mode B: the parser’s `add_parser` / `@app.command` registrations, not `--help` text.

## Go

Parser of record: `spf13/cobra` (plus `viper` only for config files, not for flag grammar).

- Persistent flags vs local flags must show up in leaf help as inherited.
- `SilenceUsage: true` on runtime errors so usage is not dumped as if it were the error.
- Suggestions are on by default; keep them. Do not enable prefix matching that collapses `i` → `install`.
- JSON to `cmd.OutOrStdout()`, diagnostics to `cmd.ErrOrStderr()`.
- Schema: walk `root.Commands()` to emit the machine-readable tree.

## Rust

Parser of record: `clap` derive.

- `arg_required_else_help` at the root.
- `disable_help_subcommand(false)` so `help` works as a word.
- Color: `ColorChoice::Auto` and honor `NO_COLOR`.
- Errors: `ErrorKind::InvalidValue` / missing argument should exit 2, not 1, if you control the mapping.
- Schema: clap’s command graph is the model; serialize that, do not maintain a parallel JSON file.

## Node

Parser of record: `commander` or `oclif`.

- Disable implicit greedy matching that treats unknown words as arguments to a default command.
- `process.stdout.isTTY` / `process.stdin.isTTY` for prompts and color.
- JSON: `process.stdout.write(JSON.stringify(x) + "\n")`. Logs on `console.error`.
- oclif topics are groups; root help must list every topic and every top-level command.

## Any other runtime

Map the same twelve shared constraints onto whatever parser exists. If the language has no mature parser, write a 40-line dispatcher rather than a novel grammar. The help text and the schema still come from one command model.

## Design output extra

When Mode A names a runtime, the spec includes:

- shebang or binary entry
- parser library and the non-default settings this skill requires
- how TTY is detected
- how JSON is encoded without extra dependencies if the environment may lack them
