---
name: write-legible-c
description: >
  Strict C11 machine-legibility for writing or reviewing .c/.h, C APIs,
  C tests, and C-facing AGENTS.md. Triggers: /write-legible-c, legible C,
  MODULE_TRY, near-miss map_eat. Use when another skill needs host C base.
metadata:
  short-description: "Enforce legible C and repository standards"
---

# Write Legible C

Apply the machine-legibility standard to every C region created, changed,
reviewed, or presented.

## Load the standard

1. Read [c-standard.md](c-standard.md) sections **1–14** before designing a C
   change. Treat that file as the normative rule set and pre-delivery gate.
2. Load disclosed material only when its branch fires:
   - **Greenfield** module or new file that should show full layout →
     [skeleton.md](skeleton.md)
   - **Existing** function that already looks short and flat →
     [near-miss-map-eat.md](near-miss-map-eat.md) (diagnose near miss, smallest
     behavior-preserving decomposition, then decide whether scope allows the
     fully conforming API stage)
   - **Repository** agent guidance, `AGENTS.md`, directory docs, or test
     feedback loop → [repository-level.md](repository-level.md)
   - **Provenance** questions only (not a delivery gate) →
     [PROVENANCE.md](PROVENANCE.md)

If the workspace has a repo-root `AGENTS.md` that already embeds this standard
(or a subset), treat repo `AGENTS.md` as higher-priority for that workspace,
and still use this skill's full checklist for any rule the repo file omits.

## Work in this order

1. Read the applicable user instructions, `AGENTS.md` files, public headers,
   build rules, and tests before designing the change.
2. Map the touched module's ownership, public API, constants, types, static
   call graph, bounded loops, resources, status values, dispatch tables, and
   state invariants.
3. Preserve behavior and compatibility unless the user requests a semantic
   change. Use adapters when an external API conflicts with the standard.
4. Design the file-top vocabulary and function boundaries before editing
   bodies. Classify every function as an **orchestrator**, **leaf**, or
   **adapter**, then separately record whether it is a public boundary. Public
   visibility is not a fourth function altitude. Keep each helper at one
   altitude and require it to pass the **name test** in section 4 of the
   standard.
5. Implement the smallest coherent change. Apply the standard to every
   touched function and declaration, including test code written in C.
6. Run the project's required build and tests, then apply **every item** in
   [c-standard.md](c-standard.md) section **14** (pre-delivery checklist) to
   the final diff. Section 14 is the single verification source of truth; do
   not restate its items here.

**Done when:** section 14 is fully applied to the final diff (or each forced
deviation has a precise source-site comment).

Treat the prose rules as authoritative when an example is incomplete. Apply
the same gates to snippets and full files. For an existing function that
already looks short and flat, complete the near-miss pass in
[near-miss-map-eat.md](near-miss-map-eat.md) before accepting it—judge the
refactor by the cost of the next change.

For repository-level work, follow [repository-level.md](repository-level.md):
dense, evidence-based guidance only; do not invent a path map discoverable
from the tree; do not change agent guidance or test policy unless the task
authorizes repository-level changes.

## Resolve constraints

- Follow higher-priority user, repository, ABI, wire-format, generated-code,
  and platform requirements when they conflict with this skill.
- Do not widen a scoped task into a repository-wide rewrite merely because
  nearby untouched C predates the standard.
- When a required constraint forces a deviation, add the required comment at
  the deviation site and state the constraint precisely.
- When a frozen public signature cannot return a status, preserve its behavior
  and place the deviation comment immediately above the affected declaration
  or definition, including in a standalone snippet. A delivery note does not
  replace the source-site comment. Do not let the legacy boundary excuse
  missing internal assertions or other locally satisfiable rules.
- Do not claim compliance when required checks could not run. Report the
  unchecked command or rule.

## Deliver

Report the behavior change, the structural changes that materially improve
legibility, the verification performed, and any documented deviations. Keep
the report shorter than the code review it summarizes.
