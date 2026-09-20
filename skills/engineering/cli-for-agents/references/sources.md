# What is inside this skill

This folder is complete offline. Licensed upstream works are copied under
`vendor/`. A run does not need `npx`, `gh skill`, or `git clone`.

See [NOTICE](../NOTICE) and [vendor/NOTICE.md](../vendor/NOTICE.md) for licenses
and the git SHAs captured at copy time.

## Layout

```
cli-for-agents/
├── SKILL.md                          # entry / router (license: SEE NOTICE)
├── NOTICE                            # mixed-license map
├── references/
│   ├── human-cli.md                  # index into vendor/clig
│   ├── agent-cli.md                  # index into vendor/agent-cli-design
│   ├── scorecard.md                  # this skill's 0–21 scoring form
│   ├── runtimes.md                   # this skill's own runtime map
│   └── sources.md                    # this file
└── vendor/
    ├── NOTICE.md
    ├── clig/
    │   ├── LICENSE                   # CC BY-SA 4.0
    │   └── cli-guidelines.md         # full clig.dev source
    └── agent-cli-design/
        ├── LICENSE.md                # MIT
        ├── agent-cli-design.md       # upstream SKILL.md, renamed so it is not discovered
        ├── metadata.json
        └── references/
            ├── help-anatomy.md
            ├── audit-checklist.md
            ├── probe.sh
            └── probe-tests.sh
```

## How to load

- Everyday constraints: `SKILL.md` plus the matching `references/` index plus `runtimes.md`.
- Help page templates, probe, audit form: files under `vendor/agent-cli-design/`.
- Human-CLI rule not settled by the index: `vendor/clig/cli-guidelines.md`.
- Scoring axes: `references/scorecard.md`.

## Probe self-check

`vendor/agent-cli-design/references/probe-tests.sh` checks the harness. It is
not a skill release gate. `sh -n` on `probe.sh` is the syntax check this skill
claims. Do not report the suite as all-green unless you just ran it on this
host. Some `timeout(1)` builds reject `timeout -k 1 1 true` and then mis-report
a valid deadline as "timeout lacks -k".

## Refresh (optional, online)

Only when the user asks to update the vendored copies. Offline machines skip this section.

```bash
git clone --depth 1 https://github.com/cli-guidelines/cli-guidelines.git
git clone --depth 1 https://github.com/pnocera/agent-cli-design.git
```

Replace `vendor/clig/cli-guidelines.md` from `cli-guidelines/content/_index.md`.
Replace `vendor/agent-cli-design/` from `agent-cli-design/skills/agent-cli-design/`, then rename that copy's `SKILL.md` to `agent-cli-design.md`.
Update SHAs in `vendor/NOTICE.md`.

Do not vendor `jpoehnelt/skills/agent-dx-cli-scale` (no LICENSE in that repo).
Change `references/scorecard.md` if this skill's scoring form needs an update.

Do not rewrite vendor files by hand to keep them "in sync" with the indexes. Change the indexes if this skill needs a different operational summary.
