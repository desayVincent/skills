# write-legible-embedded-c

Single skill for **host userspace C** and **embedded/kernel/BSP C** (Linux, Zephyr, RT-Thread).

**Classify before styling.** Model-invoked description covers both host and embedded branches.

| Branch | Behavior |
|--------|----------|
| **HOST** | Vendored Base (`references/base/` = write-legible-c) |
| **EMBEDDED** | Hard Order: Active Git Root → Path Class → HOT / DRIVER / ORCH |

**L1 platforms:** Linux appendix is the deep profile; Zephyr/RT-Thread are thinner decision tables by design.

**Base packaging:** normative rules live in `references/base/c-standard.md` §§1–14; examples and provenance are disclosed beside it (same MIT text, progressive disclosure only).

**Classification record:** fill the template in `references/classify-repo.md` on every EMBEDDED (and when useful HOST) delivery — that is the artifact for Path/CTX (not mandatory in-tree `/* PATH */` comments).

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
    ├── concurrency-memory.md
    ├── path-class.md
    ├── hot-rules.md
    └── platforms/
```

## Attribution

Embeds [write-legible-c](https://github.com/7etsuo/write-legible-c) (7etsuo, MIT) under `references/base/`. Overlay rules are team work. See `NOTICE`.
