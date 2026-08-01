# write-legible-embedded-c

Single skill for **host userspace C** and **embedded/kernel/BSP C** (Linux, Zephyr, RT-Thread).

| Branch | Behavior |
|--------|----------|
| **HOST** | Vendored Base (`references/base/` = write-legible-c) |
| **EMBEDDED** | Hard Order: Active Git Root → Path Class → HOT / DRIVER / ORCH |

## Layout

```text
write-legible-embedded-c/
├── SKILL.md
├── README.md
├── NOTICE
├── agents/openai.yaml
└── references/
    ├── base/          # third-party write-legible-c (MIT, 7etsuo)
    ├── classify-repo.md
    ├── path-class.md
    ├── hot-rules.md
    └── platforms/
```

## Attribution

Embeds [write-legible-c](https://github.com/7etsuo/write-legible-c) (7etsuo, MIT) under `references/base/`. Overlay rules are team work. See `NOTICE`.
