# Design it twice (C/C++)

Alternative **interfaces** for one deepening candidate (Ousterhout).
Vocabulary: [SKILL.md](SKILL.md).

Load when the user wants options, not a single proposal.

## 1. Frame the problem space

Write for the user:

- Constraints (ABI freeze, realtime, no alloc on path, …)
- Dependencies + [DEEPENING.md](DEEPENING.md) category
- Illustrative public-header sketch (not a proposal)

**Done when:** user has seen the frame. Proceed to step 2 without waiting.

## 2. Produce three radically different interfaces

Each design uses a **different** constraint:

1. Minimise interface (1–3 entry points; max leverage; opaque handles)
2. Maximise extension (ops/plugin; core header stays small)
3. Optimise common caller (default path one call; advanced knobs secondary)
4. (If platform deps) Ports & adapters — prod ops vs test fake

**How:** spawn parallel sub-agents when available; otherwise the current agent
produces all three independently (same briefs, no cross-copying).

Brief each design with file paths, coupling, category, architecture vocabulary,
and `CONTEXT.md` terms.

Each design returns: interface facts, caller usage sample, what hides behind
the seam, adapters, trade-offs (where leverage is high or thin).

**Done when:** ≥3 substantially different interfaces exist (parallel or serial).

## 3. Compare

Present sequentially, then contrast on **depth**, **locality**, **seam
placement**. Give one recommendation; hybrid only if it clearly wins.

**Done when:** user has a single recommended shape (or an explicit hybrid).
