# Skills

Team agent skills for real embedded / product engineering — managed like [mattpocock/skills](https://github.com/mattpocock/skills): **one git monorepo**, many skill folders.

## Layout

```text
skills/                              ← this repository root
├── README.md
├── skills/
│   ├── engineering/                 ← code & platform work
│   │   └── write-legible-embedded-c/
│   ├── productivity/                ← (future) grill, docs helpers, …
│   └── in-progress/                 ← (future) not ready to share
└── docs/
    ├── adr/                         ← decisions about the skills themselves
    └── domain/                      ← glossaries for skill design
```

Each skill is a directory with at least `SKILL.md`. Optional: `references/`, `agents/`, `README.md`, `NOTICE`.

## Skills

### Engineering

| Skill | Invoke | Purpose |
|-------|--------|---------|
| [write-legible-embedded-c](./skills/engineering/write-legible-embedded-c/) | `/write-legible-embedded-c` | Legible C for host **and** embedded (Linux / Zephyr / RT-Thread, BSP, ISR). Vendors Base [write-legible-c](https://github.com/7etsuo/write-legible-c) (MIT) under `references/base/`. |

## Install (Grok)

**Whole monorepo** (discovers every skill under `skills/` recursively):

```toml
# ~/.grok/config.toml
[skills]
paths = ["/absolute/path/to/this-repo"]
```

**Or copy one skill**:

```bash
cp -a skills/engineering/write-legible-embedded-c ~/.grok/skills/
```

**Repo-local** (per product tree):

```bash
mkdir -p .grok/skills
cp -a /path/to/this-repo/skills/engineering/write-legible-embedded-c .grok/skills/
```

Reload Grok / new session after install.

### Other agents (optional)

If you use [skills.sh](https://skills.sh) style tooling later, point it at this GitHub repo the same way you would `mattpocock/skills`. Until then, `cp` or `paths` is enough.

## Adding a skill

1. Create `skills/<area>/<skill-name>/SKILL.md` (`area` = `engineering` | `productivity` | `in-progress` | …).
2. Keep the skill **self-contained** (references live under that folder).
3. Document it in this README table.
4. Prefer small, composable skills over one mega-skill (unless a single entrypoint is intentional, as with write-legible-embedded-c).

## Third-party

See each skill’s `NOTICE` when vendoring upstream content. Do not rebrand third-party text as original.

## Design notes

- Domain glossary for the C skill: [docs/domain/write-legible-embedded-c-CONTEXT.md](./docs/domain/write-legible-embedded-c-CONTEXT.md)
- ADR: [docs/adr/0001-base-plus-embedded-overlay-bundle.md](./docs/adr/0001-base-plus-embedded-overlay-bundle.md)
