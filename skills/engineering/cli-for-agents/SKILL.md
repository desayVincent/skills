---
name: cli-for-agents
description: >
  CLI：设计、改动或审计 Agent 可驱动的命令行。
  用于新 CLI、给现有 CLI 做加法、按源码打 agent-readiness 分；
  也用于把编译、打包、刷机、测试等可重复操作做成 CLI 而不是 skill。
license: SEE NOTICE
metadata:
  version: "1.4.0"
  sources: clig.dev, pnocera/agent-cli-design
  offline: self-contained
---

# CLI for Agents

Offline entry. Indexes in `references/`; full texts in `vendor/`. Do not fetch, clone, or `npx`. Do not edit `vendor/`.

Human DX is discoverability on a TTY. Agent DX is predictability on non-TTY. The agent is not a trusted operator.

## CLI vs skill

A repeatable operation with flags, artifacts, and exit codes is a **CLI**. Put the procedure in the binary. Then pick a mode below.

Judgment, review, and one-off writing stay a skill (`writing-for-agents`).

Done when the deliverable is named: new CLI, additive change to a named binary, or audit of a named binary.

## Three-source stack

| Priority | Job | Full local copy | Index |
|---|---|---|---|
| 1 | Human and TTY surface | [vendor/clig/cli-guidelines.md](vendor/clig/cli-guidelines.md) | [references/human-cli.md](references/human-cli.md) |
| 2 | Agent help-as-API, audit, probe | [vendor/agent-cli-design/agent-cli-design.md](vendor/agent-cli-design/agent-cli-design.md) | [references/agent-cli.md](references/agent-cli.md) |
| 3 | Score 0–21 | — | [references/scorecard.md](references/scorecard.md) |
| — | Parser and runtime (shell, Python, …) | — | [references/runtimes.md](references/runtimes.md) |

Provenance: [NOTICE](NOTICE) and [vendor/NOTICE.md](vendor/NOTICE.md). Inventory: [references/sources.md](references/sources.md).

Load the index first. Open the matching `vendor/` file when the index does not settle the question, when writing help pages, or when scoring. If an index line and the vendor text disagree, the vendor text wins for that source's job. Record the disagreement.

## Pick a mode

Do not read every reference. Identify the mode, then follow only that path.

| Mode | The user is… | First load |
|---|---|---|
| **A. Design** | creating a CLI or a new command group | this file → `runtimes.md` → `human-cli.md` → `vendor/agent-cli-design/agent-cli-design.md` (Mode A) |
| **B. Change** | modifying an existing CLI | this file → inventory (include runtime) → vendor Mode B |
| **C. Audit / Score** | reviewing agent-readiness | this file (trust gate) → `scorecard.md` → vendor Mode C; `probe.sh` only for a trusted binary or inside a sandbox |

Completion criterion for this step: one mode named, and the files for that mode opened.

## Shared constraints (every mode)

Apply these before writing or judging a command. Details and failure modes are in `references/agent-cli.md`.

1. Lock the runtime, then pick its parser from [references/runtimes.md](references/runtimes.md). The surface rules in this file do not change with language. Test unknown command, unknown flag, and prefix abbreviation against the real parser. Turn suggestions on. Turn implicit abbreviation off.
2. One grammar everywhere — `<noun> <verb>` or `<verb> <noun>` — same verb set on every noun.
3. `0` on success, non-zero on failure. Usage errors distinguishable from runtime failures.
4. stdout is data. stderr is narration. JSON mode stdout is only valid JSON.
5. `-h` / `--help` always help, exit 0, write stdout, need no config, network, auth, or special cwd.
6. Non-TTY never pages, never prompts, never animates, never emits ANSI unless an explicit color flag asked for it. Honor `NO_COLOR` and `TERM=dumb`.
7. Every prompt-reachable path is also flag-reachable. `--no-input` fails naming the missing flag.
8. No secrets in flags. Prefer `--token-file`, stdin, or a credential store.
9. Mutating commands have `--dry-run`. Severe operations use `--confirm=<exact-name>`, not `--yes` as a safety story.
10. Data commands offer `--output json` (or JSON-by-default on non-TTY), `--limit` / field projection, and bounded pagination.
11. Prefer a standalone `schema --format=json` over `--help --json`.
12. Help is the API. From any help page the agent can invoke correctly or know the single next help page (SEE ALSO with a reason).

Human-side checklist (TTY, naming, config precedence, signals) is in `references/human-cli.md`. Do not skip it when humans are also an audience.

## Mode A — Design

1. Lock runtime (POSIX shell, Python, Go, Rust, Node, other), parser, and audience (humans, agents, or both). Both is the default. If the user did not name a language, ask once — do not default to Python. Apply the matching section of `references/runtimes.md`.
2. Write the **root help page before any command**. That page is the spec. Use `vendor/agent-cli-design/references/help-anatomy.md` for page templates.
3. Implement text help and the machine-readable schema from **one command model**.
4. Convenience flags for humans may exist. Agents also get a raw `--json` / stdin payload that maps to the real schema with no translation loss.
5. Ship a `SKILL.md` or `CONTEXT.md` next to the binary. It states invariants agents must not guess — always `--dry-run` on mutate, always `--fields` on large reads, never secrets on the argv. It does not re-encode the command procedure.
6. Verify non-TTY help, JSON, dry-run, and a usage-error exit code before calling the design done.

Done when every shared constraint has a concrete command or flag that satisfies it, and root help enumerates the entire surface.

## Mode B — Change

1. Inventory from **parser registration**, not from help text. Name the runtime and use the inventory hint in `references/runtimes.md` (`case`/`getopts` for shell, `add_parser` / `@command` for Python, and so on).
2. Do not rename commands or flags to satisfy this skill. Inconsistencies in a mature CLI are load-bearing. Default to additive fixes — JSON output, schema command, dry-run, better errors, complete help, `--no-input`.
3. Fix the shared constraints that can land without a breaking change first.
4. Report compatibility effects of anything that did change.

Done when the inventory lists every command touched and every skipped breaking fix, with a reason.

## Mode C — Audit / Score

1. Enumerate the surface from source registration.
2. Classify the binary before any probe:
   - **Trusted** — first-party, in-tree, or the user named it as a binary they own.
   - **Untrusted** — downloaded, unknown origin, or not confirmed by the user.
3. Score the seven axes from [references/scorecard.md](references/scorecard.md). Cite evidence per axis — a command, a flag, or an observed failure. Do not award a 2 or 3 without a named command.
4. Separately list Tier-1 invariant failures from `vendor/agent-cli-design/agent-cli-design.md`. Use `vendor/agent-cli-design/references/audit-checklist.md` as the audit form. Do not improvise help probes.
   - **Trusted** executable: run `vendor/agent-cli-design/references/probe.sh`.
   - **Untrusted**: do not run `probe.sh` in the current user environment. Re-run only inside a disposable sandbox with no network and no write access to the caller's files. If that sandbox is unavailable, score from source registration and already-captured help text, and record `probe skipped: untrusted binary`.
5. End with total (0–21), rating, the cheapest additive fixes that raise the score, and any multi-surface notes (MCP, headless auth) as unscored extras.

Done when every axis has a score, evidence, and a next fix or an explicit “already maxed”. If the probe was skipped, the report says so.

`probe-tests.sh` is a harness self-check. It is not a skill release gate.

## Output the agent produces

Match the mode.

- **Design** — command tree, USAGE, flags table, output contract, exit-code map, safety flags, config precedence, and the help/schema plan.
- **Change** — inventory, additive patch list, breaking changes refused.
- **Audit** — scorecard table, invariant defects, recommended order of operations.

Cite the local `vendor/` paths that were actually opened. Do not claim a network copy was used.
