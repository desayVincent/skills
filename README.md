# Skills

Team agent skills for real embedded / product engineering — managed like [mattpocock/skills](https://github.com/mattpocock/skills): **one git monorepo**, many skill folders.

## Layout

```text
skills/                              ← this repository root
├── README.md
├── skills/
│   ├── engineering/                 ← code & platform work
│   │   ├── write-legible-embedded-c/
│   │   ├── deep-modules-c/          ← Matt-derived, C/C++ deep modules
│   │   ├── domain-model-c/          ← Matt-derived, C/C++ domain language
│   │   └── improve-architecture-c/  ← Matt-derived, C/C++ architecture scan
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
| [deep-modules-c](./skills/engineering/deep-modules-c/) | `/deep-modules-c` | Deep-module vocabulary for C/C++ / SDK (module, interface, depth, seam, ops). Derived from Matt’s `codebase-design` (MIT); renamed to avoid collision. |
| [domain-model-c](./skills/engineering/domain-model-c/) | `/domain-model-c` | Ubiquitous language + `CONTEXT.md` / ADRs for C/C++ SDK (session, stream, message, error semantics). Derived from Matt’s `domain-modeling` (MIT). |
| [improve-architecture-c](./skills/engineering/improve-architecture-c/) | `/improve-architecture-c` | Scan C/C++ trees for deepening opportunities → controlled-Chinese HTML report → inline grill. **Self-contained** (no sibling skill required). Derived from Matt’s `improve-codebase-architecture` (MIT). |

**Suggested flow (optional composition):** `domain-model-c` → `deep-modules-c` → `improve-architecture-c` → `write-legible-embedded-c`. Each skill runs alone if only one is installed. Line-level over-engineering on diffs: upstream **`ponytail-review`** (not vendored here).

## Install (Grok)

**Whole monorepo** (discovers every skill under `skills/` recursively):

```toml
# ~/.grok/config.toml
[skills]
paths = ["/absolute/path/to/this-repo"]
```

**Or copy one skill**:

```bash
cp -a skills/engineering/deep-modules-c ~/.grok/skills/
cp -a skills/engineering/domain-model-c ~/.grok/skills/
cp -a skills/engineering/improve-architecture-c ~/.grok/skills/
cp -a skills/engineering/write-legible-embedded-c ~/.grok/skills/
```

**Repo-local** (per product tree):

```bash
mkdir -p .grok/skills
cp -a /path/to/this-repo/skills/engineering/* .grok/skills/
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

Matt-derived skills (`deep-modules-c`, `domain-model-c`, `improve-architecture-c`) keep MIT [LICENSE](./skills/engineering/deep-modules-c/LICENSE) and pin upstream in `NOTICE`.

## Design notes

- Domain glossary for the C skill: [docs/domain/write-legible-embedded-c-CONTEXT.md](./docs/domain/write-legible-embedded-c-CONTEXT.md)
- ADR: [docs/adr/0001-base-plus-embedded-overlay-bundle.md](./docs/adr/0001-base-plus-embedded-overlay-bundle.md)
- ADR: [docs/adr/0002-matt-skills-c-fork.md](./docs/adr/0002-matt-skills-c-fork.md)
