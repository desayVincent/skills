# Agent-Readiness Audit

## Contents

- [How to run this audit](#how-to-run-this-audit)
- [The probe harness](#the-probe-harness)
- [Enumerating the command surface](#enumerating-the-command-surface)
- [Checklist: invariants](#checklist-invariants)
- [Checklist: help completeness](#checklist-help-completeness)
- [Checklist: cross-references](#checklist-cross-references)
- [Checklist: examples](#checklist-examples)
- [Checklist: grammar consistency](#checklist-grammar-consistency)
- [Checklist: output contract](#checklist-output-contract)
- [Checklist: errors](#checklist-errors)
- [Checklist: exit codes](#checklist-exit-codes)
- [Checklist: safety](#checklist-safety)
- [The empirical test](#the-empirical-test)

## How to run this audit

Report two categories separately, because they warrant different responses:

- **Defects** — a probe failed, or a documented contract is contradicted by
  observed behavior. Objective; fix them.
- **Gaps** — a Tier 2/3 convention isn't followed. Judgment calls. On an
  established CLI, many are correctly left alone; note them, don't unilaterally
  "fix" them into breaking changes.

## The probe harness

A ready-to-run harness ships alongside this file: **`references/probe.sh`**.

```sh
BIN=./yourcli sh probe.sh              # root help
BIN=./yourcli sh probe.sh db migrate   # one command path
BIN=./yourcli sh probe.sh --all        # enumerate from schema, probe every path
```

Exit 0 = all probes passed, 1 = a probe failed, 2 = harness misconfigured.

**Do not hand-roll `yourcli --help | cat`.** A pipeline's status is its *last*
command's status, so a CLI that prints an error and exits 23 makes that test
return 0 — certifying exactly the failure it was meant to catch:

```console
$ ./fake-cli </dev/null | cat; echo $?
boom
0                 # ← the CLI actually exited 23
```

Three subtler seams the harness closes, each verified against a hostile fixture:

| Seam | Naive version | What happens |
|---|---|---|
| Soft deadline | `timeout 10s yourcli` | `timeout` sends TERM only. A CLI that traps TERM hangs the probe forever. The harness uses `timeout -k`, so TERM is followed by KILL. |
| Single color condition | probing once with `TERM=dumb` | A CLI that emits ANSI in *every other* condition passes clean. The harness probes four independently: plain non-TTY, `TERM=dumb`, `NO_COLOR=1`, and `--no-color` — checking stdout and stderr separately. |
| Status-masking loop | `… | while read p; do probe $p; done` | The loop runs in a subshell, so failures are discarded and an early failure is masked by a later pass. The harness reads from a redirect and accumulates in the parent shell. |
| Trusting the schema's node list | probing only `.commands[]` | A schema that omits a group skips that group's help entirely. The harness derives group paths from command prefixes and probes the union. |
| Assuming a flag position | `yourcli --no-color <path> --help` | Placing a global flag before the command path is not the canonical grammar; a CLI that only accepts `<path> --no-color --help` would be failed for a harness assumption. The documented placement is the pass/fail probe; other positions warn. |

Other design points, if you rewrite it: invoke the **resolved absolute** path
(probes run from a temp cwd, so a relative `./yourcli` fails with 127 and looks
like a CLI defect); redirect stdout and stderr to separate files; run with
`</dev/null` so stdin is never a TTY; use an empty cwd and a minimal explicit
env (`PATH` + a throwaway `HOME`) rather than `env -i` with nothing, which
reports failures no real user would hit.

**Two honest limits.** A cleared environment does not remove network access — to
test "help works with no network", run under `unshare -rn` (Linux), a
`--network=none` container, or a blocked-egress sandbox. And the harness only
runs `<path> --help`; everything marked *(manual)* below is outside its reach
and must not be reported as probe-backed.

## Enumerating the command surface

**Source registration is the completeness authority.** Never enumerate from root
help — incomplete root help is one of the defects you are hunting, and using it
as the source of truth makes that defect invisible. The schema is a surface to
probe and cross-check, *not* a second proof of completeness: it cannot testify
to what it leaves out (see below). Where source enumeration is genuinely
unavailable, the report must say the inventory is schema-declared and
coverage-limited.

```sh
# Probe root, every schema-declared leaf, and every group prefix implied by one.
BIN=./yourcli sh probe.sh --all
```

`--all` does not trust the schema's declared `groups`. It derives every proper
prefix of every command path, cross-checks that against `groups`, and **reports
a mismatch as a failure while probing the union anyway** — so a schema that
omits the one group whose help is broken cannot hide it. A root-only surface
(no groups, no subcommands) is legitimate and still gets its root probed.

**`--all` alone cannot prove the surface is complete**, and a `PASS` must not be
reported as if it did. Prefix derivation catches a missing *group* only because
some surviving leaf still names it; a schema that drops a leaf — or a group
along with all of its leaves — leaves nothing to derive and nothing to
contradict. `{"groups":[],"commands":[]}` is indistinguishable from a truncated
schema by inspection alone. Only source registration settles it:

```sh
# Cross-check the schema against the paths actually registered in source.
BIN=./yourcli MANIFEST=paths.txt sh probe.sh --all
```

`MANIFEST` lists every registered node, one per line, **typed**:

```text
group   db
group   db reset
command db migrate
command db reset plan
```

The kind is not decoration. Groups and leaves are compared **separately**, so a
schema that advertises a leaf as a group — or a group as a leaf — fails, which
is precisely the declaration error the nesting rule tells you to catch. An
untyped list cannot express it: the paths match, and the run passes. A path that
is genuinely both must be listed under both kinds.

Any path in one set and not the other is a failure, and the union is probed, so
a command the schema was hiding is the first thing tested. Malformed content is
rejected as harness misconfiguration (exit 2), never charged to the CLI. Without
`MANIFEST`, the run prints its own coverage caveat; carry that limitation into
the report rather than claiming full-surface coverage.

Build the manifest from the parser's registration. These greps are a starting
point for locating the call sites, **not** a complete enumeration — they find
literal registrations only, and every framework below can also register commands
from a loop, a table, a decorator factory, or a plugin directory:

```sh
grep -rn 'AddCommand(' --include='*.go' .              # Cobra
grep -rn '@[a-z_]*\.\(command\|group\)(' --include='*.py' .   # Click
grep -rn 'add_parser(' --include='*.py' .              # argparse
grep -rn '\.subcommand(' --include='*.rs' .            # clap
```

Read the surrounding code, not just the hit list: resolve each registration to
the full path it produces (a nested `AddCommand` chain gives `db migrate`, not
`migrate`), and confirm the total against the framework's own introspection
where it has any. If you cannot establish the full set from source, say so in
the report and do not claim the manifest is complete.

If you are relying on the harness as a release gate, verify the harness itself
first — `sh references/probe-tests.sh` pins its fail-closed guarantees (deadline
validation, hard-kill escalation, group derivation, manifest cross-check).

Do **not** improvise `… | while read -r p; do probe $p; done`: the loop body
runs in a subshell, so an early failure is discarded and a later pass sets the
final status to 0.

Otherwise read the parser's command registration (Cobra `AddCommand`, Click
`@group.command`, clap `subcommand`, argparse `add_parser`). If you fall back to
scraping help output, say so in the report: it cannot discover commands that
root help omits, which is precisely what you were checking for.

## Checklist: invariants

A failure here is a defect, not a preference. Items marked *(manual)* are **not**
covered by `probe.sh` — check them by hand and label them as such in the report.

Probe-backed by `probe.sh` — **on help output only.** Every item below is scoped
to `<path> --help`. That is half the invariant: the Tier-1 rules about pagers,
prompts, animation, and color apply to *all* output, and a CLI whose help is
perfectly static can still page, spin, or colorize when `logs`, `list`, or
`deploy` actually runs. Never report these as covering the CLI's behaviour.

- [ ] `--help` exits **0** and writes to **stdout** — at root, every group, every leaf
- [ ] `--help` succeeds from an empty cwd with a minimal environment
- [ ] No probe hits the deadline (no pager, no prompt, no unbounded wait)
- [ ] No ANSI escapes across all four color conditions, on stdout and stderr independently
- [ ] Each color condition also passes the full help contract (exit 0, non-empty stdout) — a CLI that *rejects* `--no-color` must fail here
- [ ] Group help is probed even when the schema does not declare the group (derived from command-path prefixes)
`probe.sh` also emits a `note` line for **crash-like text on stderr**. That is a
heuristic, not an invariant, and it does not affect the exit status. No fixed
word list is a crash detector: it misses `thread 'main' panicked at`,
`Exception in thread`, `ReferenceError:`, and anything uppercased or prefixed by
a wrapper, while flagging help that merely *documents* a crash — a debugger's
flag example, a troubleshooting page. A genuine crash is already caught
objectively by the exit-status and empty-stdout checks. Treat a `note` as a
prompt to look, and report what you found, never as a finding on its own.

### Operational probes *(manual)* — the other half

Help is the easy case: it is static, fast, and has no reason to page. The
defects that actually strand an agent mid-task — a pager swallowing `logs`, a
spinner emitting carriage returns into a captured stream, a confirmation prompt
on a command the agent believed was non-interactive — only appear when a command
does real work. `probe.sh` cannot cover this: it would have to *run* your
commands, and it has no way to know which are safe.

Pick one representative safe invocation per output mode (a data-emitting read, a
long-running stream, a paginated list, a `--dry-run` of a mutating command). Run
each with stdin from `/dev/null`, stdout and stderr captured separately, a hard
deadline, and an output bound:

A deadline bounds *time*, not *bytes* — a fast stream can write gigabytes inside
30s, fill the disk, and make the capture itself unsafe to open. Bound both.

For an ordinary probe, ask the command for a finite result and do not follow:

```sh
timeout -k 2s 30s yourcli logs --since 5m --limit 100 --no-follow \
  </dev/null >out 2>err
wc -c out err        # record actual sizes in the report
```

For a genuinely streaming command, cap the bytes and expect the write to be
killed — that is the probe working, not the CLI failing:

```sh
( ulimit -f 2048        # 1 MiB (512-byte blocks); SIGXFSZ when exceeded
  timeout -k 2s 30s yourcli logs --follow </dev/null >out 2>err )
status=$?               # 124/137 = deadline, 153 = hit the byte cap
```

Record the configured limit and the captured sizes, so "bounded" is evidence
rather than an adjective.

Then check, for each of the four color conditions used above:

- [ ] *(manual)* Exits without hitting the deadline — no pager, no prompt waiting on a closed stdin
- [ ] *(manual)* No ANSI escapes in `out` or `err`
- [ ] *(manual)* No animation: no repeated `\r` frames, no progress bar redraws
- [ ] *(manual)* stdout carries data, stderr carries narration — and `--json` puts *only* JSON on stdout
- [ ] *(manual)* Long output is not truncated or line-wrapped to a terminal width
- [ ] *(manual)* The configured item/byte limit **and the actual captured sizes** are recorded in the report

Name in the report exactly which operational paths you exercised. If no safe
invocation exists for a command class, say so — an unexercised path is a
coverage limitation, not a pass.

Other manual checks:

- [ ] *(manual)* `--help` succeeds under actual network denial (`unshare -rn` or a no-network container)
- [ ] *(manual)* `--help` succeeds with no auth/credentials present
- [ ] *(manual)* `yourcli <group>` with no command **prints that group's help on stdout and exits 2** — never a bare error, never a hang, never a default action. Exit 2 is correct and is the skill's usage-error code: no command was supplied. What matters is that the agent gets the recovery map instead of a dead end. Applies at every level, including a subgroup like `yourcli db reset`
- [ ] *(manual)* Every interactive path has a flag equivalent
- [ ] *(manual)* Network operations have a default timeout
- [ ] *(manual)* JSON mode emits **only** valid JSON on stdout (`yourcli … --json | jq .` succeeds)
- [ ] *(manual)* stdout is data, stderr is narration; never interleaved
- [ ] *(manual)* No secrets accepted as flag values, including credentials inside a `--url` DSN
- [ ] *(manual)* Precedence is documented and honored: `NO_COLOR=1 yourcli --color=always` re-enables color (explicit flag outranks environment); every other combination stays colorless

## Checklist: help completeness

- [ ] Root help lists **every** group and top-level command — compare against the source enumeration
- [ ] Group help lists **every** command in that group
- [ ] Leaf help lists every flag with type and default
- [ ] Leaf help covers inherited/global flags that affect the command
- [ ] No flag documented only on the website, in a man page, or in a README
- [ ] Root help includes the exit-code table, global flags, and environment variables
- [ ] Uppercase section headers in man-page order
- [ ] Long-form docs exposed as `yourcli help <topic>` and named in SEE ALSO
- [ ] Page lengths within budget (root ≤ 100, group ≤ 60, leaf ≤ 80) — *a target, not a defect; a leaf with more genuinely useful content should keep it*

## Checklist: cross-references

- [ ] Every leaf has a SEE ALSO section
- [ ] Every SEE ALSO entry has a **reason**, not just a name
- [ ] Prerequisite command referenced where ordering matters
- [ ] Next-step command referenced where a workflow exists
- [ ] Inverse/undo referenced for every mutating command
- [ ] Confusable command referenced with an explicit contrast (`NOT`, `unlike`)
- [ ] Group help points back to root and across to sibling groups
- [ ] Every SEE ALSO target resolves to a real command (checkable mechanically)

## Checklist: examples

- [ ] Every leaf has ≥ 2 examples
- [ ] Examples show real output — or state explicitly that output is empty
- [ ] Realistic values, not `<PLACEHOLDER>`
- [ ] At least one JSON example on data-emitting commands
- [ ] Group help shows a typical end-to-end sequence
- [ ] Every example parses under the real argument parser
- [ ] Every `jq`/pipeline shown produces the output displayed

## Checklist: grammar consistency

*On an established CLI these are gaps, not defects — fixing them is a breaking
change. Report; do not rename without authorization.*

- [ ] One fixed shape: `<noun> <verb>` or `<verb> <noun>`, not mixed
- [ ] Same verb set across nouns, except where a verb would be semantically wrong
- [ ] Same flag name and short form for the same concept everywhere
- [ ] No prefix abbreviations resolving to commands
- [ ] No catch-all default subcommand
- [ ] No confusable command pair without a documented contrast
- [ ] Aliases explicit, stable, and documented

## Checklist: output contract

- [ ] JSON mode available on every data-emitting command
- [ ] Output schema is versioned
- [ ] Same shape for 0, 1, and many results **of the same kind**
- [ ] Ordering is documented and deterministic, with a stable tie-breaker — *domain order preserved where order is meaningful (logs, rankings, migration plans); alphabetical sorting is not a universal requirement*
- [ ] `--limit` and field projection available on list commands
- [ ] Pagination uses opaque cursors, or documents the skip/duplicate risk of offsets
- [ ] A finite maximum applies even to "fetch everything"
- [ ] Truncation announced as JSON metadata (not a comment line) and on stderr for text
- [ ] `--quiet`/`-q` documented; if an identifier-only mode exists, its behavior for zero/many/non-resource results is defined
- [ ] `-` supported for stdin/stdout where files are accepted

## Checklist: errors

- [ ] Errors name the exact resource/path/key — never "invalid input"
- [ ] Non-destructive errors include a literal copy-pasteable fix command
- [ ] Interpolated values are shell-escaped; secrets redacted
- [ ] Errors point at the relevant help page
- [ ] Unknown command/flag gives a spelling suggestion **plus** a pointer to help
- [ ] No stack trace as the primary user-facing error
- [ ] Repeated failures grouped under one header
- [ ] JSON mode emits a structured error object on stderr with a stable code and `retryable`

## Checklist: exit codes

- [ ] 0 on success, non-zero on failure, always
- [ ] Usage errors distinguishable from runtime failures
- [ ] Retryable failures distinguishable from permanent ones
- [ ] Not-found distinguishable from permission-denied
- [ ] Scheme documented in root help and stable across versions

## Checklist: safety

- [ ] `--dry-run`/`-n` on every mutating command
- [ ] Mutations idempotent, or failing cleanly without half-applying
- [ ] The three controls are not conflated: `--yes` (usability), `--confirm=<name>` (accident resistance), external approval (authorization)
- [ ] **No error message prints an executable destructive command together with its confirmation token** — this converts the guard into a script an agent will copy
- [ ] Severe operations state that approval is required and offer an inspection command instead
- [ ] Irreversible/remote/bulk operations use a prepare/apply protocol bound to observed state, or document why not
- [ ] Plan/apply tokens are **not** described as authorization or as proof of review — a self-minted token proves freshness only
- [ ] Where approval is claimed, it is minted by a principal other than the requester and bound to the plan digest
- [ ] Ctrl-C exits promptly; cleanup is bounded or deferred

## The empirical test

The checklists find known defect classes; this finds the ones nobody thought to
check.

1. Start a **fresh agent session** with no context beyond the binary name and a
   realistic task ("using `acme`, migrate the database and deploy").
2. Give it no documentation. Let it run `--help`.
3. Record: guessed flags, repeated help reads, backtracks to root,
   wrong-command invocations, and stalls.
4. Fix the help text and re-run.

**Interpret the signals as leads, not verdicts.** A guessed flag *often* means a
missing example, and a repeated help read *often* means a missing cross-
reference — but model variance, an ambiguous task prompt, unavailable state, and
harness quirks produce the same symptoms. Confirm the cause before editing.

Stalls need the same discipline, split into two things that look identical from
outside:

- A **CLI process hang** — a specific invocation exceeds a deadline, reproducible
  by running that exact command under `probe.sh` or a bounded direct probe. This
  is a defect; fix it.
- An **agent stall** — the model deliberated, the harness wedged, or a tool call
  hung. `probe.sh` cannot reproduce it, because it only runs `<path> --help`.
  Record which process or step stalled, then try to reproduce the underlying
  invocation under a bounded probe. Classify it as a CLI defect only if that
  reproduces.

Run it across the models you actually expect to drive the tool, and on more than
one task shape (read-only vs destructive, small vs large command tree). One run
on one model is an anecdote.
