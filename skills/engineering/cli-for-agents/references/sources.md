# What is inside this skill

This folder is complete offline. The three upstream works are copied under `vendor/`. A run does not need `npx`, `gh skill`, or `git clone`.

See [vendor/NOTICE.md](../vendor/NOTICE.md) for licenses and the git SHAs captured at copy time.

## Layout

```
cli-for-agents/
├── SKILL.md                          # entry / router
├── NOTICE                            # wrapper provenance; vendor SHAs in vendor/NOTICE.md
├── references/
│   ├── human-cli.md                  # index into vendor/clig
│   ├── agent-cli.md                  # index into vendor/agent-cli-design
│   ├── scorecard.md                  # index into vendor/agent-dx-cli-scale
│   ├── runtimes.md                   # this skill's own runtime map
│   └── sources.md                    # this file
└── vendor/
    ├── NOTICE.md
    ├── clig/
    │   ├── LICENSE                   # CC BY-SA 4.0
    │   └── cli-guidelines.md         # full clig.dev source
    ├── agent-cli-design/
    │   ├── LICENSE.md                # MIT
    │   ├── agent-cli-design.md       # upstream SKILL.md, renamed so it is not discovered
    │   ├── metadata.json
    │   └── references/
    │       ├── help-anatomy.md
    │       ├── audit-checklist.md
    │       ├── probe.sh
    │       └── probe-tests.sh
    └── agent-dx-cli-scale/
        ├── agent-dx-cli-scale.md     # upstream SKILL.md, renamed so it is not discovered
        └── UPSTREAM-README.md
```

## How to load

- Everyday constraints: `SKILL.md` plus the matching `references/` index plus `runtimes.md`.
- Help page templates, probe, audit form: files under `vendor/agent-cli-design/`.
- Human-CLI rule not settled by the index: `vendor/clig/cli-guidelines.md`.
- Scoring axes: `vendor/agent-dx-cli-scale/agent-dx-cli-scale.md`.

## Refresh (optional, online)

Only when the user asks to update the vendored copies. Offline machines skip this section.

```bash
git clone --depth 1 https://github.com/cli-guidelines/cli-guidelines.git
git clone --depth 1 https://github.com/pnocera/agent-cli-design.git
git clone --depth 1 https://github.com/jpoehnelt/skills.git
```

Replace `vendor/clig/cli-guidelines.md` from `cli-guidelines/content/_index.md`.
Replace `vendor/agent-cli-design/` from `agent-cli-design/skills/agent-cli-design/`, then rename that copy's `SKILL.md` to `agent-cli-design.md`.
Replace `vendor/agent-dx-cli-scale/agent-dx-cli-scale.md` from `skills/agent-dx-cli-scale/SKILL.md` (keep the local filename).
Update SHAs in `vendor/NOTICE.md`.

Do not rewrite vendor files by hand to keep them "in sync" with the indexes. Change the indexes if this skill needs a different operational summary.
