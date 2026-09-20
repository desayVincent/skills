---
name: agent-cli-design
description: Design, build, or audit a command-line tool that AI agents can drive correctly from its own help output — complete inline help at every level, cross-referenced "SEE ALSO" navigation, machine-readable output, agent-recoverable errors, and safe non-interactive behavior. Use when creating a new CLI, adding subcommands, writing or reviewing help text, designing JSON output or exit codes, or making an existing CLI usable by LLM agents.
license: MIT
metadata:
  author: pnocera
  version: '1.0.0'
---

# Designing CLIs for AI Agents

Adapts the Command Line Interface Guidelines (clig.dev) for a consumer those
guidelines did not target: an LLM agent that has never seen your tool, cannot
open your website, and decides how to invoke you based on whatever
`yourcli --help` prints.

## Start here: pick a mode

Do not read this file front to back and apply everything. Identify the mode,
follow its workflow, and load references on demand.

| Mode | You are… | Go to |
|---|---|---|
| **A. Design** | creating a new CLI, or adding a command group | **Mode A** |
| **B. Change** | modifying an existing CLI | **Mode B** |
| **C. Audit** | reviewing a CLI's agent-readiness | **Mode C** |

### Mode A — designing a new CLI

1. Confirm constraints: language, argument-parsing library, whether humans are
   also a primary audience (usually yes — see **Two audiences**).
2. Pick the argument parser first (Cobra, Click, clap, oclif, argparse). It
   gives you `-h/--help` and per-subcommand help for free — but **only the help
   machinery is free.** Error recovery and grammar behaviour (did-you-mean
   suggestions, prefix abbreviation, where global flags may appear) are
   framework- and version-dependent, and several defaults are wrong for agents.
   Configure and then *test* them: turn suggestions on, turn implicit
   abbreviation off, and run an unknown command, an unknown flag, and an
   ambiguous prefix against the real parser. Python's `argparse`, for one,
   defaults to `suggest_on_error=False` (3.14 emits a bare "invalid choice")
   and `allow_abbrev=True`, which contradicts **Predictable grammar** below —
   set `suggest_on_error=True` where your Python provides it, and
   `allow_abbrev=False`. `probe.sh` does not catch any of this; it only
   exercises help.
3. Fix the grammar before the first command: `<noun> <verb>` or `<verb> <noun>`,
   one verb set, applied everywhere. See **Predictable grammar**.
4. Write the **root help page before writing any command** — it is the spec.
   Load `references/help-anatomy.md` for templates.
5. Implement text help and the machine-readable schema **from one command
   model**, so they cannot drift.
6. Apply the **Invariants** — these are the ones with real
   failure mechanisms.
7. Verify with `references/probe.sh`.

### Mode B — changing an existing CLI

1. **Inventory first.** Read the parser's command registration to enumerate the
   real command tree, flags, and defaults. Do not infer the surface from help
   text you are about to judge.
2. **Do not break established grammar to satisfy this skill.** A mature CLI's
   inconsistencies are load-bearing: scripts, muscle memory, and docs depend on
   them. Renaming commands or flags for consistency is a breaking change that
   needs explicit user authorization. Default to additive fixes — new flags, new
   help sections, better errors — which capture most of the benefit at none of
   the cost.
3. Fix **Invariants** first; they are usually non-breaking.
4. Apply **defaults** only where they don't collide with an
   established convention.
5. Report compatibility effects of anything you changed.

### Mode C — auditing a CLI

1. Enumerate the surface from **source registration** — the parser's own
   `AddCommand`/`add_parser`/`subcommand` calls, or framework introspection
   derived from them. Not from root help, since incomplete root help is one of
   the defects you are looking for; and not from the schema *as proof of
   completeness*, since a schema cannot testify to what it omits. Probe and
   cross-check the schema, but let source decide what the full surface is. If
   source enumeration is unavailable, call the inventory schema-declared and
   coverage-limited in the report — mirroring the caveat `probe.sh` prints.
2. Run `references/probe.sh` (documented in `references/audit-checklist.md`).
   Use it rather than improvising: `yourcli --help | cat` silently passes a CLI
   that exits non-zero, a plain `timeout` cannot contain a TERM-ignoring hang,
   and probing color only under `TERM=dumb` misses the other three conditions.
3. Record evidence per finding, and separate **interoperability/safety defects**
   (verifiable failures) from **heuristic gaps** (judgment calls).

---

## The behavior everything follows from

An agent meeting an unknown CLI runs this loop:

```
yourcli --help  →  yourcli <group> --help  →  yourcli <group> <cmd> --help  →  invoke
```

It has a limited patience budget before it stops reading and starts guessing
flags. Guessed flags produce failed runs, failed runs produce retries, retries
burn context, and a burnt agent abandons your tool for `curl` and `sed`.

The design target is **one-hop sufficiency**:

> From any help page the agent lands on, it can either invoke the command
> correctly, or know exactly which *single* next help page to read.

A CLI is a documentation artifact that happens to execute. The help text is the
API; the binary is its implementation.

### Two audiences

Agents are a *new* audience, not a replacement. Nearly every rule here is
scoped to **non-TTY** behavior, where the agent lives. When stdout/stdin *is* a
terminal, keep the human-first behavior clig.dev prescribes — progress bars,
color, prompts, terse output. The conflicts dissolve once you branch on TTY.

### How to weigh these rules

The rules are tiered by how much evidence stands behind them. Respect the tier;
do not enforce a Tier 3 heuristic as if it were a Tier 1 invariant.

- **Tier 1 — Invariants.** Concrete failure mechanisms, reproducible on demand.
  Violating one breaks agents. Fix unconditionally.
- **Tier 2 — Defaults.** Well-founded conventions. Follow unless a project
  constraint or established convention justifies deviating; say why when you do.
- **Tier 3 — Heuristics.** Plausible claims about agent behavior that this skill
  does *not* back with measurements. Useful as design targets and as things to
  test on your actual models. Never a reason to break a working CLI.

---

## Tier 1: Invariants

Each has a mechanical failure mode. Test each in a **non-TTY** context — that is
how an agent runs you.

1. **`--help` exits 0 and writes to stdout.** At root, every group, every leaf.
   Non-zero reads as "tool is broken"; stderr gets dropped by pipelines that
   capture only stdout. (Matches the GNU convention for requested help.)
2. **`--help` needs no config, no network, no auth, no particular cwd.** Agents
   run it in a bare environment. Help that fails without `~/.acme/config.yaml`
   makes discovery impossible.
3. **Never page when stdout is not a TTY.** A pager waiting on `q` is a hung
   agent — the most expensive failure mode there is.
4. **Never prompt when stdin is not a TTY.** Fail immediately, naming the flag
   that supplies the answer: `error: --name required (stdin is not a terminal)`.
5. **No interactive-only paths.** Anything reachable by answering a prompt must
   be reachable by a flag.
6. **No animation on non-TTY stdout.** Spinners write thousands of
   `\r`-separated frames straight into the context window.
7. **No ANSI escapes on non-TTY output**, when `NO_COLOR` is set to a non-empty
   value, when `TERM=dumb`, or when `--no-color` is passed. Decide for stdout
   and stderr independently. **Precedence:** an explicit flag outranks the
   environment, so `--color=always` may re-enable color even under `NO_COLOR`
   — that is the one exception, and it must be a deliberate request, never a
   default. Everything else disables.
8. **Under a JSON output mode, stdout is only valid JSON.** No banner, no timing
   line, no warning. One stray line breaks every parse.
9. **stdout is data, stderr is narration.** Never interleave.
10. **Every network operation has a default timeout.** Unbounded waits hang the
    agent exactly like a prompt does.
11. **0 on success, non-zero on failure**, always, and usage errors must be
    distinguishable from runtime failures.
12. **No secrets in flag values.** They leak into `ps`, shell history, and — with
    an agent — into transcripts and logs the user may later share. Provide
    `--token-file`, stdin, or a credential store. This includes connection
    strings with embedded credentials: prefer `--url-file` or a config
    reference, or reject userinfo in the URL.

## Tier 2: Defaults

### Help completeness

Three kinds of page, each with a job:

| Level | Job | Must contain |
|---|---|---|
| **Root** | Complete map | *Every* group and top-level command, one line each; global flags; exit-code table; a getting-started example |
| **Group** | Complete map of the group | Every command in it; group-scoped flags; a typical end-to-end sequence |
| **Leaf** | Everything needed to run it | Full synopsis (including inherited flags that affect it), every flag with type and default, examples with real output, exit codes, SEE ALSO |

Root must enumerate the **entire** command surface. An agent that sees five of
your twelve commands will conclude the other seven don't exist.

Help must be complete **inline**. "See https://docs.example.com for the full
flag list" is a dead end: assume no network and no browser.

Long-tail material (format specs, migration guides) belongs in
`yourcli help <topic>`, named in root's SEE ALSO so the agent knows it exists.

### Section order

```
NAME / USAGE / DESCRIPTION / COMMANDS / ARGUMENTS / OPTIONS /
EXAMPLES / EXIT CODES / ENVIRONMENT / FILES / SEE ALSO
```

Man-page order is the most common help shape in the text these models trained
on, which makes its uppercase headers reliable extraction anchors. That is a
plausibility argument, not a measured result — but the order is free to adopt
and costs nothing if the reasoning is wrong.

### SEE ALSO: the navigation graph

A navigation element most CLIs omit entirely. Without it, an agent whose
current page is insufficient has one move: return to root and re-read the tree
at full token cost. With it, it hops laterally in one call. (Tier 2 — the
reasoning is mechanical, but the size of the effect is unmeasured here.)

**Every cross-reference carries a reason.** A bare list of names is a hyperlink
with no anchor text — the agent must visit each one to learn which is relevant.

```
SEE ALSO
  acme db status --help      Check for pending migrations before running this
  acme db rollback --help    Undo the migrations this command applies
  acme db seed --help        Populate tables after migrating
  acme db reset --help       Drops and recreates — NOT the same as `rollback`
```

Fill four slots on each leaf, dropping any with no honest answer:

- **Prerequisite** — what runs before this?
- **Next step** — what follows in the workflow?
- **Inverse** — how is this undone?
- **Confusable** — what will I mistake this for? State the contrast in the
  negative (`NOT`, `unlike`, `does not`). LLMs reach for the plausible-sounding
  neighbor; `reset` vs `rollback`, `update` vs `upgrade`, `sync` vs `push`. One
  line of disambiguation addresses a whole error class.

### Examples

Agents pattern-match more reliably than they parse specifications.

- Show the **actual command and its actual output**. An example with no output
  teaches half of what it could.
- Common case first, then one non-obvious case (piping, JSON, a flag
  combination that isn't guessable).
- Realistic values — `--to 20240115_add_users`, not `--to <VERSION>`.
- One JSON example per data-emitting command, so output shape is learned without
  a trial invocation.
- Exception: a command whose output is intentionally empty. Say so rather than
  faking output.

### Predictable grammar

LLMs extrapolate. If `acme db list` exists, an agent will assume `acme users
list` does too and invoke it unchecked. Make the assumption correct.

- One shape throughout: **`<noun> <verb>`** (recommended) or `<verb> <noun>`.
  Deeper nesting is allowed only if you **declare** it: the extra level is a
  namespace, root USAGE shows it (`acme <group> [<subgroup>] <command>`), the
  parent is listed as a *subgroup* rather than a command, it has its own help
  page, and it appears as a group node in the schema. A path that resolves in
  the parser but that no help page presents as a group teaches the agent two
  contradictory grammars at once — that `reset` is the verb, and that `reset`
  owns the verbs `plan` and `apply`.
- The **same verb set across every noun**: `list`, `get`, `create`, `delete`,
  `update`. Not `list` here and `ls` there. (Exception: a verb that would be
  semantically wrong for a noun — don't force it.)
- Same concept → same flag name and short form everywhere.
- **No prefix abbreviations.** `acme i` resolving to `install` forbids ever
  adding another `i*` command and makes guesses non-deterministic across
  versions. Explicit, stable, documented aliases are fine.
- **No catch-all default subcommand.** If `acme foo.txt` implicitly means
  `acme run foo.txt`, you can never add a `foo` command, and the agent cannot
  tell commands from arguments.

### Output contract

- **A JSON output mode on every data-emitting command.** Stable keys; version
  the schema.
- **Same shape for 0, 1, and many results *of the same kind*.** A list command
  must not switch between object and array by count. This does not mean forcing
  unrelated singleton and collection commands into one schema.
- **Documented, deterministic order** — not necessarily alphabetical. Sorting is
  wrong for logs, ranked results, and migration plans, where order carries
  meaning. Preserve domain order; define a stable tie-breaker so repeated runs
  match.
- **Bound the output, including the escape hatch.** Provide `--limit` and field
  projection. Prefer opaque cursors over offsets — offset pagination skips or
  duplicates rows under concurrent mutation. Keep a finite maximum even for
  "all"; an unbounded escape hatch defeats the purpose.
- **Announce truncation in-band.** In JSON, as metadata (`"truncated": true`,
  `"next_cursor": "…"`), not as a comment line that breaks parsing. In text, as
  a stderr note naming the command that gets the rest.
- **`--quiet`/`-q`** reduces output to essentials. If you want "identifier only",
  make it an explicit mode (`--output=id`) and define what it does for zero,
  many, and non-resource results.
- Support `-` for stdin/stdout where files are accepted.

### Machine-readable discovery

An agent that can afford one large call would rather have the whole surface than
crawl the tree. Offer a **standalone command**:

```
acme schema --format=json
```

Not `acme --help --json`: help conventionally short-circuits and ignores other
arguments (clig.dev and the GNU standards both say so), so `--help --json` may
yield text help, JSON, or an error depending on parser and argument order.

Generate it from the same command model as the text help. To actually let an
agent validate an invocation before running it, include: group **and** leaf
nodes; inherited/effective flags per command; positional grammar and
cardinality; enum values; required-together and mutually-exclusive constraints;
stable command IDs; aliases and deprecations; stdin behavior; mutation/danger
attributes; output and error schema IDs; and reason-bearing `see_also` entries
(keep the reasons — they are the point). Version the schema itself.

### Exit codes

Agents branch on the code before reading the message. Distinguish the three
outcomes that imply different next actions: *fix your invocation*, *retry
later*, *this is impossible*.

| Code | Meaning | Agent's next action |
|---|---|---|
| 0 | Success | Continue |
| 1 | Generic / unexpected failure | Report |
| 2 | Usage error — bad flag, missing arg | Re-read help, fix invocation |
| 3 | Not found | Verify the resource exists |
| 4 | Auth / permission denied | Fix credentials; don't retry |
| 5 | Conflict / precondition failed | Reconcile state; don't blind-retry |
| 6 | Transient (network, rate limit, lock) | Retry with backoff |
| 7 | Timeout | Retry, or raise the timeout |

Any scheme works; this one is a starting point. **Print the table in root help**
and keep it stable. An undocumented exit code is a coin flip.

### Errors are instructions

An agent takes its next action from the error text. Write the next command, not
a diagnosis.

- Name the **exact** resource — path, key, ID. Never "invalid input".
- For **non-destructive** fixes, include the literal copy-pasteable command.
  (For destructive ones, see **Safety** — do *not* hand
  over the executable command.)
- **Shell-escape** any value interpolated into a suggested command, and redact
  secrets before printing.
- On unknown command/flag: spelling suggestion **plus** the pointer back to
  help.
- Never a stack trace as the primary error — the agent will copy it verbatim
  into its report.
- Group repeated failures under one header, not 200 near-identical lines.
- Under JSON mode, emit a structured error object on stderr with a stable code
  and a `retryable` boolean.

### Safety without prompts

Agents cannot answer `Are you sure? [y/N]`. They hang — or find the flag that
suppresses the question and use it reflexively. **Distinguish three controls
that are routinely conflated:**

| Control | What it actually provides |
|---|---|
| `--yes` / `-y` | **Usability.** Suppresses a prompt. No safety value against an agent whatsoever. |
| `--confirm=<exact-name>` | **Accident resistance.** Proves the caller identified the *right target* — catches "deleted prod, meant staging". Does **not** confer permission. |
| Plan/apply token | **Freshness.** Proves the plan being applied matches the state that was previewed. Does **not** confer permission either — see below. |
| External approval | **Authorization.** Only this. An approval minted by a principal or policy *other than the caller*, after reviewing the specific plan. |

The failure mode to avoid: an error message that prints
`acme db reset --confirm=web-production` hands the agent both the ritual and the
resource name, and the skill's own "copy the fix command" instinct does the
rest. The guard evaporates.

So for **severe** operations (irreversible, remote, bulk):

- Do **not** print the executable destructive command as the suggested next
  step. Print the *inspection* command, and state that the operation requires
  approval.
- Add a **prepare/apply protocol** for drift safety: a read-only preview returns
  an opaque, short-lived plan ID bound to the target, the observed state
  version, and an immutable digest; execution requires it and fails if state
  moved. This closes the gap where a preview goes stale before execution.

  **A plan token is not authorization.** The same caller mints it and spends it,
  so an agent can run both halves reflexively exactly as it would copy a
  `--confirm` value. Possessing one proves *the plan endpoint was called*, not
  that anyone reviewed the result. To actually gate the operation, require a
  separate **approval** bound to the plan digest, target, state version,
  requester, and approver identity — minted by a principal or policy that is not
  the requester, single-use and expiring. Reject self-approval where separation
  of duties is required.

  If your CLI cannot enforce that — most cannot — say so plainly in the help
  text: describe plan/apply as a drift and intent safeguard, and state that the
  surrounding harness must block execution until it has recorded human or policy
  approval. Do not describe token possession as proof of review.
- `--dry-run`/`-n` on every mutating command remains valuable — it is the
  agent's cheap way to verify intent — but it is a *correctness* check, not an
  authorization one.
- Make mutations **idempotent** or fail cleanly (exit 5). Agents retry; nothing
  should half-apply.

---

## Anti-patterns

| Anti-pattern | Effect on an agent |
|---|---|
| Prompt with no flag equivalent | Hangs until timeout; whole task fails |
| Pager on non-TTY output | Hangs waiting for `q` |
| Spinner written to captured output | Floods context with `\r` frames |
| `--help` exiting non-zero, or printing to stderr | Read as failure; output discarded |
| `--help` requiring config or network | Discovery impossible in a fresh env |
| "See our docs at …" as the only flag reference | Dead end; agent guesses flags |
| Root help hiding some subcommands | Agent concludes they don't exist |
| Different verbs for the same action per noun | Extrapolation fails |
| Prefix abbreviations (`acme i` → `install`) | Non-deterministic guessing |
| Banner line on JSON stdout | Parse error on every call |
| Schema shape varying with result count | Parser breaks on the edge case |
| Unbounded default output, or `--limit 0` as the escape hatch | Blows the context window |
| Bare `error: invalid input` | No next action; agent retries identically |
| Stack trace as the user-facing error | Copied verbatim into the agent's report |
| Error printing the destructive command with its confirm token | Turns a safety guard into a script |

## Tier 3: Heuristics worth testing, not enforcing

Stated plainly because they drive the design above, but **this skill does not
measure them.** Treat as design targets; measure on your actual models before
treating any as a requirement.

- Agents read roughly one to three help pages before guessing. (Varies by model,
  harness, and task.)
- Suggested budgets: root ≤ 100 lines, group ≤ 60, leaf ≤ 80. Rationale: help is
  charged to context on every read, and an over-long leaf usually means the
  command does too much. Not a pass/fail threshold — a leaf whose useful content
  runs longer should stay longer.
- Two examples per leaf is a reasonable floor.
- A task completed in ≤ 3 help reads with 0 guessed flags is a good target.

When you run the empirical test in `references/audit-checklist.md`, remember
that a repeated help read or a guessed flag has causes other than bad help —
model variance, an ambiguous task, missing state, harness quirks. Treat those
signals as pointers to investigate, not proof of a documentation defect.

## References

- `references/help-anatomy.md` — templates for root, group, and leaf help,
  the SEE ALSO recipe, error templates, and the discovery schema.
- `references/audit-checklist.md` — probe harness and pass/fail checklist.

## Attribution

Adapted from [*Command Line Interface Guidelines*](https://clig.dev) by Aanand
Prasad, Ben Firshman, Carl Tashian, and Eva Parish, licensed under
[CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/). **Changes:**
retargeted from a human-first to an agent-first audience; added the help-graph
navigation model, machine-readable discovery schema, agent-specific safety
controls, context-budget guidance, and the audit harness. This adaptation is
likewise offered under CC BY-SA 4.0.

Where this skill and clig.dev conflict — progress animation, terse success
output, prompting for missing input — the rule here applies **only when the
relevant stream is not a TTY**; keep clig.dev's behavior for interactive use.
