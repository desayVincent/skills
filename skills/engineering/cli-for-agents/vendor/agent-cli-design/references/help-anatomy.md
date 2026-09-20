# Help Page Anatomy — Templates and Worked Example

## Contents

- [Conventions](#conventions)
- [Template: root help](#template-root-help-acme---help)
- [Template: group help](#template-group-help-acme-db---help)
- [Template: leaf help](#template-leaf-help-acme-db-migrate---help)
- [The SEE ALSO recipe](#the-see-also-recipe)
- [Error message templates](#error-message-templates)
- [Destructive operations](#destructive-operations)
- [Discovery schema](#discovery-schema-acme-schema---formatjson)
- [Keeping the examples honest](#keeping-the-examples-honest)

## Conventions

Uppercase section headers, blank line between sections, two-space indent for
entries, aligned description columns. Section order is man-page order
deliberately — see the rationale in `agent-cli-design.md`. Omit sections that are genuinely
empty; never reorder the ones you keep.

Everything below is one **canonical `acme` fixture**: the same command names,
flags, and scopes across all templates. The discovery-schema section is an
explicitly marked *fragment* of that fixture, not the whole surface — but every
name, flag, and scope it does show agrees with the help pages. Consistency here
is the point — see
[Keeping the examples honest](#keeping-the-examples-honest).

---

## Template: root help (`acme --help`)

Suggested budget: ≤ 100 lines. Must list **every** group and top-level command.

```
acme — deploy and manage Acme services

USAGE
  acme <command> [flags]                        # top-level: status, schema, …
  acme <group> <command> [flags]                # e.g. acme db migrate
  acme <group> <subgroup> <command> [flags]     # e.g. acme db reset plan
  acme help <topic>                             # long-form topics

DESCRIPTION
  Manages Acme applications: databases, deployments, and configuration.
  Every command supports --json for machine-readable output, and every
  mutating command supports --dry-run.

COMMAND GROUPS
  db          Database creation, migration, and backups
  deploy      Build and release application versions
  config      Read and write application configuration
  logs        Stream and query application logs
  approvals   Request and inspect approvals for destructive operations

COMMANDS
  status      Show current state of the application
  schema      Print the full command tree as JSON
  version     Print version and build information
  help        Show help, or a long-form topic: acme help <topic>

GLOBAL FLAGS
  --app <name>        Target application. Default: $ACME_APP, then app in
                      ./acme.toml; required if neither is set.
  --json              Emit machine-readable JSON on stdout
  --quiet, -q         Print only essential output
  --color <when>      Color output: auto, always, never (default: auto)
                      --no-color is an alias for --color=never
  --dry-run, -n       Show what would change without changing it
  --timeout <dur>     Network timeout (default: 30s)
  --help, -h          Show help for any command
  --version           Print version

EXAMPLES
  # See what state the app is in — safe first call
  $ acme status --app web
  app        web
  version    v1.4.2 (deployed 2h ago)
  database   ready, 2 pending migrations

  # Full command surface as JSON, for programmatic discovery
  $ acme schema --format=json | jq -r '.commands[].id'
  db.migrate
  db.rollback
  db.status
  ...

EXIT CODES
  0  success                     4  auth / permission denied
  1  unexpected failure          5  conflict / precondition failed
  2  usage error (re-read help)  6  transient — retry with backoff
  3  not found                   7  timeout

ENVIRONMENT
  ACME_APP         Default --app value
  ACME_TOKEN_FILE  Path to a file containing the API token
  NO_COLOR         Disable color when set to a non-empty value. TERM=dumb also
                   disables color. An explicit --color=always overrides both
                   (flags outrank the environment).

SEE ALSO
  acme db --help          Database commands — start here for schema work
  acme deploy --help      Release commands — start here to ship code
  acme help config-file      Reference for the ./acme.toml format
  acme help exit-codes       Exit code semantics and retry guidance
  acme help destructive-ops  Plan/approve/apply procedure for destructive commands
```

Note `acme schema --format=json`, **not** `acme --help --json`: help
conventionally ignores other arguments, so combining the two is parser-dependent.

---

## Template: group help (`acme db --help`)

Suggested budget: ≤ 60 lines. Must list **every** command in the group, plus a
typical end-to-end sequence — the sequence conveys ordering constraints that
names alone cannot.

```
acme db — database creation, migration, and backups

USAGE
  acme db <command> [flags]
  acme db <subgroup> <command> [flags]     # e.g. acme db reset plan

COMMANDS
  status      Show schema version and pending migrations
  query       Run a read-only SQL query and print the result
  migrate     Apply pending migrations
  rollback    Revert the most recently applied migration(s)
  new         Generate an empty migration file
  seed        Load seed data into the database
  backup      Write a snapshot to a file or stdout
  restore     Load a snapshot from a file or stdin

SUBGROUPS
  reset       Drop, recreate, migrate, and seed — destructive, two-step.
              Run 'acme db reset --help'; it is a group, not a command.

GROUP FLAGS
  --dir <path>     Migrations directory (default: ./migrations)
  --url-file <p>   File containing the connection string
                   (default: database.url in ./acme.toml)

TYPICAL SEQUENCE
  $ acme db status              # check what's pending
  $ acme db migrate --dry-run   # preview
  $ acme db migrate             # apply
  $ acme db seed                # optional: load fixtures

SEE ALSO
  acme db migrate --help   Most common operation in this group
  acme deploy --help       Deploys run pending migrations automatically
  acme --help              Global flags and exit codes
```

The connection string is read from a **file**, not a `--url <dsn>` flag: DSNs
routinely carry credentials, and flag values are visible in `ps` and shell
history.

---

## Template: leaf help (`acme db migrate --help`)

Suggested budget: ≤ 80 lines. This page must be sufficient on its own — an agent
landing here should not need another page to invoke correctly. That includes
inherited flags that affect the command.

```
acme db migrate — apply pending database migrations

USAGE
  acme db migrate [--to <version>] [--lock-timeout <seconds>]
                  [--dir <path>] [--url-file <path>]
                  [--dry-run] [--json] [--quiet] [--app <name>] [--timeout <dur>]

DESCRIPTION
  Applies every migration in --dir not yet recorded in the schema_migrations
  table, in filename order. Each migration runs in its own transaction; a
  failure rolls back that migration only and stops, leaving earlier ones
  applied. Safe to re-run: already-applied migrations are skipped.

FLAGS
  --to <version>            Stop after this migration (default: apply all pending)
  --lock-timeout <seconds>  Wait for the migration advisory lock (default: 10)

INHERITED FLAGS (from `acme db`)
  --dir <path>              Migrations directory (default: ./migrations)
  --url-file <path>         File containing the connection string
                            (default: database.url in ./acme.toml)

INHERITED FLAGS (global)
  --dry-run, -n             Print the migrations that would run; change nothing
  --json                    Emit results as JSON on stdout
                            (mutually exclusive with --quiet)
  --quiet, -q               Print only the resulting schema version
                            (mutually exclusive with --json)
  --app <name>              Target application. Default: $ACME_APP, then app
                            in ./acme.toml; required if neither is set.
  --timeout <dur>           Network timeout (default: 30s)

EXAMPLES
  # Preview before applying — recommended first call
  $ acme db migrate --dry-run
  would apply 2 migrations:
    20240115_add_users.sql
    20240118_add_index_users_email.sql

  # Apply everything pending
  $ acme db migrate
  applied 20240115_add_users.sql             (124ms)
  applied 20240118_add_index_users_email.sql  (32ms)
  schema now at 20240118_add_index_users_email

  # Apply up to a specific version only
  $ acme db migrate --to 20240115_add_users
  applied 20240115_add_users.sql             (124ms)
  schema now at 20240115_add_users
  1 migration still pending — run `acme db status` to list it

  # Machine-readable result
  $ acme db migrate --json
  {
    "format": "acme.db.migrate.result/1",
    "applied": [
      {"version": "20240115_add_users", "duration_ms": 124},
      {"version": "20240118_add_index_users_email", "duration_ms": 32}
    ],
    "schema_version_after": "20240118_add_index_users_email",
    "pending": []
  }

EXIT CODES
  0  all pending migrations applied (or none were pending)
  2  bad --to version, or --dir does not exist
  5  a migration failed; schema left at the last successful version
  6  could not acquire the migration lock — another migrate is running, retry
  7  lock timeout exceeded

SEE ALSO
  acme db status --help     Check what is pending before running this
  acme db rollback --help   Undo migrations this command applied
  acme db new --help        Create a new migration file to apply
  acme db seed --help       Usual next step after a successful migrate
  acme db reset --help      Drops and recreates the database — destructive,
                            NOT an alternative to `rollback`
```

Every flag in the FLAGS and INHERITED FLAGS tables appears in USAGE, each is
listed under the scope that actually owns it, every flag with a value has a
typed placeholder, and every example shows real output. Those three properties
are checkable mechanically — see [Keeping the examples honest](#keeping-the-examples-honest).

---

## The SEE ALSO recipe

Fill these four slots per leaf. Drop a slot only if it has no honest answer.

| Slot | Question it answers | Example line |
|---|---|---|
| Prerequisite | "What should I run first?" | `acme db status --help   Check pending migrations before running this` |
| Next step | "What comes after?" | `acme db seed --help     Usual next step after a successful migrate` |
| Inverse | "How do I undo this?" | `acme db rollback --help Undo migrations this command applied` |
| Confusable | "What am I about to mistake this for?" | `acme db reset --help    Drops and recreates — NOT an alternative to rollback` |

The confusable slot is often the most useful one, and is commonly missing.
Find it by asking: *which command here has the most similar name or
description?* Then write the contrast explicitly, in the negative (`NOT`,
`unlike`, `does not`).

---

## Error message templates

What happened → the fix → where to read more. Shell-escape interpolated values;
redact secrets.

**Missing prerequisite**

```
error: no migrations directory found at ./migrations

  Create a first migration:
    acme db new create_users

  Or point at an existing directory:
    acme db migrate --dir path/to/migrations

  See: acme db new --help
```

**Wrong invocation (exit 2)**

```
error: unknown flag --target

  Did you mean --to?
    acme db migrate --to 20240115_add_users

  See: acme db migrate --help
```

**Unknown subcommand (exit 2)**

```
error: unknown command "migrat" for "acme db"

  Did you mean "migrate"?

  Run 'acme db --help' to list all database commands.
```

**Conflict (exit 5)**

```
error: migration 20240118_add_index_users_email failed
  SQL: CREATE UNIQUE INDEX users_email_idx ON users (email)
  Cause: duplicate key value violates unique constraint — 3 rows share an email

  Schema is at 20240115_add_users. Nothing was left half-applied.

  Inspect the conflicting rows:
    acme db query "SELECT email, count(*) FROM users GROUP BY email HAVING count(*) > 1"
```

**Structured error under `--json`** (stderr; exit code still set)

```json
{
  "format": "acme.error/1",
  "error": {
    "code": "migration_failed",
    "exit_code": 5,
    "message": "migration 20240118_add_index_users_email failed",
    "resource": "20240118_add_index_users_email",
    "retryable": false,
    "hint": "3 rows share an email; deduplicate before re-running",
    "see": "acme db migrate --help"
  }
}
```

---

## Destructive operations

The trap: an error that prints the ready-to-run destructive command hands the
agent both the ritual and the target name. Since the agent has been told to copy
the fix command, `--confirm` stops guarding anything.

**Don't do this** (`yourcli`, not `acme` — anti-examples are deliberately outside
the canonical fixture, so no reader mistakes one for a supported invocation and
no consistency check has to resolve it):

```
error: --confirm is required for `db reset`
  To proceed:
    yourcli db reset --confirm=web-production     # ← agent copies this verbatim
```

**Do this** — name the consequence, offer *inspection*, and state that approval
comes from outside the tool:

```
error: `db reset` requires approval and was not performed

  This destroys all data in database "web-production" (est. 1.2M rows,
  last backup 6 days ago). It cannot be undone.

  Inspect before deciding:
    acme db status
    acme db backup --to ./pre-reset.dump

  This operation requires explicit human approval. If you are an automated
  agent, stop here and ask the user; do not construct the confirmation
  yourself. Approval procedure: acme help destructive-ops
```

### Plan/apply gives freshness, not authorization

For irreversible, remote, or bulk operations, add a **prepare/apply protocol**.
It prevents a stale preview from being applied to drifted state:

Use **two distinct commands**, so inspection can never become execution by
supplying an optional value. That makes `reset` a **subgroup**, not a command —
and it must be declared as one everywhere, or the agent learns from the same
fixture both that `reset` is a verb and that it owns two further verbs:

```
acme db reset — drop, recreate, migrate, and seed a database

USAGE
  acme db reset <command> [flags]

COMMANDS
  plan        Compute what a reset would do; mint a plan id. Changes nothing.
  apply       Execute a specific plan, given a matching fresh approval.

  This group has no default command: 'acme db reset' with no command prints
  this page on stdout and exits 2 (usage error — no command supplied), the
  same contract as every other group. Destruction is never one keystroke
  from inspection.

SEE ALSO
  acme db --help                  Parent group — all other database commands
  acme --help                     Root — all command groups
  acme approvals request --help   Approval must be granted before apply
  acme db backup --help           Take a snapshot before any reset
```

```
$ acme db reset plan
would drop database "web-production" (1.2M rows across 14 tables)
plan:   pln_7f3a9c2e   digest sha256:4b1f…  state version 4821  expires in 10m

$ acme db reset apply --plan-id pln_7f3a9c2e --approval apr_2c81d5
error: state version changed (4821 → 4830) since plan pln_7f3a9c2e was created
  That plan and its approval are void. Start again:
    acme db reset plan
```

**Do not mistake this for an authorization control.** The same caller mints the
plan and spends it, so an agent can run both halves reflexively exactly as it
would copy a `--confirm` value. Possessing a plan proves the plan endpoint was
called — not that anyone reviewed the result.

Gating the operation requires a second credential minted by someone *other than
the requester*, bound to the plan digest:

```
$ acme db reset plan
plan:   pln_9e04b1a   digest sha256:c72d…  state version 4830  expires in 10m

$ acme db reset apply --plan-id pln_9e04b1a --approval apr_2c81d5
error: approval apr_2c81d5 is bound to digest sha256:4b1f…, not sha256:c72d…
  An approval covers one exact plan. Request approval for the new plan:
    acme approvals request --plan-id pln_9e04b1a

$ acme db reset apply --plan-id pln_9e04b1a
error: plan pln_9e04b1a has no approval

  Approval must be granted by a principal other than the requester
  (requester: svc-deploy-agent). Self-approval is rejected for this operation.

  Request review:  acme approvals request --plan-id pln_9e04b1a
  Check status:    acme approvals show    --plan-id pln_9e04b1a

$ acme db reset apply --plan-id pln_9e04b1a --approval apr_7d13f0
dropped database "web-production" (1.2M rows across 14 tables)
```

The two commands that workflow invokes are registered like any other — a
recovery hint may never name a command the CLI does not expose:

```
acme approvals — request and inspect approvals for destructive operations

USAGE
  acme approvals <command> [flags]

COMMANDS
  request     Request approval for one exact plan
  show        Show approval state, approver, and expiry for a plan

SEE ALSO
  acme --help            Root — all command groups
  acme db reset --help   The destructive operation these approvals gate
```

The approval is bound to operation, exact target, plan digest, observed state
version, requester identity, approver identity, and an expiry, and is
single-use. Approval never overrides freshness: drift voids the plan *and* every
approval attached to it, and a new plan needs a new approval.

**If your CLI cannot enforce that** — most standalone CLIs cannot, because there
is no second principal — then say so in the help text. Describe plan/apply as a
drift and intent safeguard only, and state that the surrounding harness must
block execution until it has recorded human or policy approval. Claiming more
than the mechanism delivers is how a safety control becomes a ritual.

---

## Discovery schema (`acme schema --format=json`)

One call, whole surface, generated from the same command model as the text help.
To let an agent validate an invocation *before* running it, the schema needs
more than names — resolved inherited flags, cardinality, and constraints are
what make validation possible.

> **This listing is a fragment**, showing one group and one command so the shape
> stays readable. A real `acme schema` emits every group and every leaf. Each
> command's `flags` array is the **resolved union** of global, group, and
> command flags, tagged with `source` — an agent should never have to join three
> lists to know what it may pass.
>
> "Fragment" applies to *which nodes are listed*, not to the contents of the
> nodes shown: the global metadata (`global_flags`, `exit_codes`) and every
> displayed command are complete, including all of that command's `see_also`
> edges and constraints. A consumer must never have to guess whether an absent
> field means "unsupported" or "elided".
>
> The union covers flags that change what the command *does*. Universal
> presentation flags (`--help`, `--version`, `--color`) live only in
> `global_flags` and are understood to apply everywhere; repeating them on every
> node is noise. Whichever rule you pick, state it — an agent validating an
> invocation needs to know whether an absent flag is unsupported or merely
> global.

```json
{
  "schema_version": "1",
  "name": "acme",
  "version": "1.4.2",
  "description": "Deploy and manage Acme services",
  "global_flags": [
    {"name": "--app", "type": "string", "description": "Target application",
     "default_sources": [
       {"kind": "env", "name": "ACME_APP"},
       {"kind": "config", "file": "./acme.toml", "key": "app"},
       {"kind": "unset", "behavior": "usage error, exit 2"}
     ]},
    {"name": "--json", "type": "boolean", "default": false, "description": "Machine-readable output on stdout"},
    {"name": "--quiet", "short": "-q", "type": "boolean", "default": false, "description": "Print only essential output"},
    {"name": "--color", "type": "enum", "values": ["auto", "always", "never"], "default": "auto",
     "aliases": [{"name": "--no-color", "equivalent_to": "--color=never"}],
     "description": "Color output"},
    {"name": "--dry-run", "short": "-n", "type": "boolean", "default": false, "description": "Show what would change without changing it"},
    {"name": "--timeout", "type": "duration", "default": "30s", "description": "Network timeout"},
    {"name": "--help", "short": "-h", "type": "boolean", "default": false, "description": "Show help"},
    {"name": "--version", "type": "boolean", "default": false, "description": "Print version"}
  ],
  "exit_codes": {
    "0": "success", "1": "unexpected failure", "2": "usage error",
    "3": "not found", "4": "auth / permission denied", "5": "conflict",
    "6": "transient, retry with backoff", "7": "timeout"
  },
  "groups": [
    {
      "id": "db",
      "path": ["db"],
      "summary": "Database creation, migration, and backups",
      "flags": [
        {"name": "--dir", "type": "string", "default": "./migrations", "description": "Migrations directory"},
        {"name": "--url-file", "type": "path", "default": "database.url in ./acme.toml", "description": "File containing the connection string"}
      ]
    }
  ],
  "commands": [
    {
      "id": "db.migrate",
      "path": ["db", "migrate"],
      "summary": "Apply pending database migrations",
      "aliases": [],
      "deprecated": null,
      "mutating": true,
      "idempotent": true,
      "danger": "moderate",
      "requires_approval": false,
      "reads_stdin": false,
      "positionals": [],
      "flags": [
        {"name": "--to", "type": "string", "required": false,
         "description": "Stop after this migration", "source": "command"},
        {"name": "--lock-timeout", "type": "integer", "default": 10, "units": "seconds",
         "description": "Wait for the migration advisory lock", "source": "command"},

        {"name": "--dir", "type": "string", "default": "./migrations",
         "description": "Migrations directory", "source": "group:db"},
        {"name": "--url-file", "type": "path", "default": "database.url in ./acme.toml",
         "description": "File containing the connection string", "source": "group:db"},

        {"name": "--dry-run", "short": "-n", "type": "boolean", "default": false,
         "description": "Preview only", "source": "global"},
        {"name": "--json", "type": "boolean", "default": false,
         "description": "Machine-readable output on stdout", "source": "global"},
        {"name": "--quiet", "short": "-q", "type": "boolean", "default": false,
         "description": "Print only the resulting schema version", "source": "global"},
        {"name": "--app", "type": "string",
         "description": "Target application", "source": "global",
         "default_sources": [
           {"kind": "env", "name": "ACME_APP"},
           {"kind": "config", "file": "./acme.toml", "key": "app"},
           {"kind": "unset", "behavior": "usage error, exit 2"}
         ]},
        {"name": "--timeout", "type": "duration", "default": "30s",
         "description": "Network timeout", "source": "global"}
      ],
      "constraints": [
        {"kind": "mutually_exclusive", "flags": ["--quiet", "--json"]}
      ],
      "output_schema": "acme.db.migrate.result/1",
      "error_schema": "acme.error/1",
      "see_also": [
        {"id": "db.status",   "reason": "Check what is pending before running this"},
        {"id": "db.rollback", "reason": "Undo migrations this command applied"},
        {"id": "db.new",      "reason": "Create a new migration file to apply"},
        {"id": "db.seed",     "reason": "Usual next step after a successful migrate"},
        {"id": "db.reset",    "reason": "Destructive — NOT an alternative to rollback"}
      ],
      "examples": [
        "acme db migrate --dry-run",
        "acme db migrate --to 20240115_add_users"
      ]
    }
  ]
}
```

`see_also` keeps the **reasons**. Reducing it to a list of IDs discards exactly
the information that makes the graph navigable.

---

## Keeping the examples honest

Documentation examples rot silently, and a wrong example is worse than a missing
one: the agent trusts it and invokes something that fails. Define one canonical
fixture and check the docs against it in CI. A short test can catch the common
breakages mechanically:

- every flag in a FLAGS table also appears in USAGE, and vice versa;
- every constraint in the schema (mutual exclusion, required-together) is also
  stated in the human help — otherwise the text page cannot validate an
  invocation the way the skill promises;
- flag aliases and value grammars match between help and schema
  (`--color <auto|always|never>` with `--no-color` as a documented alias, not a
  spelling that appears only in prose);
- defaults agree everywhere the flag appears — root help, every leaf that
  inherits it, and the schema — **including the precedence chain**, not just the
  first source. A flag resolved from an environment variable, then a config key,
  then an error is three facts; a leaf that shows only `$ACME_APP` tells an
  agent the config file does not exist. Represent the chain as an ordered
  `default_sources` array (env var name, exact config file and key, and what
  happens when nothing is set) rather than crushing it into one scalar
  `default` string, and compare the whole ordered list;
- the exit codes in root help and the schema's `exit_codes` map are the same set;
- a command's SEE ALSO edges are identical in help and schema;
- every flag taking a value has a typed placeholder (`--lock-timeout <seconds>`);
- every command named in a SEE ALSO block resolves to a real command;
- **every `acme …` invocation in every console block resolves** — walkthroughs
  and transcripts included, not just SEE ALSO blocks and EXAMPLES sections.
  Extract the command from each line and resolve it against the registered
  model; a destructive-operation walkthrough is the last place a fictional
  command should survive. Anti-examples ("don't do this") use `yourcli`
  instead, which both marks them as non-canonical and keeps them out of the
  checker;
- **every invocation is admitted by the displayed USAGE grammar**, not merely
  resolvable by the parser — checked against each applicable ancestor page, not
  one permissive aggregate. Root USAGE must admit its own top-level commands, a
  group page must show the subgroup form if it has subgroups, and every
  intermediate path must appear as the correct node *kind*. A path the parser
  accepts but no synopsis admits teaches a grammar the help pages contradict;
- **every command appearing in an error message's recovery hint resolves too.**
  Recovery hints are the most copy-pasteable text the CLI emits — an agent hits
  the error, lifts the suggested command verbatim, and runs it. A hint naming a
  command that was never registered converts one failure into two, and it is
  easy to miss because the checks above only walk SEE ALSO blocks and example
  sections. Extract command names from error copy as well;
- every command name in prose matches the registered command (`new`, not
  `new-migration`);
- every `jq` expression shown in an example runs against the real schema and
  produces the output displayed (a query for `.commands[].name` against objects
  keyed by `id` and `path` silently yields `null`);
- every example command parses under the real argument parser;
- exit codes listed in a leaf are a subset of the documented global scheme.
