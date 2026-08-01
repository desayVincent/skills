# Agents

This repository holds **agent skills** only (prompt packages), not product application code.

## Conventions

- One skill = one directory under `skills/<area>/` with a `SKILL.md`.
- Self-contained skills: put references next to `SKILL.md`, not at repo root.
- User-invoked orchestration skills should stay small; reusable discipline can be model-invoked.
- When vendoring third-party skills or standards, keep `NOTICE` / `LICENSE` and do not claim authorship of their text.

## Install for local Grok

```toml
[skills]
paths = ["/absolute/path/to/this-repo"]
```
