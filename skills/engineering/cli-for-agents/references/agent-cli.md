# Agent CLI — index

Full text (offline): [vendor/agent-cli-design/agent-cli-design.md](../vendor/agent-cli-design/agent-cli-design.md)
Help templates: [vendor/agent-cli-design/references/help-anatomy.md](../vendor/agent-cli-design/references/help-anatomy.md)
Audit form: [vendor/agent-cli-design/references/audit-checklist.md](../vendor/agent-cli-design/references/audit-checklist.md)
Probe: [vendor/agent-cli-design/references/probe.sh](../vendor/agent-cli-design/references/probe.sh)

This index is a short operational list. Open the vendor skill when designing help, changing grammar, or auditing.

The agent loop is:

```
yourcli --help  →  yourcli <group> --help  →  yourcli <group> <cmd> --help  →  invoke
```

Target **one-hop sufficiency**: from the help page the agent landed on, it can invoke correctly or it knows the single next help page.

Nearly every rule below is scoped to **non-TTY**. Keep clig.dev human behavior when stdout/stdin is a terminal.

## Tier 1 — invariants

Each has a mechanical failure. Test in a non-TTY context.

1. `--help` exits 0 and writes stdout, at root, every group, every leaf.
2. `--help` needs no config, network, auth, or special cwd.
3. Never page when stdout is not a TTY.
4. Never prompt when stdin is not a TTY. Fail naming the flag that supplies the answer.
5. No interactive-only paths.
6. No animation on non-TTY stdout.
7. No ANSI on non-TTY, when `NO_COLOR` is set, when `TERM=dumb`, or when `--no-color` is passed. An explicit `--color=always` may override. Decide stdout and stderr independently.
8. Under JSON output, stdout is only valid JSON. No banner, timing line, or warning.
9. stdout is data, stderr is narration.
10. Every network operation has a default timeout.
11. 0 on success, non-zero on failure. Usage errors distinguishable from runtime failures.
12. No secrets in flag values — including URLs with embedded userinfo.

## Help completeness

| Level | Must contain |
|---|---|
| Root | Every group and top-level command, one line each; global flags; exit-code table; a getting-started example |
| Group | Every command in the group; group flags; a typical sequence |
| Leaf | Full synopsis including inherited flags; every flag with type and default; examples with real output; exit codes; SEE ALSO |

Help is complete **inline**. A docs URL is not a substitute. Long-tail topics go in `yourcli help <topic>` and are named from root SEE ALSO.

Suggested section order:

```
NAME / USAGE / DESCRIPTION / COMMANDS / ARGUMENTS / OPTIONS /
EXAMPLES / EXIT CODES / ENVIRONMENT / FILES / SEE ALSO
```

## SEE ALSO

Every cross-reference carries a reason. Fill four slots when they have an honest answer:

- Prerequisite — what runs before this
- Next step — what follows
- Inverse — how this is undone
- Confusable — what it will be mistaken for, stated in the negative

## Grammar

- One shape throughout. Deeper nesting only if help and schema declare it as a group.
- Same verb set across nouns (`list`, `get`, `create`, `delete`, `update`) unless a verb would be semantically wrong.
- Same concept → same flag name everywhere.
- No prefix abbreviations. Stable documented aliases are fine.
- No catch-all default subcommand.

Parser defaults that hurt agents: Python argparse `allow_abbrev=True`; missing `suggest_on_error`. Configure and test the real parser. Unknown command and unknown flag must suggest **and** point back to help.

## Output contract

- JSON mode on every data-emitting command. Stable keys. Version the schema.
- Same shape for 0, 1, and many results of the same kind. A list command does not flip between object and array by count.
- Documented deterministic order. Domain order is fine; define a tie-breaker.
- Bound output with `--limit` and field projection. Prefer opaque cursors. A finite maximum even for “all”.
- Announce truncation in-band (`truncated`, `next_cursor` in JSON; stderr note in text).
- Support `-` for stdin/stdout where files are accepted.
- Raw `--json` / stdin payload on mutating commands so agents do not flatten a nested schema into flags. Convenience flags may still exist for humans.

## Machine-readable discovery

Offer a standalone command:

```
yourcli schema --format=json
```

Do not rely on `--help --json`. Help conventionally short-circuits.

Generate schema from the same model as text help. Include groups and leaves, inherited flags, positional grammar, enums, required-together and mutually-exclusive constraints, aliases, deprecations, stdin behavior, mutation/danger attributes, output and error schema ids, and reason-bearing `see_also`.

## Exit codes

Print the table in root help and keep it stable. A starting map:

| Code | Meaning | Next action |
|---|---|---|
| 0 | Success | Continue |
| 1 | Unexpected failure | Report |
| 2 | Usage error | Re-read help, fix invocation |
| 3 | Not found | Verify the resource |
| 4 | Auth / permission | Fix credentials; do not retry |
| 5 | Conflict / precondition | Reconcile state |
| 6 | Transient | Retry with backoff |
| 7 | Timeout | Retry or raise timeout |

## Errors are instructions

Name the exact resource. For non-destructive fixes, include a copy-pasteable command. Shell-escape interpolations. Redact secrets. Do not print the executable form of a severe destructive command as the “fix”. Under JSON mode, emit a structured error on stderr with a stable code and `retryable`.

## Safety without prompts

| Control | What it actually provides |
|---|---|
| `--yes` / `-y` | Suppresses a prompt. No safety against an agent. |
| `--confirm=<exact-name>` | Proves the caller named the right target. |
| Plan / apply token | Proves the preview still matches current state. |
| External approval | Authorization. Only this confers permission. |

Severe operations (irreversible, remote, bulk) get `--dry-run` plus confirm-by-name or a prepare/apply token. Do not hand the agent the fully filled destructive command in the error text.

## Input hardening

Reject control characters, path traversal (`../`), percent-encoded traversal (`%2e`), and embedded `?` / `#` in resource ids. Sandbox output paths to CWD unless an explicit escape is documented. Assume adversarial input even when the caller is “just an agent”.

## Context discipline

Field masks on reads. Pagination that can stream (NDJSON). Guidance in the shipped skill file — always `--fields` on large list endpoints, never dump an unbounded collection into the window.

## Knowledge packaging

Ship `SKILL.md` or `CONTEXT.md` with the CLI. Encode the invariants agents will not infer: dry-run before mutate, field masks on large reads, schema command name, exit-code table, where secrets live.

Optional extra surfaces from the same binary: MCP over stdio, extension install, headless auth via env or a token file. Unscored; note them in audits.
