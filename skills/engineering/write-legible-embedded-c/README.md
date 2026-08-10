# write-legible-embedded-c

Single skill for **host userspace C** and **embedded/kernel/BSP C** (Linux, Zephyr, RT-Thread).

**Correctness before shape; classify before styling.** Model-invoked description
front-loads **HOST|EMBEDDED** write/review triggers (no project-specific jargon).

| Branch | Behavior |
|--------|----------|
| **ALL** | `references/c-quality.md` correctness floor before legibility rules |
| **HOST** | Vendored Base applied through the quality floor; both the quality checklist and Base §14 are fail-closed |
| **EMBEDDED** | Hard Order: Active Git Root → Path Class → HOT / DRIVER / ORCH |

**L1 platforms:** Linux appendix is the deep profile; Zephyr/RT-Thread are thinner decision tables by design.

**Base packaging:** normative rules live in `references/base/c-standard.md` §§1–14; examples and provenance are disclosed beside it (same MIT text, progressive disclosure only).

**Classification record:** mandatory on every EMBEDDED delivery (multi-region when Path/CTX differ; HOT requires `HOT call notes`). Template: `references/classify-repo.md`. Incomplete record ⇒ incomplete delivery. Not satisfied by in-tree `/* PATH */` comments alone.

## Layout

```text
write-legible-embedded-c/
├── SKILL.md
├── README.md
├── NOTICE
├── agents/openai.yaml
└── references/
    ├── base/                    # third-party write-legible-c (MIT, 7etsuo)
    │   ├── write-legible-c-SKILL.md
    │   ├── c-standard.md        # §§1–14 normative + gate
    │   ├── skeleton.md          # disclosed (greenfield)
    │   ├── near-miss-map-eat.md # disclosed (near-miss)
    │   ├── repository-level.md  # disclosed (AGENTS.md work)
    │   ├── PROVENANCE.md        # disclosed (human-facing)
    │   ├── LICENSE
    │   └── UPSTREAM-plugin.json
    ├── classify-repo.md
    ├── c-quality.md
    ├── concurrency-memory.md
    ├── path-class.md
    ├── hot-rules.md
    └── platforms/
```

## Attribution

Embeds [write-legible-c](https://github.com/7etsuo/write-legible-c) (7etsuo, MIT) under `references/base/`. Overlay rules are team work. See `NOTICE`.
