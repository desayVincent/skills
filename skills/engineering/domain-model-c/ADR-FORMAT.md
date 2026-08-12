# ADR format

Load when writing an ADR. **Whether** to write an ADR is the three-gate in
[SKILL.md](SKILL.md). This file is path and template only.

Path: `docs/adr/0001-slug.md` (increment highest N).

## Template

```md
# {Short title}

{1–3 sentences: context, decision, why.}
```

Optional only when useful: **Status**, **Considered Options**, **Consequences**.

## C/C++ SDK examples that usually pass the three-gate

- Opaque handles on the public surface
- Stable public error space vs OS errno passthrough
- Buffer ownership across submit/complete
- Media ↔ Transport integration (events vs shared globals)
- “No alloc on ISR path” or partner timing constraints not visible in code

## Usually skip

Local helper names, easy reversals, pure style (brace/comment taste).
