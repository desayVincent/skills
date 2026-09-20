# Human CLI — index

Full text (offline): [vendor/clig/cli-guidelines.md](../vendor/clig/cli-guidelines.md)
License: CC BY-SA 4.0 in [vendor/clig/LICENSE](../vendor/clig/LICENSE)
Authors: Aanand Prasad, Ben Firshman, Carl Tashian, Eva Parish. Published at https://clig.dev/

Use this index on the TTY path. Open the vendor file when a rule below is not enough. Agent-only rules stay in `agent-cli.md` and `vendor/agent-cli-design`.

## Non-negotiables

- Mature argument parser.
- Exit `0` on success, non-zero on failure.
- Primary result on stdout. Errors, warnings, progress, prompts, logs on stderr.
- `-h` / `--help` always mean help. Never overload `-h`. `--version` prints version and exits.
- Prompt only when stdin is a TTY. Every prompted value also has a flag, arg, file, or stdin path.
- Non-interactive mode fails clearly. It does not hang.
- Dangerous work confirms, dry-runs, or requires `--force` / `--confirm=<name>` in proportion to severity.
- Do not accept secrets as flag values.

## Help

Help is the interface.

- `cmd --help`, `cmd -h`, and for groups `cmd help`, `cmd help sub`, `cmd sub --help`.
- If the help flag appears, show help and ignore other args.
- Lead with examples. Common flags before rare ones.
- Scan-friendly headings: `USAGE`, `EXAMPLES`, `OPTIONS`, `COMMANDS`.
- If the command expects a pipe and stdin is a TTY, say so and exit.

## Output

- Default output is human-readable, brief, and useful. Silence after a state change looks broken.
- `--quiet` reduces noise. `--verbose` / `--debug` hold diagnostics.
- `--json` for structured output. `--plain` when rich formatting breaks grep.
- Human output may evolve. Machine output is an API.

## Color, pager, animation

Disable color when the stream is not a TTY, when `NO_COLOR` is set and non-empty, or when `TERM=dumb`. Support `--no-color`. No spinners on non-TTY. Page large text only when interactive.

## Errors

Say what failed, why if known, and the fix. Group repeated failures. No stack trace as the primary expected-error text. Suggest a likely command on typos — do not auto-run a state-changing correction.

## Flags and args

- Full long flag for every option. Short flags only for common ones.
- Prefer flags when several distinct inputs exist. Famous two-position forms (`cp src dest`) are the exception.
- Support `-` as stdin/stdout filename where files are accepted.
- Stable aliases are fine. Arbitrary prefix abbreviation is not.

Common meanings to reuse: `--all`, `--debug`, `--force`, `--json`, `--help`, `--dry-run`, `--no-input`, `--output`, `--quiet`, `--version`.

Avoid a lone `-v` if version and verbose would collide.

## Subcommands

Use them when there are multiple workflows or object types. Prefer one shape (`noun verb` scales). Same flag names and error style across the tree. No catch-all default subcommand. Each leaf has its own help.

## Config and env

Precedence, highest first: flags → environment → project config → user config → system config.

Env vars are uppercase with underscores. Respect `NO_COLOR`, `FORCE_COLOR`, `DEBUG`, `EDITOR`, `PAGER`, proxy vars, `TERM`, `TMPDIR`, `HOME`. Do not treat env vars as a secret store.

Follow XDG where possible. Ask before mutating shared shell config.

## Signals and robustness

Ctrl-C acknowledges immediately, then cleans up with a timeout. Restore the terminal. Network calls have timeouts. Validate before expensive or destructive work. Prefer idempotent operations.

## Naming and distribution

Short, lowercase, memorable, hard to collide with. Single binary when feasible. Uninstall instructions next to install. Analytics opt-in, or absent.

## Future-proofing

Additive changes first. Deprecate before removal. Once users script a behavior, it is API. Do not invent catch-all syntax that blocks future flags.

## Human review checklist

- Parser, help, stdout/stderr, exit codes
- Non-interactive path, TTY-gated prompts, `--no-input`
- Confirm / dry-run / force on danger
- Secrets off argv
- `--json` or `--plain` where scripts need them
- Color / pager / progress respect TTY and env
- Config precedence documented
- Ctrl-C safe
- Install and uninstall clean
