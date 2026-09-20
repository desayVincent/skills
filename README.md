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
│   │   ├── improve-architecture-c/  ← Matt-derived, C/C++ architecture scan
│   │   ├── spawn/                   ← portable task delegation
│   │   ├── systematic-debugging/    ← evidence-first debugging
│   │   ├── tech-doc-style-chinese/  ← Chinese technical writing
│   │   ├── receiving-code-review/   ← verify and address review feedback
│   │   └── cli-for-agents/          ← design / change / audit agent-ready CLIs
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
| [spawn](./skills/engineering/spawn/) | `/spawn` | 按任务独立性、共享资源和验证条件分工；模型与角色由宿主或项目决定。 |
| [systematic-debugging](./skills/engineering/systematic-debugging/) | `/systematic-debugging` | 先取证、验证根因，再修复；支持嵌入式和无法立即复现的环境。 |
| [receiving-code-review](./skills/engineering/receiving-code-review/) | `/receiving-code-review` | 核实已有审查意见，在授权范围内处理；存疑项不阻塞独立修改。 |
| [tech-doc-style-chinese](./skills/engineering/tech-doc-style-chinese/) | `/tech-doc-style-chinese` | 中文技术写作、旧文更新与表达整理；保留技术事实，按需加载写作方法及模式检查。 |
| [cli-for-agents](./skills/engineering/cli-for-agents/) | `/cli-for-agents` | 设计、改动或审计 Agent 可驱动的 CLI（Design / Change / Audit）。Vendors [clig.dev](https://clig.dev/) (CC BY-SA 4.0) and [pnocera/agent-cli-design](https://github.com/pnocera/agent-cli-design) (MIT) under `vendor/`. Mixed license: see that skill's `NOTICE`. |

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

对支持 `~/.agents/skills/` 的宿主，从本仓根目录安装个人技能软链接：

```bash
personal_skills_root="$(git rev-parse --show-toplevel)/skills/engineering"
mkdir -p "$HOME/.agents/skills"
for name in spawn systematic-debugging receiving-code-review tech-doc-style-chinese cli-for-agents; do
  dst="$HOME/.agents/skills/$name"
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    printf '跳过已有入口，请检查目标：%s\n' "$dst"
    continue
  fi
  ln -s "$personal_skills_root/$name" "$dst"
done
```

各 Agent 的专属技能目录可链接到 `~/.agents/skills/<name>`，共用同一份仓库文件。

已有同名入口时先检查目标，不覆盖目录或复制出第二份。移走宿主专属技能目录中的旧副本，避免重复发现；个人仓库是维护来源。宿主不支持该目录时，使用其技能路径配置指向本仓。按需重启宿主以刷新列表。

这些技能均可独立使用，不串联完整 Superpowers 流程。与 `diagnosing-bugs` 等已有调试技能重叠时，由用户或项目选择入口，不叠加两套强制流程。模型选择、硬件访问和外部操作权限继续由宿主及项目规则决定。

If you use [skills.sh](https://skills.sh) style tooling later, point it at this GitHub repo the same way you would `mattpocock/skills`.

## Adding a skill

1. Create `skills/<area>/<skill-name>/SKILL.md` (`area` = `engineering` | `productivity` | `in-progress` | …).
2. Keep the skill **self-contained** (references live under that folder).
3. Document it in this README table.
4. Prefer small, composable skills over one mega-skill (unless a single entrypoint is intentional, as with write-legible-embedded-c).

## Third-party

See each skill’s `NOTICE` when vendoring upstream content. Do not rebrand third-party text as original.

Matt-derived skills (`deep-modules-c`, `domain-model-c`, `improve-architecture-c`) keep MIT [LICENSE](./skills/engineering/deep-modules-c/LICENSE) and pin upstream in `NOTICE`.

`systematic-debugging` and `receiving-code-review` are concise personal adaptations of `obra/superpowers`; `spawn` combines the previous personal skill with its independent-task guidance. Each folder retains the upstream MIT license and pinned provenance in `NOTICE`. These are maintained adaptations, not unmodified upstream distributions.

`cli-for-agents` is mixed-license: wrapper indexes and `references/scorecard.md` are team text; `vendor/clig/` is CC BY-SA 4.0; `vendor/agent-cli-design/` is MIT. It does not vendor `jpoehnelt/skills/agent-dx-cli-scale` (no LICENSE in that repo). See that skill's `NOTICE`.

## Design notes

- Domain glossary for the C skill: [docs/domain/write-legible-embedded-c-CONTEXT.md](./docs/domain/write-legible-embedded-c-CONTEXT.md)
- ADR: [docs/adr/0001-base-plus-embedded-overlay-bundle.md](./docs/adr/0001-base-plus-embedded-overlay-bundle.md)
- ADR: [docs/adr/0002-matt-skills-c-fork.md](./docs/adr/0002-matt-skills-c-fork.md)
