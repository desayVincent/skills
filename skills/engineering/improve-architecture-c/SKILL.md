---
name: improve-architecture-c
description: >
  Scan C/C++ or SDK trees for deepening opportunities; generate a controlled-
  Chinese HTML report; then grill the chosen candidate. Re-invoke with grill
  <candidate> after the report pause.
disable-model-invocation: true
metadata:
  short-description: "Deepen C/C++ architecture (HTML report)"
---

# Improve architecture (C/C++)

User-invoked scan for **deepening** opportunities: turn **shallow** modules
into **deep** ones for testability, **locality**, and AI-navigability.

**Self-contained:** one skill folder is enough (`cp -a improve-architecture-c …`).
No other skill required. Optional peers may be used if already installed; never
block on them.

## Entry (read first)

This skill is **user-invoked**. A new turn does not auto-resume unless the user
re-invokes it. Pick a branch immediately:

| User intent | Branch |
|-------------|--------|
| First scan, or rescan / new scope | **Full run** — steps 1→3, then stop |
| After a report: pick a candidate or “top recommendation” | **Continue grill** — step 4 only |
| Explicit: `/improve-architecture-c grill <name>` or `grill <name>` with this skill | **Continue grill** — step 4 only |

**Continue grill** when **any** of:

- Invocation contains `grill` plus a candidate name (or `top` / “top recommendation”)
- User re-invoked this skill and names a candidate from a prior report in-thread
- User pastes/points at an existing `architecture-review-c-*.html` and names a pick

On **Continue grill**: load vocabulary + write gate below, then go to **step 4**.
Do **not** re-scope, re-explore, or rewrite the HTML unless the user asks to rescan.

On **Full run**: steps 1→3 only; stop after step 3 (see re-invoke line).

**Done when (entry):** exactly one branch chosen before heavy work.

## Vocabulary (architecture analysis)

Keep product names from `CONTEXT.md` / headers. Use these terms for structure:

| Term | Meaning |
|------|---------|
| **Module** | One interface + implementation (public header + body, or a small lib) |
| **Interface** | Everything a caller must know: protos, order, errors, ownership, threads |
| **Depth** | Behaviour per unit of interface learned (**deep** vs **shallow**) |
| **Seam** | Place behaviour can change without editing there (ops/HAL/plugin/abstract) |
| **Adapter** | Concrete fill of a seam (prod / fake / loopback) — evidence, not definition |
| **Leverage** | Capability callers get per unit of interface |
| **Locality** | Change and bugs concentrate in one place |

**Deletion test:** delete the module — complexity vanishes → pass-through; reappears
at N callers → keep / deepen.

**Seam rule:** introduce a seam only for a **known** variation, platform edge, or
ownership boundary. One fill with no such boundary → pure indirection (cut or
justify). A second adapter (e.g. test fake) supports the claim; it is not a
hard count gate.

**C/C++ shape:** public `.h` + opaque types; ops/vtable/plugin; C++ may use a
narrow abstract interface or `extern "C"` edge. Watch include fan-out and C++
ABI leaks (exceptions/RTTI/layout across stable shared edges).

## Dependency categories

| Category | Meaning | Test angle |
|----------|---------|------------|
| `in-process` | Pure compute/memory | Contract tests at public interface |
| `local-substitutable` | Cheap local stand-in | Fake fs/clock/arena |
| `owned-platform` | Your HAL/driver/IPC | Ops port; prod + loopback/fake when useful |
| `true-external` | Closed blob / foreign HW | Mock adapter |

## Write gate

| Task posture | Action |
|--------------|--------|
| Edits allowed (user asked to model/update/implement) | May write `CONTEXT.md` / ADRs |
| Read-only / advise-only | Propose paste-ready blocks + paths only |

HTML always goes to OS temp (never the repo).

`CONTEXT.md` = stable product meanings only. ADRs only if **all** of: hard to
reverse · surprising without context · real trade-off.

## Process

### 1. Scope

- User named a module, header tree, or pain → that path only.
- Else hotspots: `git log --name-only --pretty=format:` (or `--stat`) over a
  useful window + likely roots (`include/`, `sdk/`, `mapi/`, `hal/`, …). Rank
  by touch frequency. Scattered → widen.
- Read `CONTEXT.md` / `CONTEXT-MAP.md` and ADRs in scope if present.

**Done when:** path set (or named whole-repo hotspots) is fixed before deep reads.

### 2. Explore

Walk the scope. Apply the deletion test. Tag dependency category. Use the lens:

| Signal | Look for |
|--------|----------|
| Include fan-out | Long chains; public headers pull driver-private headers |
| Opaque misuse | Full structs public when a handle suffices; or bare `void *` with no domain type |
| Large surface | Forwarding exports; field-wise getters; wrapper stacks |
| Fake seam | Ops/vtable/plugin with **no** known variation/platform/ownership boundary |
| Globals | Many `static` singletons; implicit init order across TUs |
| Misplaced seam | Product policy mixed with register I/O; no port |
| Untestable interface | No contract-test path through public header/ops |
| Pass-through | Deletion removes nothing useful |
| Error/lifetime leak | Callers carry recovery, ownership, thread rules that belong inside |
| Duplicated lifecycle | Same protocol state machine in multiple shallow modules |
| C++ ABI leak | Exceptions/RTTI/layout across a stable shared edge without ADR |

**Strength badges**

| Badge | Use when |
|-------|----------|
| **Strong** | Hotspot + clear deletion-test win + named boundary; low ADR conflict |
| **Worth exploring** | Real friction; payoff or scope still uncertain |
| **Speculative** | Thin evidence, cold code, or would reopen a firm ADR |

**Done when:** each candidate has files, one-sentence problem, deletion-test
result, category, and badge. ADR conflicts marked only when reopening is justified.

### 3. HTML report — then stop

Write: `$TMPDIR`|/tmp|`%TEMP%` → `architecture-review-c-<timestamp>.html`

Read and apply [HTML-REPORT.md](HTML-REPORT.md). Its Chinese terminology and
copy rules are mandatory for all visible report text. Keep code identifiers,
paths, symbols, commands, category keys, and product terms unchanged.

Report **absolute path**. Open (`xdg-open`/`open`/`start`) is best-effort.
No full interface designs yet.

**End this turn.** Do not start step 4 in the same turn.

Tell the user exactly how to continue (copy-paste form):

```text
Re-invoke this skill to grill, e.g.:
  /improve-architecture-c grill <candidate-title>
or:
  /improve-architecture-c grill top
Report path: <absolute-path>
```

**Done when:** HTML is readable, path reported, re-invoke line given, turn stops
without grilling.

### 4. Grill the pick (inline — no extra skill)

**Entry:** only via **Continue grill** (see Entry). Resolve the candidate from
the user message and the prior report (path in-thread or path the user pastes).
If the pick is ambiguous, ask once; do not rescan.

Walk:

1. Fixed constraints (ABI, realtime, memory, threads)?
2. Dependency category + known boundary for any seam?
3. Deepened module’s public interface facts (not full headers yet)?
4. What stays behind the seam; which adapters exist or will exist?
5. Which tests survive (contract vs white-box)?
6. What belongs in CONTEXT or an ADR under the write gate?

Optional: if the user wants more design options, sketch 3 different interfaces
in this session (min surface / max extension / common-caller) without another
skill.

Under the write gate: new/sharpened terms → CONTEXT (or proposal); load-bearing
rejection that would reappear in a future scan → offer ADR.

**Done when:** user has a decided direction; CONTEXT/ADR writes or proposals
for crystallised terms are complete.

## Route elsewhere (optional peers)

These are **not** dependencies. Use only if already available:

| Need | Optional skill |
|------|----------------|
| Deeper shared vocabulary / design-it-twice | `deep-modules-c` |
| Full domain-modeling process | `domain-model-c` |
| HOST/EMBEDDED legibility | `write-legible-embedded-c` |
| Diff defect gate | `hermes-local-review` |
| Delete over-engineering on a small diff | `ponytail-review` |
